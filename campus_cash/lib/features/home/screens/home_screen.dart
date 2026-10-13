import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/connection_model.dart';
import '../../../models/exchange_request_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../exchange/providers/exchange_provider.dart';
import '../../exchange/screens/connection_details_screen.dart';
import '../../exchange/screens/connections_screen.dart';
import '../../exchange/screens/create_request_screen.dart';
import '../../exchange/screens/requests_screen.dart';
import '../../exchange/screens/searching_match_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Give cash = true -> Give Cash in hand, Get Digital (UPI)
  // Give cash = false -> Give Digital (UPI), Get Cash in hand
  bool _giveCash = false;
  int _amount = 200;
  bool _isCustom = false;

  final TextEditingController _customController = TextEditingController();
  final FocusNode _customFocus = FocusNode();

  final List<int> _presetAmounts = const [100, 200, 500, 1000];
  static const int _minAmount = 10;
  static const int _maxAmount = 10000;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

    _customController.addListener(() {
      if (_isCustom) {
        final val = int.tryParse(_customController.text.trim()) ?? 0;
        setState(() => _amount = val);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _customController.dispose();
    _customFocus.dispose();
    super.dispose();
  }

  bool get _isValidAmount => _amount >= _minAmount && _amount <= _maxAmount;

  void _onPresetSelected(int amt) {
    setState(() {
      _isCustom = false;
      _amount = amt;
      _customController.clear();
    });
    _customFocus.unfocus();
  }

  void _onCustomSelected() {
    setState(() {
      _isCustom = true;
      _amount = int.tryParse(_customController.text.trim()) ?? 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _customFocus.requestFocus();
    });
  }

  void _handleSwap() {
    setState(() => _giveCash = !_giveCash);
  }

  void _handleCta(ExchangeRequestModel? activeReq) {
    if (!_isValidAmount) return;

    if (activeReq != null && activeReq.status == ExchangeStatus.searching) {
      _showActiveRequestDialog(activeReq);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateRequestScreen(
          initialHas: _giveCash ? 'cash' : 'digital',
          initialAmount: _amount,
        ),
      ),
    );
  }

  void _showActiveRequestDialog(ExchangeRequestModel activeReq) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Active Request in Progress'),
        content: Text(
          'You already have an active request for ₹${activeReq.amount} '
          '(${activeReq.has.toUpperCase()} → ${activeReq.wants.toUpperCase()}). '
          'Would you like to view your live search?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.jade,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchingMatchScreen(initialRequest: activeReq),
                ),
              );
            },
            child: const Text('View Live Search'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeRequestAsync = ref.watch(activeRequestProvider);
    final publicRequestsAsync = ref.watch(publicRequestsProvider);
    final connectionsAsync = ref.watch(userConnectionsProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';

    final activeReq = activeRequestAsync.value;
    final publicRequests = publicRequestsAsync.value ?? [];
    final connections = connectionsAsync.value ?? [];
    final notifs = notificationsAsync.value ?? [];
    final hasUnreadNotifs = notifs.any((n) => n['isRead'] != true);
    final otherRequests =
        publicRequests.where((r) => r.userId != currentUserId).toList();
    final liveCount = otherRequests.length;

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header (Logo, Brand, Notification Bell)
                    _buildHeader(hasUnreadNotifs),
                    const SizedBox(height: 16),

                    // 2. Active Request Alert Banner (if user has active request)
                    if (activeReq != null &&
                        activeReq.status == ExchangeStatus.searching) ...[
                      _buildActiveSearchAlert(activeReq),
                      const SizedBox(height: 14),
                    ],

                    // 3. Live Pulse Banner ("14 people near you are ready to swap")
                    _buildLiveBanner(liveCount),
                    const SizedBox(height: 12),

                    // 4. Hero Card ("What do you need today?")
                    _buildHeroCard(activeReq),
                    const SizedBox(height: 26),

                    // 5. "Waiting near you" Section
                    _buildWaitingNearYouSection(
                      publicRequests,
                      currentUserId,
                      hasActiveRequest: activeReq != null &&
                          activeReq.status == ExchangeStatus.searching,
                    ),
                    const SizedBox(height: 26),

                    // 6. "Recent activity" Section
                    _buildRecentActivitySection(connections, currentUserId),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Header ---
  Widget _buildHeader(bool hasUnreadNotifs) {
    return Row(
      children: [
        // CashMate 3D Logo
        SizedBox(
          width: 44,
          height: 44,
          child: Image.asset(
            'assets/images/cashmate_logo_transparent.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 10),

        // Brand Text: CashMate
        Expanded(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Figtree',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.4,
              ),
              children: [
                TextSpan(text: 'Cash'),
                TextSpan(
                  text: 'Mate',
                  style: TextStyle(color: AppColors.jade),
                ),
              ],
            ),
          ),
        ),

        // Notification Bell Button
        GestureDetector(
          onTap: _showNotificationsSheet,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: AppColors.ink,
                ),
                if (hasUnreadNotifs)
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Active Search Banner ---
  Widget _buildActiveSearchAlert(ExchangeRequestModel activeReq) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchingMatchScreen(initialRequest: activeReq),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.jade, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.jade.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.okBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.radar_rounded, color: AppColors.jade, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Searching for match',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${activeReq.amount}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.jade,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${activeReq.has.toUpperCase()} → ${activeReq.wants.toUpperCase()} • Tap to view status',
                    style: const TextStyle(fontSize: 11, color: AppColors.mute),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.jade, size: 20),
          ],
        ),
      ),
    );
  }

  // --- 2. Live Pulse Banner ---
  Widget _buildLiveBanner(int liveCount) {
    final bannerText = liveCount > 0
        ? '$liveCount ${liveCount == 1 ? "person" : "people"} near you ready to swap'
        : 'Instant cash & digital exchanges on campus';
    return Row(
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
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            bannerText,
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
    );
  }

  // --- 3. Hero Card ("What do you need today?") ---
  Widget _buildHeroCard(ExchangeRequestModel? activeReq) {
    final currencyFormat = NumberFormat('#,##,###', 'en_IN');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          const Text(
            'What do you need today?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),

          // Interactive Give/Get Pair with Center Swap Button
          _buildExchangePair(),
          const SizedBox(height: 16),

          // Amount Label
          const Text(
            'Amount',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.mute,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // 5 Chips: ₹100, ₹200, ₹500, ₹1000, Custom
          _buildAmountChips(),

          // Custom Input Box (Appears when Custom is pressed)
          if (_isCustom) ...[
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.jade, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mute,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _customController,
                      focusNode: _customFocus,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter amount',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 18,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Error Text
          SizedBox(
            height: 22,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                (_isCustom && !_isValidAmount && _customController.text.isNotEmpty)
                    ? 'Enter an amount from ₹$_minAmount to ₹${currencyFormat.format(_maxAmount)}'
                    : '',
                style: const TextStyle(color: AppColors.red, fontSize: 13),
              ),
            ),
          ),

          // Primary CTA Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isValidAmount ? () => _handleCta(activeReq) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.jade,
                disabledBackgroundColor: AppColors.jade.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: Text(
                _isValidAmount
                    ? 'Find a match for ₹${currencyFormat.format(_amount)}'
                    : 'Enter an amount',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Hint
          const Text(
            'We only match exact amounts, so nobody needs change.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mute,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // --- Interactive Give / Get Pair ---
  Widget _buildExchangePair() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            // Top Side: You Give
            _buildSideTile(
              isGive: true,
              isCash: _giveCash,
            ),
            const SizedBox(height: 8),

            // Bottom Side: You Get
            _buildSideTile(
              isGive: false,
              isCash: !_giveCash,
            ),
          ],
        ),

        // Floating Circular Swap Button
        Positioned(
          right: 16,
          child: GestureDetector(
            onTap: _handleSwap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.card, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedRotation(
                  turns: _giveCash ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSideTile({required bool isGive, required bool isCash}) {
    final bg = isCash ? AppColors.cashBg : AppColors.digitalBg;
    final icBg = isCash ? AppColors.cash : AppColors.dig;
    final icColor = isCash ? const Color(0xFF3B2A00) : Colors.white;
    final label = isGive ? 'You give' : 'You get';
    final title = isCash ? 'Cash in hand' : 'Digital (UPI)';
    final icon = isCash ? Icons.payments_rounded : Icons.phone_android_rounded;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: icBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(icon, color: icColor, size: 22),
            ),
          ),
          const SizedBox(width: 12),

          // Label & Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.mute,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Clearance for floating swap button
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // --- Chips: ₹100, ₹200, ₹500, ₹1000, Custom ---
  Widget _buildAmountChips() {
    return Row(
      children: [
        ..._presetAmounts.map((amt) {
          final isSelected = !_isCustom && _amount == amt;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _buildChip(
                label: '₹$amt',
                isSelected: isSelected,
                onTap: () => _onPresetSelected(amt),
              ),
            ),
          );
        }),
        Expanded(
          child: _buildChip(
            label: 'Custom',
            isSelected: _isCustom,
            onTap: _onCustomSelected,
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.jade : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.jade : AppColors.line,
            width: 1,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 4. "Waiting near you" Section ---
  Widget _buildWaitingNearYouSection(
    List<ExchangeRequestModel> publicRequests,
    String currentUserId, {
    bool hasActiveRequest = false,
  }) {
    // Filter out user's own requests
    final otherRequests =
        publicRequests.where((r) => r.userId != currentUserId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              'Waiting near you',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RequestsScreen()),
                );
              },
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.jade,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Horizontal Carousel or Clean Empty State
        if (otherRequests.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: otherRequests.take(6).map((req) {
                final isWantsCash = req.wants == 'cash';
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildNearbyCard(
                    amount: req.amount,
                    subtitle:
                        '${isWantsCash ? "Needs cash" : "Needs digital"} • ${req.location}',
                    hasLabel: req.has == 'digital' ? 'Has digital' : 'Has cash',
                    isDigitalTag: req.has == 'digital',
                    onTap: () {
                      // Tapping suggests matching: user gives what the other person wants!
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateRequestScreen(
                            initialHas: req.wants,
                            initialAmount: req.amount,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.explore_outlined,
                    color: AppColors.jade,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'No active requests nearby',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasActiveRequest
                      ? 'Your request is live on campus! We will match or notify you as soon as a peer connects.'
                      : 'Post your request to connect with peers looking to exchange.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.mute,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNearbyCard({
    required int amount,
    required String subtitle,
    required String hasLabel,
    required bool isDigitalTag,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 164,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₹$amount',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.mute,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: isDigitalTag ? AppColors.digitalBg : AppColors.cashBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                hasLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDigitalTag ? AppColors.dig : AppColors.amber,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. "Recent activity" Section ---
  Widget _buildRecentActivitySection(
    List<ConnectionModel> connections,
    String currentUserId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              'Recent activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConnectionsScreen()),
                );
              },
              child: const Text(
                'History',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.jade,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Activity Card Container
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: connections.isNotEmpty
              ? Column(
                  children: connections.take(4).map((conn) {
                    final myGive = conn.myHas(currentUserId);
                    final isDigitalToCash = myGive == 'digital';
                    final isLast = conn == connections.take(4).last;

                    return _buildActivityRow(
                      amount: conn.amount,
                      subtitle: isDigitalToCash ? 'Digital to cash' : 'Cash to digital',
                      isDigitalArrow: isDigitalToCash,
                      status: conn.status,
                      timeStr: DateFormat('d MMM, h:mm a').format(conn.createdAt),
                      showDivider: !isLast,
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
                    );
                  }).toList(),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.jade,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No exchange activity yet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your completed exchanges and active requests will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.mute,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildActivityRow({
    required int amount,
    required String subtitle,
    required bool isDigitalArrow,
    required ConnectionStatus status,
    required String timeStr,
    required bool showDivider,
    required VoidCallback onTap,
  }) {
    String statusLabel;
    Color statusBg;
    Color statusColor;

    switch (status) {
      case ConnectionStatus.completed:
        statusLabel = 'Completed';
        statusBg = AppColors.okBg;
        statusColor = AppColors.jade;
        break;
      case ConnectionStatus.pending:
      case ConnectionStatus.connected:
        statusLabel = status == ConnectionStatus.connected ? 'Connected' : 'Finding match';
        statusBg = AppColors.cashBg;
        statusColor = AppColors.amber;
        break;
      case ConnectionStatus.cancelled:
        statusLabel = 'Cancelled';
        statusBg = AppColors.redBg;
        statusColor = AppColors.red;
        break;
    }

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Direction Arrow Circle
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDigitalArrow ? AppColors.digitalBg : AppColors.cashBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      isDigitalArrow ? '↓' : '↑',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDigitalArrow ? AppColors.dig : AppColors.amber,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Amount & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹$amount',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mute,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge & Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mute,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: AppColors.line),
      ],
    );
  }
}
