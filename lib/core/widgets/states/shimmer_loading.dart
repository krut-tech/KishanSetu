import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_constants.dart';

/// Reusable shimmer loader for asynchronous card and list skeletons.
/// Theme-aware: dark skeletons on the dark theme (the old light-only colours
/// flashed bright white blocks while loading).
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppConstants.borderRadiusSmall,
  });

  factory ShimmerLoading.card({double height = 120}) {
    return ShimmerLoading(
      width: double.infinity,
      height: height,
      borderRadius: AppConstants.borderRadiusMedium,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1B3324) : AppColors.borderLight;
    final highlight = isDark ? const Color(0xFF2A4A35) : AppColors.surfaceLight;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: AppConstants.shimmerDuration,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
