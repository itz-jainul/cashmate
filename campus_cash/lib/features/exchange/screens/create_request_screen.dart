import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/exchange_provider.dart';
import 'searching_match_screen.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  final String? initialHas; // 'cash' or 'digital'
  final int? initialAmount;

  const CreateRequestScreen({super.key, this.initialHas, this.initialAmount});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  late String _have; // 'cash' or 'digital'
  int _amount = 0;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _otherLocationController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _otherFocus = FocusNode();

  static const int _minAmount = 10;
  static const int _maxAmount = 10000;
  static const List<int> _presetAmounts = [100, 200, 500, 1000, 2000];

  String _selectedPlaceKey = 'cafe';
  bool _isLoading = false;
  String? _backendError;

  final List<Map<String, dynamic>> _places = const [
    {
      'key': 'cafe',
      'label': 'Campus Cafeteria',
      'icon': Icons.local_cafe_rounded,
    },
    {
      'key': 'lib',
      'label': 'Library Lobby',
      'icon': Icons.menu_book_rounded,
    },
    {
      'key': 'sac',
      'label': 'Student Center',
      'icon': Icons.groups_rounded,
    },
    {
      'key': 'acad',
      'label': 'Main Academic Block',
      'icon': Icons.school_rounded,
    },
    {
      'key': 'atm',
      'label': 'Campus ATM Counter',
      'icon': Icons.local_atm_rounded,
    },
    {
      'key': 'other',
      'label': 'Other location',
      'icon': Icons.location_on_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _have = widget.initialHas?.toLowerCase() == 'digital' ? 'digital' : 'cash';
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amount = widget.initialAmount!;
      _amountController.text = _amount.toString();
    }

    _amountController.addListener(_onAmountChanged);
    _otherLocationController.addListener(() => setState(() {}));
  }

  void _onAmountChanged() {
    final clean = _amountController.text.replaceAll(RegExp(r'\D'), '');
    final val = int.tryParse(clean) ?? 0;
    if (val != _amount) {
      setState(() => _amount = val);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _otherLocationController.dispose();
    _amountFocus.dispose();
    _otherFocus.dispose();
    super.dispose();
  }

  bool get _isAmountValid => _amount >= _minAmount && _amount <= _maxAmount;

  bool get _isPlaceValid {
    if (_selectedPlaceKey != 'other') return true;
    return _otherLocationController.text.trim().length >= 3;
  }

  bool get _canSubmit => _isAmountValid && _isPlaceValid && !_isLoading;

  String get _resolvedPlaceName {
    if (_selectedPlaceKey == 'other') {
      final custom = _otherLocationController.text.trim();
      return custom.isNotEmpty ? custom : 'your chosen spot';
    }
    final match = _places.firstWhere(
      (p) => p['key'] == _selectedPlaceKey,
      orElse: () => _places.first,
    );
    return match['label'] as String;
  }

  int get _completedStepsCount {
    int count = 1; // Step 1 (have) is always chosen
    if (_isAmountValid) count++;
    if (_isPlaceValid) count++;
    return count;
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;

    setState(() {
      _isLoading = true;
      _backendError = null;
    });

    try {
      final user = ref.read(authStateProvider).value;
      final profile = ref.read(userProfileProvider).value;
      if (user == null) throw Exception('Please log in to post an exchange request.');

      final exchangeService = ref.read(exchangeServiceProvider);
      final myName = profile?.name.isNotEmpty == true
          ? profile!.name
          : (user.displayName ?? 'Student');

      final wants = _have == 'cash' ? 'digital' : 'cash';

      final createdReq = await exchangeService.createRequest(
        userId: user.uid,
        userName: myName,
        has: _have,
        wants: wants,
        amount: _amount,
        location: _resolvedPlaceName,
      );

      if (mounted) {
        // Navigate to the live searching screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SearchingMatchScreen(initialRequest: createdReq),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _backendError = AppStrings.cleanError(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCash = _have == 'cash';
    final currencyFormatter = NumberFormat('#,##,###', 'en_IN');
    final formattedAmount = currencyFormatter.format(_amount);
    final stepsDone = _completedStepsCount;

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
              child: Stack(
                children: [
                  // Main Scrollable Body
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 170),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header: Circular Back button + Title
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: const Center(
                                  child: Icon(
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
                                'New exchange request',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Progress Indicator: 3 segments
                        Row(
                          children: [
                            _buildProgressSegment(isActive: true),
                            const SizedBox(width: 5),
                            _buildProgressSegment(isActive: _isAmountValid),
                            const SizedBox(width: 5),
                            _buildProgressSegment(isActive: _isPlaceValid),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$stepsDone of 3 steps done',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mute,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // Backend Error Banner
                        if (_backendError != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.redBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.red, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _backendError!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ==========================================
                        // STEP 1: What do you have?
                        // ==========================================
                        const SizedBox(height: 24),
                        _buildStepHeader(stepNumber: 1, isDone: true, title: 'What do you have?'),
                        const SizedBox(height: 12),

                        // Two Choice Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildHaveCard(
                                title: 'Physical cash',
                                subtitle: 'Paper money in hand',
                                isSelected: isCash,
                                icon: Icons.payments_rounded,
                                iconColor: AppColors.amber,
                                iconBg: AppColors.cashBg,
                                onTap: () => setState(() => _have = 'cash'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildHaveCard(
                                title: 'Digital money',
                                subtitle: 'UPI, Paytm, etc.',
                                isSelected: !isCash,
                                icon: Icons.phone_android_rounded,
                                iconColor: AppColors.dig,
                                iconBg: AppColors.digitalBg,
                                onTap: () => setState(() => _have = 'digital'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Exchange Rule Banner
                        _buildExchangeRuleBanner(isCash),

                        // ==========================================
                        // STEP 2: How much?
                        // ==========================================
                        const SizedBox(height: 24),
                        _buildStepHeader(
                          stepNumber: 2,
                          isDone: _isAmountValid,
                          title: 'How much?',
                        ),
                        const SizedBox(height: 12),

                        // Preset Chips: [₹100, ₹200, ₹500, ₹1000, ₹2000]
                        Row(
                          children: _presetAmounts.map((preset) {
                            final isSelected = _amount == preset;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: preset != _presetAmounts.last ? 6 : 0,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _amount = preset;
                                      _amountController.text = preset.toString();
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.jade : AppColors.card,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: isSelected ? AppColors.jade : AppColors.line,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '₹$preset',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white : AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),

                        // Amount Input Field
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (_amountController.text.isNotEmpty && !_isAmountValid)
                                  ? const Color(0xFFD6334A)
                                  : (_amountFocus.hasFocus ? AppColors.jade : AppColors.line),
                              width: 1.5,
                            ),
                            boxShadow: _amountFocus.hasFocus
                                ? [
                                    BoxShadow(
                                      color: AppColors.jade.withValues(alpha: 0.18),
                                      blurRadius: 4,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              const Text(
                                '₹',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.mute,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  focusNode: _amountFocus,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(5),
                                  ],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Or enter any amount',
                                    hintStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.mute,
                                    ),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Error text if invalid
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 2),
                          child: SizedBox(
                            height: 18,
                            child: (_amountController.text.isNotEmpty && !_isAmountValid)
                                ? const Text(
                                    'Enter an amount from ₹10 to ₹10,000.',
                                    style: TextStyle(
                                      color: Color(0xFFD6334A),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                : null,
                          ),
                        ),

                        // ==========================================
                        // STEP 3: Where will you meet?
                        // ==========================================
                        const SizedBox(height: 14),
                        _buildStepHeader(
                          stepNumber: 3,
                          isDone: _isPlaceValid,
                          title: 'Where will you meet?',
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Pick a safe, busy spot on campus.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.mute,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 2-column places grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3.2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _places.length,
                          itemBuilder: (context, index) {
                            final place = _places[index];
                            final key = place['key'] as String;
                            final isSelected = _selectedPlaceKey == key;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedPlaceKey = key;
                                });
                                if (key == 'other') {
                                  _otherFocus.requestFocus();
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.jade : AppColors.card,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? AppColors.jade : AppColors.line,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      place['icon'] as IconData,
                                      size: 19,
                                      color: isSelected ? Colors.white : AppColors.jade,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        place['label'] as String,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? Colors.white : AppColors.ink,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // "Other location" text input field
                        if (_selectedPlaceKey == 'other') ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _otherFocus.hasFocus ? AppColors.jade : AppColors.line,
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: _otherLocationController,
                              focusNode: _otherFocus,
                              maxLength: 60,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                hintText: 'Describe the meeting spot',
                                hintStyle: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.mute,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 13),
                              ),
                            ),
                          ),
                        ],

                        // ==========================================
                        // Safety Banner
                        // ==========================================
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 22,
                                color: AppColors.jade,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'CashMate never holds or moves your money. You swap directly with your match. Never share your UPI PIN, passwords or OTPs.',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.mute,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==========================================
                  // Sticky Bottom Floating Bar
                  // ==========================================
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10201B).withValues(alpha: 0.14),
                            blurRadius: 26,
                            offset: const Offset(0, -8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Summary text
                          Text.rich(
                            _isAmountValid
                                ? TextSpan(
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: AppColors.mute,
                                      height: 1.3,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Give '),
                                      TextSpan(
                                        text: '₹$formattedAmount ${isCash ? "cash" : "digital"}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const TextSpan(text: ', get '),
                                      TextSpan(
                                        text: '₹$formattedAmount ${isCash ? "digital" : "cash"}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const TextSpan(text: ' at '),
                                      TextSpan(
                                        text: _resolvedPlaceName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ],
                                  )
                                : const TextSpan(
                                    text: 'Choose an amount to continue',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: AppColors.mute,
                                    ),
                                  ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),

                          // Primary Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _canSubmit ? _handleSubmit : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.jade,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.jade.withValues(alpha: 0.45),
                                disabledForegroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Looking for a match…',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      _isAmountValid
                                          ? 'Find match for ₹$formattedAmount'
                                          : 'Find match',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
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

  // --- Step Indicator Header ---
  Widget _buildStepHeader({
    required int stepNumber,
    required bool isDone,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isDone ? AppColors.jade : AppColors.ink,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              isDone ? '✓' : '$stepNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // --- Progress Segment ---
  Widget _buildProgressSegment({required bool isActive}) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 5,
        decoration: BoxDecoration(
          color: isActive ? AppColors.jade : const Color(0xFF10201B).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  // --- Step 1 Option Card ---
  Widget _buildHaveCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.jade : AppColors.line,
            width: isSelected ? 2.0 : 1.5,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mute,
                  ),
                ),
              ],
            ),
            // Top Right Checkmark Tick
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.jade,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Exchange Rule Flow Banner ---
  Widget _buildExchangeRuleBanner(bool isCash) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exchange rule, applied automatically',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.mute,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // You give pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: isCash ? AppColors.cashBg : AppColors.digitalBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You give',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: (isCash ? AppColors.amber : AppColors.dig).withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        isCash ? 'Cash' : 'Digital',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCash ? AppColors.amber : AppColors.dig,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Arrow Circle
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.jade,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // You get pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: isCash ? AppColors.digitalBg : AppColors.cashBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You get',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: (isCash ? AppColors.dig : AppColors.amber).withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        isCash ? 'Digital' : 'Cash',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCash ? AppColors.dig : AppColors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
