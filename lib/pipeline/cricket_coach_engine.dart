import 'dart:async';

import 'benchmark_loader.dart';
import 'coach_levels.dart';
import 'coach_models.dart';
import 'pipeline_cricket_classifier.dart';
import 'shot_segment_detector.dart';

/// Facade your Flutter screens talk to — **single instance** recommended (provider/singleton).
///
/// Typical wiring:
/// 1. Load JSON → `BenchmarkLoader.benchmarksOnly(...)`.
/// 2. Build `CoachSessionConfig` (open mode **or** level mode).
/// 3. `engine.configure(...)` then `engine.start()`.
/// 4. Each pose tick: `engine.ingestLandmarks(...)`.
/// 5. Listen to `results` / `runtimeState`.
class CricketCoachEngine {
  CricketCoachEngine({
    ShotSegmentDetector? segmentDetector,
    Duration cooldownBetweenSwings = const Duration(milliseconds: 800),
  })  : _detector = segmentDetector ?? ShotSegmentDetector(),
        _cooldown = cooldownBetweenSwings;

  CoachSessionConfig? _session;
  bool _running = false;
  bool _coolingDown = false;
  DateTime? _cooldownUntil;

  final ShotSegmentDetector _detector;
  final Duration _cooldown;

  final StreamController<CoachRuntimeState> _stateCtrl =
      StreamController<CoachRuntimeState>.broadcast();
  final StreamController<ShotCoachResult?> _resultCtrl =
      StreamController<ShotCoachResult?>.broadcast();

  Stream<CoachRuntimeState> get runtimeState => _stateCtrl.stream;
  Stream<ShotCoachResult?> get results => _resultCtrl.stream;

  /// Attach benchmarks + session mode before starting.
  void configure(CoachSessionConfig session) {
    _session = session;
    _detector.reset();
    _emit(CoachRuntimeState.idle);
  }

  /// Replace benchmarks JSON only (keeps mode / level).
  void reloadBenchmarks(Map<String, dynamic> benchmarksRootOrInner) {
    final inner = benchmarksRootOrInner.containsKey('benchmarks')
        ? BenchmarkLoader.benchmarksOnly(benchmarksRootOrInner)
        : benchmarksRootOrInner;
    final cur = _session;
    if (cur == null) return;
    configure(CoachSessionConfig(
      mode: cur.mode,
      benchmarks: inner,
      level: cur.level,
      policy: cur.policy,
    ));
  }

  void start() {
    _running = true;
    _detector.reset();
    _coolingDown = false;
    _emit(CoachRuntimeState.idle);
  }

  void stop() {
    _running = false;
    _detector.reset();
    _emit(CoachRuntimeState.idle);
  }

  /// Feed landmark maps from MoveNet/MediaPipe/etc. Pass `null` if nobody detected.
  void ingestLandmarks(Map<String, dynamic>? jointsNormalized) {
    if (!_running || _session == null) return;

    if (_coolingDown) {
      if (_cooldownUntil != null && DateTime.now().isAfter(_cooldownUntil!)) {
        _coolingDown = false;
        _cooldownUntil = null;
        _detector.reset();
        _emit(CoachRuntimeState.idle);
      } else {
        return;
      }
    }

    final clip = _detector.pushFrame(jointsNormalized);
    if (clip != null) {
      _emit(CoachRuntimeState.processing);
      final result = PipelineCricketClassifier.evaluateSwing(
        shotFramesRaw: clip,
        session: _session!,
      );
      _resultCtrl.add(result);
      _coolingDown = true;
      _cooldownUntil = DateTime.now().add(_cooldown);
      _emit(CoachRuntimeState.cooldown);
      return;
    }

    _emit(_detector.isRecording ? CoachRuntimeState.recordingSwing : CoachRuntimeState.idle);
  }

  void _emit(CoachRuntimeState s) {
    if (!_stateCtrl.isClosed) _stateCtrl.add(s);
  }

  void dispose() {
    _stateCtrl.close();
    _resultCtrl.close();
  }
}
