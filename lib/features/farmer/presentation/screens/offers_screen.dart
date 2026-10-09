import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/badges/app_status_badge.dart';
import 'package:farmer_market_app/core/widgets/cards/offer_card.dart';
import 'package:farmer_market_app/core/widgets/chips/app_chip.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/error_state_widget.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/core/widgets/states/shimmer_loading.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_providers.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/offer_controller.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';

class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({super.key});

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> {
  String _selectedStatus = 'All';

  static const List<String> _statusFilters = [
    'All',
    'pending',
    'accepted',
    'rejected',
    'countered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(offerControllerProvider).offers.isEmpty) {
        _fetchOffers();
      }
    });
  }

  void _fetchOffers() {
    final user = ref.read(authNotifierProvider).profile;
    if (user != null) {
      ref.read(offerControllerProvider.notifier).fetchOffers(
            user.id,
            status: _selectedStatus == 'All' ? null : _selectedStatus,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(offerControllerProvider);

    return SafeArea(
      top: false,
      bottom: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((status) {
                  final isSelected = _selectedStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: AppChip(
                      label: status.toUpperCase(),
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selectedStatus = status);
                        _fetchOffers();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _fetchOffers(),
              child: _buildContent(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(OfferState state) {
    if (state.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxxl + 24,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: ShimmerLoading(width: double.infinity, height: 140),
        ),
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
            title: context.l10n.failedToLoadOffers,
            message: state.errorMessage!,
            onRetry: _fetchOffers,
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
            title: context.l10n.noOffersYet,
            message: context.l10n.noOffersMatchFilterFarmer,
            icon: Icons.local_offer_outlined,
            actionLabel: context.l10n.refreshOffers,
            onAction: _fetchOffers,
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxxl + 24,
      ),
      itemCount: state.offers.length,
      itemBuilder: (context, index) {
        final offer = state.offers[index];

        final statusBadgeType = switch (offer.status.toLowerCase()) {
          'pending' => AppStatusType.pending,
          'accepted' => AppStatusType.accepted,
          'rejected' => AppStatusType.rejected,
          'cancelled' => AppStatusType.expired,
          'in_transit' => AppStatusType.inTransit,
          'completed' => AppStatusType.completed,
          _ => AppStatusType.pending,
        };

        final formattedTime = offer.createdAt != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(offer.createdAt!)
            : context.l10n.recentLabel;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: OfferCard(
            cropName: offer.produceName ?? context.l10n.cropProduceListing,
            buyerName: offer.buyerName ?? offer.buyerCompany ?? context.l10n.interestedBuyer,
            offerPrice: offer.offeredPrice,
            quantity: '${offer.quantity} ${offer.produceUnit ?? "units"}',
            status: statusBadgeType,
            expiresText: formattedTime,
            message: offer.message,
            history: offer.history,
            onAccept: () async {
              final ok = await ref
                  .read(offerControllerProvider.notifier)
                  .respondToOffer(offer.id, 'accepted');
              if (ok) {
                ref.read(farmerDashboardNotifierProvider.notifier).refreshDashboard();
                if (context.mounted) {
                  AppSnackBar.show(context, message: context.l10n.offerAcceptedStatus, type: SnackBarType.success);
                }
              }
            },
            onReject: () async {
              final ok = await ref
                  .read(offerControllerProvider.notifier)
                  .respondToOffer(offer.id, 'rejected');
              if (ok) {
                ref.read(farmerDashboardNotifierProvider.notifier).refreshDashboard();
                if (context.mounted) {
                  AppSnackBar.show(context, message: context.l10n.offerRejectedStatus, type: SnackBarType.info);
                }
              }
            },
            onCancel: () async {
              final ok = await ref
                  .read(offerControllerProvider.notifier)
                  .respondToOffer(offer.id, 'cancelled');
              if (ok) {
                ref.read(farmerDashboardNotifierProvider.notifier).refreshDashboard();
                if (context.mounted) {
                  AppSnackBar.show(context, message: 'Offer Cancelled', type: SnackBarType.info);
                }
              }
            },
            onCounter: () async {
              AppSnackBar.show(context, message: context.l10n.counterOfferComingSoon, type: SnackBarType.info);
            },
          ),
        );
      },
    );
  }
}
