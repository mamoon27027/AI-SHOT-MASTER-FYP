/// Glue between Flutter camera plugins (or native TF Lite runners) and the coaching pipeline.
///
/// **Integration rule:** Your camera loop receives pixel buffers → pose backend produces landmark maps
/// in **normalized image coordinates** (`x`, `y` in 0–1 like MediaPipe) plus `visibility`.
/// Feed those maps into [CricketCoachEngine.ingestLandmarks]; never ship raw JPEGs every tick.

/// Converts RGB camera frames → landmark batches at a capped rate (protects FPS / thermal budget).
class PoseInferenceThrottle {
  PoseInferenceThrottle({this.targetIntervalMs = 66});

  /// Default ~15 FPS pose cadence (`1000/15 ≈ 66ms`).
  final int targetIntervalMs;

  DateTime? _lastRun;

  /// Returns true when enough time elapsed since last accepted frame.
  bool shouldRun(DateTime now) {
    if (_lastRun == null) {
      _lastRun = now;
      return true;
    }
    final delta = now.difference(_lastRun!).inMilliseconds;
    if (delta >= targetIntervalMs) {
      _lastRun = now;
      return true;
    }
    return false;
  }

  void reset() {
    _lastRun = null;
  }
}
