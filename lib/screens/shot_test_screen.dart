import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../pipeline/coach_levels.dart';
import '../pipeline/coach_models.dart';
import '../pipeline/cricket_coach_engine.dart';
import '../pipeline/shot_segment_detector.dart';
import '../services/coaching_bootstrap.dart';
import '../services/mlkit_pose_service.dart';
import '../services/pose_pipeline_controller.dart';
import '../widgets/pose_skeleton_overlay.dart';

/// Demo: camera + skeleton overlay + shot scoring.
class ShotTestScreen extends StatefulWidget {
  const ShotTestScreen({super.key});

  @override
  State<ShotTestScreen> createState() => _ShotTestScreenState();
}

class _ShotTestScreenState extends State<ShotTestScreen> {
  CameraController? _camera;
  final MlkitPoseService _pose = MlkitPoseService();
  late final PosePipelineController _posePipeline = PosePipelineController(_pose);

  final CricketCoachEngine _engine = CricketCoachEngine(
    segmentDetector: ShotSegmentDetector(
      startThreshold: 0.015,
      endThreshold: 0.010,
      minPeakSpeed: 0.035,
      minFrames: 10,
      maxFramesSafety: 100,
    ),
    cooldownBetweenSwings: const Duration(milliseconds: 500),
  );

  Map<String, dynamic>? _benchmarks;
  List<String> _shotNames = [];

  bool _loading = true;
  String? _error;
  bool _sessionActive = false;

  ClassificationMode _mode = ClassificationMode.open;
  String? _selectedShot;
  CoachRuntimeState _runtimeState = CoachRuntimeState.idle;
  ShotCoachResult? _lastResult;

  Map<String, dynamic>? _liveJoints;
  int _visibleJoints = 0;
  bool _poseMissing = true;
  String _poseHint = 'Start coaching to detect body';
  bool _inferring = false;
  int _inferenceFps = 0;
  int _inferCount = 0;
  DateTime _fpsWindowStart = DateTime.now();

  StreamSubscription<CoachRuntimeState>? _stateSub;
  StreamSubscription<ShotCoachResult?>? _resultSub;

  static const int _targetJoints = 13;

  @override
  void initState() {
    super.initState();
    _posePipeline.onPoseResult = _onPoseResult;
    _posePipeline.onInferenceActivity = (active) {
      if (mounted) setState(() => _inferring = active);
    };
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _loading = false;
          _error = 'Camera permission denied.';
        });
        return;
      }

      final benchmarks = await CoachingBootstrap.loadBenchmarks();
      await _pose.init();
      await _initCamera();

      _stateSub = _engine.runtimeState.listen((s) {
        if (mounted) setState(() => _runtimeState = s);
      });
      _resultSub = _engine.results.listen((r) {
        if (mounted && r != null) setState(() => _lastResult = r);
      });

      setState(() {
        _benchmarks = benchmarks;
        _shotNames = CoachingBootstrap.shotNamesFromBenchmarks(benchmarks);
        _selectedShot = _shotNames.isNotEmpty ? _shotNames.first : null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Startup failed: $e';
      });
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw StateError('No camera on device.');

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    await controller.initialize();
    _camera = controller;
  }

  void _onPoseResult(PoseDetectionResult result) {
    if (!mounted) return;

    _inferCount++;
    final now = DateTime.now();
    if (now.difference(_fpsWindowStart).inMilliseconds >= 1000) {
      _inferenceFps = _inferCount;
      _inferCount = 0;
      _fpsWindowStart = now;
    }

    setState(() {
      _poseMissing = result.missing;
      _poseHint = result.message ??
          (result.missing
              ? 'Move back — show full body'
              : 'Body OK ($_visibleJoints/$_targetJoints joints)');
      _visibleJoints = result.visibleJointCount;
      _liveJoints = result.joints;
    });

    if (_sessionActive) {
      _engine.ingestLandmarks(result.joints);
    }
  }

  CoachSessionConfig _buildSessionConfig() {
    final benchmarks = _benchmarks!;
    if (_mode == ClassificationMode.open) {
      return CoachSessionConfig(
        mode: ClassificationMode.open,
        benchmarks: benchmarks,
        policy: FrameAggregationPolicy.averageAcrossFrames,
      );
    }

    final shot = _selectedShot ?? _shotNames.first;
    return CoachSessionConfig(
      mode: ClassificationMode.levelTargetShot,
      benchmarks: benchmarks,
      level: CoachLevel(
        levelNumber: 0,
        displayTitle: 'Practice — $shot',
        expectedShotKey: shot,
        minimumAccuracyPercent: 50,
        requireDetectedShotMatchesExpected: true,
      ),
      policy: FrameAggregationPolicy.averageAcrossFrames,
    );
  }

  Future<void> _startSession() async {
    if (_benchmarks == null || !_pose.isReady) return;

    _engine.configure(_buildSessionConfig());
    _engine.start();
    _posePipeline.resetThrottle();
    _posePipeline.inferenceIntervalMs = 70;

    setState(() {
      _sessionActive = true;
      _lastResult = null;
      _poseHint = 'Detecting body…';
    });

    await _camera?.startImageStream((image) {
      if (!_sessionActive || _camera == null) return;
      _posePipeline.handleCameraImage(image, _camera!.description.sensorOrientation, _camera!.description.lensDirection);
    });
  }

  Future<void> _stopSession() async {
    if (_camera?.value.isStreamingImages == true) {
      await _camera?.stopImageStream();
    }
    _engine.stop();
    _posePipeline.inferenceIntervalMs = 200;
    setState(() {
      _sessionActive = false;
      _inferring = false;
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _resultSub?.cancel();
    _camera?.dispose();
    _pose.dispose();
    _engine.dispose();
    super.dispose();
  }

  String _stateLabel(CoachRuntimeState s) {
    switch (s) {
      case CoachRuntimeState.idle:
        return 'Ready — play your shot';
      case CoachRuntimeState.recordingSwing:
        return 'Recording swing…';
      case CoachRuntimeState.processing:
        return 'Scoring…';
      case CoachRuntimeState.cooldown:
        return 'Next shot in a moment…';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading model & benchmarks…'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('EA Shot Master')),
        body: Center(child: Text(_error!, textAlign: TextAlign.center)),
      );
    }

    final camReady = _camera != null && _camera!.value.isInitialized;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('EA Shot Master — Test'),
        backgroundColor: Colors.black45,
        foregroundColor: Colors.white,
        elevation: 0,
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
            
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StatusChip(
                        label: _sessionActive ? _stateLabel(_runtimeState) : 'Tap Start coaching',
                        active: _sessionActive,
                      ),
                      const SizedBox(height: 6),
                      _PoseStatusBar(
                        missing: _poseMissing,
                        hint: _poseHint,
                        visible: _visibleJoints,
                        target: _targetJoints,
                        inferring: _inferring,
                        fps: _inferenceFps,
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),

                if (_runtimeState == CoachRuntimeState.processing || _runtimeState == CoachRuntimeState.recordingSwing)
                  Center(
                    child: Card(
                      color: Colors.black87,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.greenAccent),
                            const SizedBox(height: 12),
                            Text(
                              _runtimeState == CoachRuntimeState.recordingSwing 
                                  ? 'Recording your swing...' 
                                  : 'Detecting the shot...',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const Spacer(),

                Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<ClassificationMode>(
                        style: SegmentedButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                          selectedForegroundColor: Colors.black,
                          selectedBackgroundColor: Colors.greenAccent,
                        ),
                        segments: const [
                          ButtonSegment(value: ClassificationMode.open, label: Text('Any shot')),
                          ButtonSegment(
                            value: ClassificationMode.levelTargetShot,
                            label: Text('Practice one'),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: _sessionActive ? null : (s) => setState(() => _mode = s.first),
                      ),
                      if (_mode == ClassificationMode.levelTargetShot) ...[
                        const SizedBox(height: 8),
                        DropdownMenu<String>(
                          initialSelection: _selectedShot,
                          label: const Text('Shot to practice', style: TextStyle(color: Colors.white)),
                          textStyle: const TextStyle(color: Colors.white),
                          dropdownMenuEntries: _shotNames
                              .map((s) => DropdownMenuEntry(value: s, label: s))
                              .toList(),
                          onSelected: _sessionActive ? null : (v) => setState(() => _selectedShot = v),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _sessionActive ? null : _startSession,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start coaching'),
                              style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _sessionActive ? _stopSession : null,
                              icon: const Icon(Icons.stop),
                              label: const Text('Stop'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ResultCard(result: _lastResult, mode: _mode),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? Colors.black87 : Colors.black45,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _PoseStatusBar extends StatelessWidget {
  const _PoseStatusBar({
    required this.missing,
    required this.hint,
    required this.visible,
    required this.target,
    required this.inferring,
    required this.fps,
  });

  final bool missing;
  final String hint;
  final int visible;
  final int target;
  final bool inferring;
  final int fps;

  @override
  Widget build(BuildContext context) {
    final color = missing ? Colors.orange.shade800 : Colors.green.shade800;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            if (inferring)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            Expanded(
              child: Text(
                hint,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            Text(
              '$visible/$target',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            if (fps > 0) ...[
              const SizedBox(width: 6),
              Text('${fps}fps', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.mode});
  final ShotCoachResult? result;
  final ClassificationMode mode;

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Swing when you see green skeleton + “Recording swing”.'),
        ),
      );
    }

    final r = result!;
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r.accuracyPercent}% accuracy',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text('Shot: ${r.shotLabel}'),
            if (mode == ClassificationMode.levelTargetShot) ...[
              Text('Classifier saw: ${r.openModeWinnerShot ?? "—"}'),
              if (r.identityMismatch)
                const Text('Different shot detected than selected.', style: TextStyle(color: Colors.orange)),
            ],
            Text('Strong: ${r.strongArea}'),
            Text('Improve: ${r.weakArea}'),
          ],
        ),
      ),
    );
  }
}
