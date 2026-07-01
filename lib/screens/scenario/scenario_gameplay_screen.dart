import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:ea_master_demo/pipeline/coach_levels.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ea_master_demo/const/appTheme.dart';
import 'package:ea_master_demo/pipeline/coach_models.dart';
import 'package:ea_master_demo/pipeline/cricket_coach_engine.dart';
import 'package:ea_master_demo/pipeline/shot_segment_detector.dart';
import 'package:ea_master_demo/services/coaching_bootstrap.dart';
import 'package:ea_master_demo/services/mlkit_pose_service.dart';
import 'package:ea_master_demo/services/pose_pipeline_controller.dart';
import 'package:ea_master_demo/widgets/pose_skeleton_overlay.dart';
import 'package:ea_master_demo/services/tts_service.dart';
import 'scenario_models.dart';

enum ScenarioGameState {
  loading,
  error,
  showingDelivery, // Shows the ball type and target
  countdownToStart, // 5 second countdown before shot
  waitingForSwing,
  recordingSwing,
  processing,
  showingShotResult, // showing 4, 6, out, etc
  matchOver
}

class ScenarioGameplayScreen extends StatefulWidget {
  final Scenario scenario;
  final Team playerTeam;

  const ScenarioGameplayScreen({
    super.key,
    required this.scenario,
    required this.playerTeam,
  });

  @override
  State<ScenarioGameplayScreen> createState() => _ScenarioGameplayScreenState();
}

class _ScenarioGameplayScreenState extends State<ScenarioGameplayScreen> {
  CameraController? _camera;
  final MlkitPoseService _pose = MlkitPoseService();
  late final PosePipelineController _posePipeline = PosePipelineController(_pose);
  final TtsService _tts = Get.find<TtsService>();

  final CricketCoachEngine _engine = CricketCoachEngine(
    segmentDetector: ShotSegmentDetector(
      startThreshold: 0.015,
      endThreshold: 0.010,
      minPeakSpeed: 0.035,
      minFrames: 10,
      maxFramesSafety: 100,
    ),
    cooldownBetweenSwings: const Duration(milliseconds: 100),
  );

  Map<String, dynamic>? _benchmarks;
  ScenarioGameState _state = ScenarioGameState.loading;
  String? _errorMsg;
  Map<String, dynamic>? _liveJoints;
  
  int _countdown = 5;
  Timer? _countdownTimer;
  ShotCoachResult? _lastResult;

  StreamSubscription? _engineStateSub;
  StreamSubscription? _engineResultSub;

  // Match state
  late int runsNeeded;
  late int ballsLeft;
  int runsScored = 0;
  int ballsFaced = 0;
  int correctShots = 0;
  int incorrectShots = 0;
  
  String currentDelivery = '';
  List<String> idealShotsForDelivery = [];
  int _deliveryScore = 0;
  bool _deliveryIsWicket = false;
  bool _deliveryCorrectShot = false;

  final List<String> deliveries = [
    'Bouncer', 'Yorker', 'Leg-side Delivery', 'Off-side Full Ball', 'Spin Ball', 'Slower Ball', 'Good Length Ball'
  ];

  @override
  void initState() {
    super.initState();
    runsNeeded = widget.scenario.runsNeeded;
    ballsLeft = widget.scenario.ballsLeft;

    _posePipeline.onPoseResult = (res) {
      if (mounted) setState(() => _liveJoints = res.joints);
      if (_state == ScenarioGameState.waitingForSwing || _state == ScenarioGameState.recordingSwing) {
        _engine.ingestLandmarks(res.joints);
      }
    };

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _errorMsg = 'Camera permission denied.';
          _state = ScenarioGameState.error;
        });
        return;
      }

      _benchmarks = await CoachingBootstrap.loadBenchmarks();
      await _pose.init();
      
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('No camera found');
      
      final frontCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _camera = CameraController(
        frontCam,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      await _camera!.initialize();

      _engineStateSub = _engine.runtimeState.listen((engineState) {
        if (!mounted) return;
        if (_state == ScenarioGameState.showingShotResult || _state == ScenarioGameState.matchOver) return;

        if (engineState == CoachRuntimeState.recordingSwing) {
          setState(() => _state = ScenarioGameState.recordingSwing);
        } else if (engineState == CoachRuntimeState.processing) {
          setState(() => _state = ScenarioGameState.processing);
        } else if (engineState == CoachRuntimeState.idle && _state == ScenarioGameState.waitingForSwing) {
          // Stay in waiting
        }
      });

      _engineResultSub = _engine.results.listen((res) {
        if (!mounted || res == null) return;
        _handleShotResult(res);
      });

      _engine.configure(CoachSessionConfig(
        mode: ClassificationMode.open,
        benchmarks: _benchmarks!,
        policy: FrameAggregationPolicy.peakDisplacementFromStart,
      ));

      await _camera!.startImageStream((image) {
        if (_camera == null) return;
        _posePipeline.handleCameraImage(image, _camera!.description.sensorOrientation, _camera!.description.lensDirection);
      });

      await _tts.speakWelcome();
      await _tts.speakScenarioObjective(runsNeeded, ballsLeft);

      _nextDelivery();

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Failed to init: $e';
          _state = ScenarioGameState.error;
        });
      }
    }
  }

  void _nextDelivery() {
    if (runsNeeded <= 0 || ballsLeft <= 0) {
      bool isWin = runsNeeded <= 0;
      _tts.speakScenarioEnd(isWin);
      setState(() {
        _state = ScenarioGameState.matchOver;
      });
      return;
    }

    // Generate delivery
    currentDelivery = deliveries[Random().nextInt(deliveries.length)];
    idealShotsForDelivery = _getIdealShots(currentDelivery);

    setState(() {
      _state = ScenarioGameState.showingDelivery;
    });

    _tts.speakScenarioNextBall(currentDelivery);

    // Show delivery for 3 seconds, then countdown
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _startCountdown();
    });
  }

  List<String> _getIdealShots(String delivery) {
    switch (delivery) {
      case 'Bouncer': return ['Pull Shot', 'Cut Shot'];
      case 'Yorker': return ['Straight Drive'];
      case 'Leg-side Delivery': return ['Sweep Shot'];
      case 'Off-side Full Ball': return ['Cover Drive'];
      case 'Spin Ball': return ['Sweep Shot', 'Straight Drive'];
      case 'Slower Ball': return ['Cover Drive', 'Pull Shot'];
      case 'Good Length Ball': return ['Straight Drive', 'Cut Shot'];
      default: return ['Straight Drive'];
    }
  }

  void _startCountdown() {
    _engine.stop();
    setState(() {
      _state = ScenarioGameState.countdownToStart;
      _countdown = 5;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          timer.cancel();
          _engine.start();
          _state = ScenarioGameState.waitingForSwing;
        }
      });
    });
  }

  void _handleShotResult(ShotCoachResult result) async {
    _engine.stop();
    _lastResult = result;
    ballsFaced++;
    ballsLeft--;

    bool isCorrectShot = idealShotsForDelivery.contains(result.shotLabel) || 
                         idealShotsForDelivery.any((ideal) => result.shotLabel.contains(ideal));

    _deliveryCorrectShot = isCorrectShot;
    _deliveryIsWicket = false;
    _deliveryScore = 0;

    if (isCorrectShot) {
      correctShots++;
      if (result.accuracyPercent > 80) {
        // High accuracy + correct shot -> High chance of 4/6
        int outcome = Random().nextInt(10);
        _deliveryScore = outcome < 4 ? 6 : 4; // 40% chance of 6, 60% chance of 4
      } else if (result.accuracyPercent > 60) {
        // Medium accuracy
        int outcome = Random().nextInt(10);
        _deliveryScore = outcome < 3 ? 4 : (outcome < 7 ? 2 : 1);
      } else {
        // Low accuracy
        int outcome = Random().nextInt(10);
        _deliveryScore = outcome < 5 ? 1 : 0;
      }
      _tts.speakScenarioResultCorrect(result.shotLabel, _deliveryScore >= 4);
    } else {
      incorrectShots++;
      // Wrong shot -> High chance of dot or wicket
      int outcome = Random().nextInt(10);
      if (outcome < 4) {
        _deliveryIsWicket = true; // 40% chance of Wicket
      } else if (outcome < 7) {
        _deliveryScore = 0; // 30% Dot ball
      } else {
        _deliveryScore = 1; // 30% 1 run edge
      }
      _tts.speakScenarioResultWrong(_deliveryIsWicket);
    }

    runsScored += _deliveryScore;
    runsNeeded -= _deliveryScore;

    setState(() {
      _state = ScenarioGameState.showingShotResult;
    });

    await _tts.waitUntilDone();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted && _state != ScenarioGameState.matchOver) {
      _nextDelivery();
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _countdownTimer?.cancel();
    _engineStateSub?.cancel();
    _engineResultSub?.cancel();
    _engine.dispose();
    if (_camera?.value.isStreamingImages == true) {
      _camera?.stopImageStream();
    }
    _camera?.dispose();
    _pose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == ScenarioGameState.loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16),
            Text('Initializing Scenario Engine...', style: TextStyle(color: Colors.white)),
          ],
        )),
      );
    }
    
    if (_state == ScenarioGameState.error) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(child: Text(_errorMsg ?? 'Unknown Error', style: const TextStyle(color: Colors.red))),
      );
    }

    final camReady = _camera != null && _camera!.value.isInitialized;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text('${widget.scenario.tournamentName} Scenario', style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed, size: 14, color: AppColors.accentGreen),
                const SizedBox(width: 4),
                Text('$runsNeeded off $ballsLeft', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (camReady)
            Center(
              child: AspectRatio(
                aspectRatio: 1 / _camera!.value.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_camera!),
                    CustomPaint(
                      painter: PoseSkeletonOverlay(joints: _liveJoints, mirrorX: true),
                    ),
                  ],
                ),
              ),
            )
          else
            const ColoredBox(color: Colors.black),

          // Top Info Overlay (Score)
          Positioned(
            top: 90, left: 16, right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStatBox('Target', '${widget.scenario.runsNeeded}', AppColors.accent),
                _buildMiniStatBox('Current', '$runsScored / $ballsFaced', Colors.white),
              ],
            ),
          ),

          // Center UI
          Center(
            child: _buildCenterUI(),
          ),

          // Match Over Overlay
          if (_state == ScenarioGameState.matchOver)
            _buildMatchSummary(),
        ],
      ),
    );
  }

  Widget _buildMiniStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCenterUI() {
    switch (_state) {
      case ScenarioGameState.showingDelivery:
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accentGreen, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_baseball, color: AppColors.accentGreen, size: 48),
              const SizedBox(height: 16),
              const Text('Incoming Delivery:', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text(currentDelivery, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Ideal: ${idealShotsForDelivery.join(" or ")}', style: const TextStyle(color: AppColors.accent, fontSize: 14)),
            ],
          ),
        );

      case ScenarioGameState.countdownToStart:
        return Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          child: Text('$_countdown', style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold)),
        );

      case ScenarioGameState.waitingForSwing:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentGreen.withOpacity(0.5), width: 2),
              ),
              child: const Icon(Icons.play_arrow, color: AppColors.accentGreen, size: 40),
            ),
            const SizedBox(height: 12),
            Text('Ball: $currentDelivery', style: const TextStyle(color: AppColors.accentGreen, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Play the shot now!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        );

      case ScenarioGameState.recordingSwing:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.radio_button_checked, color: Colors.redAccent, size: 48),
            SizedBox(height: 12),
            Text('RECORDING SHOT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        );

      case ScenarioGameState.processing:
        return Card(
          color: Colors.black87,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: AppColors.accent),
                SizedBox(height: 16),
                Text('Classifying Shot...', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );

      case ScenarioGameState.showingShotResult:
        Color resColor = _deliveryIsWicket ? Colors.redAccent : (_deliveryCorrectShot ? AppColors.accentGreen : AppColors.accent);
        String title = _deliveryIsWicket ? 'WICKET!' : (_deliveryCorrectShot ? 'GREAT SHOT!' : 'INCORRECT SHOT');
        String runText = _deliveryIsWicket ? 'OUT' : '+$_deliveryScore RUNS';

        return Card(
          color: resColor.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: resColor)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 12),
                Text(runText, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('You played: ${_lastResult?.shotLabel ?? "Unknown"}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Timing Accuracy: ${_lastResult?.accuracyPercent ?? 0}%', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMatchSummary() {
    bool isWin = runsNeeded <= 0;
    Color resultColor = isWin ? AppColors.accentGreen : Colors.redAccent;
    double strikeRate = ballsFaced > 0 ? (runsScored / ballsFaced) * 100 : 0;
    int totalPlayed = correctShots + incorrectShots;
    double correctPct = totalPlayed > 0 ? (correctShots / totalPlayed) * 100 : 0;

    return Container(
      color: const Color(0xFF0F172A).withOpacity(0.95),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: resultColor, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: resultColor.withOpacity(0.1),
                    border: Border.all(color: resultColor, width: 4),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.emoji_events, color: resultColor, size: 48),
                ),
                const SizedBox(height: 24),
                Text(isWin ? 'Victory!' : 'Match Lost', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(isWin ? 'Target Achieved Successfully!' : 'Target Failed. Keep practicing.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                
                // Stats Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _summaryStat('Runs', '$runsScored'),
                          _summaryStat('Balls', '$ballsFaced'),
                          _summaryStat('SR', strikeRate.toStringAsFixed(1)),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text('${correctPct.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.accentGreen, fontSize: 20, fontWeight: FontWeight.bold)),
                              const Text('Correct Shots', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ]
                          ),
                          Column(
                            children: [
                              Text('${(100 - correctPct).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                              const Text('Wrong Shots', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ]
                          ),
                        ]
                      )
                    ]
                  )
                ),
                
                const SizedBox(height: 24),
                
                // Rewards Box (if won)
                if (isWin)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: const [
                            Text('+250', style: TextStyle(color: AppColors.accentGreen, fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('XP Points', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ]
                        ),
                        Container(width: 1, height: 40, color: AppColors.accent.withOpacity(0.2)),
                        Column(
                          children: const [
                            Text('+50', style: TextStyle(color: AppColors.accent, fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('SP Points', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ]
                        ),
                      ]
                    )
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.until((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Continue Training', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
                  )
                )
              ]
            )
          )
        )
      )
    );
  }

  Widget _summaryStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
