import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_bar/app_top_bar.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/chips/app_chip.dart';
import 'package:farmer_market_app/core/widgets/dropdowns/app_dropdown.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/screens/produce_details_screen.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';

/// Filterable search across organic tag, harvest date, price range, and delivery radius.
class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  ConsumerState<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen> {
  static const List<String> _categories = [
    'All',
    'Cereals',
    'Pulses',
    'Vegetables',
    'Fruits',
    'Oilseeds',
    'Spices',
    'Cotton & Fiber',
    'Other',
  ];
  static const List<String> _tags = [
    'Organic',
    'Pesticide-Free',
    'Grade A',
    'Freshly Harvested',
    'Non-GMO',
    'Sun-Dried',
    'Export Quality',
  ];

  final _queryController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  bool _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(advancedSearchControllerProvider.notifier).search();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _runSearch() {
    final controller = ref.read(advancedSearchControllerProvider.notifier);
    controller.updateFilters(
      query: _queryController.text.trim(),
      minPrice: double.tryParse(_minPriceController.text.trim()),
      maxPrice: double.tryParse(_maxPriceController.text.trim()),
      clearMinPrice: _minPriceController.text.trim().isEmpty,
      clearMaxPrice: _maxPriceController.text.trim().isEmpty,
    );
    controller.search();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(advancedSearchControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const AppTopBar(title: 'Advanced Search'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: AppTextField(
              label: 'Search produce',
              hint: 'e.g. Wheat, Tomato',
              controller: _queryController,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: _runSearch,
              ),
              onChanged: (_) {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _filtersExpanded = !_filtersExpanded),
                  icon: Icon(_filtersExpanded ? Icons.expand_less : Icons.tune_rounded),
                  label: Text(_filtersExpanded ? 'Hide filters' : 'Filters'),
                ),
                if (state.hasSearched && !state.isLoading)
                  Text('${state.results.length} result(s)', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (_filtersExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDropdownFormField<String>(
                    label: 'Category',
                    value: state.category,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => ref
                        .read(advancedSearchControllerProvider.notifier)
                        .updateFilters(category: v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Min Price',
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppTextField(
                          label: 'Max Price',
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: state.harvestAfter ?? DateTime.now().subtract(const Duration(days: 30)),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        ref.read(advancedSearchControllerProvider.notifier).updateFilters(harvestAfter: picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Harvested on or after'),
                      child: Text(
                        state.harvestAfter != null
                            ? DateFormat('dd MMM yyyy').format(state.harvestAfter!)
                            : 'Any date',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Quality Tags', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _tags.map((tag) {
                      final selected = state.qualityTags.contains(tag);
                      return AppChip(
                        label: tag,
                        isSelected: selected,
                        onTap: () {
                          final updated = List<String>.from(state.qualityTags);
                          selected ? updated.remove(tag) : updated.add(tag);
                          ref
                              .read(advancedSearchControllerProvider.notifier)
                              .updateFilters(qualityTags: updated);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Apply Filters',
                    icon: Icons.search_rounded,
                    onPressed: _runSearch,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.results.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.search_off_rounded,
                        title: state.hasSearched ? 'No matches found' : 'Search for produce',
                        message: state.hasSearched
                            ? 'Try adjusting your filters or search term.'
                            : 'Use the search bar or filters above to find listings.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.xxxl,
                        ),
                        itemCount: state.results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final r = state.results[index];
                          return AppCard(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProduceDetailsScreen(
                                  produce: ProduceModel(
                                    id: r.id,
                                    farmerId: r.farmerId,
                                    name: r.name,
                                    category: r.category,
                                    quantity: r.quantity,
                                    unit: r.unit,
                                    expectedPrice: r.expectedPrice,
                                    location: r.location,
                                    qualityTags: r.qualityTags,
                                    imageUrls: r.imageUrls,
                                    latitude: r.latitude,
                                    longitude: r.longitude,
                                  ),
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r.name,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                      ),
                                    ),
                                    if (r.distanceKm != null) Text('${r.distanceKm!.toStringAsFixed(1)} km'),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${r.quantity} ${r.unit} • ₹${r.expectedPrice.toStringAsFixed(0)}/${r.unit}${r.location != null ? ' • ${r.location}' : ''}',
                                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                                ),
                                if (r.qualityTags.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: r.qualityTags
                                        .map((t) => Chip(
                                              label: Text(t, style: const TextStyle(fontSize: 11)),
                                              visualDensity: VisualDensity.compact,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
