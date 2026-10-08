import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/theme/harvest_page_transitions.dart';

/// "Harvest Glass" Material 3 theme with full Light & Dark support.
/// Fraunces for display type, Manrope for everything else.
class AppTheme {
  AppTheme._();

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryLight,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: Color(0xFF2A1F05),
    secondaryContainer: AppColors.secondaryLight,
    onSecondaryContainer: AppColors.secondaryDark,
    error: AppColors.error,
    onError: Colors.white,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    onSurfaceVariant: AppColors.textSecondaryLight,
    outline: AppColors.borderLight,
    outlineVariant: Color(0xFFEDE8D8),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFFAF8F1),
    surfaceContainer: Color(0xFFF4F1E6),
    surfaceContainerHigh: Color(0xFFEEEADD),
    surfaceContainerHighest: Color(0xFFE8E4D5),
    inverseSurface: Color(0xFF14231A),
    onInverseSurface: Color(0xFFEDF5EA),
    surfaceTint: Colors.transparent,
    shadow: Colors.black,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.accent,
    onPrimary: AppColors.forest,
    primaryContainer: Color(0xFF2C3A1E),
    onPrimaryContainer: AppColors.accentSoft,
    secondary: AppColors.leaf,
    onSecondary: Color(0xFF06210F),
    secondaryContainer: Color(0xFF14402A),
    onSecondaryContainer: Color(0xFFC8F0D4),
    error: Color(0xFFEF4444),
    onError: Colors.white,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
    onSurfaceVariant: AppColors.textSecondaryDark,
    outline: AppColors.borderDark,
    outlineVariant: Color(0xFF1B3324),
    surfaceContainerLowest: Color(0xFF08140D),
    surfaceContainerLow: Color(0xFF0F2016),
    surfaceContainer: Color(0xFF12261A),
    surfaceContainerHigh: Color(0xFF183022),
    surfaceContainerHighest: Color(0xFF1F3A29),
    inverseSurface: Color(0xFFEDF5EA),
    onInverseSurface: AppColors.forest,
    surfaceTint: Colors.transparent,
    shadow: Colors.black,
  );

  static ThemeData get lightTheme => _build(_lightScheme);
  static ThemeData get darkTheme => _build(_darkScheme);

  static TextTheme _textTheme(TextTheme base, Color on) {
    final body = GoogleFonts.manropeTextTheme(base).apply(
      bodyColor: on,
      displayColor: on,
    );
    TextStyle? display(TextStyle? s) => GoogleFonts.fraunces(
          textStyle: s,
          fontWeight: FontWeight.w600,
          color: on,
        );
    return body.copyWith(
      displayLarge: display(body.displayLarge),
      displayMedium: display(body.displayMedium),
      displaySmall: display(body.displaySmall),
      headlineLarge: display(body.headlineLarge),
      headlineMedium: display(body.headlineMedium),
      headlineSmall: display(body.headlineSmall),
      titleLarge: display(body.titleLarge),
    );
  }

  static ThemeData _build(ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final fill = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final textTheme = _textTheme(base.textTheme, cs.onSurface);

    final r16 = BorderRadius.circular(16);
    final r18 = BorderRadius.circular(18);
    final r28 = BorderRadius.circular(28);
    final buttonShape = RoundedRectangleBorder(borderRadius: r18);
    final buttonText = GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800);

    OutlineInputBorder inputBorder(Color c, [double w = 1.0]) => OutlineInputBorder(
          borderRadius: r16,
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: cs.brightness,
      colorScheme: cs,
      // Transparent so the animated AppBackdrop (see app.dart) shows through.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: cs.surface,
      textTheme: textTheme,
      pageTransitionsTheme: HarvestPageTransitions.theme,
      iconTheme: IconThemeData(color: cs.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: bg.withValues(alpha: 0.88),
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: cs.onSurface),
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: cs.outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: cs.primary, width: 1.5),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
        prefixIconColor: cs.onSurfaceVariant,
        suffixIconColor: cs.onSurfaceVariant,
        border: inputBorder(cs.outline),
        enabledBorder: inputBorder(cs.outline),
        focusedBorder: inputBorder(cs.primary, 2.0),
        errorBorder: inputBorder(cs.error),
        focusedErrorBorder: inputBorder(cs.error, 2.0),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fill,
        selectedColor: cs.primaryContainer,
        side: BorderSide(color: cs.outline),
        shape: const StadiumBorder(),
        labelStyle: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: cs.primaryContainer,
        elevation: 0,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? cs.primary
                : cs.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: r28),
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          color: cs.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: r16),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: r16),
        textStyle: GoogleFonts.manrope(color: cs.onSurface),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: cs.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: r16),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? cs.onPrimary : cs.outline),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? cs.primary
                : cs.surfaceContainerHighest),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.outline,
      ),
      dividerTheme: DividerThemeData(color: cs.outline, thickness: 1),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: cs.primary,
        selectionColor: cs.primary.withValues(alpha: 0.3),
        selectionHandleColor: cs.primary,
      ),
    );
  }
}
