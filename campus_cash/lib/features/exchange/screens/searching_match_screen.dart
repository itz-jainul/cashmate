import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../models/exchange_request_model.dart';
import '../providers/exchange_provider.dart';
import 'connection_details_screen.dart';
import 'match_details_screen.dart';

class SearchingMatchScreen extends ConsumerStatefulWidget {
  final ExchangeRequestModel initialRequest;

  const SearchingMatchScreen({super.key, required this.initialRequest});

  @override
  ConsumerState<SearchingMatchScreen> createState() => _SearchingMatchScreenState();
}

class _SearchingMatchScreenState extends ConsumerState<SearchingMatchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel looking for a match?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Searching'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusCancelled),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isCancelling = true);
      try {
        final service = ref.read(exchangeServiceProvider);
        await service.cancelRequest(widget.initialRequest.id);
        if (mounted) Navigator.pop(context);
      } finally {
        if (mounted) setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to real-time updates for this request
    final activeRequestAsync = ref.watch(activeRequestProvider);

    activeRequestAsync.whenData((req) {
      if (req != null && req.status == ExchangeStatus.matched) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (req.connectionId != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ConnectionDetailsScreen(connectionId: req.connectionId!),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MatchDetailsScreen(request: req),
                ),
              );
            }
          }
        });
      }
    });

    final req = activeRequestAsync.value ?? widget.initialRequest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Looking for a Match'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: const Icon(
                      Icons.radar_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                '₹${req.amount}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${req.has.toUpperCase()} → ${req.wants.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'We are searching for a campus peer who has the reciprocal requirement for the exact same amount.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              CustomButton(
                text: 'Cancel Request',
                isOutlined: true,
                isLoading: _isCancelling,
                textColor: AppColors.statusCancelled,
                backgroundColor: AppColors.statusCancelled.withValues(alpha: 0.3),
                onPressed: _handleCancel,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
