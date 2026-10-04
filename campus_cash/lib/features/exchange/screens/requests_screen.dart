import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/exchange_request_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/exchange_provider.dart';
import 'connection_details_screen.dart';
import 'create_request_screen.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all'; // 'all', 'cash', 'digital'
  String _searchQuery = '';
  bool _isConnecting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect(ExchangeRequestModel targetReq) async {
    final authUser = ref.read(authStateProvider).value;
    final profile = ref.read(userProfileProvider).value;
    if (authUser == null) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.handshake_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect with ${targetReq.userName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Exchange ₹${targetReq.amount}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'You Give',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        targetReq.wants.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'You Receive',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        targetReq.has.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cashColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Both users must accept to confirm the meetup handshake.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Confirm Match'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isConnecting = true);
    try {
      final service = ref.read(exchangeServiceProvider);
      final myName = profile?.name.isNotEmpty == true
          ? profile!.name
          : (authUser.displayName ?? 'Student');

      final connection = await service.connectToRequest(
        currentUserId: authUser.uid,
        currentUserName: myName,
        targetRequestId: targetReq.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('Connection request sent! 🎉 Match created.'),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConnectionDetailsScreen(
              connectionId: connection.id,
              initialConnection: connection,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusCancelled,
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final publicRequestsAsync = ref.watch(publicRequestsProvider);
    final activeRequestAsync = ref.watch(activeRequestProvider);
    final currentUserId = ref.watch(authStateProvider).value?.uid;
    final myActiveReq = activeRequestAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Requests'),
        actions: [
          IconButton(
            tooltip: 'Create Request',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search requests by user or amount...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('💵 Cash', 'cash'),
                      const SizedBox(width: 8),
                      _buildFilterChip('📱 Digital', 'digital'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.border),

            // Requests List
            Expanded(
              child: publicRequestsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Loading public requests...',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
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
                          size: 32,
                          color: AppColors.statusCancelled,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Error loading requests: $e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () => ref.invalidate(publicRequestsProvider),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (allRequests) {
                  // Filter requests based on search and selected filter
                  var filtered = allRequests.where((req) {
                    if (_filter == 'cash' && req.has != 'cash') return false;
                    if (_filter == 'digital' && req.has != 'digital') return false;

                    if (_searchQuery.isNotEmpty) {
                      final matchName = req.userName.toLowerCase().contains(_searchQuery);
                      final matchAmount = req.amount.toString().contains(_searchQuery);
                      final matchHas = req.has.toLowerCase().contains(_searchQuery);
                      final matchWants = req.wants.toLowerCase().contains(_searchQuery);
                      if (!matchName && !matchAmount && !matchHas && !matchWants) return false;
                    }
                    return true;
                  }).toList();

                  // Separate Exact Match if user has active searching request
                  ExchangeRequestModel? exactMatch;
                  if (myActiveReq != null &&
                      myActiveReq.status == ExchangeStatus.searching &&
                      currentUserId != null) {
                    try {
                      exactMatch = filtered.firstWhere(
                        (r) =>
                            r.userId != currentUserId &&
                            r.has == myActiveReq.wants &&
                            r.wants == myActiveReq.has &&
                            r.amount == myActiveReq.amount,
                      );
                    } catch (_) {
                      exactMatch = null;
                    }
                  }

                  if (filtered.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.search_off_rounded,
                      title: 'No Matching Requests',
                      description: _searchQuery.isNotEmpty
                          ? 'No exchange requests match "$_searchQuery".'
                          : 'There are currently no active public requests.',
                      buttonText: 'Post a Request',
                      onButtonPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
                        );
                      },
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Prominent Exact Match Header & Card
                      if (exactMatch != null) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '🎯 EXACT MATCH AVAILABLE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildRequestCard(
                          req: exactMatch,
                          isExactMatch: true,
                          isOwn: exactMatch.userId == currentUserId,
                          isCompatible: true,
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 16),
                        const Text(
                          'All Active Requests',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Remaining Requests List
                      ...filtered
                          .where((r) => exactMatch == null || r.id != exactMatch.id)
                          .map((req) {
                        final isOwn = req.userId == currentUserId;
                        final isCompatible = myActiveReq != null &&
                            myActiveReq.status == ExchangeStatus.searching &&
                            !isOwn &&
                            req.has == myActiveReq.wants &&
                            req.wants == myActiveReq.has &&
                            req.amount == myActiveReq.amount;

                        return _buildRequestCard(
                          req: req,
                          isExactMatch: false,
                          isOwn: isOwn,
                          isCompatible: isCompatible,
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primaryContainer,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildRequestCard({
    required ExchangeRequestModel req,
    required bool isExactMatch,
    required bool isOwn,
    required bool isCompatible,
  }) {
    final hasIsCash = req.has == 'cash';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isExactMatch ? AppColors.primary : AppColors.border,
          width: isExactMatch ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Poster Name, Time, Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: hasIsCash ? AppColors.cashBg : AppColors.digitalBg,
                      child: Icon(
                        hasIsCash ? Icons.payments_rounded : Icons.account_balance_wallet_rounded,
                        size: 14,
                        color: hasIsCash ? AppColors.cashColor : AppColors.digitalColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOwn ? '${req.userName} (You)' : req.userName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isOwn ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      _formatTime(req.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 8),
                    const StatusBadge(status: ExchangeStatus.searching),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount and Directions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${req.amount}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildDirectionBadge(
                          label: 'Has',
                          type: req.has,
                          isCash: hasIsCash,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textMuted),
                        ),
                        _buildDirectionBadge(
                          label: 'Wants',
                          type: req.wants,
                          isCash: !hasIsCash,
                        ),
                      ],
                    ),
                  ],
                ),

                // Connect Action Button
                if (!isOwn)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExactMatch || isCompatible
                          ? AppColors.primary
                          : AppColors.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      minimumSize: const Size(90, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isConnecting ? null : () => _handleConnect(req),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isExactMatch) ...[
                          const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        const Text(
                          'Connect',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionBadge({
    required String label,
    required String type,
    required bool isCash,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCash ? AppColors.cashBg : AppColors.digitalBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: ${type.toUpperCase()}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isCash ? AppColors.cashColor : AppColors.digitalColor,
        ),
      ),
    );
  }
}
