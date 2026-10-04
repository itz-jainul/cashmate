import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/exchange_provider.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  final String? initialHas; // 'cash' or 'digital'

  const CreateRequestScreen({super.key, this.initialHas});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  late String _has;
  final _amountController = TextEditingController();
  final _customLocationController = TextEditingController();
  final List<int> _presetAmounts = [100, 200, 500, 1000, 2000];
  int? _selectedPreset;
  String _selectedLocation = 'Campus Cafeteria';
  bool _isCustomLocation = false;
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _presetLocations = [
    {'name': 'Campus Cafeteria', 'icon': Icons.local_cafe_outlined},
    {'name': 'Library Lobby', 'icon': Icons.local_library_outlined},
    {'name': 'Student Center (SAC)', 'icon': Icons.groups_outlined},
    {'name': 'Main Academic Block', 'icon': Icons.school_outlined},
    {'name': 'Campus ATM Counter', 'icon': Icons.local_atm_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _has = widget.initialHas ?? 'cash';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customLocationController.dispose();
    super.dispose();
  }

  String get _wants => _has == 'cash' ? 'digital' : 'cash';

  void _selectPreset(int amount) {
    setState(() {
      _selectedPreset = amount;
      _amountController.text = amount.toString();
    });
  }

  Future<void> _handleSubmit() async {
    final amountText = _amountController.text.trim();
    final amount = int.tryParse(amountText);

    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount greater than 0');
      return;
    }

    if (amount > 10000) {
      setState(() => _errorMessage = 'Maximum allowed exchange amount is ₹10,000');
      return;
    }

    final chosenLocation = _isCustomLocation && _customLocationController.text.trim().isNotEmpty
        ? _customLocationController.text.trim()
        : _selectedLocation;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(authStateProvider).value;
      final profile = ref.read(userProfileProvider).value;

      if (user == null) throw Exception('User not logged in');

      final exchangeService = ref.read(exchangeServiceProvider);
      await exchangeService.createRequest(
        userId: user.uid,
        userName: profile?.name.isNotEmpty == true ? profile!.name : (user.displayName ?? 'Student'),
        has: _has,
        wants: _wants,
        amount: amount,
        location: chosenLocation,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCash = _has == 'cash';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Exchange Request'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. What do you have?',
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
                    child: _buildChoiceCard(
                      title: 'Physical Cash',
                      subtitle: 'You have paper money',
                      icon: Icons.payments_outlined,
                      isSelected: isCash,
                      color: AppColors.cashColor,
                      bgColor: AppColors.cashBg,
                      onTap: () {
                        setState(() => _has = 'cash');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildChoiceCard(
                      title: 'Digital Money',
                      subtitle: 'UPI, Paytm, etc.',
                      icon: Icons.account_balance_wallet_outlined,
                      isSelected: !isCash,
                      color: AppColors.digitalColor,
                      bgColor: AppColors.digitalBg,
                      onTap: () {
                        setState(() => _has = 'digital');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Automatic desire calculation banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Exchange Rule (Auto-Applied)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCash
                                ? 'You give Cash → You receive Digital'
                                : 'You give Digital → You receive Cash',
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
              const SizedBox(height: 28),
              const Text(
                '2. How much would you like to exchange?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              // Quick preset chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetAmounts.map((preset) {
                  final isSelected = _selectedPreset == preset;
                  return ChoiceChip(
                    label: Text(
                      '₹$preset',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (_) => _selectPreset(preset),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _amountController,
                hintText: 'Enter amount in ₹ (e.g. 500)',
                keyboardType: TextInputType.number,
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _selectedPreset = int.tryParse(val);
                  });
                },
              ),
              const SizedBox(height: 28),

              // 3. Meetup Location Selection
              const Text(
                '3. Choose Exchange Place',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select a safe public landmark on campus to meet your partner.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._presetLocations.map((loc) {
                    final isSelected = !_isCustomLocation && _selectedLocation == loc['name'];
                    return FilterChip(
                      avatar: Icon(
                        loc['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      label: Text(
                        loc['name'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (_) {
                        setState(() {
                          _isCustomLocation = false;
                          _selectedLocation = loc['name'] as String;
                        });
                      },
                    );
                  }),
                  FilterChip(
                    avatar: Icon(
                      Icons.edit_location_alt_outlined,
                      size: 16,
                      color: _isCustomLocation ? Colors.white : AppColors.primary,
                    ),
                    label: Text(
                      'Other Location',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isCustomLocation ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    selected: _isCustomLocation,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _isCustomLocation ? AppColors.primary : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (_) {
                      setState(() {
                        _isCustomLocation = true;
                      });
                    },
                  ),
                ],
              ),
              if (_isCustomLocation) ...[
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _customLocationController,
                  hintText: 'e.g. Near Mechanical Workshop or Gate 2',
                  prefixIcon: const Icon(Icons.place_outlined, color: AppColors.primary),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.statusCancelled, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              // Safety notice box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.safetyWarning,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Find Match',
                isLoading: _isLoading,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? bgColor.withValues(alpha: 0.3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
