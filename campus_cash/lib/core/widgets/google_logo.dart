import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double radius = w / 2;
    final center = Offset(radius, radius);
    final stroke = w * 0.22;

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);

    // Red arc (top)
    canvas.drawArc(rect, -2.4, 1.4, false, paintRed);
    // Yellow arc (left)
    canvas.drawArc(rect, 2.3, 1.58, false, paintYellow);
    // Green arc (bottom)
    canvas.drawArc(rect, 0.78, 1.52, false, paintGreen);
    // Blue arc (right)
    canvas.drawArc(rect, 0.0, 0.78, false, paintBlue);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(
      radius - stroke * 0.15,
      radius - stroke / 2,
      radius + stroke * 0.15,
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, Radius.circular(stroke / 4)),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
