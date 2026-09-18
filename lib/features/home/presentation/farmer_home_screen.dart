import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmer_market_app/core/constants/app_constants.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/localization/locale_controller.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import 'package:farmer_market_app/core/routing/route_names.dart';
import 'package:farmer_market_app/core/theme/theme_controller.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/error_state_widget.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/core/widgets/states/shimmer_loading.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_providers.dart';
import 'package:farmer_market_app/features/farmer/presentation/screens/market_prices_screen.dart';
import 'package:farmer_market_app/features/farmer/presentation/screens/my_produce_screen.dart';
import 'package:farmer_market_app/features/farmer/presentation/screens/offers_screen.dart';
import 'package:farmer_market_app/features/farmer/presentation/widgets/farmer_header.dart';
import 'package:farmer_market_app/features/farmer/presentation/widgets/market_insights_card.dart';
import 'package:farmer_market_app/features/farmer/presentation/widgets/market_price_highlights.dart';
import 'package:farmer_market_app/features/farmer/presentation/widgets/produce_summary_cards.dart';
import 'package:farmer_market_app/features/farmer/presentation/widgets/quick_actions_grid.dart';
import 'package:farmer_market_app/features/farmer/presentation/widgets/recent_offers_list.dart';

/// Role-specific home dashboard for authenticated farmers.
class FarmerHomeScreen extends ConsumerStatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  ConsumerState<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends ConsumerState<FarmerHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  void _loadDashboard() {
    final profile = ref.read(authNotifierProvider).profile;
    if (profile != null) {
      ref.read(farmerDashboardNotifierProvider.notifier).loadDashboardData(profile.id);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentLocale = ref.watch(localeControllerProvider);
    final authState = ref.watch(authNotifierProvider);
    final profile = authState.profile;

    final pages = [
      _buildDashboardView(context, profile),
      const MarketPricesScreen(),
      const MyProduceScreen(),
      const OffersScreen(),
      _buildProfileTab(context, profile),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.farmerHomeTitle),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: context.l10n.selectLanguage,
            onSelected: (code) {
              ref.read(localeControllerProvider.notifier).setLocale(code);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: AppConstants.localeEnglish,
                child: Row(
                  children: [
                    if (currentLocale.languageCode == AppConstants.localeEnglish)
                      Icon(Icons.check, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(context.l10n.english),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AppConstants.localeHindi,
                child: Row(
                  children: [
                    if (currentLocale.languageCode == AppConstants.localeHindi)
                      Icon(Icons.check, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(context.l10n.hindi),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AppConstants.localeGujarati,
                child: Row(
                  children: [
                    if (currentLocale.languageCode == AppConstants.localeGujarati)
                      Icon(Icons.check, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(context.l10n.gujarati),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              ref.read(themeControllerProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: colorScheme.primary),
            label: context.l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up, color: colorScheme.primary),
            label: context.l10n.marketPrices,
          ),
          NavigationDestination(
            icon: const Icon(Icons.eco_outlined),
            selectedIcon: Icon(Icons.eco, color: colorScheme.primary),
            label: context.l10n.myProduce,
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer, color: colorScheme.primary),
            label: context.l10n.offers,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: colorScheme.primary),
            label: context.l10n.profile,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView(BuildContext context, UserProfile? profile) {
    final colorScheme = Theme.of(context).colorScheme;
    final dashboardState = ref.watch(farmerDashboardNotifierProvider);

    if (dashboardState.isLoading) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: const [
            ShimmerLoading(width: double.infinity, height: 80),
            SizedBox(height: AppSpacing.md),
            ShimmerLoading(width: double.infinity, height: 120),
            SizedBox(height: AppSpacing.md),
            ShimmerLoading(width: double.infinity, height: 140),
            SizedBox(height: AppSpacing.md),
            ShimmerLoading(width: double.infinity, height: 160),
          ],
        ),
      );
    }

    if (dashboardState.errorMessage != null && dashboardState.recentProduce.isEmpty) {
      return ErrorStateWidget(
        title: 'Unable to load dashboard',
        message: dashboardState.errorMessage!,
        onRetry: _loadDashboard,
      );
    }

    final greetingText = '${_getGreeting()}, ${profile?.fullName ?? "Farmer"}!';

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(farmerDashboardNotifierProvider.notifier).refreshDashboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            FarmerHeader(
              profile: profile,
              onNotificationPressed: () {
                AppSnackBar.show(context, message: 'No new notifications', type: SnackBarType.info);
              },
              onProfilePressed: () {
                setState(() => _currentIndex = 4);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Welcome Card
            AppCard(
              backgroundColor: colorScheme.primaryContainer,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.eco_rounded,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greetingText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Direct market access & transparent price discovery for your crops.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quick Actions Grid
            QuickActionsGrid(
              onAddProduce: () => context.push(RouteNames.addProduce),
              onMyProduce: () => setState(() => _currentIndex = 2),
              onMarketPrices: () => setState(() => _currentIndex = 1),
              onMyOffers: () => setState(() => _currentIndex = 3),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Produce & Offers Summary Cards
            ProduceSummaryCards(
              stats: dashboardState.stats,
              onStatCardTap: (index) => setState(() => _currentIndex = index),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Market Price Highlights
            MarketPriceHighlights(
              prices: dashboardState.marketHighlights,
              onViewAll: () => setState(() => _currentIndex = 1),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Recent Offers List
            RecentOffersList(
              offers: dashboardState.recentOffers,
              onViewAll: () => setState(() => _currentIndex = 3),
              onRespond: (offer, status) async {
                final ok = await ref
                    .read(offerControllerProvider.notifier)
                    .respondToOffer(offer.id, status);
                if (ok) {
                  ref.read(farmerDashboardNotifierProvider.notifier).refreshDashboard();
                  if (context.mounted) {
                    AppSnackBar.show(context, message: 'Offer marked as ${status.toUpperCase()}', type: SnackBarType.success);
                  }
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Market Insights Card
            MarketInsightsCard(
              marketPrices: dashboardState.marketHighlights,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, UserProfile? profile) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl + 24),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farmer Profile Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const Divider(),
            ListTile(title: const Text('Name'), subtitle: Text(profile?.fullName ?? '-')),
            ListTile(title: const Text('Phone'), subtitle: Text(profile?.phone ?? '-')),
            ListTile(
              title: const Text('Location'),
              subtitle: Text('${profile?.village ?? ''}, ${profile?.district ?? ''}, ${profile?.state ?? ''}'),
            ),
            ListTile(title: const Text('Primary Crop'), subtitle: Text(profile?.primaryCrop ?? '-')),
            ListTile(
              title: const Text('Land Size'),
              subtitle: Text('${profile?.landSizeAcres ?? 0} Acres'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: context.l10n.logout,
              style: AppButtonStyle.outlined,
              icon: Icons.logout,
              onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
