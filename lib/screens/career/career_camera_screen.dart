import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:ea_master_demo/pipeline/coach_levels.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ea_master_demo/const/appTheme.dart';
import 'package:ea_master_demo/pipeline/career_levels.dart';
import 'package:ea_master_demo/pipeline/coach_models.dart';
import 'package:ea_master_demo/pipeline/cricket_coach_engine.dart';
import 'package:ea_master_demo/pipeline/shot_segment_detector.dart';
import 'package:ea_master_demo/services/coaching_bootstrap.dart';
import 'package:ea_master_demo/services/mlkit_pose_service.dart';
import 'package:ea_master_demo/services/pose_pipeline_controller.dart';
import 'package:ea_master_demo/services/career_service.dart';
import 'package:ea_master_demo/widgets/pose_skeleton_overlay.dart';
import 'package:ea_master_demo/services/tts_service.dart';

enum CareerCameraState {
  loading,
  error,
  countdownToStart,
  waitingForSwing,
  recordingSwing,
  processing,
  showingResult,
  victory,
  failed
}

class ObjectiveProgress {
  final ShotObjective objective;
  int currentCount = 0;
  int attemptsUsed = 0;
  ObjectiveProgress(this.objective);
  bool get isComplete => currentCount >= objective.count;
  bool get hasFailed => attemptsUsed >= objective.maxAttempts && !isComplete;
}

class CareerCameraScreen extends StatefulWidget {
  final CareerLevel level;

  const CareerCameraScreen({super.key, required this.level});

  @override
  State<CareerCameraScreen> createState() => _CareerCameraScreenState();
}

class _CareerCameraScreenState extends State<CareerCameraScreen> {
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
  CareerCameraState _state = CareerCameraState.loading;
  String? _errorMsg;

  late List<ObjectiveProgress> _progress;

  Map<String, dynamic>? _liveJoints;
  
  int _countdown = 5;
  Timer? _countdownTimer;
  ShotCoachResult? _lastResult;

  StreamSubscription? _engineStateSub;
  StreamSubscription? _engineResultSub;

  @override
  void initState() {
    super.initState();
    _progress = widget.level.objectives.map((o) => ObjectiveProgress(o)).toList();

    _posePipeline.onPoseResult = (res) {
      if (mounted) setState(() => _liveJoints = res.joints);
      if (_state == CareerCameraState.waitingForSwing || _state == CareerCameraState.recordingSwing) {
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
          _state = CareerCameraState.error;
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
        if (_state == CareerCameraState.showingResult || _state == CareerCameraState.victory || _state == CareerCameraState.failed) return;

        if (engineState == CoachRuntimeState.recordingSwing) {
          setState(() => _state = CareerCameraState.recordingSwing);
        } else if (engineState == CoachRuntimeState.processing) {
          setState(() => _state = CareerCameraState.processing);
        } else if (engineState == CoachRuntimeState.idle) {
          setState(() => _state = CareerCameraState.waitingForSwing);
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
      if (widget.level.objectives.isNotEmpty) {
         final firstObj = widget.level.objectives.first;
         await _tts.speakObjective(widget.level.totalShots.toString(), firstObj.shotName, firstObj.minAccuracy.toString());
      }
      
      _startCountdown(isInitial: true);

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Failed to init: $e';
          _state = CareerCameraState.error;
        });
      }
    }
  }

  void _startCountdown({bool isInitial = false}) {
    _engine.stop(); // Ensure engine is not running during countdown
    setState(() {
      _state = CareerCameraState.countdownToStart;
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
        if (_countdown == 2 && !isInitial) {
           _tts.speakReady();
        }
        if (_countdown <= 0) {
          timer.cancel();
          if (isInitial) _tts.speakReady();
          _engine.start(); // Engine becomes idle waiting for swing
          _state = CareerCameraState.waitingForSwing;
        }
      });
    });
  }

  void _handleShotResult(ShotCoachResult result) async {
    _engine.stop();
    _lastResult = result;
    
    // Find the first incomplete objective
    ObjectiveProgress? activeProgress;
    for (var p in _progress) {
      if (!p.isComplete) {
        activeProgress = p;
        break;
      }
    }

    bool isExpectedShot = true;
    if (activeProgress != null) {
      activeProgress.attemptsUsed++;
      if (activeProgress.objective.shotName.toLowerCase() == result.shotLabel.toLowerCase()) {
        if (result.accuracyPercent >= activeProgress.objective.minAccuracy) {
          activeProgress.currentCount++;
        }
      } else {
        isExpectedShot = false;
      }
    }

    bool allComplete = _progress.every((p) => p.isComplete);
    bool anyFailed = _progress.any((p) => p.hasFailed);

    CareerCameraState nextState = CareerCameraState.showingResult;
    if (anyFailed) {
      nextState = CareerCameraState.failed;
    } else if (allComplete) {
      nextState = CareerCameraState.victory;
    }

    setState(() {
      _state = nextState;
    });

    if (!isExpectedShot && activeProgress != null) {
      _tts.speakMismatchedShot(activeProgress.objective.shotName);
    } else {
      _tts.speakAnalysis(result.shotLabel, result.accuracyPercent, result.strongArea, result.weakArea, "");
    }

    if (nextState == CareerCameraState.victory) {
      _tts.speakSuccess();
      _saveProgress();
    } else if (nextState == CareerCameraState.failed) {
      _tts.speakFailure();
    } else {
      await _tts.waitUntilDone();
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _state != CareerCameraState.victory && _state != CareerCameraState.failed) {
        _startCountdown();
      }
    }
  }

  Future<void> _saveProgress() async {
    final svc = Get.find<CareerService>();
    await svc.saveLevelProgress(widget.level.levelNumber, {
      'xpEarned': widget.level.xpReward,
      'skillEarned': widget.level.skillReward,
    });
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
    if (_state == CareerCameraState.loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16),
            Text('Initializing AI Camera...', style: TextStyle(color: Colors.white)),
          ],
        )),
      );
    }
    
    if (_state == CareerCameraState.error) {
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
        title: Text('Level ${widget.level.levelNumber} Training', style: const TextStyle(color: Colors.white)),
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

          // Top Objectives Overlay
          Positioned(
            top: 100, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: _progress.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${p.objective.shotName} (>${p.objective.minAccuracy}%)', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        Column(
                           crossAxisAlignment: CrossAxisAlignment.end,
                           children: [
                              Text('${p.currentCount} / ${p.objective.count}', style: TextStyle(color: p.isComplete ? AppColors.accentGreen : AppColors.accent, fontWeight: FontWeight.bold)),
                              Text('Attempts: ${p.attemptsUsed} / ${p.objective.maxAttempts}', style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
                           ]
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Center Status UI
          Center(
            child: _buildCenterUI(),
          ),

          // Victory Overlay
          if (_state == CareerCameraState.victory)
            Container(
              color: const Color(0xFF0F172A).withOpacity(0.95),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: const BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 60, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 24),
                    const Text('LEVEL COMPLETE!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    Text('+${widget.level.xpReward} XP Earned', style: const TextStyle(color: AppColors.accentGreen, fontSize: 18)),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        // Return to career screen (pops camera and level detail)
                        Get.until((route) => route.isFirst);
                      },
                      child: const Text('Return to Career Path', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
          
          // Failed Overlay
          if (_state == CareerCameraState.failed)
            Container(
              color: const Color(0xFF0F172A).withOpacity(0.95),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 60, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 24),
                    const Text('MISSION FAILED', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    const Text('You ran out of attempts.', style: TextStyle(color: Colors.redAccent, fontSize: 18)),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        // Return to career screen
                        Get.until((route) => route.isFirst);
                      },
                      child: const Text('Return to Career Path', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCenterUI() {
    switch (_state) {
      case CareerCameraState.countdownToStart:
        return Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          child: Text('$_countdown', style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold)),
        );
      case CareerCameraState.waitingForSwing:
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
            const Text('AI Camera Tracking Active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Text('Position yourself and play the shot', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        );
      case CareerCameraState.recordingSwing:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.radio_button_checked, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            const Text('RECORDING', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        );
      case CareerCameraState.processing:
        return Card(
          color: Colors.black87,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: AppColors.accent),
                SizedBox(height: 16),
                Text('Analyzing biomechanics...', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
      case CareerCameraState.showingResult:
        if (_lastResult == null) return const SizedBox.shrink();
        
        bool isValidForObj = false;
        bool isMismatch = true;
        String expectedShot = "";

        // Check against the FIRST incomplete objective only to avoid confusion
        for (var obj in widget.level.objectives) {
          expectedShot = obj.shotName;
          if (obj.shotName.toLowerCase() == _lastResult!.shotLabel.toLowerCase()) {
            isMismatch = false;
            if (_lastResult!.accuracyPercent >= obj.minAccuracy) {
              isValidForObj = true;
            }
            break;
          }
          break; // only check the first active objective
        }

        if (isMismatch) {
          return Card(
            color: Colors.red.shade900.withOpacity(0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('WRONG SHOT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  const Icon(Icons.error_outline, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text('Detected: ${_lastResult!.shotLabel}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  Text('Expected: $expectedShot', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }

        return Card(
          color: isValidForObj ? Colors.green.shade900.withOpacity(0.9) : Colors.red.shade900.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isValidForObj ? AppColors.accentGreen : Colors.redAccent)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isValidForObj ? 'SUCCESS!' : 'MISSED OBJECTIVE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 12),
                Text('${_lastResult!.accuracyPercent}%', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                Text(_lastResult!.shotLabel, style: const TextStyle(color: Colors.white70, fontSize: 18)),
                const SizedBox(height: 16),
                Text('Strong: ${_lastResult!.strongArea}', style: const TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
                Text('Improve: ${_lastResult!.weakArea}', style: const TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
