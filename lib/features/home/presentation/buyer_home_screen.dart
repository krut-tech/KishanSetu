import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmer_market_app/core/animations/staggered_reveal.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/core/constants/app_constants.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/localization/locale_controller.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import 'package:farmer_market_app/core/routing/route_names.dart';
import 'package:farmer_market_app/core/theme/theme_controller.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/error_state_widget.dart';
import 'package:farmer_market_app/core/widgets/fade_indexed_stack.dart';
import 'package:farmer_market_app/core/widgets/hero_welcome_card.dart';
import 'package:farmer_market_app/core/widgets/navigation/app_bottom_nav.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/core/widgets/states/shimmer_loading.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';
import 'package:farmer_market_app/features/notifications/presentation/widgets/notification_badge_icon.dart';
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
import 'package:farmer_market_app/features/update/presentation/controllers/update_controller.dart';
import 'package:farmer_market_app/features/update/presentation/widgets/update_dialog.dart';

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
      return context.l10n.goodMorning;
    } else if (hour < 17) {
      return context.l10n.goodAfternoon;
    } else {
      return context.l10n.goodEvening;
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
          if (profile?.isAdmin == true)
            IconButton(
              tooltip: 'Admin Panel',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => context.push(RouteNames.adminPanel),
            ),
          const NotificationBadgeIcon(),
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
        child: FadeIndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        items: [
          AppBottomNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: context.l10n.home,
          ),
          AppBottomNavItem(
            icon: Icons.storefront_outlined,
            activeIcon: Icons.storefront_rounded,
            label: context.l10n.marketplace,
          ),
          AppBottomNavItem(
            icon: Icons.trending_up_outlined,
            activeIcon: Icons.trending_up_rounded,
            label: context.l10n.marketPrices,
          ),
          AppBottomNavItem(
            icon: Icons.local_offer_outlined,
            activeIcon: Icons.local_offer_rounded,
            label: context.l10n.myOffers,
          ),
          AppBottomNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: context.l10n.profile,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView(BuildContext context, UserProfile? profile) {
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
        title: context.l10n.unableToLoadDashboard,
        message: dashboardState.errorMessage!,
        onRetry: _loadDashboard,
      );
    }

    final buyerName = profile?.companyName ?? profile?.fullName ?? context.l10n.buyerLabel;
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
            StaggeredReveal(
              index: 0,
              child: BuyerHeader(
                profile: profile,
                onNotificationPressed: () {
                  AppLogger.info('NOTIFICATION BELL TAPPED');
                  AppLogger.info('NAVIGATING TO NOTIFICATION CENTER');
                  try {
                    context.pushNamed('notifications');
                  } catch (e, stackTrace) {
                    AppLogger.error('Failed to navigate to Notification Center', e, stackTrace);
                  }
                },
                onProfilePressed: () {
                  setState(() => _currentIndex = 4);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Welcome Hero
            StaggeredReveal(
              index: 1,
              child: HeroWelcomeCard(
                icon: Icons.storefront_rounded,
                title: greetingText,
                subtitle: context.l10n.welcomeSubtitleBuyer,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quick Actions
            StaggeredReveal(
              index: 2,
              child: BuyerQuickActionsGrid(
                onBrowseMarketplace: () => setState(() => _currentIndex = 1),
                onMarketPrices: () => setState(() => _currentIndex = 2),
                onMyOffers: () => setState(() => _currentIndex = 3),
                onProfile: () => setState(() => _currentIndex = 4),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Summary Cards
            StaggeredReveal(
              index: 3,
              child: MarketplaceSummaryCards(
                stats: dashboardState.stats,
                onStatCardTap: (index) => setState(() => _currentIndex = index),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Featured Produce
            StaggeredReveal(
              index: 4,
              child: FeaturedProduceList(
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
            ),
            const SizedBox(height: AppSpacing.lg),

            // Market Price Highlights
            StaggeredReveal(
              index: 5,
              child: MarketPriceHighlights(
                prices: dashboardState.marketHighlights,
                onViewAll: () => setState(() => _currentIndex = 2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Recent Offers List
            StaggeredReveal(
              index: 6,
              child: BuyerRecentOffersList(
                offers: dashboardState.recentOffers,
                onViewAll: () => setState(() => _currentIndex = 3),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, UserProfile? profile) {
    final colorScheme = Theme.of(context).colorScheme;
    final kycStatus = profile?.kycStatus ?? 'unverified';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl + 24),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.buyerBusinessDetailsTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const Divider(),
            ListTile(title: Text(context.l10n.contactNameLabel), subtitle: Text(profile?.fullName ?? '-')),
            ListTile(title: Text(context.l10n.companyBusinessLabel), subtitle: Text(profile?.companyName ?? '-')),
            ListTile(title: Text(context.l10n.businessTypeLabel), subtitle: Text(profile?.businessType ?? '-')),
            ListTile(
              title: Text(context.l10n.locationLabel),
              subtitle: Text('${profile?.district ?? ''}, ${profile?.state ?? ''}'),
            ),
            ListTile(title: Text(context.l10n.gstNumberLabel), subtitle: Text(profile?.gstNumber ?? context.l10n.notProvided)),
            ListTile(
              title: Text(context.l10n.buyingCapacityLabel),
              subtitle: Text('${profile?.buyingCapacityQuintals ?? 0} ${context.l10n.quintalsLabel}'),
            ),
            ListTile(
              leading: Icon(
                kycStatus == 'verified' ? Icons.verified_rounded : Icons.verified_user_outlined,
                color: kycStatus == 'verified' ? Colors.green : colorScheme.onSurfaceVariant,
              ),
              title: const Text('Identity Verification'),
              subtitle: Text(kycStatus[0].toUpperCase() + kycStatus.substring(1)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(RouteNames.kycVerification),
            ),
            ListTile(
              leading: const Icon(Icons.system_update_rounded),
              title: const Text('Check for Updates'),
              subtitle: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snap) => Text(
                  snap.hasData
                      ? 'KisanSetu v${snap.data!.version}+${snap.data!.buildNumber}'
                      : 'KisanSetu',
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final updateNotifier = ref.read(updateNotifierProvider.notifier);
                final info = await updateNotifier.checkForUpdate(isManual: true);
                if (context.mounted) {
                  if (info != null) {
                    UpdateDialog.show(context);
                  } else {
                    AppSnackBar.show(
                      context,
                      message: 'You are on the latest version of KisanSetu.',
                      type: SnackBarType.success,
                    );
                  }
                }
              },
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
