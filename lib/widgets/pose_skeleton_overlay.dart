import 'package:flutter/material.dart';

/// Draws detected cricket joints on top of [CameraPreview] (normalized 0–1 coords).
class PoseSkeletonOverlay extends CustomPainter {
  PoseSkeletonOverlay({
    required this.joints,
    this.mirrorX = true,
  });

  final Map<String, dynamic>? joints;
  final bool mirrorX;

  static const _connections = [
    ['nose', 'left_shoulder'],
    ['nose', 'right_shoulder'],
    ['left_shoulder', 'right_shoulder'],
    ['left_shoulder', 'left_elbow'],
    ['right_shoulder', 'right_elbow'],
    ['left_elbow', 'left_wrist'],
    ['right_elbow', 'right_wrist'],
    ['left_shoulder', 'left_hip'],
    ['right_shoulder', 'right_hip'],
    ['left_hip', 'right_hip'],
    ['left_hip', 'left_knee'],
    ['right_hip', 'right_knee'],
    ['left_knee', 'left_ankle'],
    ['right_knee', 'right_ankle'],
  ];

  Offset? _pt(String name) {
    final j = joints?[name];
    if (j == null) return null;
    double x = (j['x'] as num).toDouble();
    double y = (j['y'] as num).toDouble();
    if (mirrorX) x = 1.0 - x;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (joints == null || joints!.isEmpty) return;

    final linePaint = Paint()
      ..color = Colors.limeAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    for (final pair in _connections) {
      final a = _pt(pair[0]);
      final b = _pt(pair[1]);
      if (a == null || b == null) continue;
      canvas.drawLine(
        Offset(a.dx * size.width, a.dy * size.height),
        Offset(b.dx * size.width, b.dy * size.height),
        linePaint,
      );
    }

    for (final entry in joints!.entries) {
      final p = _pt(entry.key);
      if (p == null) continue;
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        6,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PoseSkeletonOverlay oldDelegate) {
    return oldDelegate.joints != joints;
  }
}
