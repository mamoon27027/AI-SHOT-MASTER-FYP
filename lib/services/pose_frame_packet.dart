import 'dart:typed_data';

import 'package:camera/camera.dart';

/// Lightweight copy of camera Y-plane only (fast; avoids full RGB on UI thread).
class PoseFramePacket {
  PoseFramePacket({
    required this.width,
    required this.height,
    required this.yBytes,
    required this.yRowStride,
    this.formatNv21 = false,
    this.uvBytes,
    this.uvRowStride,
    this.uvPixelStride,
  });

  final int width;
  final int height;
  final Uint8List yBytes;
  final int yRowStride;
  final bool formatNv21;
  final Uint8List? uvBytes;
  final int? uvRowStride;
  final int? uvPixelStride;

  static PoseFramePacket? fromCameraImage(CameraImage image) {
    if (image.planes.isEmpty) return null;

    final y = image.planes[0];
    final yCopy = Uint8List.fromList(y.bytes);

    if (image.planes.length >= 3) {
      return PoseFramePacket(
        width: image.width,
        height: image.height,
        yBytes: yCopy,
        yRowStride: y.bytesPerRow,
        formatNv21: false,
      );
    }

    if (image.planes.length == 2) {
      final uv = image.planes[1];
      return PoseFramePacket(
        width: image.width,
        height: image.height,
        yBytes: yCopy,
        yRowStride: y.bytesPerRow,
        formatNv21: true,
        uvBytes: Uint8List.fromList(uv.bytes),
        uvRowStride: uv.bytesPerRow,
        uvPixelStride: uv.bytesPerPixel ?? 2,
      );
    }

    return PoseFramePacket(
      width: image.width,
      height: image.height,
      yBytes: yCopy,
      yRowStride: y.bytesPerRow,
    );
  }
}
