import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/connection_model.dart';
import '../../../models/exchange_request_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../exchange/providers/exchange_provider.dart';
import '../../exchange/screens/connection_details_screen.dart';
import '../../exchange/screens/create_request_screen.dart';
import '../../exchange/screens/searching_match_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final activeRequestAsync = ref.watch(activeRequestProvider);
    final connectionsAsync = ref.watch(userConnectionsProvider);
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';

    final userName = profileAsync.value?.name ?? 'Friend';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CashMate App Brand Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.currency_exchange_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            AppStrings.appName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        AppStrings.appTagline,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Hi, $userName 👋',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Create Request Primary Action
              CustomButton(
                text: '+ Create Exchange Request',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Your Request Section
              const Text(
                'Your Request',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              activeRequestAsync.when(
                data: (req) {
                  if (req == null) {
                    return _buildNoActiveRequestCard(context);
                  }
                  return _buildActiveRequestCard(context, req);
                },
                loading: () => Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.statusCancelledBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('Error loading request: $e'),
                ),
              ),

              const SizedBox(height: 28),

              // Quick Post Need Tiles
              const Text(
                'What do you need?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      context: context,
                      title: 'I Have Cash',
                      subtitle: 'Need digital UPI',
                      icon: Icons.payments_rounded,
                      color: AppColors.cashColor,
                      bgColor: AppColors.cashBg,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateRequestScreen(initialHas: 'cash'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionTile(
                      context: context,
                      title: 'I Have Digital',
                      subtitle: 'Need paper cash',
                      icon: Icons.phone_android_rounded,
                      color: AppColors.digitalColor,
                      bgColor: AppColors.digitalBg,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateRequestScreen(initialHas: 'digital'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Recent Connections Section
              const Text(
                'Recent Matches & Connections',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              connectionsAsync.when(
                data: (conns) {
                  if (conns.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.handshake_outlined,
                              size: 32, color: AppColors.textMuted),
                          SizedBox(height: 8),
                          Text(
                            'No recent matches yet',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'When an exact opposite request appears, CashMate matches you automatically.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: conns.take(3).map((conn) {
                      final partnerName = conn.partnerName(currentUserId);
                      final myGive = conn.myHas(currentUserId);
                      final myReceive = conn.myWants(currentUserId);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primaryContainer,
                            child: const Icon(
                              Icons.person_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                partnerName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusPill(conn.status),
                            ],
                          ),
                          subtitle: Text(
                            '₹${conn.amount} • ${myGive.toUpperCase()} ↔ ${myReceive.toUpperCase()}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConnectionDetailsScreen(
                                  connectionId: conn.id,
                                  initialConnection: conn,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),

              const SizedBox(height: 28),

              // Safety Reminder Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security_rounded, size: 20, color: Color(0xFFB45309)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'CashMate does not transfer or hold money. The actual exchange happens directly between users outside the app. Never share UPI PIN, passwords, or OTPs.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoActiveRequestCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.currency_exchange_outlined, size: 36, color: AppColors.textMuted),
          const SizedBox(height: 8),
          const Text(
            'No active request',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Post what you have and what you need to find an exact peer match.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRequestCard(BuildContext context, ExchangeRequestModel req) {
    final isSearching = req.status == ExchangeStatus.searching;
    return GestureDetector(
      onTap: () {
        if (isSearching) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SearchingMatchScreen(initialRequest: req),
            ),
          );
        } else if (req.connectionId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConnectionDetailsScreen(connectionId: req.connectionId!),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${req.amount}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                StatusBadge(status: req.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${req.has.toUpperCase()} → ${req.wants.toUpperCase()}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  isSearching ? 'View Live Search →' : 'View Connection →',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(ConnectionStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case ConnectionStatus.pending:
        bg = AppColors.statusSearchingBg;
        fg = AppColors.statusSearching;
        label = 'Pending';
        break;
      case ConnectionStatus.connected:
        bg = AppColors.primaryContainer;
        fg = AppColors.primary;
        label = 'Connected ✓';
        break;
      case ConnectionStatus.completed:
        bg = AppColors.statusCompletedBg;
        fg = AppColors.statusCompleted;
        label = 'Completed ✓';
        break;
      case ConnectionStatus.cancelled:
        bg = AppColors.statusCancelledBg;
        fg = AppColors.statusCancelled;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
