import 'dart:async';
import 'dart:io';

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
import 'package:ea_master_demo/services/train_service.dart';
import 'package:ea_master_demo/services/tts_service.dart';
import 'train_models.dart';
import 'train_demo_screen.dart';

enum TrainCameraState {
  loading,
  error,
  showingWelcome,
  gettingReady,
  waitingForSwing,
  recordingSwing,
  processing,
  showingShotResult,
  sessionSummary
}

class TrainCameraScreen extends StatefulWidget {
  final TrainingShot shot;

  const TrainCameraScreen({super.key, required this.shot});

  @override
  State<TrainCameraScreen> createState() => _TrainCameraScreenState();
}

class _TrainCameraScreenState extends State<TrainCameraScreen> {
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
  TrainCameraState _state = TrainCameraState.loading;
  String? _errorMsg;
  Map<String, dynamic>? _liveJoints;
  
  Timer? _resultTimer;
  ShotCoachResult? _lastResult;

  StreamSubscription? _engineStateSub;
  StreamSubscription? _engineResultSub;

  // Session Stats
  int _totalAttempts = 0;
  int _correctAttempts = 0;
  int _failedAttemptsRow = 0;
  double _sumAccuracy = 0;
  
  // Track weaknesses for summary
  Map<String, int> _weaknessCounts = {};
  String _bestStrength = "N/A";

  // State flags for UI
  bool _isCorrectShot = false;

  @override
  void initState() {
    super.initState();
    _posePipeline.onPoseResult = (res) {
      if (mounted) setState(() => _liveJoints = res.joints);
      if (_state == TrainCameraState.waitingForSwing || _state == TrainCameraState.recordingSwing) {
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
          _state = TrainCameraState.error;
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
        if (_state == TrainCameraState.showingShotResult || _state == TrainCameraState.sessionSummary) return;

        if (engineState == CoachRuntimeState.recordingSwing) {
          setState(() => _state = TrainCameraState.recordingSwing);
        } else if (engineState == CoachRuntimeState.processing) {
          setState(() => _state = TrainCameraState.processing);
        } else if (engineState == CoachRuntimeState.idle) {
          setState(() => _state = TrainCameraState.waitingForSwing);
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

      _startTrainingFlow();

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Failed to init: $e';
          _state = TrainCameraState.error;
        });
      }
    }
  }

  void _handleShotResult(ShotCoachResult result) async {
    _engine.stop();
    _lastResult = result;
    _totalAttempts++;
    
    // Strict match validation
    _isCorrectShot = result.shotLabel.toLowerCase().contains(widget.shot.name.toLowerCase());

    if (_isCorrectShot) {
      _correctAttempts++;
      _failedAttemptsRow = 0;
      _sumAccuracy += result.accuracyPercent;
      _bestStrength = result.strongArea;
    } else {
      _failedAttemptsRow++;
    }

    if (result.weakArea.isNotEmpty) {
      _weaknessCounts[result.weakArea] = (_weaknessCounts[result.weakArea] ?? 0) + 1;
    }

    if (_isCorrectShot) {
      _tts.speakAnalysis(result.shotLabel, result.accuracyPercent, result.strongArea, result.weakArea, "");
    } else {
      _tts.speakTrainingWrongShot(widget.shot.name);
    }

    setState(() {
      _state = TrainCameraState.showingShotResult;
    });

    if (_failedAttemptsRow >= 5) {
      _showAssistancePrompt();
    } else {
      await _tts.waitUntilDone();
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _state != TrainCameraState.sessionSummary) {
        _resumeTraining();
      }
    }
  }

  void _startTrainingFlow() async {
    setState(() => _state = TrainCameraState.showingWelcome);
    await _tts.speakTrainingWelcome(widget.shot.name);
    
    _resultTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _state != TrainCameraState.sessionSummary) {
        _resumeTraining(isInitial: true);
      }
    });
  }

  void _resumeTraining({bool isInitial = false}) {
    setState(() => _state = TrainCameraState.gettingReady);
    _tts.speakReady(); // e.g. "Get ready for the shot"
    
    _resultTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _state != TrainCameraState.sessionSummary) {
        _engine.start();
        setState(() => _state = TrainCameraState.waitingForSwing);
      }
    });
  }

  void _showAssistancePrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Need Assistance?', style: TextStyle(color: Colors.white)),
        content: Text('You missed the ${widget.shot.name} 5 times in a row. Would you like to watch the demo video again for proper technique?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _failedAttemptsRow = 0;
              _resumeTraining();
            },
            child: const Text('No, Continue', style: TextStyle(color: AppColors.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _failedAttemptsRow = 0;
              Get.off(() => TrainDemoScreen(shot: widget.shot)); // replace current route
            },
            child: const Text('Watch Demo', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  void _endSession() {
    _engine.stop();
    _resultTimer?.cancel();
    setState(() {
      _state = TrainCameraState.sessionSummary;
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _resultTimer?.cancel();
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
    if (_state == TrainCameraState.loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: AppColors.accentGreen),
            SizedBox(height: 16),
            Text('Initializing AI Tracking...', style: TextStyle(color: Colors.white)),
          ],
        )),
      );
    }
    
    if (_state == TrainCameraState.error) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(child: Text(_errorMsg ?? 'Unknown Error', style: const TextStyle(color: Colors.red))),
      );
    }

    if (_state == TrainCameraState.sessionSummary) {
      return _buildSessionSummary();
    }

    final camReady = _camera != null && _camera!.value.isInitialized;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        leading: const SizedBox(), // Hidden back button to force 'End Session'
        title: Text('${widget.shot.name} Training', style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _endSession,
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

          // Top Info Overlay (REC)
          Positioned(
            top: 100, left: 16, right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('REC', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
                  child: Text('Attempts: $_totalAttempts', style: const TextStyle(color: Colors.white, fontSize: 12)),
                )
              ],
            ),
          ),

          // Center UI
          Center(
            child: _buildCenterUI(),
          ),

          // End Session Button
          if (_state == TrainCameraState.waitingForSwing || _state == TrainCameraState.recordingSwing)
            Positioned(
              bottom: 40, left: 16, right: 16,
              child: ElevatedButton(
                onPressed: _endSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('End Training Session', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildCenterUI() {
    switch (_state) {
      case TrainCameraState.showingWelcome:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Welcome Back', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Today we are practicing the ${widget.shot.name}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        );

      case TrainCameraState.gettingReady:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.hourglass_empty, color: AppColors.accent, size: 48),
            SizedBox(height: 12),
            Text('Get Ready For The Shot', style: TextStyle(color: AppColors.accent, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        );

      case TrainCameraState.waitingForSwing:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentGreen.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.play_arrow, color: AppColors.accentGreen, size: 40),
            ),
            const SizedBox(height: 12),
            Text('AI Tracking: ${widget.shot.name}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Execute the shot with proper technique', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        );

      case TrainCameraState.recordingSwing:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.radio_button_checked, color: Colors.redAccent, size: 48),
            SizedBox(height: 12),
            Text('RECORDING SHOT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        );

      case TrainCameraState.processing:
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: AppColors.accentGreen),
              SizedBox(height: 16),
              Text('Analyzing Technique...', style: TextStyle(color: Colors.white)),
            ],
          ),
        );

      case TrainCameraState.showingShotResult:
        if (!_isCorrectShot) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent, width: 2)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text('No ${widget.shot.name} Detected', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Please perform the correct shot.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.accentGreen, width: 2)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('PERFECT!', style: TextStyle(color: AppColors.accentGreen, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text('${_lastResult?.accuracyPercent ?? 0}%', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
              const Text('Accuracy', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              _buildMetricRow('Timing Quality', 'Good'),
              const SizedBox(height: 8),
              _buildMetricRow('Shot Strength', _lastResult?.strongArea ?? "N/A"),
              const SizedBox(height: 8),
              _buildMetricRow('Confidence', '${(_lastResult!.accuracyPercent * 0.95).toStringAsFixed(1)}%'),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(width: 24),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSessionSummary() {
    double sessionAccuracy = _correctAttempts > 0 ? (_sumAccuracy / _correctAttempts) : 0.0;
    
    // Sort weaknesses to find the most common one
    String mainWeakness = "None detected";
    if (_weaknessCounts.isNotEmpty) {
      var sortedWeaknesses = _weaknessCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      mainWeakness = sortedWeaknesses.first.key;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.analytics, color: AppColors.accent, size: 40),
                ),
                const SizedBox(height: 16),
                const Text('Session Summary', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(widget.shot.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 32),
                
                // Stats Grid
                Row(
                  children: [
                    _buildSummaryStatBox('Attempts', '$_totalAttempts', AppColors.accentGreen),
                    const SizedBox(width: 12),
                    _buildSummaryStatBox('Correct', '$_correctAttempts', AppColors.accent),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Session Accuracy', style: TextStyle(color: AppColors.textSecondary)),
                      Text('${sessionAccuracy.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.accentGreen, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Feedback
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Performance Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildFeedbackRow(Icons.bolt, 'Strength', _bestStrength),
                      const SizedBox(height: 8),
                      _buildFeedbackRow(Icons.warning_amber, 'Weakness', mainWeakness),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Update overall mastery via Firebase Service
                      if (Get.isRegistered<TrainService>()) {
                         Get.find<TrainService>().saveTrainingSession(widget.shot.name, sessionAccuracy);
                      }
                      Get.until((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Complete & Save', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        ),
      )
    );
  }

  Widget _buildSummaryStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      )
    );
  }

  Widget _buildFeedbackRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.accent, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          )
        )
      ],
    );
  }
}
