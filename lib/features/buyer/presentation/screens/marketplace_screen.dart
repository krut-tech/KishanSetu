import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/cards/produce_card.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/error_state_widget.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_search_field.dart';
import 'package:farmer_market_app/core/widgets/states/shimmer_loading.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/marketplace_controller.dart';
import 'package:farmer_market_app/features/buyer/presentation/screens/produce_details_screen.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';

/// Full Marketplace Screen for Buyers to browse, search, filter, and sort active farmer produce.
class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<OfferModel> _statusOffers = const [];
  String _selectedOfferStatus = 'accepted';
  RealtimeChannel? _acceptedOffersChannel;
  String? _acceptedBuyerId;

  /// Display label for a category chip. The English [cat] string stays the
  /// value sent to the marketplace filter; only the label is localized.
  String _categoryLabel(String cat) {
    switch (cat) {
      case 'All':
        return context.l10n.allLabel;
      case 'Grains':
        return context.l10n.grainsCategory;
      case 'Vegetables':
        return context.l10n.vegetablesCategory;
      case 'Fruits':
        return context.l10n.fruitsCategory;
      case 'Pulses':
        return context.l10n.pulsesCategory;
      case 'Spices':
        return context.l10n.spicesCategory;
      case 'Oilseeds':
        return context.l10n.oilseedsCategory;
      case 'Commercial Crops':
        return context.l10n.commercialCropsCategory;
      default:
        return cat;
    }
  }

  static const List<String> _categories = [
    'All',
    'Grains',
    'Vegetables',
    'Fruits',
    'Pulses',
    'Spices',
    'Oilseeds',
    'Commercial Crops',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(marketplaceControllerProvider).produceList.isEmpty) {
        ref.read(marketplaceControllerProvider.notifier).fetchProduce();
      }
      final buyer = ref.read(authNotifierProvider).state.user;
      if (buyer != null) _watchBuyerOffers(buyer.id);
    });
  }

  @override
  void dispose() {
    _acceptedOffersChannel?.unsubscribe();
    _searchController.dispose();
    super.dispose();
  }

  void _watchBuyerOffers(String buyerId) {
    _acceptedBuyerId = buyerId;
    _acceptedOffersChannel?.unsubscribe();
    _acceptedOffersChannel = ref
        .read(buyerRepositoryProvider)
        .subscribeToBuyerOffers(buyerId, (_) {
      final currentBuyerId = _acceptedBuyerId;
      if (mounted && currentBuyerId != null) {
        _fetchStatusOffers(currentBuyerId);
      }
    });
    _fetchAcceptedOffers(buyerId);
  }

  Future<void> _fetchStatusOffers(String buyerId) async {
    final result = await ref
        .read(buyerRepositoryProvider)
        .getBuyerOffers(buyerId, status: _selectedOfferStatus);
    if (!mounted) return;
    result.fold(
      (_) {},
      (offers) => setState(() => _statusOffers = offers),
    );
  }

  void _onSearchChanged(String query) {
    ref.read(marketplaceControllerProvider.notifier).fetchProduce(query: query);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      bottom: true,
      child: Column(
        children: [
          // Search & Filter Header Section
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: colorScheme.surface,
            child: Column(
              children: [
                // Search Field
                AppSearchField(
                  hint: context.l10n.searchCropCategoryLocation,
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // Category Filters Scrollable Chips
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = state.selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: FilterChip(
                          label: Text(
                            _categoryLabel(cat),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: colorScheme.primary,
                          backgroundColor: colorScheme.surface,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(marketplaceControllerProvider.notifier)
                                  .fetchProduce(category: cat);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // Sort Dropdown Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${state.produceList.length} ${context.l10n.availableProduce}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.sort_rounded,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        DropdownButton<String>(
                          value: state.sortBy,
                          underline: const SizedBox(),
                          dropdownColor: colorScheme.surface,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                          items: [
                            DropdownMenuItem(
                                value: 'newest',
                                child: Text(context.l10n.sortNewest)),
                            DropdownMenuItem(
                                value: 'price_asc',
                                child: Text(context.l10n.priceLowToHighArrow)),
                            DropdownMenuItem(
                                value: 'price_desc',
                                child: Text(context.l10n.priceHighToLowArrow)),
                            DropdownMenuItem(
                                value: 'quantity_desc',
                                child: Text(context.l10n.quantityHighToLow)),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref
                                  .read(marketplaceControllerProvider.notifier)
                                  .fetchProduce(sortBy: val);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content List with RefreshIndicator
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(marketplaceControllerProvider.notifier)
                    .fetchProduce();
              },
              child: _buildBody(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferStatusFilters() {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: AppSpacing.sm,
        children: [
          for (final status in const ['accepted', 'rejected'])
            FilterChip(
              label: Text(status == 'accepted' ? 'Accepted' : 'Rejected'),
              avatar: Icon(
                status == 'accepted' ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 18,
              ),
              selected: _selectedOfferStatus == status,
              onSelected: (selected) {
                if (!selected || _selectedOfferStatus == status) return;
                final buyerId = _acceptedBuyerId;
                if (buyerId == null) return;
                setState(() {
                  _selectedOfferStatus = status;
                  _statusOffers = const [];
                });
                _fetchStatusOffers(buyerId);
              },
              selectedColor: colorScheme.primaryContainer,
            ),
        ],
      ),
    );
  }

  Widget _buildAcceptedOffersSection() {
    if (_statusOffers.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final formatter = DateFormat('dd MMM yyyy, hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _selectedOfferStatus == 'accepted' ? 'Accepted Offers' : 'Rejected Offers',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        ..._statusOffers.map((offer) {
          final unit = offer.produceUnit ?? 'units';
          final createdText = offer.createdAt == null
              ? '—'
              : formatter.format(offer.createdAt!.toLocal());
          final acceptedText = offer.updatedAt == null
              ? '—'
              : formatter.format(offer.updatedAt!.toLocal());

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.produceName ?? context.l10n.produceListingLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Chip(
                          avatar: Icon(
                            _selectedOfferStatus == 'accepted'
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 16,
                          ),
                          label: Text(_selectedOfferStatus == 'accepted' ? 'Accepted' : 'Rejected'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${context.l10n.farmerLabel}: ${offer.farmerName ?? context.l10n.farmerLabel}'),
                    Text('Agreed price: ₹${offer.offeredPrice.toStringAsFixed(2)} / $unit'),
                    Text('Accepted quantity: ${offer.quantity} $unit'),
                    const Divider(height: AppSpacing.lg),
                    Text('Offer created: $createdText'),
                    Text('Offer accepted: $acceptedText'),
                    if (offer.message != null && offer.message!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'Message: ${offer.message}',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBody(MarketplaceState state) {
    final children = <Widget>[];

    if (_acceptedBuyerId != null) {
      children.add(_buildOfferStatusFilters());
      children.add(const SizedBox(height: AppSpacing.md));
    }
    if (_statusOffers.isNotEmpty) {
      children.add(_buildAcceptedOffersSection());
      children.add(const SizedBox(height: AppSpacing.md));
    }

    if (state.isLoading) {
      children.addAll(List<Widget>.generate(
        4,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: ShimmerLoading(width: double.infinity, height: 160),
        ),
      ));
    } else if (state.errorMessage != null && state.produceList.isEmpty) {
      children.add(Container(
        constraints: const BoxConstraints(minHeight: 300),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ErrorStateWidget(
          title: context.l10n.failedToLoadMarketplace,
          message: state.errorMessage!,
          onRetry: () => ref.read(marketplaceControllerProvider.notifier).fetchProduce(),
        ),
      ));
    } else if (state.produceList.isEmpty) {
      children.add(Container(
        constraints: const BoxConstraints(minHeight: 300),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: EmptyStateWidget(
          title: context.l10n.noProduceAvailableTitle,
          message: context.l10n.noFarmerProduceMatches,
          actionLabel: context.l10n.resetFilters,
          onAction: () {
            _searchController.clear();
            ref.read(marketplaceControllerProvider.notifier).resetFilters();
          },
        ),
      ));
    } else {
      if (_statusOffers.isNotEmpty) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Available Produce',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ));
      }

      for (final produce in state.produceList) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ProduceCard(
            cropName: produce.name,
            grade: produce.category,
            quantity: '${produce.quantity} ${produce.unit}',
            askingPrice: produce.expectedPrice,
            netRealizationPrice: produce.expectedPrice * 0.95,
            location: produce.location ?? produce.farmerDistrict ?? 'Gujarat',
            farmerName: produce.farmerName ?? context.l10n.farmerLabel,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProduceDetailsScreen(produce: produce),
                ),
              );
            },
          ),
        ));
      }
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxxl + 24,
      ),
      children: children,
    );
  }

}
