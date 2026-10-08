import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../exchange/providers/exchange_provider.dart';
import '../../exchange/screens/connection_details_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (user != null)
            TextButton.icon(
              onPressed: () async {
                final exchangeService = ref.read(exchangeServiceProvider);
                await exchangeService.markAllNotificationsAsRead(user.uid);
                ref.invalidate(notificationsProvider);
              },
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.jade,
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: notificationsAsync.when(
          loading: () => const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 40, color: AppColors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load notifications: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.mute, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(notificationsProvider),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.notifications_none_rounded,
                title: 'No Notifications Yet',
                description:
                    'When you match with peers or status updates occur, alerts will appear here in real time.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notificationsProvider);
              },
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final id = notif['id'] as String? ?? '';
                  final title = notif['title'] as String? ?? 'Notification';
                  final message = notif['message'] as String? ?? '';
                  final type = notif['type'] as String? ?? 'general';
                  final isRead = notif['isRead'] as bool? ?? false;
                  final connectionId = notif['connectionId'] as String?;

                  DateTime? createdAt;
                  final rawCreatedAt = notif['createdAt'];
                  if (rawCreatedAt != null && rawCreatedAt is DateTime) {
                    createdAt = rawCreatedAt;
                  } else if (rawCreatedAt != null &&
                      rawCreatedAt.runtimeType.toString().contains('Timestamp')) {
                    createdAt = (rawCreatedAt as dynamic).toDate();
                  }

                  final timeStr = createdAt != null
                      ? DateFormat('MMM d, h:mm a').format(createdAt)
                      : '';

                  // Icon & Color per notification type
                  IconData icon;
                  Color iconColor;
                  Color bgColor;

                  switch (type) {
                    case 'match_found':
                      icon = Icons.celebration_rounded;
                      iconColor = AppColors.jade;
                      bgColor = AppColors.primaryContainer;
                      break;
                    case 'accepted':
                      icon = Icons.handshake_rounded;
                      iconColor = AppColors.dig;
                      bgColor = AppColors.digitalBg;
                      break;
                    case 'completed':
                      icon = Icons.check_circle_rounded;
                      iconColor = AppColors.jade;
                      bgColor = AppColors.okBg;
                      break;
                    case 'cancelled':
                      icon = Icons.cancel_rounded;
                      iconColor = AppColors.red;
                      bgColor = AppColors.redBg;
                      break;
                    case 'chat':
                      icon = Icons.chat_bubble_rounded;
                      iconColor = AppColors.amber;
                      bgColor = AppColors.cashBg;
                      break;
                    default:
                      icon = Icons.notifications_rounded;
                      iconColor = AppColors.jade;
                      bgColor = AppColors.primaryContainer;
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      if (!isRead && id.isNotEmpty) {
                        final exchangeService =
                            ref.read(exchangeServiceProvider);
                        await exchangeService.markNotificationAsRead(id);
                      }
                      if (connectionId != null &&
                          connectionId.isNotEmpty &&
                          context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConnectionDetailsScreen(
                              connectionId: connectionId,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.white : const Color(0xFFF7FCF9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isRead
                              ? AppColors.line
                              : AppColors.jade.withValues(alpha: 0.3),
                          width: isRead ? 1.0 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: bgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: iconColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isRead
                                              ? FontWeight.w600
                                              : FontWeight.w800,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.jade,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isRead
                                        ? AppColors.mute
                                        : AppColors.ink,
                                    height: 1.35,
                                  ),
                                ),
                                if (timeStr.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
