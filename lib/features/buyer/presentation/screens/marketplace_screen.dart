import 'dart:async';

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
import 'package:farmer_market_app/features/buyer/presentation/screens/buyer_offers_screen.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';

/// Full Marketplace Screen for Buyers to browse, search, filter, and sort active farmer produce.
class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  static const List<String> _offerStatuses = [
    'All', 'Pending', 'Accepted', 'Rejected', 'Countered', 'Cancelled',
  ];

  List<OfferModel> _buyerOffers = const [];
  RealtimeChannel? _buyerOffersChannel;
  String? _buyerId;
  String _selectedOfferStatus = 'All';
  bool _hasLoadedBuyerOffers = false;
  String? _offersLoadError;
  int _offerFetchGeneration = 0;
  Timer? _searchDebounce;
  Timer? _offersRefreshDebounce;

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
    WidgetsBinding.instance.addObserver(this);
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    final buyerId = _buyerId;
    if (buyerId != null) _fetchBuyerOffers(buyerId);
    ref.read(marketplaceControllerProvider.notifier).fetchProduce();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _buyerOffersChannel?.unsubscribe();
    _searchDebounce?.cancel();
    _offersRefreshDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _watchBuyerOffers(String buyerId) {
    if (_buyerId == buyerId && _buyerOffersChannel != null) return;
    _buyerId = buyerId;
    _buyerOffersChannel?.unsubscribe();
    _buyerOffersChannel = ref
        .read(buyerRepositoryProvider)
        .subscribeToBuyerOffers(buyerId, (_) {
      _offersRefreshDebounce?.cancel();
      _offersRefreshDebounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted && _buyerId == buyerId) _fetchBuyerOffers(buyerId);
      });
    });
    _fetchBuyerOffers(buyerId);
  }

  Future<void> _fetchBuyerOffers(String buyerId) async {
    final generation = ++_offerFetchGeneration;
    final result = await ref.read(buyerRepositoryProvider).getBuyerOffers(buyerId);
    if (!mounted || generation != _offerFetchGeneration || _buyerId != buyerId) {
      return;
    }
    result.fold(
      (failure) => setState(() {
        _hasLoadedBuyerOffers = true;
        _offersLoadError = failure.message;
      }),
      (offers) => setState(() {
        _buyerOffers = offers;
        _hasLoadedBuyerOffers = true;
        _offersLoadError = null;
      }),
    );
  }

  int _offerCount(String status) {
    final normalizedStatus = status.toLowerCase();
    return _buyerOffers.where((offer) {
      final offerStatus = offer.status.trim().toLowerCase();
      return normalizedStatus == 'all'
          ? true
          : normalizedStatus == 'cancelled'
              ? offerStatus == 'cancelled' || offerStatus == 'canceled'
              : offerStatus == normalizedStatus;
    }).length;
  }

  List<OfferModel> get _visibleBuyerOffers {
    if (_selectedOfferStatus.toLowerCase() == 'all') return _buyerOffers;
    final target = _selectedOfferStatus.toLowerCase();
    return _buyerOffers.where((offer) {
      final status = offer.status.trim().toLowerCase();
      return target == 'cancelled'
          ? status == 'cancelled' || status == 'canceled'
          : status == target;
    }).toList(growable: false);
  }

  String _offerStatusLabel(String status) {
    if (status == 'All') return 'All Offers';
    switch (status.toLowerCase()) {
      case 'pending':
        return context.l10n.pendingOffers;
      case 'accepted':
        return context.l10n.acceptedOffers;
      case 'rejected':
        return 'Rejected';
      case 'countered':
        return 'Countered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(marketplaceControllerProvider.notifier).fetchProduce(query: query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider.select((auth) => auth.state.user?.id),
        (previousBuyerId, nextBuyerId) {
      if (nextBuyerId != null && nextBuyerId != _buyerId) {
        _watchBuyerOffers(nextBuyerId);
      } else if (nextBuyerId == null && _buyerId != null) {
        _buyerOffersChannel?.unsubscribe();
        _buyerOffersChannel = null;
        _buyerId = null;
        _buyerOffers = const [];
        _hasLoadedBuyerOffers = false;
        _offersLoadError = null;
        _selectedOfferStatus = 'All';
        if (mounted) setState(() {});
      }
    });
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
                final buyerId = _buyerId;
                if (buyerId != null) {
                  await _fetchBuyerOffers(buyerId);
                }
              },
              child: _buildBody(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerOffersSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = DateFormat('dd MMM yyyy, hh:mm a');
    final visibleOffers = _visibleBuyerOffers;
    final statusCounts =
        'Total ${_offerCount('all')}  •  Pending ${_offerCount('pending')}  •  Accepted ${_offerCount('accepted')}  •  Rejected ${_offerCount('rejected')}  •  Countered ${_offerCount('countered')}  •  Cancelled ${_offerCount('cancelled')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              Icon(Icons.local_offer_outlined, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              const Expanded(
                child: Text('Offers', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              Text('${_buyerOffers.length} total', style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              )),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(statusCounts, style: TextStyle(
              fontSize: 12, color: colorScheme.onSurfaceVariant,
            )),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _offerStatuses.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              final status = _offerStatuses[index];
              final selected = _selectedOfferStatus == status;
              return FilterChip(
                label: Text('${_offerStatusLabel(status)} (${_offerCount(status.toLowerCase())})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                  ),
                ),
                selected: selected,
                selectedColor: colorScheme.primary,
                backgroundColor: colorScheme.surface,
                onSelected: (value) {
                  if (value) setState(() => _selectedOfferStatus = status);
                },
              );
            },
          ),
        ),
        if (_offersLoadError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text('Could not refresh offers. Pull down to retry.',
              style: TextStyle(color: colorScheme.error, fontSize: 12)),
          ),
        if (_hasLoadedBuyerOffers && visibleOffers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              _buyerOffers.isEmpty
                  ? 'No offers yet. Offers you send will appear here.'
                  : 'No ${_offerStatusLabel(_selectedOfferStatus).toLowerCase()} found.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ...visibleOffers.take(5).map((offer) {
          final unit = offer.produceUnit ?? 'units';
          final createdText = offer.createdAt == null ? '—' : formatter.format(offer.createdAt!.toLocal());
          final updatedText = offer.updatedAt == null ? '—' : formatter.format(offer.updatedAt!.toLocal());
          final status = offer.status.trim().toLowerCase();
          final accepted = status == 'accepted';
          final displayStatus = status.isEmpty ? 'Pending' : status[0].toUpperCase() + status.substring(1);

          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(
                          offer.produceName ?? context.l10n.produceListingLabel,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        )),
                        const SizedBox(width: AppSpacing.xs),
                        Chip(
                          avatar: Icon(
                            accepted ? Icons.check_circle : status == 'rejected' ? Icons.cancel_outlined : Icons.schedule,
                            size: 16,
                          ),
                          label: Text(_offerStatusLabel(displayStatus)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${context.l10n.farmerLabel}: ${offer.farmerName ?? context.l10n.farmerLabel}'),
                    Text('${accepted ? 'Agreed' : 'Offered'} price: ₹${offer.offeredPrice.toStringAsFixed(2)} / $unit'),
                    Text('${accepted ? 'Accepted' : 'Requested'} quantity: ${offer.quantity} $unit'),
                    const Divider(height: AppSpacing.lg),
                    Text('Offer created: $createdText'),
                    if (offer.updatedAt != null)
                      Text('${accepted ? 'Accepted/updated' : 'Last updated'}: $updatedText'),
                    if (offer.message != null && offer.message!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text('Message: ${offer.message}',
                          style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (visibleOffers.length > 5)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BuyerOffersScreen(),
                  ),
                );
              },
              child: Text('View all offers (${visibleOffers.length})'),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(MarketplaceState state) {
    final children = <Widget>[];

    if (_buyerId != null) {
      children.add(_buildBuyerOffersSection());
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
      if (_buyerId != null) {
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
