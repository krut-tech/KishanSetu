import 'package:flutter/material.dart';
import 'package:farmer_market_app/l10n/generated/app_localizations.dart';

/// Extension for convenient access to localized strings: `context.l10n.welcomeMessage`
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    if (localizations == null) {
      throw FlutterError(
        'AppLocalizations not found in BuildContext. Ensure LocalizationsDelegate is configured in MaterialApp.',
      );
    }
    return localizations;
  }
}
