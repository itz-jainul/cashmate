import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/connection_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/exchange_provider.dart';
import '../widgets/meetup_chat_widget.dart';

class ConnectionDetailsScreen extends ConsumerStatefulWidget {
  final String connectionId;
  final ConnectionModel? initialConnection;

  const ConnectionDetailsScreen({
    super.key,
    required this.connectionId,
    this.initialConnection,
  });

  @override
  ConsumerState<ConnectionDetailsScreen> createState() =>
      _ConnectionDetailsScreenState();
}

class _ConnectionDetailsScreenState
    extends ConsumerState<ConnectionDetailsScreen> {
  bool _isLoading = false;

  Future<void> _handleAccept(ConnectionModel conn, String currentUserId) async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(exchangeServiceProvider);
      await service.acceptConnection(
        connectionId: conn.id,
        userId: currentUserId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusCancelled,
            content: Text(AppStrings.cleanError(e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleConfirm(ConnectionModel conn, String currentUserId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Exchange'),
        content: Text(
          'Confirm that you have received ₹${conn.amount} from ${conn.partnerName(currentUserId)}?\n\n'
          'Both parties must confirm to complete the exchange.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCompleted,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Received',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final service = ref.read(exchangeServiceProvider);
      await service.confirmConnection(
        connectionId: conn.id,
        userId: currentUserId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusCancelled,
            content: Text(AppStrings.cleanError(e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCancel(ConnectionModel conn, String currentUserId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Connection?'),
        content: const Text(
          'Are you sure you want to cancel this connection? Both users will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Active'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCancelled,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final service = ref.read(exchangeServiceProvider);
      await service.cancelConnection(
        connectionId: conn.id,
        userId: currentUserId,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusCancelled,
            content: Text(AppStrings.cleanError(e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionAsync =
        ref.watch(connectionByIdProvider(widget.connectionId));
    final conn = connectionAsync.value ?? widget.initialConnection;
    final currentUser = ref.watch(authStateProvider).value;

    if (conn == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Connection Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Loading connection details...',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(
                      connectionByIdProvider(widget.connectionId)),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentUserId = currentUser?.uid ?? '';
    final partnerName = conn.partnerName(currentUserId);
    final isUserAccepted = conn.isAcceptedByMe(currentUserId);
    final isUserConfirmed = conn.isConfirmedByMe(currentUserId);

    final isPending = conn.status == ConnectionStatus.pending;
    final isConnected = conn.status == ConnectionStatus.connected;
    final isCompleted = conn.status == ConnectionStatus.completed;
    final isCancelled = conn.status == ConnectionStatus.cancelled;

    final myGive = conn.myHas(currentUserId);
    final myReceive = conn.myWants(currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Connection Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _buildStatusPill(conn.status)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
                        : isConnected
                            ? [AppColors.primary, AppColors.primaryDark]
                            : [AppColors.secondary, const Color(0xFF3730A3)],
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
                          : isConnected
                              ? Icons.handshake_rounded
                              : Icons.celebration_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isCompleted
                          ? 'Exchange Completed!'
                          : isConnected
                              ? 'Connected with $partnerName 🤝'
                              : '🎉 Match Found!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${conn.amount}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connected with $partnerName',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Exchange Overview Card (You Give / You Receive)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildGiveReceiveColumn(
                              title: 'You Give',
                              type: myGive,
                              isGive: true,
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: AppColors.border,
                          ),
                          Expanded(
                            child: _buildGiveReceiveColumn(
                              title: 'You Receive',
                              type: myReceive,
                              isGive: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Meetup Location Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Meetup Spot',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              conn.location,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Meetup Coordination Chat
              if (currentUser != null && !isCancelled) ...[
                MeetupChatWidget(
                  chatId: conn.id,
                  currentUserId: currentUserId,
                  currentUserName: currentUser.displayName?.isNotEmpty == true
                      ? currentUser.displayName!
                      : (currentUser.email?.split('@').first ?? 'Student'),
                  isReadOnly: isCompleted || isCancelled,
                  location: conn.location,
                ),
                const SizedBox(height: 20),
              ],

              // Safety Reminder Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: Color(0xFFB45309),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Meet in a safe public place. CashMate does not hold or process money. Never share OTPs, PINs, or bank passwords.',
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
              const SizedBox(height: 24),

              // Action Buttons Based on Lifecycle State
              if (isPending) ...[
                if (!isUserAccepted)
                  ElevatedButton(
                    onPressed:
                        _isLoading ? null : () => _handleAccept(conn, currentUserId),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Accept Connection'),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Waiting for $partnerName to accept...',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed:
                      _isLoading ? null : () => _handleCancel(conn, currentUserId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusCancelled,
                    side: const BorderSide(color: AppColors.statusCancelled),
                  ),
                  child: const Text('Cancel Match'),
                ),
              ] else if (isConnected) ...[
                if (!isUserConfirmed)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusCompleted,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () => _handleConfirm(conn, currentUserId),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('I Have Received ₹${conn.amount}'),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.statusCompletedBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.statusCompleted,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Waiting for $partnerName to confirm receipt...',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusCompleted,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed:
                      _isLoading ? null : () => _handleCancel(conn, currentUserId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusCancelled,
                    side: const BorderSide(color: AppColors.statusCancelled),
                  ),
                  child: const Text('Cancel Exchange'),
                ),
              ] else if (isCompleted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.statusCompletedBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: AppColors.statusCompleted,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Exchange Completed Successfully!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusCompleted,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (isCancelled) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.statusCancelledBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color: AppColors.statusCancelled,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'This exchange was cancelled.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusCancelled,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGiveReceiveColumn({
    required String title,
    required String type,
    required bool isGive,
  }) {
    final isCash = type.toLowerCase() == 'cash';
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCash
                  ? Icons.payments_outlined
                  : Icons.account_balance_wallet_outlined,
              size: 18,
              color: isCash ? AppColors.cashColor : AppColors.digitalColor,
            ),
            const SizedBox(width: 6),
            Text(
              type.toUpperCase(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isCash ? AppColors.cashColor : AppColors.digitalColor,
              ),
            ),
          ],
        ),
      ],
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
        label = 'Connected';
        break;
      case ConnectionStatus.completed:
        bg = AppColors.statusCompletedBg;
        fg = AppColors.statusCompleted;
        label = 'Completed';
        break;
      case ConnectionStatus.cancelled:
        bg = AppColors.statusCancelledBg;
        fg = AppColors.statusCancelled;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
