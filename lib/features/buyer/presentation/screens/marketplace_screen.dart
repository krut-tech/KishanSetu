import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/cards/produce_card.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/error_state_widget.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_search_field.dart';
import 'package:farmer_market_app/core/widgets/states/shimmer_loading.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/marketplace_controller.dart';
import 'package:farmer_market_app/features/buyer/presentation/screens/produce_details_screen.dart';

/// Full Marketplace Screen for Buyers to browse, search, filter, and sort active farmer produce.
class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();

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
      if (ref.read(marketplaceControllerProvider).produceList.isEmpty) {
        ref.read(marketplaceControllerProvider.notifier).fetchProduce();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  hint: 'Search crop, category, or location...',
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
                            cat,
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
                      '${state.produceList.length} Produce Available',
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
                          items: const [
                            DropdownMenuItem(value: 'newest', child: Text('Sort: Newest')),
                            DropdownMenuItem(value: 'price_asc', child: Text('Price: Low → High')),
                            DropdownMenuItem(value: 'price_desc', child: Text('Price: High → Low')),
                            DropdownMenuItem(value: 'quantity_desc', child: Text('Quantity: High → Low')),
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
                await ref.read(marketplaceControllerProvider.notifier).fetchProduce();
              },
              child: _buildBody(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(MarketplaceState state) {
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
        itemBuilder: (context, index) => const ShimmerLoading(width: double.infinity, height: 160),
      );
    }

    if (state.errorMessage != null && state.produceList.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: const BoxConstraints(minHeight: 350),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ErrorStateWidget(
            title: 'Failed to load marketplace',
            message: state.errorMessage!,
            onRetry: () => ref.read(marketplaceControllerProvider.notifier).fetchProduce(),
          ),
        ),
      );
    }

    if (state.produceList.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: const BoxConstraints(minHeight: 350),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: EmptyStateWidget(
            title: 'No produce available',
            message: 'No farmer produce matches your search or filter criteria.',
            actionLabel: 'Reset Filters',
            onAction: () {
              _searchController.clear();
              ref.read(marketplaceControllerProvider.notifier).resetFilters();
            },
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
      itemCount: state.produceList.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final produce = state.produceList[index];
        return ProduceCard(
          cropName: produce.name,
          grade: produce.category,
          quantity: '${produce.quantity} ${produce.unit}',
          askingPrice: produce.expectedPrice,
          netRealizationPrice: produce.expectedPrice * 0.95,
          location: produce.location ?? produce.farmerDistrict ?? 'Gujarat',
          farmerName: produce.farmerName ?? 'Farmer',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProduceDetailsScreen(produce: produce),
              ),
            );
          },
        );
      },
    );
  }
}
