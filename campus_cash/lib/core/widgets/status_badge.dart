import 'package:flutter/material.dart';
import '../../models/exchange_request_model.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final ExchangeStatus status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case ExchangeStatus.searching:
        bg = AppColors.statusSearchingBg;
        fg = AppColors.statusSearching;
        label = 'Searching';
        icon = Icons.search_rounded;
        break;
      case ExchangeStatus.matched:
        bg = AppColors.statusMatchedBg;
        fg = AppColors.statusMatched;
        label = 'Matched';
        icon = Icons.handshake_outlined;
        break;
      case ExchangeStatus.accepted:
        bg = AppColors.statusAcceptedBg;
        fg = AppColors.statusAccepted;
        label = 'Accepted';
        icon = Icons.thumb_up_alt_outlined;
        break;
      case ExchangeStatus.completed:
        bg = AppColors.statusCompletedBg;
        fg = AppColors.statusCompleted;
        label = 'Completed';
        icon = Icons.check_circle_outline;
        break;
      case ExchangeStatus.cancelled:
        bg = AppColors.statusCancelledBg;
        fg = AppColors.statusCancelled;
        label = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
      case ExchangeStatus.expired:
        bg = AppColors.statusExpiredBg;
        fg = AppColors.statusExpired;
        label = 'Expired';
        icon = Icons.timer_off_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
