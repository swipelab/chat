import 'package:flutter/material.dart';

class HorizontalStrikePainter extends CustomPainter {
  final double gap = 48.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.blueGrey
          ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width / 2 - gap / 2, size.height / 2),
      paint,
    );

    canvas.drawLine(
      Offset(size.width / 2 + gap / 2, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
