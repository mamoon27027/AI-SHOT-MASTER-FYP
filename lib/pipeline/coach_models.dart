/// Shared types for the EA Sport Master mobile coaching pipeline.
/// Copy this folder into your Flutter `lib/` (or use as a package).

enum CoachRuntimeState {
  idle,
  recordingSwing,
  processing,
  cooldown,
}

enum ClassificationMode {
  /// Compare motion against every benchmark (nearest wins).
  open,

  /// Compare motion against the level's expected shot; optional identity check vs open winner.
  levelTargetShot,
}

/// Freeze parity with desktop Python vs legacy Dart — choose one for production builds.
enum FrameAggregationPolicy {
  /// Matches `Mobile_App_Logic/cricket_classifier.dart` (peak motion vs first frame).
  peakDisplacementFromStart,

  /// Matches `RealTime_Inference/live_classifier.py` average pose over the swing clip.
  averageAcrossFrames,
}

/// One evaluated swing after segmentation + scoring.
class ShotCoachResult {
  ShotCoachResult({
    required this.shotLabel,
    required this.accuracyPercent,
    required this.strongArea,
    required this.weakArea,
    required this.totalErrorVersusBenchmark,
    this.openModeWinnerShot,
    this.identityMismatch = false,
    this.levelPassed,
    this.levelNumber,
  });

  /// Shot name shown to user (in level mode this is usually the expected shot).
  final String shotLabel;

  final int accuracyPercent;
  final String strongArea;
  final String weakArea;

  /// Raw error vs the benchmark used for scoring (lower is closer match).
  final double totalErrorVersusBenchmark;

  /// When [ClassificationMode.open], same as [shotLabel]. In level mode, which shot the open classifier would pick.
  final String? openModeWinnerShot;

  /// True when motion fits another benchmark better than the expected shot (see level rules).
  final bool identityMismatch;

  /// Set when a [CoachLevel] was active during evaluation.
  final bool? levelPassed;
  final int? levelNumber;
}
