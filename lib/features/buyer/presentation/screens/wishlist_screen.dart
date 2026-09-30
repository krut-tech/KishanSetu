import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_bar/app_top_bar.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/error_state_widget.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/screens/produce_details_screen.dart';

/// Lists produce a buyer has saved for later.
class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final buyerId = ref.read(authNotifierProvider).profile?.id;
    if (buyerId != null) {
      ref.read(wishlistControllerProvider.notifier).fetch(buyerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wishlistControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final buyerId = ref.read(authNotifierProvider).profile?.id;

    Widget body;
    if (state.isLoading && state.items.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.errorMessage != null && state.items.isEmpty) {
      body = ErrorStateWidget(
        title: 'Unable to load wishlist',
        message: state.errorMessage!,
        onRetry: _load,
      );
    } else if (state.items.isEmpty) {
      body = const EmptyStateWidget(
        icon: Icons.favorite_border_rounded,
        title: 'Your wishlist is empty',
        message: 'Tap the heart icon on any produce listing to save it here.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxxl,
          ),
          itemCount: state.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = state.items[index];
            final produce = item.produce;
            return AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProduceDetailsScreen(produce: produce)),
                ),
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.eco_rounded, color: colorScheme.primary),
                ),
                title: Text(produce.name),
                subtitle: Text(
                  '${produce.quantity} ${produce.unit} • ₹${produce.expectedPrice.toStringAsFixed(0)}/${produce.unit}${produce.location != null ? ' • ${produce.location}' : ''}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                  onPressed: buyerId == null
                      ? null
                      : () async {
                          final ok = await ref
                              .read(wishlistControllerProvider.notifier)
                              .remove(item.id, buyerId);
                          if (!context.mounted) return;
                          if (ok) {
                            AppSnackBar.show(
                              context,
                              message: 'Removed from wishlist',
                              type: SnackBarType.success,
                            );
                          }
                        },
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: const AppTopBar(title: 'My Wishlist'),
      body: body,
    );
  }
}
