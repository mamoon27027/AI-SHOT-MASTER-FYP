import 'dart:collection';

import 'pipeline_cricket_classifier.dart';

/// Stateful detector that mirrors `RealTime_Inference/live_classifier.py` swing segmentation:
/// movement crosses **start** threshold → buffer frames → smoothed speed drops below **end** → emit clip.
class ShotSegmentDetector {
  ShotSegmentDetector({
    this.startThreshold = 0.015,
    this.endThreshold = 0.01,
    this.minPeakSpeed = 0.035,
    this.minFrames = 25,
    this.maxFramesSafety = 150,
    this.speedWindowLength = 5,
    this.enabled = true,
  });

  double startThreshold;
  double endThreshold;
  double minPeakSpeed;
  int minFrames;
  int maxFramesSafety;
  int speedWindowLength;
  bool enabled;

  bool _recording = false;

  /// Exposed for UI state (waiting vs capturing swing).
  bool get isRecording => _recording;

  Map<String, dynamic>? _prevJoints;
  final List<Map<String, dynamic>> _buffer = [];
  double _maxSpeedInShot = 0.0;

  final Queue<double> _speedWindow = Queue<double>();
  final Map<String, Map<String, double>> _smoothedJoints = {};

  void reset() {
    _recording = false;
    _prevJoints = null;
    _buffer.clear();
    _maxSpeedInShot = 0.0;
    _speedWindow.clear();
    _smoothedJoints.clear();
  }

  /// Process one timestep with raw landmark maps (`null` if pose lost).
  /// Returns a finished swing clip **once** when segmentation completes; otherwise `null`.
  List<Map<String, dynamic>>? pushFrame(Map<String, dynamic>? currJoints) {
    if (!enabled) return null;

    Map<String, dynamic>? smoothedCurrJoints;
    if (currJoints != null) {
      smoothedCurrJoints = {};
      currJoints.forEach((key, val) {
        if (val is Map) {
          final cx = (val['x'] as num?)?.toDouble();
          final cy = (val['y'] as num?)?.toDouble();
          final vis = (val['visibility'] as num?)?.toDouble() ?? 0.0;
          if (cx != null && cy != null) {
            if (!_smoothedJoints.containsKey(key)) {
              _smoothedJoints[key] = {'x': cx, 'y': cy};
            } else {
              final prevS = _smoothedJoints[key]!;
              final sx = 0.65 * cx + 0.35 * prevS['x']!;
              final sy = 0.65 * cy + 0.35 * prevS['y']!;
              _smoothedJoints[key] = {'x': sx, 'y': sy};
            }
            smoothedCurrJoints![key] = {
              'x': _smoothedJoints[key]!['x'],
              'y': _smoothedJoints[key]!['y'],
              'visibility': vis,
            };
          } else {
            smoothedCurrJoints![key] = val;
          }
        } else {
          smoothedCurrJoints![key] = val;
        }
      });
    }

    double avgSpeed = 0.0;
    if (smoothedCurrJoints != null && _prevJoints != null) {
      final sp = PipelineCricketClassifier.jointSpeed(
        PipelineCricketClassifier.normaliseJoints(Map<String, dynamic>.from(_prevJoints!)),
        PipelineCricketClassifier.normaliseJoints(Map<String, dynamic>.from(smoothedCurrJoints)),
      );
      _speedWindow.addLast(sp);
      while (_speedWindow.length > speedWindowLength) {
        _speedWindow.removeFirst();
      }
      avgSpeed = _speedWindow.isEmpty ? 0.0 : _speedWindow.reduce((a, b) => a + b) / _speedWindow.length;
    } else {
      _speedWindow.addLast(0.0);
      while (_speedWindow.length > speedWindowLength) {
        _speedWindow.removeFirst();
      }
      avgSpeed = _speedWindow.isEmpty ? 0.0 : _speedWindow.reduce((a, b) => a + b) / _speedWindow.length;
    }

    _prevJoints = smoothedCurrJoints;

    List<Map<String, dynamic>>? completed;

    if (!_recording) {
      if (avgSpeed > startThreshold) {
        _recording = true;
        _buffer.clear();
        _maxSpeedInShot = avgSpeed;
        if (smoothedCurrJoints != null) {
          _buffer.add(Map<String, dynamic>.from(smoothedCurrJoints));
        }
      }
    } else {
      if (smoothedCurrJoints != null) {
        _buffer.add(Map<String, dynamic>.from(smoothedCurrJoints));
      }
      _maxSpeedInShot = _maxSpeedInShot > avgSpeed ? _maxSpeedInShot : avgSpeed;

      final endedSlow = avgSpeed < endThreshold;
      final timeout = _buffer.length >= maxFramesSafety;

      if (endedSlow || timeout) {
        _recording = false;
        if (_buffer.length >= minFrames && _maxSpeedInShot >= minPeakSpeed) {
          completed = List<Map<String, dynamic>>.from(_buffer);
        }
        _buffer.clear();
        _maxSpeedInShot = 0.0;
      }
    }

    return completed;
  }
}
