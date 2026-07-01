import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'mlkit_pose_service.dart';

/// Keeps camera callback light: copy frame → run pose → callbacks.
class PosePipelineController {
  PosePipelineController(this._pose);

  final MlkitPoseService _pose;

  bool _busy = false;
  bool get isBusy => _busy;
  DateTime? _lastInferAt;

  /// Minimum gap between inferences (ms). Lower = more CPU, higher = smoother preview.
  int inferenceIntervalMs = 70;

  void Function(PoseDetectionResult result)? onPoseResult;
  void Function(bool active)? onInferenceActivity;

  void handleCameraImage(CameraImage image, int sensorOrientation, CameraLensDirection lensDirection) {
    final now = DateTime.now();
    if (_busy) return;
    if (_lastInferAt != null &&
        now.difference(_lastInferAt!).inMilliseconds < inferenceIntervalMs) {
      return;
    }

    final inputImage = _inputImageFromCameraImage(image, sensorOrientation, lensDirection);
    if (inputImage == null) {
      onPoseResult?.call(
        PoseDetectionResult(missing: true, message: 'Unsupported camera format'),
      );
      return;
    }

    _busy = true;
    _lastInferAt = now;
    onInferenceActivity?.call(true);

    _pose.processImage(inputImage).then((result) {
      onPoseResult?.call(result);
    }).catchError((e, st) {
      debugPrint('Pose pipeline error: $e\n$st');
      onPoseResult?.call(
        PoseDetectionResult(missing: true, message: 'Pose error: $e'),
      );
    }).whenComplete(() {
      _busy = false;
      onInferenceActivity?.call(false);
    });
  }

  void resetThrottle() {
    _lastInferAt = null;
    _busy = false;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image, int sensorOrientation, CameraLensDirection lensDirection) {
    InputImageRotation? rotation;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      var rotationCompensation = 0; // Assume portraitUp
      if (lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (defaultTargetPlatform == TargetPlatform.android && format != InputImageFormat.nv21) ||
        (defaultTargetPlatform == TargetPlatform.iOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }
}
