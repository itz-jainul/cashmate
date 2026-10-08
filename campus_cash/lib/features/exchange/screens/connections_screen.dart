import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/connection_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/exchange_provider.dart';
import 'connection_details_screen.dart';
import 'create_request_screen.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedTab = 'active'; // 'active', 'completed', 'all'
  String? _armedCancelConnectionId;
  Timer? _cancelDisarmTimer;
  late AnimationController _spinController;

  static const List<List<Color>> _avatarColors = [
    [AppColors.cashBg, AppColors.amber],
    [AppColors.digitalBg, AppColors.dig],
    [AppColors.okBg, AppColors.jade],
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _cancelDisarmTimer?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        duration: const Duration(milliseconds: 2200),
      ),
    );
  }

  void _onRefresh() {
    _spinController.forward(from: 0.0);
    ref.invalidate(userConnectionsProvider);
    _showToast('You are up to date');
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final timeStr = DateFormat('h:mm a').format(dt);
    if (isToday) {
      return 'Today, $timeStr';
    }
    return '${DateFormat('d MMM').format(dt)}, $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(userConnectionsProvider);
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
    final currencyFormatter = NumberFormat('#,##,###', 'en_IN');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bg],
          stops: [0.0, 0.45],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Column(
                  children: [
                    // Header: "My connections" + Refresh button with spin
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'My connections',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _onRefresh,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Center(
                              child: RotationTransition(
                                turns: _spinController,
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  size: 20,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Connections Content
                    Expanded(
                      child: connectionsAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.jade,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 14),
                                Text(
                                  'Loading connections…',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.mute,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        error: (e, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 36,
                                  color: AppColors.red,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Error loading connections: $e',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: () => ref.invalidate(userConnectionsProvider),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.jade,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        data: (connections) {
                          final activeCount = connections
                              .where((c) =>
                                  c.status == ConnectionStatus.pending ||
                                  c.status == ConnectionStatus.connected)
                              .length;

                          final completedCount = connections
                              .where((c) =>
                                  c.status == ConnectionStatus.completed ||
                                  c.status == ConnectionStatus.cancelled)
                              .length;

                          final allCount = connections.length;

                          final filteredList = connections.where((c) {
                            if (_selectedTab == 'active') {
                              return c.status == ConnectionStatus.pending ||
                                  c.status == ConnectionStatus.connected;
                            } else if (_selectedTab == 'completed') {
                              return c.status == ConnectionStatus.completed ||
                                  c.status == ConnectionStatus.cancelled;
                            }
                            return true;
                          }).toList();

                          return Column(
                            children: [
                              // 3-Segmented Pill Tabs
                              _buildPillTabs(
                                activeCount: activeCount,
                                completedCount: completedCount,
                                allCount: allCount,
                              ),
                              const SizedBox(height: 12),

                              // List or Empty State
                              Expanded(
                                child: filteredList.isEmpty
                                    ? _buildEmptyState()
                                    : ListView.builder(
                                        padding: const EdgeInsets.only(
                                          bottom: 96,
                                          top: 4,
                                        ),
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: filteredList.length,
                                        itemBuilder: (ctx, i) {
                                          final conn = filteredList[i];
                                          return _buildConnectionCard(
                                            conn: conn,
                                            currentUserId: currentUserId,
                                            currencyFormatter: currencyFormatter,
                                            index: i,
                                          );
                                        },
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Segmented Pill Tabs ---
  Widget _buildPillTabs({
    required int activeCount,
    required int completedCount,
    required int allCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabItem(
            tabKey: 'active',
            title: 'Active',
            count: activeCount,
          ),
          const SizedBox(width: 4),
          _buildTabItem(
            tabKey: 'completed',
            title: 'Completed',
            count: completedCount,
          ),
          const SizedBox(width: 4),
          _buildTabItem(
            tabKey: 'all',
            title: 'All',
            count: allCount,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String tabKey,
    required String title,
    required int count,
  }) {
    final isSelected = _selectedTab == tabKey;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = tabKey;
            _armedCancelConnectionId = null;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.mute,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.okBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.jade,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Connection Card ---
  Widget _buildConnectionCard({
    required ConnectionModel conn,
    required String currentUserId,
    required NumberFormat currencyFormatter,
    required int index,
  }) {
    final isActive = conn.status == ConnectionStatus.pending ||
        conn.status == ConnectionStatus.connected;
    final partnerName = conn.partnerName(currentUserId);
    final myGive = conn.myHas(currentUserId);
    final isGiveCash = myGive.toLowerCase() == 'cash';
    final colors = _avatarColors[(conn.id.hashCode.abs() + index) % _avatarColors.length];
    final initialLetter =
        partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'S';
    final formattedAmount = currencyFormatter.format(conn.amount);
    final timeStr = _formatDateTime(conn.createdAt);

    return InkWell(
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
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isActive ? 13 : 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive ? AppColors.jade : AppColors.line,
            width: isActive ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Avatar + Name/Spot/Time + Amount
            Row(
              children: [
                // Circular Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors[0],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initialLetter,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors[1],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name and Place · Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${conn.location} · $timeStr',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mute,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Amount
                Text(
                  '₹$formattedAmount',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Flow Row: Give tag -> Get tag (and Status tag if not active)
            Row(
              children: [
                // Give Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isGiveCash ? AppColors.cashBg : AppColors.digitalBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isGiveCash ? 'Give cash' : 'Give digital',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isGiveCash ? AppColors.amber : AppColors.dig,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.mute,
                ),
                const SizedBox(width: 6),

                // Get Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isGiveCash ? AppColors.digitalBg : AppColors.cashBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isGiveCash ? 'Get digital' : 'Get cash',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isGiveCash ? AppColors.dig : AppColors.amber,
                    ),
                  ),
                ),

                const Spacer(),

                // Status Tag for completed/cancelled
                if (!isActive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: conn.status == ConnectionStatus.completed
                          ? AppColors.okBg
                          : AppColors.redBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      conn.status == ConnectionStatus.completed
                          ? 'Completed'
                          : 'Cancelled',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: conn.status == ConnectionStatus.completed
                          ? AppColors.jade
                          : AppColors.red,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Active Connection Steps & Action Buttons
            if (isActive) ...[
              const SizedBox(height: 16),
              // 3-Step Progress Indicator
              _buildProgressSteps(conn: conn, currentUserId: currentUserId),
              const SizedBox(height: 12),

              // Action Buttons Row: Main Action + Chat + Cancel
              _buildActionButtons(
                conn: conn,
                currentUserId: currentUserId,
                partnerName: partnerName,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- 3-Step Progress Steps (Matched, Meet up, Exchange) ---
  Widget _buildProgressSteps({
    required ConnectionModel conn,
    required String currentUserId,
  }) {
    // Step 0: Matched (always done)
    const step0Done = true;

    // Step 1: Meet up
    final step1Done = conn.status == ConnectionStatus.connected ||
        conn.status == ConnectionStatus.completed;
    final step1Now = conn.status == ConnectionStatus.pending;

    // Step 2: Exchange
    final step2Done = conn.status == ConnectionStatus.completed;
    final step2Now = conn.status == ConnectionStatus.connected;

    return Row(
      children: [
        // Step 1: Matched
        _buildSingleStep(
          stepNumber: 1,
          label: 'Matched',
          isDone: step0Done,
          isNow: false,
        ),

        // Line 1-2
        _buildStepLine(isActive: step0Done),

        // Step 2: Meet up
        _buildSingleStep(
          stepNumber: 2,
          label: 'Meet up',
          isDone: step1Done,
          isNow: step1Now,
        ),

        // Line 2-3
        _buildStepLine(isActive: step1Done),

        // Step 3: Exchange
        _buildSingleStep(
          stepNumber: 3,
          label: 'Exchange',
          isDone: step2Done,
          isNow: step2Now,
        ),
      ],
    );
  }

  Widget _buildSingleStep({
    required int stepNumber,
    required String label,
    required bool isDone,
    required bool isNow,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDone ? AppColors.jade : AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: (isDone || isNow) ? AppColors.jade : AppColors.line,
              width: 2,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 13,
                  )
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isNow ? AppColors.jade : AppColors.mute,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: (isDone || isNow) ? AppColors.ink : AppColors.mute,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine({required bool isActive}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 22),
        height: 2,
        color: isActive ? AppColors.jade : AppColors.line,
      ),
    );
  }

  // --- Action Buttons: Main Button + Chat Button + Cancel Button ---
  Widget _buildActionButtons({
    required ConnectionModel conn,
    required String currentUserId,
    required String partnerName,
  }) {
    final isPending = conn.status == ConnectionStatus.pending;
    final isConnected = conn.status == ConnectionStatus.connected;
    final isAcceptedByMe = conn.isAcceptedByMe(currentUserId);
    final isConfirmedByMe = conn.isConfirmedByMe(currentUserId);
    final isArmed = _armedCancelConnectionId == conn.id;

    String mainBtnText;
    bool isMainBtnEnabled;
    VoidCallback? onMainBtnTap;

    if (isPending) {
      if (!isAcceptedByMe) {
        mainBtnText = "I've reached the spot";
        isMainBtnEnabled = true;
        onMainBtnTap = () async {
          try {
            await ref.read(exchangeServiceProvider).acceptConnection(
                  connectionId: conn.id,
                  userId: currentUserId,
                );
            _showToast('Great. Meet and swap safely.');
          } catch (e) {
            _showToast('Failed to accept: $e');
          }
        };
      } else {
        mainBtnText = 'Waiting for $partnerName…';
        isMainBtnEnabled = false;
        onMainBtnTap = null;
      }
    } else if (isConnected) {
      if (!isConfirmedByMe) {
        mainBtnText = 'Confirm exchange done';
        isMainBtnEnabled = true;
        onMainBtnTap = () async {
          try {
            await ref.read(exchangeServiceProvider).confirmConnection(
                  connectionId: conn.id,
                  userId: currentUserId,
                );
            _showToast('Exchange completed with $partnerName');
          } catch (e) {
            _showToast('Failed to confirm: $e');
          }
        };
      } else {
        mainBtnText = 'Waiting for confirmation…';
        isMainBtnEnabled = false;
        onMainBtnTap = null;
      }
    } else {
      mainBtnText = 'View Details';
      isMainBtnEnabled = true;
      onMainBtnTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConnectionDetailsScreen(
              connectionId: conn.id,
              initialConnection: conn,
            ),
          ),
        );
      };
    }

    return Row(
      children: [
        // Main Action Button
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: isMainBtnEnabled ? onMainBtnTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.jade,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.jade.withValues(alpha: 0.45),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                mainBtnText,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Chat Button
        InkWell(
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
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line, width: 1.5),
            ),
            child: const Center(
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 20,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Cancel Button with Two-Tap Arming
        InkWell(
          onTap: () async {
            if (isArmed) {
              _cancelDisarmTimer?.cancel();
              setState(() => _armedCancelConnectionId = null);
              try {
                await ref.read(exchangeServiceProvider).cancelConnection(
                      connectionId: conn.id,
                      userId: currentUserId,
                    );
                _showToast('Connection cancelled');
              } catch (e) {
                _showToast('Failed to cancel: $e');
              }
            } else {
              setState(() => _armedCancelConnectionId = conn.id);
              _cancelDisarmTimer?.cancel();
              _cancelDisarmTimer = Timer(const Duration(seconds: 3), () {
                if (mounted && _armedCancelConnectionId == conn.id) {
                  setState(() => _armedCancelConnectionId = null);
                }
              });
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(
              isArmed ? 'Tap again' : 'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isArmed ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.red,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState() {
    final isActiveTab = _selectedTab == 'active';
    final title = isActiveTab ? 'No active connections' : 'Nothing here yet';
    final desc = isActiveTab
        ? 'You have no ongoing exchanges. Post a request and we will match you with someone nearby.'
        : 'Finished exchanges will show up here.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Handshake Circle Illustration
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: const Center(
                child: Icon(
                  Icons.handshake_outlined,
                  size: 50,
                  color: AppColors.jade,
                ),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                desc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.mute,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (isActiveTab)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateRequestScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.jade,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Create request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
