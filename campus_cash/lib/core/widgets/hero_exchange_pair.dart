import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class HeroExchangePair extends StatelessWidget {
  const HeroExchangePair({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 122,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Tilted Cash Tile (Warm Gold -6deg)
              Positioned(
                left: 0,
                child: Transform.rotate(
                  angle: -6.0 * math.pi / 180.0,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.cashBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(26, 26),
                        painter: _CashNotePainter(color: AppColors.cashColor),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Tilted Digital Phone Tile (Lavender +6deg)
              Positioned(
                right: 0,
                child: Transform.rotate(
                  angle: 6.0 * math.pi / 180.0,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.digitalBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(26, 26),
                        painter: _PhonePainter(color: AppColors.dig),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Overlapping Circular Jade Exchange Badge (Centered on top)
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.jade,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 3),
                ),
                child: const Center(
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashNotePainter extends CustomPainter {
  final Color color;
  const _CashNotePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 5, size.width - 4, size.height - 10),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3.0, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PhonePainter extends CustomPainter {
  final Color color;
  const _PhonePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 2.5, size.width - 12, size.height - 5),
      const Radius.circular(3),
    );
    canvas.drawRRect(phoneRect, paint);
    // Home button bar
    canvas.drawLine(
      Offset(size.width / 2 - 2, size.height - 6),
      Offset(size.width / 2 + 2, size.height - 6),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
