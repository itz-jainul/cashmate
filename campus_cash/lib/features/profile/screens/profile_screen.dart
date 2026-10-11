import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/onboarding_screen.dart';
import '../../history/screens/history_screen.dart';
import 'edit_profile_screen.dart';
import 'notification_preferences_screen.dart';
import 'privacy_security_screen.dart';
import 'safety_guidelines_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final authUser = ref.watch(authStateProvider).value;

    final profile = profileAsync.value;
    final name = profile?.name.isNotEmpty == true
        ? profile!.name
        : (authUser?.displayName ?? 'Student');
    final email = profile?.email.isNotEmpty == true
        ? profile!.email
        : (authUser?.email ?? 'user@cashmate.com');
    final completedCount = profile?.completedExchanges ?? 0;
    final rating = profile?.rating ?? 5.0;

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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My profile',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.025,
                            color: AppColors.ink,
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                            },
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
                                Icons.edit_outlined,
                                size: 20,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // User Identity Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.line),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.jade,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.jade,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.02,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.mute,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.okBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 14, color: AppColors.jade),
                                SizedBox(width: 4),
                                Text(
                                  'Student Verified',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.jade,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatTile(
                            title: 'Completed',
                            value: '$completedCount',
                            subtitle: 'Swaps',
                            icon: Icons.sync_alt_rounded,
                            iconBg: AppColors.okBg,
                            iconColor: AppColors.jade,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatTile(
                            title: 'Trust rating',
                            value: rating.toStringAsFixed(1),
                            subtitle: '★ 5.0 base',
                            icon: Icons.star_rounded,
                            iconBg: AppColors.cashBg,
                            iconColor: AppColors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Exchange History Direct Card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(22),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.digitalBg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.history_rounded,
                                    color: AppColors.dig,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Exchange history',
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'View receipts & past peer swaps',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.mute,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textMuted,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Financial Safety Notice Banner (Prompt Section 15 Requirement)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FDFB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.jade.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.okBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              size: 20,
                              color: AppColors.jade,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Financial safety notice',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'CashMate does not transfer, store, or hold money. The exchange happens directly between peers. Never share banking PINs, passwords, or OTPs.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: AppColors.mute,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Menu Options Group
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.edit_note_rounded,
                            title: 'Edit profile',
                            subtitle: 'Update full name and phone number',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: AppColors.line),
                          _buildMenuItem(
                            icon: Icons.notifications_none_rounded,
                            title: 'Notification preferences',
                            subtitle: 'Sound, match alerts & meetup updates',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationPreferencesScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: AppColors.line),
                          _buildMenuItem(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy & security rules',
                            subtitle: 'Read Firestore data protection rules',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrivacySecurityScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: AppColors.line),
                          _buildMenuItem(
                            icon: Icons.shield_outlined,
                            title: 'Campus safety guidelines',
                            subtitle: 'Safe meetup spots & verification tips',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SafetyGuidelinesScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: AppColors.line),
                          _buildMenuItem(
                            icon: Icons.explore_outlined,
                            title: 'How CashMate works',
                            subtitle: 'Guided walkthrough & core principles',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const OnboardingScreen(isFromSettings: true),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sign Out Action
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text(
                                'Sign Out?',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              content: const Text(
                                'Are you sure you want to log out of CashMate?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Sign Out'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            await ref.read(authServiceProvider).signOut();
                          }
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.redBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.red.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: AppColors.red,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Log out of CashMate',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildStatTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mute,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.02,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.field,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.ink, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mute,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

