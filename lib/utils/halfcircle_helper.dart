import 'dart:math';

import 'package:flutter/material.dart';

class HalfCirclePainter extends CustomPainter {
  final double progress;

  HalfCirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    final progressPaint = Paint()
      ..color = Color.fromARGB(255, 248, 223, 2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    final rect = Rect.fromLTWH(0, 0, size.width, size.width);

    canvas.drawArc(rect, pi, pi, false, basePaint);

    canvas.drawArc(rect, pi, pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(HalfCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
