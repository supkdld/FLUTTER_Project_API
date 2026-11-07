import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'palette.dart';

class Flower extends StatelessWidget {
  const Flower({super.key, this.size = 90});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _FlowerPainter()),
    ),
  );
}

class _FlowerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas.scale(scale);
    final paint = Paint()..color = Palette.olive;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(48, 48, 5, 46),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.save();
    canvas.translate(42, 78);
    canvas.rotate(.5);
    canvas.drawOval(const Rect.fromLTWH(-15, -6, 24, 12), paint);
    canvas.restore();
    canvas.save();
    canvas.translate(58, 68);
    canvas.rotate(-.5);
    canvas.drawOval(const Rect.fromLTWH(-8, -6, 24, 12), paint);
    canvas.restore();
    paint.color = Palette.rose;
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      canvas.drawCircle(
        Offset(50 + math.cos(angle) * 20, 33 + math.sin(angle) * 20),
        16,
        paint,
      );
    }
    canvas.drawCircle(
      const Offset(50, 33),
      19,
      Paint()..color = Palette.background,
    );
    paint.color = Palette.ink;
    canvas.drawCircle(const Offset(44, 31), 1.8, paint);
    canvas.drawCircle(const Offset(56, 31), 1.8, paint);
    canvas.drawArc(
      const Rect.fromLTWH(45, 32, 10, 8),
      0,
      math.pi,
      false,
      Paint()
        ..color = Palette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    paint.color = Palette.coral;
    canvas.drawOval(const Rect.fromLTWH(35, 34, 7, 4), paint);
    canvas.drawOval(const Rect.fromLTWH(58, 34, 7, 4), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
