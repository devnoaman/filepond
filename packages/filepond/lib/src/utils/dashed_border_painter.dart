import 'dart:ui';

import 'package:flutter/material.dart';

class DashedBorderPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double dashLength;
  final double gapLength;
  final double borderRadius;

  DashedBorderPainter({
    this.strokeWidth = 2,
    this.color = Colors.black,
    this.dashLength = 5,
    this.gapLength = 3,
    this.borderRadius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final path = Path()..addRRect(rRect);

    final Path dashedPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double end = distance + dashLength;
        dashedPath.addPath(
          metric.extractPath(distance, end.clamp(0.0, metric.length)),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
