import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SafetyGuidelinesScreen extends StatelessWidget {
  const SafetyGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CashMate Safety Guidelines'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // Warning Callout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 28, color: Color(0xFFB45309)),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important Safety Reminder',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'The physical exchange of cash and digital funds occurs directly between peers. Follow these guidelines for every meetup.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF92400E),
                            height: 1.35,
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
              'Best Practices for Campus Exchanges',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            _buildGuidelineStep(
              stepNumber: '1',
              title: 'Meet at Recognized Public Campus Spots',
              description:
                  'Always choose populated landmarks such as the Campus Cafeteria, Library Entrance, Student Activity Center, or Academic Block. Avoid secluded locations.',
              icon: Icons.location_on_outlined,
              color: AppColors.primary,
            ),
            _buildGuidelineStep(
              stepNumber: '2',
              title: 'Verify UPI Inside Your Bank/UPI App',
              description:
                  'If you are receiving digital money, open your GPay, PhonePe, or Paytm app directly and check your bank balance. Do not rely solely on screenshot proofs or SMS notifications.',
              icon: Icons.phone_android_rounded,
              color: AppColors.secondary,
            ),
            _buildGuidelineStep(
              stepNumber: '3',
              title: 'Count Physical Cash on the Spot',
              description:
                  'If you are receiving cash, count each note and inspect for genuine currency in the presence of your counterpart before tapping Confirm.',
              icon: Icons.payments_outlined,
              color: AppColors.cashColor,
            ),
            _buildGuidelineStep(
              stepNumber: '4',
              title: 'UPI PIN is NEVER Required to Receive Money',
              description:
                  'Remember: entering your UPI PIN always debits money from your account. If anyone asks you to enter your PIN to receive funds, cancel immediately.',
              icon: Icons.lock_outline_rounded,
              color: AppColors.statusCancelled,
            ),
            _buildGuidelineStep(
              stepNumber: '5',
              title: 'Cancel If Something Feels Wrong',
              description:
                  'You have the full right to cancel the connection at any moment before confirmation if the peer does not arrive at the agreed spot or behaves suspiciously.',
              icon: Icons.cancel_outlined,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineStep({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
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
