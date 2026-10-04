import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/exchange_request_model.dart';
import '../providers/exchange_provider.dart';
import 'create_request_screen.dart';
import 'match_details_screen.dart';
import 'searching_match_screen.dart';

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRequestAsync = ref.watch(activeRequestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Requests'),
      ),
      body: SafeArea(
        child: activeRequestAsync.when(
          data: (req) {
            if (req == null) {
              return EmptyStateWidget(
                icon: Icons.inbox_outlined,
                title: 'No Active Requests',
                description: 'You have no exchange requests in progress. Create a request to match with peers.',
                buttonText: 'Create Request',
                onButtonPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
                  );
                },
              );
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ongoing Exchange',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${req.amount}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              StatusBadge(status: req.status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Exchange: ${req.has.toUpperCase()} → ${req.wants.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Created: ${req.createdAt.hour}:${req.createdAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            text: req.status == ExchangeStatus.searching
                                ? 'View Live Search'
                                : 'Manage Exchange Handshake',
                            onPressed: () {
                              if (req.status == ExchangeStatus.searching) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SearchingMatchScreen(initialRequest: req),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MatchDetailsScreen(request: req),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
