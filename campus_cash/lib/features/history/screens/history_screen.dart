import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../exchange/providers/exchange_provider.dart';
import '../../exchange/screens/create_request_screen.dart';
import '../../../models/exchange_model.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  String _selectedTab = 'all'; // 'all', 'completed', 'cancelled'
  late AnimationController _refreshAnimController;

  static const List<List<Color>> _avatarThemes = [
    [Color(0xFFFFF4DC), Color(0xFF9A6500)], // Warm gold / amber
    [Color(0xFFECEAFE), Color(0xFF4B3FD6)], // Soft lavender / indigo
    [Color(0xFFE2F5EC), Color(0xFF0B8F63)], // Mint / jade
  ];

  @override
  void initState() {
    super.initState();
    _refreshAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _refreshAnimController.dispose();
    super.dispose();
  }

  void _handleRefresh() {
    _refreshAnimController.forward(from: 0.0);
    ref.invalidate(userHistoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(userHistoryProvider);
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

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
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.line),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_rounded,
                                      size: 20,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Exchange history',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.025,
                                    color: AppColors.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        RotationTransition(
                          turns: _refreshAnimController,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleRefresh,
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.line),
                                ),
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
                  ),

                  // Content
                  Expanded(
                    child: historyAsync.when(
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
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.red,
                                size: 36,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Error loading history: $err',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: _handleRefresh,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.jade,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (historyList) {
                        final completedCount = historyList
                            .where((h) => h.status.toLowerCase() == 'completed')
                            .length;
                        final cancelledCount = historyList
                            .where((h) => h.status.toLowerCase() == 'cancelled')
                            .length;
                        final allCount = historyList.length;

                        // Total amount swapped in completed trades
                        final totalAmountSwapped = historyList
                            .where((h) => h.status.toLowerCase() == 'completed')
                            .fold<int>(0, (sum, h) => sum + h.amount);

                        final filteredList = historyList.where((h) {
                          if (_selectedTab == 'completed') {
                            return h.status.toLowerCase() == 'completed';
                          } else if (_selectedTab == 'cancelled') {
                            return h.status.toLowerCase() == 'cancelled';
                          }
                          return true;
                        }).toList();

                        return Column(
                          children: [
                            // Segmented Tabs
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: _buildPillTabs(
                                allCount: allCount,
                                completedCount: completedCount,
                                cancelledCount: cancelledCount,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Total Swapped Metric Banner (if has history)
                            if (allCount > 0)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 18),
                                child: _buildMetricsBanner(
                                  totalSwapped: totalAmountSwapped,
                                  completedSwaps: completedCount,
                                  currencyFormatter: currencyFormatter,
                                ),
                              ),
                            const SizedBox(height: 10),

                            // History List or Empty State
                            Expanded(
                              child: filteredList.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                        18,
                                        4,
                                        18,
                                        40,
                                      ),
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: filteredList.length,
                                      itemBuilder: (context, index) {
                                        final item = filteredList[index];
                                        return _buildHistoryCard(
                                          item: item,
                                          currentUserId: currentUserId,
                                          currencyFormatter: currencyFormatter,
                                          index: index,
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
    );
  }

  Widget _buildPillTabs({
    required int allCount,
    required int completedCount,
    required int cancelledCount,
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
          _buildTabButton('all', 'All', allCount),
          _buildTabButton('completed', 'Completed', completedCount),
          _buildTabButton('cancelled', 'Cancelled', cancelledCount),
        ],
      ),
    );
  }

  Widget _buildTabButton(String key, String label, int count) {
    final isSelected = _selectedTab == key;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
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
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.mute,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.okBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
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

  Widget _buildMetricsBanner({
    required int totalSwapped,
    required int completedSwaps,
    required NumberFormat currencyFormatter,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.okBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: AppColors.jade,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currencyFormatter.format(totalSwapped)} swapped',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.02,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$completedSwaps peer exchanges successfully finalized',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mute,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required ExchangeModel item,
    required String currentUserId,
    required NumberFormat currencyFormatter,
    required int index,
  }) {
    final isCompleted = item.status.toLowerCase() == 'completed';
    final theme = _avatarThemes[index % _avatarThemes.length];

    // Determine partner and directions from logged-in user perspective
    final bool isUserA = currentUserId.isNotEmpty && item.userAId == currentUserId;
    final partnerName = isUserA
        ? (item.userBName.isNotEmpty ? item.userBName : 'Peer')
        : (item.userAName.isNotEmpty ? item.userAName : 'Peer');

    final myGive = (isUserA ? item.userAHas : item.userBHas).toLowerCase();
    final myGet = (isUserA ? item.userBHas : item.userAHas).toLowerCase();

    final dateStr = DateFormat('d MMM, h:mm a').format(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partner Header & Status
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme[0],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'P',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme[1],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partnerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.location != null && item.location!.isNotEmpty
                          ? '${item.location} • $dateStr'
                          : dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mute,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.okBg : AppColors.redBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 13,
                      color: isCompleted ? AppColors.jade : AppColors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCompleted ? 'Completed' : 'Cancelled',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isCompleted ? AppColors.jade : AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Flow and Amount Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                currencyFormatter.format(item.amount),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.02,
                  color: AppColors.ink,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFlowTag(
                    isCash: myGive == 'cash',
                    prefix: 'Gave',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  _buildFlowTag(
                    isCash: myGet == 'cash',
                    prefix: 'Got',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowTag({required bool isCash, required String prefix}) {
    final bg = isCash ? AppColors.cashBg : AppColors.digitalBg;
    final fg = isCash ? AppColors.amber : AppColors.dig;
    final label = isCash ? 'Cash' : 'Digital';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$prefix $label',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 42,
                color: AppColors.jade,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _selectedTab == 'cancelled'
                  ? 'No cancelled exchanges'
                  : (_selectedTab == 'completed'
                      ? 'No completed swaps yet'
                      : 'Nothing here yet'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.02,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Once you and a peer finish an exchange, receipts and details will be logged here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.mute,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Create exchange request',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

