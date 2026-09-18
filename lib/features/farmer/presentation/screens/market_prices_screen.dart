import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/chips/app_chip.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/error_state_widget.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_search_field.dart';
import 'package:farmer_market_app/core/widgets/price/app_price_text.dart';
import 'package:farmer_market_app/core/widgets/states/shimmer_loading.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_providers.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/market_price_controller.dart';

class MarketPricesScreen extends ConsumerStatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  ConsumerState<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends ConsumerState<MarketPricesScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedSort = 'date_desc';

  static const List<String> _categories = [
    'All',
    'Cereals',
    'Pulses',
    'Vegetables',
    'Fruits',
    'Oilseeds',
    'Spices',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(marketPriceControllerProvider).prices.isEmpty) {
        _fetchPrices();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchPrices() {
    ref.read(marketPriceControllerProvider.notifier).fetchMarketPrices(
          produceName: _searchController.text,
          category: _selectedCategory,
          sortBy: _selectedSort,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(marketPriceControllerProvider);

    return SafeArea(
      top: false,
      bottom: true,
      child: Column(
        children: [
          // Header Search & Filter Bar (fixed at top)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppSearchField(
                        controller: _searchController,
                        hint: 'Search market prices by crop name...',
                        onChanged: (val) => _fetchPrices(),
                        onClear: () {
                          _searchController.clear();
                          _fetchPrices();
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.sort_rounded,
                        color: isDark ? const Color(0xFF4ADE80) : AppColors.primary,
                      ),
                      tooltip: 'Sort Prices',
                      onSelected: (sortVal) {
                        setState(() => _selectedSort = sortVal);
                        _fetchPrices();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'date_desc',
                          child: Text('Latest Date'),
                        ),
                        PopupMenuItem(
                          value: 'price_asc',
                          child: Text('Price: Low to High'),
                        ),
                        PopupMenuItem(
                          value: 'price_desc',
                          child: Text('Price: High to Low'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: AppChip(
                          label: cat,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            _fetchPrices();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Scrollable Area with RefreshIndicator wrapping scrollable ListView/ScrollView
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _fetchPrices(),
              child: _buildContent(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(MarketPriceState state) {
    if (state.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxxl + 16,
        ),
        itemCount: 5,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: ShimmerLoading(width: double.infinity, height: 90),
        ),
      );
    }

    if (state.errorMessage != null && state.prices.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: const BoxConstraints(minHeight: 350),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ErrorStateWidget(
            title: 'Failed to load market prices',
            message: state.errorMessage!,
            onRetry: _fetchPrices,
          ),
        ),
      );
    }

    if (state.prices.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: const BoxConstraints(minHeight: 350),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: EmptyStateWidget(
            title: 'No Market Prices Found',
            message: 'No market price records match your current search or category filter.',
            icon: Icons.trending_up_outlined,
            actionLabel: 'Reset Filters',
            onAction: () {
              _searchController.clear();
              setState(() {
                _selectedCategory = 'All';
                _selectedSort = 'date_desc';
              });
              _fetchPrices();
            },
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxxl + 24,
      ),
      itemCount: state.prices.length,
      itemBuilder: (context, index) {
        final item = state.prices[index];
        final trendEnum = switch (item.trend.toLowerCase()) {
          'up' => PriceTrend.up,
          'down' => PriceTrend.down,
          'stable' => PriceTrend.stable,
          _ => PriceTrend.none,
        };

        final formattedDate = item.priceDate != null
            ? DateFormat('dd MMM yyyy').format(item.priceDate!)
            : 'Today';

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.produceName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.category != null) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.category!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFDCFCE7) : AppColors.primaryDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.marketName}${item.location != null ? " • ${item.location}" : ""}',
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Updated: $formattedDate${item.source != null ? " • Source: ${item.source}" : ""}',
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: AppPriceText(
                    price: item.price,
                    unit: item.unit,
                    trend: trendEnum,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
