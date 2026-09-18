import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';

enum PriceTrend { up, down, stable, none }

/// Formats currency with Indian rupee formatting, units, and trend indicators.
class AppPriceText extends StatelessWidget {
  final double price;
  final String unit;
  final TextStyle? priceStyle;
  final PriceTrend trend;
  final bool isNetRealization;

  const AppPriceText({
    super.key,
    required this.price,
    this.unit = 'quintal',
    this.priceStyle,
    this.trend = PriceTrend.none,
    this.isNetRealization = false,
  });

  String _formatIndianCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedPrice = _formatIndianCurrency(price);

    Widget trendIcon = const SizedBox.shrink();
    if (trend == PriceTrend.up) {
      trendIcon = Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: Icon(Icons.arrow_upward_rounded, size: 16, color: isDark ? const Color(0xFF4ADE80) : AppColors.success),
      );
    } else if (trend == PriceTrend.down) {
      trendIcon = Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: Icon(Icons.arrow_downward_rounded, size: 16, color: isDark ? const Color(0xFFF87171) : AppColors.error),
      );
    }

    final defaultStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: isNetRealization
          ? (isDark ? const Color(0xFF34D399) : AppColors.netRealizationBadge)
          : colorScheme.onSurface,
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            formattedPrice,
            style: priceStyle ?? defaultStyle,
          ),
          if (unit.isNotEmpty) ...[
            Text(
              ' / $unit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          trendIcon,
        ],
      ),
    );
  }
}
