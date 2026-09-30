import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_bar/app_top_bar.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/error_state_widget.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';

/// Manages a buyer's recurring (subscription-based) produce orders.
class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final buyerId = ref.read(authNotifierProvider).profile?.id;
    if (buyerId != null) {
      ref.read(subscriptionControllerProvider.notifier).fetch(buyerId);
    }
  }

  String _frequencyLabel(String freq) {
    switch (freq) {
      case 'weekly':
        return 'Every week';
      case 'biweekly':
        return 'Every 2 weeks';
      case 'monthly':
        return 'Every month';
      default:
        return freq;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    Widget body;
    if (state.isLoading && state.subscriptions.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.errorMessage != null && state.subscriptions.isEmpty) {
      body = ErrorStateWidget(
        title: 'Unable to load subscriptions',
        message: state.errorMessage!,
        onRetry: _load,
      );
    } else if (state.subscriptions.isEmpty) {
      body = const EmptyStateWidget(
        icon: Icons.autorenew_rounded,
        title: 'No recurring orders yet',
        message: 'Set up weekly supply from a produce listing\'s details page.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
          itemCount: state.subscriptions.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final sub = state.subscriptions[index];
            final isActive = sub.status == 'active';
            final isPaused = sub.status == 'paused';
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          sub.produceName ?? 'Produce',
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isActive ? Colors.green : colorScheme.onSurfaceVariant).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sub.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.green : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${sub.quantity} ${sub.unit ?? ''} • ${_frequencyLabel(sub.frequency)}'),
                  Text(
                    'Next delivery: ${DateFormat('dd MMM yyyy').format(sub.nextDeliveryDate)}',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                  if (sub.farmerName != null)
                    Text(
                      'From: ${sub.farmerName}',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: isPaused ? 'Resume' : 'Pause',
                          style: AppButtonStyle.outlined,
                          icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          onPressed: sub.status == 'cancelled'
                              ? null
                              : () => ref
                                  .read(subscriptionControllerProvider.notifier)
                                  .updateStatus(sub.id, isPaused ? 'active' : 'paused'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton(
                          label: 'Cancel',
                          style: AppButtonStyle.outlined,
                          icon: Icons.cancel_outlined,
                          onPressed: sub.status == 'cancelled'
                              ? null
                              : () => ref
                                  .read(subscriptionControllerProvider.notifier)
                                  .updateStatus(sub.id, 'cancelled'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: const AppTopBar(title: 'My Subscriptions'),
      body: body,
    );
  }
}
