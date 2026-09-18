import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/constants/app_constants.dart';
import 'package:farmer_market_app/core/localization/locale_controller.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/core/routing/app_router.dart';
import 'package:farmer_market_app/core/theme/app_theme.dart';
import 'package:farmer_market_app/core/theme/theme_controller.dart';
import 'package:farmer_market_app/l10n/generated/app_localizations.dart';

/// Root Application Widget configuring theme, router, and localization delegates.
class FarmerMarketApp extends ConsumerWidget {
  const FarmerMarketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.info('FarmerMarketApp build -> watching appRouterProvider');
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale(AppConstants.localeEnglish),
        Locale(AppConstants.localeHindi),
        Locale(AppConstants.localeGujarati),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
