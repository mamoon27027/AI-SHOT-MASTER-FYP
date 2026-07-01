import 'coach_models.dart';

/// Level definition: maps app “Level N” UI to one expected cricket shot from `cricket_benchmarks.json`.
///
/// Keys **must** match JSON benchmark names exactly (e.g. `"Cut Shot"` with space).
class CoachLevel {
  const CoachLevel({
    required this.levelNumber,
    required this.displayTitle,
    required this.expectedShotKey,
    required this.minimumAccuracyPercent,
    this.requireDetectedShotMatchesExpected = true,
    this.description,
  });

  final int levelNumber;
  final String displayTitle;

  /// Exact key inside `benchmarks` map in JSON.
  final String expectedShotKey;

  /// Player passes when [ShotCoachResult.accuracyPercent] >= this value (and identity rule if enabled).
  final int minimumAccuracyPercent;

  /// If true: open classifier winner must equal [expectedShotKey], otherwise level fails as mismatch.
  final bool requireDetectedShotMatchesExpected;

  final String? description;

  /// Example progression — edit freely; keys align with bundled `assets/cricket_benchmarks.json`.
  static const List<CoachLevel> exampleProgression = [
    CoachLevel(
      levelNumber: 1,
      displayTitle: 'Level 1 — Cut Shot',
      expectedShotKey: 'Cut Shot',
      minimumAccuracyPercent: 55,
      description: 'Practice cut shot form only.',
    ),
    CoachLevel(
      levelNumber: 2,
      displayTitle: 'Level 2 — Cover Drive',
      expectedShotKey: 'Cover Drive',
      minimumAccuracyPercent: 55,
    ),
    CoachLevel(
      levelNumber: 3,
      displayTitle: 'Level 3 — Straight Drive',
      expectedShotKey: 'Straight Drive',
      minimumAccuracyPercent: 55,
    ),
    CoachLevel(
      levelNumber: 4,
      displayTitle: 'Level 4 — Pull Shot',
      expectedShotKey: 'Pull Shot',
      minimumAccuracyPercent: 55,
    ),
    CoachLevel(
      levelNumber: 5,
      displayTitle: 'Level 5 — Sweep Shot',
      expectedShotKey: 'Sweep Shot',
      minimumAccuracyPercent: 55,
    ),
  ];

  static CoachLevel? byNumber(int n) {
    for (final l in exampleProgression) {
      if (l.levelNumber == n) return l;
    }
    return null;
  }
}

/// Active session configuration consumed by [CricketCoachEngine].
class CoachSessionConfig {
  CoachSessionConfig({
    required this.mode,
    required this.benchmarks,
    this.level,
    this.policy = FrameAggregationPolicy.peakDisplacementFromStart,
  }) : assert(
          mode != ClassificationMode.levelTargetShot || level != null,
          'levelTargetShot requires a CoachLevel',
        );

  final ClassificationMode mode;
  final Map<String, dynamic> benchmarks;
  final CoachLevel? level;

  /// Freeze parity with desktop — pick one policy app-wide unless experimenting.
  final FrameAggregationPolicy policy;
}
