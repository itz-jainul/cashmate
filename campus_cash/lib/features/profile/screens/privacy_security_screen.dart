import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security Rules'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // Hero Security Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zero-Credential Platform',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'CashMate does not store, process, or transmit money, keeping your banking info 100% private.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Core Privacy Principles',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            _buildRuleCard(
              icon: Icons.key_off_rounded,
              title: 'Never Share Sensitive Credentials',
              description:
                  'CashMate will NEVER ask for your UPI PIN, ATM PIN, bank passwords, CVVs, or OTPs. UPI PIN is only entered to send money, never to receive.',
              color: AppColors.statusCancelled,
            ),
            _buildRuleCard(
              icon: Icons.lock_clock_rounded,
              title: '30-Minute Automatic Expiry',
              description:
                  'All unmatched public requests expire automatically after 30 minutes to prevent stale posts and protect your real-time campus presence.',
              color: AppColors.statusSearching,
            ),
            _buildRuleCard(
              icon: Icons.handshake_rounded,
              title: 'Dual-Party Handshake Verification',
              description:
                  'An exchange only finishes when both peers tap "Confirm Receipt". Neither party can unilaterally finalize without the other.',
              color: AppColors.primary,
            ),
            _buildRuleCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Pseudonymous Matchmaking',
              description:
                  'Only your first name and general spot are visible publicly. Contact details are never broadcasted to open feeds.',
              color: AppColors.cashColor,
            ),
            _buildRuleCard(
              icon: Icons.security_update_good_rounded,
              title: 'Role-Based Firestore Security',
              description:
                  'Data access is locked down by strict security rules. Only participants in a match can read meetup chats and exchange statuses.',
              color: AppColors.secondary,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
