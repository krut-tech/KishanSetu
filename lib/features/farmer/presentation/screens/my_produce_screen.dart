import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/routing/route_names.dart';
import 'package:farmer_market_app/core/widgets/chips/app_chip.dart';
import 'package:farmer_market_app/core/widgets/dialogs/app_dialogs.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/error_state_widget.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_search_field.dart';
import 'package:farmer_market_app/core/widgets/cards/produce_card.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/core/widgets/states/shimmer_loading.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_providers.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/produce_controller.dart';

class MyProduceScreen extends ConsumerStatefulWidget {
  const MyProduceScreen({super.key});

  @override
  ConsumerState<MyProduceScreen> createState() => _MyProduceScreenState();
}

class _MyProduceScreenState extends ConsumerState<MyProduceScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'All';

  static const List<String> _statusFilters = [
    'All',
    'active',
    'pending',
    'sold',
    'draft',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(produceControllerProvider).produceList.isEmpty) {
        _fetchProduce();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchProduce() {
    final user = ref.read(authNotifierProvider).profile;
    if (user != null) {
      ref.read(produceControllerProvider.notifier).fetchProduce(
            user.id,
            status: _selectedStatus == 'All' ? null : _selectedStatus,
            query: _searchController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(produceControllerProvider);
    final user = ref.watch(authNotifierProvider).profile;

    return SafeArea(
      top: false,
      bottom: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                AppSearchField(
                  controller: _searchController,
                  hint: 'Search my produce by crop name...',
                  onChanged: (val) => _fetchProduce(),
                  onClear: () {
                    _searchController.clear();
                    _fetchProduce();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
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
                            _fetchProduce();
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _fetchProduce();
              },
              child: _buildContent(state, user?.fullName ?? 'Farmer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ProduceState state, String farmerName) {
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
          child: ShimmerLoading(width: double.infinity, height: 160),
        ),
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
            title: 'Failed to load produce',
            message: state.errorMessage!,
            onRetry: _fetchProduce,
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
            title: 'No produce listed yet',
            message: 'You have not added any produce listings in this category.',
            icon: Icons.eco_outlined,
            actionLabel: 'Add Produce',
            onAction: () => context.push(RouteNames.addProduce),
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
      itemCount: state.produceList.length,
      itemBuilder: (context, index) {
        final item = state.produceList[index];
        final netRealization = item.expectedPrice * 0.95; // 95% net after estimated charges

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Stack(
            children: [
              ProduceCard(
                cropName: item.name,
                grade: item.category,
                quantity: '${item.quantity} ${item.unit}',
                askingPrice: item.expectedPrice,
                netRealizationPrice: netRealization,
                location: item.location ?? 'Location not specified',
                farmerName: farmerName,
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () async {
                    final confirmed = await AppDialogs.showConfirmDialog(
                      context: context,
                      title: 'Delete Produce Listing',
                      message: 'Are you sure you want to delete ${item.name}?',
                      confirmLabel: 'Delete',
                      isDestructive: true,
                    );
                    if (confirmed == true) {
                      final success = await ref
                          .read(produceControllerProvider.notifier)
                          .deleteProduce(item.id);
                      if (success) {
                        ref.read(farmerDashboardNotifierProvider.notifier).refreshDashboard();
                        if (context.mounted) {
                          AppSnackBar.show(context, message: 'Produce deleted', type: SnackBarType.info);
                        }
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
