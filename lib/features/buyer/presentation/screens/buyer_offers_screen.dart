import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/badges/app_status_badge.dart';
import 'package:farmer_market_app/core/widgets/cards/offer_card.dart';
import 'package:farmer_market_app/core/widgets/dialogs/app_dialogs.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/error_state_widget.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/core/widgets/states/shimmer_loading.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_offer_controller.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/screens/make_offer_dialog.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';

/// Screen displaying submitted offers created by the authenticated buyer.
class BuyerOffersScreen extends ConsumerStatefulWidget {
  const BuyerOffersScreen({super.key});

  @override
  ConsumerState<BuyerOffersScreen> createState() => _BuyerOffersScreenState();
}

class _BuyerOffersScreenState extends ConsumerState<BuyerOffersScreen> {
  static const List<String> _statuses = [
    'All',
    'Pending',
    'Accepted',
    'Rejected',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(buyerOfferControllerProvider).offers.isEmpty) {
        _fetchOffers();
      }
    });
  }

  void _fetchOffers({String? status}) {
    final user = ref.read(authNotifierProvider).state.user;
    if (user != null) {
      ref.read(buyerOfferControllerProvider.notifier).fetchOffers(
            user.id,
            status: status,
          );
    }
  }

  AppStatusType _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppStatusType.accepted;
      case 'rejected':
        return AppStatusType.rejected;
      case 'cancelled':
        return AppStatusType.expired;
      case 'pending':
      default:
        return AppStatusType.pending;
    }
  }

  Future<void> _handleCancelOffer(OfferModel offer) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Cancel Offer',
      message: 'Are you sure you want to cancel this pending offer of ₹${offer.offeredPrice.toStringAsFixed(0)}?',
      confirmLabel: 'Yes, Cancel',
      cancelLabel: 'Keep Offer',
      isDestructive: true,
    );

    if (confirmed == true) {
      final user = ref.read(authNotifierProvider).state.user;
      if (user == null) return;

      final success = await ref
          .read(buyerOfferControllerProvider.notifier)
          .cancelOffer(offer.id, user.id);

      if (mounted) {
        if (success) {
          ref.read(buyerDashboardNotifierProvider.notifier).refreshDashboard();
          AppSnackBar.show(context, message: 'Offer cancelled successfully', type: SnackBarType.success);
        } else {
          final error = ref.read(buyerOfferControllerProvider).errorMessage ?? 'Failed to cancel offer';
          AppSnackBar.show(context, message: error, type: SnackBarType.error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(buyerOfferControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      bottom: true,
      child: Column(
        children: [
          // Status Filter Chips
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses.map((status) {
                  final isSelected = state.selectedStatus.toLowerCase() == status.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: FilterChip(
                      label: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.surface,
                      onSelected: (selected) {
                        if (selected) {
                          _fetchOffers(status: status);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Offers List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _fetchOffers(),
              child: _buildBody(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuyerOfferState state) {
    if (state.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxxl + 24,
        ),
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => const ShimmerLoading(width: double.infinity, height: 140),
      );
    }

    if (state.errorMessage != null && state.offers.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: const BoxConstraints(minHeight: 350),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ErrorStateWidget(
            title: 'Failed to load offers',
            message: state.errorMessage!,
            onRetry: () => _fetchOffers(),
          ),
        ),
      );
    }

    if (state.offers.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: const BoxConstraints(minHeight: 350),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: EmptyStateWidget(
            title: 'No offers found',
            message: 'You have not created any offers matching this filter.',
            actionLabel: 'Refresh Offers',
            onAction: () => _fetchOffers(),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxxl + 24,
      ),
      itemCount: state.offers.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final offer = state.offers[index];
        final isPending = offer.status.toLowerCase() == 'pending';
        final farmerIdDisplay = offer.farmerId.length > 6 ? offer.farmerId.substring(0, 6) : offer.farmerId;

        final statusType = _mapStatus(offer.status);

        return OfferCard(
          cropName: offer.produceName ?? 'Produce Listing',
          buyerName: offer.farmerName != null ? 'Farmer: ${offer.farmerName}' : 'Farmer ID: $farmerIdDisplay',
          offerPrice: offer.offeredPrice,
          quantity: '${offer.quantity} ${offer.produceUnit ?? "Units"}',
          status: statusType,
          expiresText: 'Status: ${offer.status.toUpperCase()}',
          message: offer.message,
          history: offer.history,
          onCancel: isPending ? () => _handleCancelOffer(offer) : null,
          onEdit: isPending
              ? () async {
                  final produce = ProduceModel(
                    id: offer.produceId,
                    farmerId: offer.farmerId,
                    name: offer.produceName ?? 'Produce Listing',
                    category: offer.produceCategory ?? 'General',
                    quantity: offer.quantity,
                    unit: offer.produceUnit ?? 'units',
                    expectedPrice: offer.produceExpectedPrice ?? offer.offeredPrice,
                  );
                  final updated = await MakeOfferDialog.show(
                    context,
                    produce,
                    existingOffer: offer,
                  );
                  if (updated == true) {
                    _fetchOffers();
                  }
                }
              : null,
        );
      },
    );
  }
}
