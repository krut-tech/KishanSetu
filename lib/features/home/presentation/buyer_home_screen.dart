import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/constants/app_constants.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/localization/locale_controller.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import 'package:farmer_market_app/core/theme/theme_controller.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/error_state_widget.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/core/widgets/states/shimmer_loading.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/screens/buyer_offers_screen.dart';
import 'package:farmer_market_app/features/buyer/presentation/screens/marketplace_screen.dart';
import 'package:farmer_market_app/features/buyer/presentation/screens/produce_details_screen.dart';
import 'package:farmer_market_app/features/buyer/presentation/widgets/buyer_header.dart';
import 'package:farmer_market_app/features/buyer/presentation/widgets/buyer_quick_actions.dart';
import 'package:farmer_market_app/features/buyer/presentation/widgets/buyer_recent_offers_list.dart';
import 'package:farmer_market_app/features/buyer/presentation/widgets/featured_produce_list.dart';
import 'package:farmer_market_app/features/buyer/presentation/widgets/marketplace_summary_cards.dart';
import 'package:farmer_market_app/features/farmer/presentation/screens/market_prices_screen.dart';
import 'package:farmer_market_app/features/farmer/presentation/widgets/market_price_highlights.dart';

/// Role-specific home shell & dashboard for authenticated buyers.
class BuyerHomeScreen extends ConsumerStatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  ConsumerState<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends ConsumerState<BuyerHomeScreen> {
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
      ref.read(buyerDashboardNotifierProvider.notifier).loadDashboardData(profile.id);
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
      const MarketplaceScreen(),
      const MarketPricesScreen(),
      const BuyerOffersScreen(),
      _buildProfileTab(context, profile),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.buyerHomeTitle),
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
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: colorScheme.primary),
            label: context.l10n.marketplace,
          ),
          NavigationDestination(
            icon: const Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up, color: colorScheme.primary),
            label: context.l10n.marketPrices,
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer, color: colorScheme.primary),
            label: context.l10n.myOffers,
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
    final dashboardState = ref.watch(buyerDashboardNotifierProvider);

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

    if (dashboardState.errorMessage != null && dashboardState.featuredProduce.isEmpty) {
      return ErrorStateWidget(
        title: 'Unable to load dashboard',
        message: dashboardState.errorMessage!,
        onRetry: _loadDashboard,
      );
    }

    final buyerName = profile?.companyName ?? profile?.fullName ?? 'Buyer';
    final greetingText = '${_getGreeting()}, $buyerName!';

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(buyerDashboardNotifierProvider.notifier).refreshDashboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            BuyerHeader(
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
                    Icons.storefront_rounded,
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
                          'Direct crop procurement portal & price discovery marketplace.',
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

            // Quick Actions
            BuyerQuickActionsGrid(
              onBrowseMarketplace: () => setState(() => _currentIndex = 1),
              onMarketPrices: () => setState(() => _currentIndex = 2),
              onMyOffers: () => setState(() => _currentIndex = 3),
              onProfile: () => setState(() => _currentIndex = 4),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Summary Cards
            MarketplaceSummaryCards(
              stats: dashboardState.stats,
              onStatCardTap: (index) => setState(() => _currentIndex = index),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Featured Produce
            FeaturedProduceList(
              produceList: dashboardState.featuredProduce,
              onViewAll: () => setState(() => _currentIndex = 1),
              onProduceTap: (produce) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProduceDetailsScreen(produce: produce),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Market Price Highlights
            MarketPriceHighlights(
              prices: dashboardState.marketHighlights,
              onViewAll: () => setState(() => _currentIndex = 2),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Recent Offers List
            BuyerRecentOffersList(
              offers: dashboardState.recentOffers,
              onViewAll: () => setState(() => _currentIndex = 3),
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
              'Buyer Business Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const Divider(),
            ListTile(title: const Text('Contact Name'), subtitle: Text(profile?.fullName ?? '-')),
            ListTile(title: const Text('Company / Business'), subtitle: Text(profile?.companyName ?? '-')),
            ListTile(title: const Text('Business Type'), subtitle: Text(profile?.businessType ?? '-')),
            ListTile(
              title: const Text('Location'),
              subtitle: Text('${profile?.district ?? ''}, ${profile?.state ?? ''}'),
            ),
            ListTile(title: const Text('GST Number'), subtitle: Text(profile?.gstNumber ?? 'Not Provided')),
            ListTile(
              title: const Text('Buying Capacity'),
              subtitle: Text('${profile?.buyingCapacityQuintals ?? 0} Quintals'),
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
