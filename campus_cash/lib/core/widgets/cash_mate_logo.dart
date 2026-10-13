import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CashMateLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final Color primaryColor;
  final bool showText;
  final bool showSubtitle;
  final String? subtitle;
  final bool isVertical;

  const CashMateLogo({
    super.key,
    this.iconSize = 36,
    this.fontSize = 20,
    this.primaryColor = AppColors.jade,
    this.showText = true,
    this.showSubtitle = false,
    this.subtitle,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = SizedBox(
      width: iconSize,
      height: iconSize,
      child: Image.asset(
        'assets/images/cashmate_logo_transparent.png',
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      ),
    );

    if (!showText) return iconWidget;

    final textWidget = RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: -0.4,
        ),
        children: [
          const TextSpan(text: 'Cash'),
          TextSpan(
            text: 'Mate',
            style: TextStyle(color: primaryColor),
          ),
        ],
      ),
    );

    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 8),
          textWidget,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        const SizedBox(width: 10),
        Flexible(
          fit: FlexFit.loose,
          child: textWidget,
        ),
      ],
    );
  }
}
