import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/exchange_request_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/exchange_provider.dart';

class MatchDetailsScreen extends ConsumerStatefulWidget {
  final ExchangeRequestModel request;

  const MatchDetailsScreen({super.key, required this.request});

  @override
  ConsumerState<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends ConsumerState<MatchDetailsScreen> {
  bool _isLoading = false;

  Future<void> _handleAccept(ExchangeRequestModel req) async {
    if (req.matchedRequestId == null) return;

    setState(() => _isLoading = true);
    try {
      final service = ref.read(exchangeServiceProvider);
      await service.acceptMatch(
        requestId: req.id,
        matchedRequestId: req.matchedRequestId!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showChangeLocationDialog(ExchangeRequestModel req) async {
    final spots = [
      'Campus Cafeteria',
      'Library Lobby',
      'Student Center (SAC)',
      'Main Academic Block',
      'Campus ATM Counter',
    ];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Change Meetup Place'),
        children: spots.map((spot) {
          final isCurr = spot == req.location;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, spot),
            child: Row(
              children: [
                Icon(
                  Icons.place_rounded,
                  color: isCurr ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    spot,
                    style: TextStyle(
                      fontWeight: isCurr ? FontWeight.w700 : FontWeight.w500,
                      color: isCurr ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isCurr) const Icon(Icons.check, color: AppColors.primary, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (selected != null && selected != req.location) {
      await ref.read(exchangeServiceProvider).updateMeetupLocation(
        requestId: req.id,
        matchedRequestId: req.matchedRequestId,
        newLocation: selected,
      );
    }
  }

  Future<void> _handleConfirm(ExchangeRequestModel req) async {
    if (req.matchedRequestId == null) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Receipt?'),
        content: Text(
          'Confirm ONLY if you have actually received ₹${req.amount} ${req.wants == 'cash' ? 'in physical cash' : 'in your digital UPI account'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusCompleted),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Received', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final service = ref.read(exchangeServiceProvider);
        await service.confirmExchange(
          requestId: req.id,
          matchedRequestId: req.matchedRequestId!,
          currentUserId: user.uid,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCancel(ExchangeRequestModel req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Exchange?'),
        content: const Text(
          'Are you sure? This will end the active exchange and alert your partner.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Active'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusCancelled),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final service = ref.read(exchangeServiceProvider);
        await service.cancelRequest(req.id);
        if (mounted) Navigator.pop(context);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(requestByIdProvider(widget.request.id));
    final req = requestAsync.value ?? widget.request;

    final isAccepted = req.status == ExchangeStatus.accepted;
    final isCompleted = req.status == ExchangeStatus.completed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange Details'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatusBadge(status: req.status),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [AppColors.statusCompleted, const Color(0xFF15803D)]
                        : [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : isAccepted
                              ? Icons.handshake_rounded
                              : Icons.celebration_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isCompleted
                          ? 'Exchange Completed!'
                          : isAccepted
                              ? 'Exchange Ready to Meet'
                              : '🎉 Compatible Match Found!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${req.amount}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Mutual Exchange Breakdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'You Give',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: req.has == 'cash' ? AppColors.cashBg : AppColors.digitalBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              req.has.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: req.has == 'cash'
                                    ? AppColors.cashColor
                                    : AppColors.digitalColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'You Receive',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: req.wants == 'cash' ? AppColors.cashBg : AppColors.digitalBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              req.wants.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: req.wants == 'cash'
                                    ? AppColors.cashColor
                                    : AppColors.digitalColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Designated Meetup Location Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Meetup Place',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              req.location,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (req.status != ExchangeStatus.completed)
                        TextButton.icon(
                          onPressed: () => _showChangeLocationDialog(req),
                          icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                          label: const Text('Change'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Step-by-Step Offline Guidance (Phases 14 & 15)
              if (isAccepted) ...[
                const Text(
                  'Offline Meetup Protocol',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInstructionItem(
                  step: '1',
                  title: 'Meet at ${req.location}',
                  subtitle: 'Head to the designated meetup spot to meet your exchange partner.',
                ),
                _buildInstructionItem(
                  step: '2',
                  title: 'Verify Currency / UPI Transfer',
                  subtitle: 'Count cash or check your official UPI banking app for credit confirmation.',
                ),
                _buildInstructionItem(
                  step: '3',
                  title: 'Confirm in CampusCash',
                  subtitle: 'Tap the confirmation button below ONLY after you have verified the money.',
                ),
                const SizedBox(height: 16),
              ],
              // Safety Callout
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.statusSearchingBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.statusSearching.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.statusSearching, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'CampusCash never requests UPI PINs, passwords, or OTPs. Exchange is done directly between students outside the app.',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Action Buttons Based on Lifecycle State
              if (req.status == ExchangeStatus.matched) ...[
                if (!req.userAccepted) ...[
                  CustomButton(
                    text: 'Accept Exchange',
                    isLoading: _isLoading,
                    onPressed: () => _handleAccept(req),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_top_rounded, color: AppColors.secondary, size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Accepted! Waiting for partner to accept...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Decline / Cancel',
                  isOutlined: true,
                  textColor: AppColors.statusCancelled,
                  backgroundColor: AppColors.statusCancelled.withValues(alpha: 0.3),
                  onPressed: () => _handleCancel(req),
                ),
              ] else if (isAccepted) ...[
                if (!req.userConfirmed) ...[
                  CustomButton(
                    text: 'Confirm I Received ₹${req.amount}',
                    isLoading: _isLoading,
                    backgroundColor: AppColors.statusCompleted,
                    onPressed: () => _handleConfirm(req),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.statusCompletedBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.statusCompleted.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, color: AppColors.statusCompleted, size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'You confirmed receipt! Waiting for partner...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.statusCompleted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Cancel Exchange',
                  isOutlined: true,
                  textColor: AppColors.statusCancelled,
                  backgroundColor: AppColors.statusCancelled.withValues(alpha: 0.3),
                  onPressed: () => _handleCancel(req),
                ),
              ] else if (isCompleted) ...[
                CustomButton(
                  text: 'Return to Home',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem({
    required String step,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
