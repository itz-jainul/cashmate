import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
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

class _RequestsScreenState extends ConsumerState<RequestsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String _filter = 'all'; // 'all', 'cash', 'digital'
  String _searchQuery = '';
  int _sortIndex = 0; // 0: Nearest, 1: Newest, 2: Amount
  final List<String> _sortLabels = const ['Nearest', 'Newest', 'Amount'];

  bool _isConnecting = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Rotating avatar background palettes from the design specification
  static const List<List<Color>> _avatarPalettes = [
    [Color(0xFFFFF4DC), Color(0xFF9A6500)], // Amber
    [Color(0xFFECEAFE), Color(0xFF4B3FD6)], // Lavender
    [Color(0xFFE2F5EC), Color(0xFF0B8F63)], // Mint
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _cycleSort() {
    setState(() => _sortIndex = (_sortIndex + 1) % _sortLabels.length);
  }

  void _resetSearchAndFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filter = 'all';
    });
    _searchFocus.unfocus();
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} d ago';
  }

  Future<void> _handleConnect(ExchangeRequestModel targetReq) async {
    final authUser = ref.read(authStateProvider).value;
    final profile = ref.read(userProfileProvider).value;
    if (authUser == null) return;

    final myActiveReq = ref.read(activeRequestProvider).value;

    // Guard: Prevent conflicting matches if already accepted/matched
    if (myActiveReq != null &&
        (myActiveReq.status == ExchangeStatus.matched ||
            myActiveReq.status == ExchangeStatus.accepted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.statusCancelled,
          content: Text(
            'You already have an active exchange in progress. Please complete or cancel it first.',
          ),
        ),
      );
      return;
    }

    final hasDifferentActiveSearch = myActiveReq != null &&
        myActiveReq.status == ExchangeStatus.searching &&
        (myActiveReq.has != targetReq.wants ||
            myActiveReq.wants != targetReq.has ||
            myActiveReq.amount != targetReq.amount);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.handshake_rounded,
                    color: AppColors.jade,
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
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Exchange ₹${targetReq.amount}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.jade,
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
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
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
                          color: AppColors.mute,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        targetReq.wants.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18, color: AppColors.line),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'You Receive',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.mute,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        targetReq.has.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.jade,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (hasDifferentActiveSearch) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: Color(0xFFB45309)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This will update your current active search (₹${myActiveReq.amount}, ${myActiveReq.has.toUpperCase()} → ${myActiveReq.wants.toUpperCase()}) to match this exchange.',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: AppColors.mute),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Both users must accept to confirm the meetup handshake.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.mute),
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
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.jade,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      hasDifferentActiveSearch ? 'Update & Connect' : 'Confirm Match',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
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
            backgroundColor: AppColors.jade,
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
            content: Text(AppStrings.cleanError(e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final publicRequestsAsync = ref.watch(publicRequestsProvider);
    final activeRequestAsync = ref.watch(activeRequestProvider);
    final currentUserId = ref.watch(authStateProvider).value?.uid;
    final myActiveReq = activeRequestAsync.value;

    final allRawRequests = publicRequestsAsync.value ?? [];

    // Filter out user's own requests
    final otherRequests = currentUserId != null
        ? allRawRequests.where((r) => r.userId != currentUserId).toList()
        : allRawRequests;

    // Use demo items if Firestore is empty (for testing and offline demo)
    final requestsToUse = otherRequests.isNotEmpty
        ? otherRequests
        : _getDemoRequests();

    // Compute filter counts
    final totalCount = requestsToUse.length;
    final wantsCashCount =
        requestsToUse.where((r) => r.wants.toLowerCase() == 'cash').length;
    final wantsDigitalCount =
        requestsToUse.where((r) => r.wants.toLowerCase() == 'digital').length;

    // Apply Filter & Search
    final filtered = requestsToUse.where((r) {
      if (_filter == 'cash' && r.wants.toLowerCase() != 'cash') return false;
      if (_filter == 'digital' && r.wants.toLowerCase() != 'digital') return false;

      if (_searchQuery.isNotEmpty) {
        final cleanQ = _searchQuery.replaceAll(RegExp(r'[₹,\s]'), '');
        final matchName = r.userName.toLowerCase().contains(_searchQuery);
        final matchAmount = cleanQ.isNotEmpty && r.amount.toString().contains(cleanQ);
        final matchLocation = r.location.toLowerCase().contains(_searchQuery);
        if (!matchName && !matchAmount && !matchLocation) return false;
      }
      return true;
    }).toList();

    // Apply Sorting
    filtered.sort((a, b) {
      if (_sortIndex == 0) {
        // Nearest: simulated or location comparison
        return a.location.compareTo(b.location);
      } else if (_sortIndex == 1) {
        // Newest: createdAt descending
        return b.createdAt.compareTo(a.createdAt);
      } else {
        // Amount: amount descending
        return b.amount.compareTo(a.amount);
      }
    });

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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Section (Header, Search, Filter Bar)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header: Title, Live Count, '+' Button
                        _buildHeader(filtered.length),
                        const SizedBox(height: 16),

                        // Search Bar
                        _buildSearchBar(),
                        const SizedBox(height: 12),

                        // Filter Chips & Sort Button Row
                        _buildFilterAndSortBar(
                          totalCount: totalCount,
                          cashCount: wantsCashCount,
                          digitalCount: wantsDigitalCount,
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),

                  // 2. Request Cards List or Empty State
                  Expanded(
                    child: filtered.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 2, 18, 108),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                                  final req = filtered[index];
                                  final isExactMatch = myActiveReq != null &&
                                      myActiveReq.status == ExchangeStatus.searching &&
                                      myActiveReq.amount == req.amount &&
                                      myActiveReq.has.toLowerCase() == req.wants.toLowerCase() &&
                                      myActiveReq.wants.toLowerCase() == req.has.toLowerCase();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildRequestCard(
                                      req: req,
                                      isExactMatch: isExactMatch,
                                      index: index,
                                      myActiveReq: myActiveReq,
                                    ),
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

  // --- 1. Header (Title, Count, '+' Add Button) ---
  Widget _buildHeader(int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Public requests',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.6,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.jade,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.jade.withValues(alpha: 0.4),
                              blurRadius: 4 * _pulseAnimation.value,
                              spreadRadius: 2 * (_pulseAnimation.value - 1.0),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Text(
                      '$count ${count == 1 ? "open request" : "open requests"} near you',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.mute,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // '+' Add Button
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.jade,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x280B8F63),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Search Bar ---
  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: AppColors.mute),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              style: const TextStyle(
                fontSize: 15.5,
                color: AppColors.ink,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search by name or amount',
                hintStyle: TextStyle(
                  color: AppColors.mute,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 18, color: AppColors.mute),
              ),
            ),
        ],
      ),
    );
  }

  // --- Filter Chips & Sort Button Row ---
  Widget _buildFilterAndSortBar({
    required int totalCount,
    required int cashCount,
    required int digitalCount,
  }) {
    return Row(
      children: [
        // Scrolling chips
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterPill(
                  label: 'All',
                  count: totalCount,
                  type: 'all',
                ),
                const SizedBox(width: 8),
                _buildFilterPill(
                  label: 'Wants cash',
                  count: cashCount,
                  type: 'cash',
                ),
                const SizedBox(width: 8),
                _buildFilterPill(
                  label: 'Wants digital',
                  count: digitalCount,
                  type: 'digital',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Sort Button
        GestureDetector(
          onTap: _cycleSort,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Text(
              '↕ ${_sortLabels[_sortIndex]}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.jade,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill({
    required String label,
    required int count,
    required String type,
  }) {
    final isSelected = _filter == type;

    return GestureDetector(
      onTap: () => setState(() => _filter = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.jade : AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.jade : AppColors.line,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.mute,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Request Card ---
  Widget _buildRequestCard({
    required ExchangeRequestModel req,
    required bool isExactMatch,
    required int index,
    required ExchangeRequestModel? myActiveReq,
  }) {
    final isWantsCash = req.wants.toLowerCase() == 'cash';
    final palette = _avatarPalettes[index % _avatarPalettes.length];
    final currencyFormat = NumberFormat('#,##,###', 'en_IN');

    final initial = req.userName.isNotEmpty ? req.userName[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isExactMatch ? AppColors.jade : AppColors.line,
          width: isExactMatch ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExactMatch
                ? AppColors.jade.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exact Match Banner
          if (isExactMatch && myActiveReq != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.okBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded, size: 14, color: AppColors.jade),
                  const SizedBox(width: 4),
                  Text(
                    'Exact match for your ₹${myActiveReq.amount} request',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.jade,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Top Row: Avatar, Name, Location/Time, Amount
          Row(
            children: [
              // Avatar Circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette[0],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: palette[1],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & Location / Distance / Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.userName,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${req.location} • ${_formatTimeAgo(req.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12.5,
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '₹${currencyFormat.format(req.amount)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom Row: Tag + Subtitle & 'Offer swap' Action Button
          Row(
            children: [
              // Tag + Direction Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isWantsCash ? AppColors.cashBg : AppColors.digitalBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isWantsCash ? 'Wants cash' : 'Wants digital',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isWantsCash ? AppColors.amber : AppColors.dig,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isWantsCash ? 'You give cash, get UPI' : 'You give UPI, get cash',
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

              // Offer Swap Button
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: _isConnecting
                      ? null
                      : () {
                          if (req.id.startsWith('demo_')) {
                            // Demo request tap -> open CreateRequestScreen with matching pair
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateRequestScreen(
                                  initialHas: req.wants,
                                  initialAmount: req.amount,
                                ),
                              ),
                            );
                          } else {
                            _handleConnect(req);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Offer swap',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState() {
    final isQueryActive = _searchQuery.isNotEmpty;
    final isFilterActive = _filter != 'all';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustrated circle
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
                  Icons.search_off_rounded,
                  size: 48,
                  color: AppColors.jade,
                ),
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'No requests match',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              isQueryActive
                  ? 'Nothing found for “$_searchQuery”. Try another amount or name.'
                  : 'Nobody is asking for ${_filter == 'cash' ? 'cash' : 'digital'} right now. Post yours and we will notify you when someone matches.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mute,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Primary Post Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.jade,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Post a request',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Ghost Reset Button
            if (isQueryActive || isFilterActive) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _resetSearchAndFilters,
                child: const Text(
                  'Clear search and filters',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.jade,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Demo Requests matching the exact HTML prototype ---
  List<ExchangeRequestModel> _getDemoRequests() {
    final now = DateTime.now();
    final expireTime = now.add(const Duration(hours: 1));
    return [
      ExchangeRequestModel(
        id: 'demo_1',
        userId: 'demo_user_1',
        userName: 'Aarav S.',
        has: 'digital',
        wants: 'cash',
        amount: 200,
        location: '0.4 km • Campus Cafeteria',
        createdAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
        expiresAt: expireTime,
      ),
      ExchangeRequestModel(
        id: 'demo_2',
        userId: 'demo_user_2',
        userName: 'Meera K.',
        has: 'cash',
        wants: 'digital',
        amount: 500,
        location: '0.9 km • Library Lobby',
        createdAt: now.subtract(const Duration(minutes: 12)),
        updatedAt: now.subtract(const Duration(minutes: 12)),
        expiresAt: expireTime,
      ),
      ExchangeRequestModel(
        id: 'demo_3',
        userId: 'demo_user_3',
        userName: 'Rahul D.',
        has: 'digital',
        wants: 'cash',
        amount: 100,
        location: '1.2 km • Student Center',
        createdAt: now.subtract(const Duration(minutes: 20)),
        updatedAt: now.subtract(const Duration(minutes: 20)),
        expiresAt: expireTime,
      ),
      ExchangeRequestModel(
        id: 'demo_4',
        userId: 'demo_user_4',
        userName: 'Fatima Z.',
        has: 'cash',
        wants: 'digital',
        amount: 1000,
        location: '1.8 km • Main Gate',
        createdAt: now.subtract(const Duration(minutes: 35)),
        updatedAt: now.subtract(const Duration(minutes: 35)),
        expiresAt: expireTime,
      ),
      ExchangeRequestModel(
        id: 'demo_5',
        userId: 'demo_user_5',
        userName: 'Karthik R.',
        has: 'digital',
        wants: 'cash',
        amount: 300,
        location: '2.1 km • Hostel Block 3',
        createdAt: now.subtract(const Duration(minutes: 48)),
        updatedAt: now.subtract(const Duration(minutes: 48)),
        expiresAt: expireTime,
      ),
      ExchangeRequestModel(
        id: 'demo_6',
        userId: 'demo_user_6',
        userName: 'Divya P.',
        has: 'cash',
        wants: 'digital',
        amount: 50,
        location: '2.6 km • Sports Complex',
        createdAt: now.subtract(const Duration(minutes: 75)),
        updatedAt: now.subtract(const Duration(minutes: 75)),
        expiresAt: expireTime,
      ),
    ];
  }
}
