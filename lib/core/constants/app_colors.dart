import 'package:flutter/material.dart';

/// "Harvest Glass" palette: deep forest greens, wheat gold and warm cream.
/// All pre-existing token names are preserved so every feature picks up the
/// new look automatically.
class AppColors {
  AppColors._();

  // Primary - Leaf Green
  static const Color primary = Color(0xFF238B4D);
  static const Color primaryDark = Color(0xFF14633A);
  static const Color primaryLight = Color(0xFFE4F4EA);

  // Secondary - Wheat Gold
  static const Color secondary = Color(0xFFC99A2E);
  static const Color secondaryDark = Color(0xFF8A6414);
  static const Color secondaryLight = Color(0xFFFBF1D6);

  // Harvest Glass signature accents
  static const Color accent = Color(0xFFE3B65B);
  static const Color accentSoft = Color(0xFFF4DFA6);
  static const Color leaf = Color(0xFF5BC77A);
  static const Color forest = Color(0xFF0A1A11);

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF4DFA6), Color(0xFFE3B65B), Color(0xFFC99A2E)],
  );

  static const LinearGradient forestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F6B3F), Color(0xFF0F3B22)],
  );

  // Status Badges & Transaction State Colors
  static const Color pendingBg = Color(0xFFFEF3C7);
  static const Color pendingFg = Color(0xFFB45309);

  static const Color acceptedBg = Color(0xFFDCFCE7);
  static const Color acceptedFg = Color(0xFF15803D);

  static const Color rejectedBg = Color(0xFFFEE2E2);
  static const Color rejectedFg = Color(0xFFB91C1C);

  static const Color expiredBg = Color(0xFFF1F5F9);
  static const Color expiredFg = Color(0xFF64748B);

  static const Color inTransitBg = Color(0xFFE0F2FE);
  static const Color inTransitFg = Color(0xFF0369A1);

  static const Color completedBg = Color(0xFFD1FAE5);
  static const Color completedFg = Color(0xFF047857);

  static const Color activeBg = Color(0xFFECFDF5);
  static const Color activeFg = Color(0xFF065F46);

  static const Color draftBg = Color(0xFFF3F4F6);
  static const Color draftFg = Color(0xFF374151);

  // Standard Alerts & Semantic Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);

  // Neutral Light Theme (warm cream)
  static const Color backgroundLight = Color(0xFFF5F2E8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF14231A);
  static const Color textSecondaryLight = Color(0xFF5C6E62);
  static const Color borderLight = Color(0xFFE3DECD);

  // Neutral Dark Theme (deep forest)
  static const Color backgroundDark = Color(0xFF0A1A11);
  static const Color surfaceDark = Color(0xFF12261A);
  static const Color textPrimaryDark = Color(0xFFEDF5EA);
  static const Color textSecondaryDark = Color(0xFF9DB5A3);
  static const Color borderDark = Color(0xFF24402E);

  // Price & Realization Highlights
  static const Color priceHighlight = Color(0xFF16A36B);
  static const Color netRealizationBadge = Color(0xFF047857);
  static const Color netRealizationBg = Color(0xFFECFDF5);
}
