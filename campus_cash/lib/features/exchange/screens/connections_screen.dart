import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/connection_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/exchange_provider.dart';
import 'connection_details_screen.dart';
import 'create_request_screen.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(userConnectionsProvider);
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Connections'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(userConnectionsProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: SafeArea(
        child: connectionsAsync.when(
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
                    'Loading connections...',
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
                    'Error loading connections: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(userConnectionsProvider),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (connections) {
            final active = connections
                .where((c) =>
                    c.status == ConnectionStatus.pending ||
                    c.status == ConnectionStatus.connected)
                .toList();

            final completed = connections
                .where((c) => c.status == ConnectionStatus.completed)
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildList(active, currentUserId, 'No Active Connections',
                    'You have no ongoing peer exchanges. Post a request to match!'),
                _buildList(completed, currentUserId, 'No Completed Exchanges',
                    'Completed peer exchanges will appear here.'),
                _buildList(connections, currentUserId, 'No Connections Yet',
                    'Create an exchange request to find your match.'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<ConnectionModel> list, String currentUserId,
      String emptyTitle, String emptyDesc) {
    if (list.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.handshake_outlined,
        title: emptyTitle,
        description: emptyDesc,
        buttonText: 'Create Request',
        onButtonPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final conn = list[i];
        final partnerName = conn.partnerName(currentUserId);
        final myGive = conn.myHas(currentUserId);
        final myReceive = conn.myWants(currentUserId);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primaryContainer,
                          child: const Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              partnerName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '₹${conn.amount}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildStatusPill(conn.status),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Give: ${myGive.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Icon(Icons.swap_horiz_rounded,
                          size: 16, color: AppColors.textMuted),
                      Text(
                        'Receive: ${myReceive.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cashColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
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
                    child: const Text('View Connection',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(ConnectionStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case ConnectionStatus.pending:
        bg = AppColors.statusSearchingBg;
        fg = AppColors.statusSearching;
        label = 'Pending';
        break;
      case ConnectionStatus.connected:
        bg = AppColors.primaryContainer;
        fg = AppColors.primary;
        label = 'Connected ✓';
        break;
      case ConnectionStatus.completed:
        bg = AppColors.statusCompletedBg;
        fg = AppColors.statusCompleted;
        label = 'Completed ✓';
        break;
      case ConnectionStatus.cancelled:
        bg = AppColors.statusCancelledBg;
        fg = AppColors.statusCancelled;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
