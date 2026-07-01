import 'dart:math';

import 'coach_levels.dart';
import 'coach_models.dart';

/// Stand-alone scorer aligned with `Mobile_App_Logic/cricket_classifier.dart`,
/// extended with **[FrameAggregationPolicy.averageAcrossFrames]** (desktop Python parity)
/// and **level / selective** evaluation helpers.
class PipelineCricketClassifier {
  PipelineCricketClassifier._();

  static const Map<String, int> jointMap = {
    'nose': 0,
    'left_shoulder': 11,
    'right_shoulder': 12,
    'left_elbow': 13,
    'right_elbow': 14,
    'left_wrist': 15,
    'right_wrist': 16,
    'left_hip': 23,
    'right_hip': 24,
    'left_knee': 25,
    'right_knee': 26,
    'left_ankle': 27,
    'right_ankle': 28,
  };

  static const List<String> angleNames = [
    'left_elbow_angle',
    'right_elbow_angle',
    'left_knee_angle',
    'right_knee_angle',
    'left_shoulder_angle',
    'right_shoulder_angle',
    'left_hip_angle',
    'right_hip_angle',
    'nose_to_body_angle',
  ];

  static double angle3Pts(List<double> a, List<double> b, List<double> c) {
    final ba = [a[0] - b[0], a[1] - b[1]];
    final bc = [c[0] - b[0], c[1] - b[1]];
    double dot = ba[0] * bc[0] + ba[1] * bc[1];
    double normBA = sqrt(ba[0] * ba[0] + ba[1] * ba[1]);
    double normBC = sqrt(bc[0] * bc[0] + bc[1] * bc[1]);
    double cosv = dot / ((normBA * normBC) + 1e-9);
    cosv = cosv.clamp(-1.0, 1.0);
    return acos(cosv) * (180.0 / pi);
  }

  static Map<String, dynamic> computeAngles(Map<String, dynamic> joints) {
    List<double> xy(String n) {
      if (joints.containsKey(n) && joints[n] != null) {
        return [(joints[n]['x'] as num).toDouble(), (joints[n]['y'] as num).toDouble()];
      }
      return [0.0, 0.0];
    }

    final hipMid = [
      (xy('left_hip')[0] + xy('right_hip')[0]) / 2,
      (xy('left_hip')[1] + xy('right_hip')[1]) / 2,
    ];
    final nosePt = xy('nose');
    final vec = [nosePt[0] - hipMid[0], nosePt[1] - hipMid[1]];
    double dot = vec[0] * 0.0 + vec[1] * -1.0;
    double normVec = sqrt(vec[0] * vec[0] + vec[1] * vec[1]);
    double cosv = dot / (normVec + 1e-9);
    cosv = cosv.clamp(-1.0, 1.0);
    double trunk = acos(cosv) * (180.0 / pi);

    return {
      'left_elbow_angle': angle3Pts(xy('left_shoulder'), xy('left_elbow'), xy('left_wrist')),
      'right_elbow_angle': angle3Pts(xy('right_shoulder'), xy('right_elbow'), xy('right_wrist')),
      'left_knee_angle': angle3Pts(xy('left_hip'), xy('left_knee'), xy('left_ankle')),
      'right_knee_angle': angle3Pts(xy('right_hip'), xy('right_knee'), xy('right_ankle')),
      'left_shoulder_angle': angle3Pts(xy('left_hip'), xy('left_shoulder'), xy('left_elbow')),
      'right_shoulder_angle': angle3Pts(xy('right_hip'), xy('right_shoulder'), xy('right_elbow')),
      'left_hip_angle': angle3Pts(xy('left_shoulder'), xy('left_hip'), xy('left_knee')),
      'right_hip_angle': angle3Pts(xy('right_shoulder'), xy('right_hip'), xy('right_knee')),
      'nose_to_body_angle': trunk,
    };
  }

  static Map<String, dynamic> normaliseJoints(Map<String, dynamic> joints) {
    List<double>? arr(String n) {
      if (joints.containsKey(n) && joints[n] != null) {
        return [(joints[n]['x'] as num).toDouble(), (joints[n]['y'] as num).toDouble()];
      }
      return null;
    }

    final lh = arr('left_hip');
    final rh = arr('right_hip');
    final ls = arr('left_shoulder');
    final rs = arr('right_shoulder');

    if (lh == null || rh == null || ls == null || rs == null) return joints;

    final hipMid = [(lh[0] + rh[0]) / 2.0, (lh[1] + rh[1]) / 2.0];
    final shoulderMid = [(ls[0] + rs[0]) / 2.0, (ls[1] + rs[1]) / 2.0];

    double dx = shoulderMid[0] - hipMid[0];
    double dy = shoulderMid[1] - hipMid[1];
    double torsoLen = sqrt(dx * dx + dy * dy);

    if (torsoLen < 1e-6) return joints;

    final norm = <String, dynamic>{};
    joints.forEach((name, jd) {
      norm[name] = {
        'x': ((jd['x'] as num).toDouble() - hipMid[0]) / torsoLen,
        'y': ((jd['y'] as num).toDouble() - hipMid[1]) / torsoLen,
        'visibility': jd['visibility'] ?? 0.0,
      };
    });
    return norm;
  }

  static double jointSpeed(Map<String, dynamic>? prev, Map<String, dynamic>? curr) {
    if (prev == null || curr == null) return 0.0;
    final deltas = <double>[];

    for (final n in jointMap.keys) {
      if (prev.containsKey(n) && curr.containsKey(n)) {
        double dx = (curr[n]['x'] as num).toDouble() - (prev[n]['x'] as num).toDouble();
        double dy = (curr[n]['y'] as num).toDouble() - (prev[n]['y'] as num).toDouble();
        deltas.add(sqrt(dx * dx + dy * dy));
      }
    }

    if (deltas.isEmpty) return 0.0;
    return deltas.fold(0.0, (a, b) => a + b) / deltas.length;
  }

  /// Builds `{ joints, angles }` used by classification / scoring.
  static Map<String, dynamic> buildRepresentativeFrame(
    List<Map<String, dynamic>> shotFramesRaw,
    FrameAggregationPolicy policy,
  ) {
    if (shotFramesRaw.isEmpty) {
      throw ArgumentError('shotFramesRaw empty');
    }

    final framesData = <Map<String, dynamic>>[];
    for (final joints in shotFramesRaw) {
      final norm = normaliseJoints(joints);
      final angles = computeAngles(norm);
      framesData.add({'joints': norm, 'angles': angles});
    }

    switch (policy) {
      case FrameAggregationPolicy.peakDisplacementFromStart:
        int peakIdx = 0;
        double maxDist = -1.0;
        final startFrame = framesData[0]['joints'] as Map<String, dynamic>;
        for (int i = 0; i < framesData.length; i++) {
          double dist = 0.0;
          for (final jName in ['left_wrist', 'right_wrist', 'left_ankle', 'right_ankle']) {
            final ij = framesData[i]['joints'] as Map<String, dynamic>;
            if (ij.containsKey(jName) && startFrame.containsKey(jName)) {
              double dx = (ij[jName]['x'] as num).toDouble() - (startFrame[jName]['x'] as num).toDouble();
              double dy = (ij[jName]['y'] as num).toDouble() - (startFrame[jName]['y'] as num).toDouble();
              dist += sqrt(dx * dx + dy * dy);
            }
          }
          if (dist > maxDist) {
            maxDist = dist;
            peakIdx = i;
          }
        }
        return {
          'joints': framesData[peakIdx]['joints'],
          'angles': framesData[peakIdx]['angles'],
        };

      case FrameAggregationPolicy.averageAcrossFrames:
        final avgJoints = <String, dynamic>{};
        for (final jName in jointMap.keys) {
          final xs = <double>[];
          final ys = <double>[];
          for (final f in framesData) {
            final j = f['joints'] as Map<String, dynamic>;
            if (j.containsKey(jName)) {
              xs.add((j[jName]['x'] as num).toDouble());
              ys.add((j[jName]['y'] as num).toDouble());
            }
          }
          if (xs.isNotEmpty && ys.isNotEmpty) {
            avgJoints[jName] = {
              'x': xs.reduce((a, b) => a + b) / xs.length,
              'y': ys.reduce((a, b) => a + b) / ys.length,
              'visibility': 1.0,
            };
          }
        }
        final avgAngles = <String, double>{};
        for (final a in angleNames) {
          final vals = <double>[];
          for (final f in framesData) {
            final ang = f['angles'] as Map<String, dynamic>;
            if (ang.containsKey(a)) vals.add((ang[a] as num).toDouble());
          }
          if (vals.isNotEmpty) {
            avgAngles[a] = vals.reduce((x, y) => x + y) / vals.length;
          }
        }
        return {'joints': avgJoints, 'angles': avgAngles};
    }
  }

  static Map<String, dynamic> analyzeShotDetails(Map<String, dynamic> peakFrame, Map<String, dynamic> bm) {
    final zoneErrors = <String, double>{'legs': 0.0, 'arms': 0.0, 'body': 0.0};
    final zoneCounts = <String, int>{'legs': 0, 'arms': 0, 'body': 0};

    void addErr(String name, double err) {
      String z = 'body';
      if (name.contains('ankle') || name.contains('knee')) z = 'legs';
      else if (name.contains('wrist') || name.contains('elbow')) z = 'arms';

      zoneErrors[z] = zoneErrors[z]! + err;
      zoneCounts[z] = zoneCounts[z]! + 1;
    }

    double totalErr = 0.0;
    final pj = peakFrame['joints'] as Map<String, dynamic>;
    final benchJ = bm['benchmark_joints'] as Map<String, dynamic>;

    for (final jName in jointMap.keys) {
      if (pj.containsKey(jName) && benchJ.containsKey(jName)) {
        double bx = (benchJ[jName]['x_mean'] as num).toDouble();
        double by = (benchJ[jName]['y_mean'] as num).toDouble();
        double px = (pj[jName]['x'] as num).toDouble();
        double py = (pj[jName]['y'] as num).toDouble();

        double dx = px - bx;
        double dy = py - by;
        double dist = sqrt((dx * dx) + (dy * dy));

        if (jName.contains('wrist') || jName.contains('knee')) {
          dist *= 2.0;
        }

        addErr(jName, dist);
        totalErr += dist;
      }
    }

    if (bm.containsKey('benchmark_angles')) {
      final ba = bm['benchmark_angles'] as Map<String, dynamic>;
      final pa = peakFrame['angles'] as Map<String, dynamic>;
      for (final a in angleNames) {
        if (pa.containsKey(a) && ba.containsKey(a)) {
          double pAng = (pa[a] as num).toDouble();
          double bAng = (ba[a]['mean_deg'] as num).toDouble();
          double diff = (pAng - bAng).abs() / 50.0;
          addErr(a, diff);
          totalErr += diff;
        }
      }
    }

    final avgZones = <String, double>{};
    zoneErrors.forEach((z, err) {
      avgZones[z] = zoneCounts[z]! > 0 ? err / zoneCounts[z]! : 0.0;
    });

    String strongKey = avgZones.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    String weakKey = avgZones.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final vocab = <String, List<String>>{
      'legs': ['footwork and base', 'stride and balance', 'knee bend and foot positioning'],
      'arms': ['arm extension and bat swing', 'bat flow', 'wrist position and elbow bend'],
      'body': ['head position and weight transfer', 'shoulder alignment', 'upper body posture'],
    };

    final random = Random();
    String strongArea = vocab[strongKey]![random.nextInt(vocab[strongKey]!.length)];
    String weakArea = vocab[weakKey]![random.nextInt(vocab[weakKey]!.length)];

    int acc = (100 - ((totalErr - 3.0) * 3.0)).round().clamp(0, 100);

    return {
      'accuracy': acc,
      'strong_area': strongArea,
      'weak_area': weakArea,
      'total_error': totalErr,
    };
  }

  static double _jointAngleErrors(Map<String, dynamic> peakFrame, Map<String, dynamic> bm) {
    double jointError = 0.0;
    final pj = peakFrame['joints'] as Map<String, dynamic>;
    final benchJ = bm['benchmark_joints'] as Map<String, dynamic>;

    for (final jName in jointMap.keys) {
      if (pj.containsKey(jName) && benchJ.containsKey(jName)) {
        double bx = (benchJ[jName]['x_mean'] as num).toDouble();
        double by = (benchJ[jName]['y_mean'] as num).toDouble();
        double px = (pj[jName]['x'] as num).toDouble();
        double py = (pj[jName]['y'] as num).toDouble();

        double dx = px - bx;
        double dy = py - by;
        double dist = sqrt((dx * dx) + (dy * dy));

        if (jName.contains('wrist') || jName.contains('knee')) {
          dist *= 2.0;
        }
        jointError += dist;
      }
    }

    double angleError = 0.0;
    if (bm.containsKey('benchmark_angles')) {
      final ba = bm['benchmark_angles'] as Map<String, dynamic>;
      final pa = peakFrame['angles'] as Map<String, dynamic>;
      for (final a in angleNames) {
        if (pa.containsKey(a) && ba.containsKey(a)) {
          double pAng = (pa[a] as num).toDouble();
          double bAng = (ba[a]['mean_deg'] as num).toDouble();
          angleError += (pAng - bAng).abs() / 10.0;
        }
      }
    }

    return jointError + angleError;
  }

  /// Returns classification-error per shot (lower is better match).
  static Map<String, double> classificationErrors(
    Map<String, dynamic> peakFrame,
    Map<String, dynamic> benchmarks,
  ) {
    final out = <String, double>{};
    benchmarks.forEach((shotName, bm) {
      if (bm is! Map<String, dynamic>) return;
      if (!bm.containsKey('benchmark_joints')) return;
      out[shotName] = _jointAngleErrors(peakFrame, bm);
    });
    return out;
  }

  /// Nearest-shot classification using the same metric as legacy Dart classifier,
  /// enhanced with a soft biometric weight adjustment to resolve visual similarity tie-breakers.
  static String? classifyOpenWinner(List<Map<String, dynamic>> shotFramesRaw, Map<String, dynamic> peakFrame, Map<String, dynamic> benchmarks) {
    final rawErrors = classificationErrors(peakFrame, benchmarks);
    if (rawErrors.isEmpty) return null;

    double torsoLen(Map<String, dynamic> joints) {
      final ls = joints['left_shoulder'];
      final rs = joints['right_shoulder'];
      final lh = joints['left_hip'];
      final rh = joints['right_hip'];
      if (ls == null || rs == null || lh == null || rh == null) return 1.0;
      
      double smX = ((ls['x'] as num).toDouble() + (rs['x'] as num).toDouble()) / 2.0;
      double smY = ((ls['y'] as num).toDouble() + (rs['y'] as num).toDouble()) / 2.0;
      double hmX = ((lh['x'] as num).toDouble() + (rh['x'] as num).toDouble()) / 2.0;
      double hmY = ((lh['y'] as num).toDouble() + (rh['y'] as num).toDouble()) / 2.0;
      return sqrt((smX - hmX) * (smX - hmX) + (smY - hmY) * (smY - hmY));
    }

    double ratio = 1.0;
    if (shotFramesRaw.isNotEmpty) {
      int numStart = min(3, shotFramesRaw.length);
      double startLenSum = 0.0;
      for (int i = 0; i < numStart; i++) {
        startLenSum += torsoLen(shotFramesRaw[i]);
      }
      double avgStartLen = startLenSum / numStart;

      final startRw = shotFramesRaw[0]['right_wrist'];
      if (startRw != null) {
        int peakIdx = 0;
        double maxD = -1.0;
        for (int i = 0; i < shotFramesRaw.length; i++) {
          final rw = shotFramesRaw[i]['right_wrist'];
          if (rw != null) {
            double dx = (rw['x'] as num).toDouble() - (startRw['x'] as num).toDouble();
            double dy = (rw['y'] as num).toDouble() - (startRw['y'] as num).toDouble();
            double d = sqrt(dx * dx + dy * dy);
            if (d > maxD) {
              maxD = d;
              peakIdx = i;
            }
          }
        }
        double peakLen = torsoLen(shotFramesRaw[peakIdx]);
        ratio = peakLen / (avgStartLen + 1e-6);
      }
    }

    final adjustedErrors = Map<String, double>.from(rawErrors);

    // Apply soft biometric adjustments for Cover Drive, Straight Drive, and Cut Shot
    if (adjustedErrors.containsKey('Straight Drive') &&
        adjustedErrors.containsKey('Cut Shot') &&
        adjustedErrors.containsKey('Cover Drive')) {
      if (ratio > 1.03) {
        // Tall/upright stance: bonus to Straight Drive, penalty to Cut Shot
        adjustedErrors['Straight Drive'] = adjustedErrors['Straight Drive']! * 0.75;
        adjustedErrors['Cut Shot'] = adjustedErrors['Cut Shot']! * 1.25;
      } else if (ratio < 0.97) {
        // Crouched/squarer stance: bonus to Cut Shot
        adjustedErrors['Cut Shot'] = adjustedErrors['Cut Shot']! * 0.75;
      } else {
        // Lunged/diagonal stance: bonus to Cover Drive
        adjustedErrors['Cover Drive'] = adjustedErrors['Cover Drive']! * 0.75;
      }
    }

    print('[Classification Debug] --- START ---');
    print('[Classification Debug] Torso Length Ratio: ${ratio.toStringAsFixed(4)}');
    print('[Classification Debug] Raw Errors:');
    rawErrors.forEach((k, v) => print('  - $k: ${v.toStringAsFixed(4)}'));
    print('[Classification Debug] Adjusted Errors (after soft biometrics):');
    adjustedErrors.forEach((k, v) => print('  - $k: ${v.toStringAsFixed(4)}'));

    double minE = double.infinity;
    String best = 'Unknown';
    adjustedErrors.forEach((name, e) {
      if (e < minE) {
        minE = e;
        best = name;
      }
    });

    print('[Classification Debug] Selected Winner: $best (Error: ${minE.toStringAsFixed(4)})');
    print('[Classification Debug] --- END ---');

    return best;
  }

  /// Full evaluation for UI / levels — call after segment detector yields one swing clip.
  static ShotCoachResult? evaluateSwing({
    required List<Map<String, dynamic>> shotFramesRaw,
    required CoachSessionConfig session,
  }) {
    if (shotFramesRaw.length < 3) return null;

    final peakFrame = buildRepresentativeFrame(shotFramesRaw, session.policy);
    final benchmarks = session.benchmarks;

    final openWinner = classifyOpenWinner(shotFramesRaw, peakFrame, benchmarks);
    if (openWinner == null) return null;

    switch (session.mode) {
      case ClassificationMode.open:
        final details = analyzeShotDetails(peakFrame, benchmarks[openWinner] as Map<String, dynamic>);
        return ShotCoachResult(
          shotLabel: openWinner,
          accuracyPercent: details['accuracy'] as int,
          strongArea: details['strong_area'] as String,
          weakArea: details['weak_area'] as String,
          totalErrorVersusBenchmark: (details['total_error'] as num).toDouble(),
          openModeWinnerShot: openWinner,
          identityMismatch: false,
          levelPassed: null,
          levelNumber: null,
        );

      case ClassificationMode.levelTargetShot:
        final level = session.level!;
        final expected = level.expectedShotKey;
        if (!benchmarks.containsKey(expected)) return null;

        final details = analyzeShotDetails(peakFrame, benchmarks[expected] as Map<String, dynamic>);
        final totalErr = (details['total_error'] as num).toDouble();

        final mismatch =
            level.requireDetectedShotMatchesExpected && openWinner != expected;

        final passed = (details['accuracy'] as int) >= level.minimumAccuracyPercent && !mismatch;

        return ShotCoachResult(
          shotLabel: expected,
          accuracyPercent: details['accuracy'] as int,
          strongArea: details['strong_area'] as String,
          weakArea: details['weak_area'] as String,
          totalErrorVersusBenchmark: totalErr,
          openModeWinnerShot: openWinner,
          identityMismatch: mismatch,
          levelPassed: passed,
          levelNumber: level.levelNumber,
        );
    }
  }
}
