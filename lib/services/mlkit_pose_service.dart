import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:get/get.dart';
import 'package:ea_master_demo/auth/authService.dart';

class MlkitPoseService {
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());

  static const Map<PoseLandmarkType, String> mlkitToJoint = {
    PoseLandmarkType.nose: 'nose',
    PoseLandmarkType.leftShoulder: 'left_shoulder',
    PoseLandmarkType.rightShoulder: 'right_shoulder',
    PoseLandmarkType.leftElbow: 'left_elbow',
    PoseLandmarkType.rightElbow: 'right_elbow',
    PoseLandmarkType.leftWrist: 'left_wrist',
    PoseLandmarkType.rightWrist: 'right_wrist',
    PoseLandmarkType.leftHip: 'left_hip',
    PoseLandmarkType.rightHip: 'right_hip',
    PoseLandmarkType.leftKnee: 'left_knee',
    PoseLandmarkType.rightKnee: 'right_knee',
    PoseLandmarkType.leftAnkle: 'left_ankle',
    PoseLandmarkType.rightAnkle: 'right_ankle',
  };

  bool isReady = true;

  Future<void> init() async {
    // ML Kit requires no async initialization
  }

  void dispose() {
    _poseDetector.close();
  }

  Future<PoseDetectionResult> processImage(InputImage inputImage) async {
    try {
      final List<Pose> poses = await _poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        return PoseDetectionResult(
          missing: true,
          message: 'Body not found — step into frame',
          visibleJointCount: 0,
        );
      }

      final Pose pose = poses.first;
      final joints = <String, dynamic>{};

      // Ensure we have metadata to normalize the coordinates (since ML Kit gives absolute pixels).
      // If no metadata, fallback to 1.0 (though it shouldn't happen with camera streams).
      // Note: For iOS bgra8888 and Android yuv420, width and height might be swapped depending on orientation.
      // We will normalize based on the metadata width/height we provide when creating InputImage.
      final width = inputImage.metadata?.size.width ?? 1.0;
      final height = inputImage.metadata?.size.height ?? 1.0;

      bool isLeftHanded = false;
      if (Get.isRegistered<AuthService>()) {
        isLeftHanded = Get.find<AuthService>().isLeftHanded.value;
      }

      for (final entry in mlkitToJoint.entries) {
        final landmark = pose.landmarks[entry.key];
        if (landmark != null) {
          // ML Kit coordinates are relative to the raw image bytes size.
          // In Flutter, usually x/y are given in the orientation of the original bytes, 
          // but if ML Kit rotates it internally based on orientation, x/y might be based on the rotated dimensions.
          // By dividing by the metadata size, we normalize it to 0.0 - 1.0.
          double x = (landmark.x / width).clamp(0.0, 1.0);
          final y = (landmark.y / height).clamp(0.0, 1.0);
          final visibility = landmark.likelihood;

          String jointName = entry.value;

          if (isLeftHanded) {
            x = 1.0 - x;
            if (jointName.startsWith('left_')) {
              jointName = jointName.replaceFirst('left_', 'right_');
            } else if (jointName.startsWith('right_')) {
              jointName = jointName.replaceFirst('right_', 'left_');
            }
          }

          joints[jointName] = {
            'x': x,
            'y': y,
            'visibility': visibility,
          };
        }
      }

      if (joints.length < 4) {
        return PoseDetectionResult(
          missing: true,
          message: 'Body not clear — show full body',
          visibleJointCount: joints.length,
        );
      }

      return PoseDetectionResult(
        joints: joints,
        visibleJointCount: joints.length,
        missing: false,
      );
    } catch (e) {
      return PoseDetectionResult(missing: true, message: 'Inference error: $e');
    }
  }
}

class PoseDetectionResult {
  PoseDetectionResult({
    this.joints,
    this.visibleJointCount = 0,
    this.missing = false,
    this.message,
  });

  final Map<String, dynamic>? joints;
  final int visibleJointCount;
  final bool missing;
  final String? message;
}
