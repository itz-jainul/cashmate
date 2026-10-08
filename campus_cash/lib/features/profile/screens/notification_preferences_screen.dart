import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  late Map<String, bool> _preferences;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final user = ref.read(userProfileProvider).value;
      _preferences = Map<String, bool>.from(
        user?.notificationPreferences ??
            const {
              'matchAlerts': true,
              'chatAlerts': true,
              'statusAlerts': true,
              'soundAlerts': true,
            },
      );
      _isInitialized = true;
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    setState(() {
      _preferences[key] = value;
    });

    final authUser = ref.read(authStateProvider).value;
    if (authUser == null) return;

    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateNotificationPreferences(
        authUser.uid,
        _preferences,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 1500),
            backgroundColor: AppColors.primary,
            content: Text('Preferences saved ✓'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            const Text(
              'Exchange Alerts',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'New Match Found',
                    subtitle: 'Notify immediately when an exact peer match is made.',
                    icon: Icons.bolt_rounded,
                    value: _preferences['matchAlerts'] ?? true,
                    onChanged: (val) => _updatePreference('matchAlerts', val),
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: 'Meetup Chat Messages',
                    subtitle: 'Alerts when your matched peer sends a chat message.',
                    icon: Icons.chat_bubble_outline_rounded,
                    value: _preferences['chatAlerts'] ?? true,
                    onChanged: (val) => _updatePreference('chatAlerts', val),
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: 'Status & Confirmations',
                    subtitle: 'Updates when peer accepts meetup or confirms completion.',
                    icon: Icons.verified_outlined,
                    value: _preferences['statusAlerts'] ?? true,
                    onChanged: (val) => _updatePreference('statusAlerts', val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Device Feedback',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: _buildSwitchTile(
                title: 'In-App Sound & Haptics',
                subtitle: 'Play subtle vibrations and tones on important updates.',
                icon: Icons.volume_up_outlined,
                value: _preferences['soundAlerts'] ?? true,
                onChanged: (val) => _updatePreference('soundAlerts', val),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 20, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Push notifications keep you informed during active exchanges without draining battery.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
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
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? AppColors.primaryContainer
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value ? AppColors.primary : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 14),
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
