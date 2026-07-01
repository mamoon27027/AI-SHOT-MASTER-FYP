import 'coach_models.dart';
import 'pipeline_cricket_classifier.dart';

/// Documents “freeze parity” and builds one pose summary from a swing clip.
///
/// - [FrameAggregationPolicy.peakDisplacementFromStart] — same idea as `Mobile_App_Logic/cricket_classifier.dart`.
/// - [FrameAggregationPolicy.averageAcrossFrames] — same idea as `RealTime_Inference/live_classifier.py`.
class PoseFrameAggregator {
  PoseFrameAggregator._();

  /// Returns `{ "joints": {...}, "angles": {...} }` in **normalised** space.
  static Map<String, dynamic> buildRepresentativeFrame(
    List<Map<String, dynamic>> shotFramesRaw,
    FrameAggregationPolicy policy,
  ) {
    return PipelineCricketClassifier.buildRepresentativeFrame(shotFramesRaw, policy);
  }
}
