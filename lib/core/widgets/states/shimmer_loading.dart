import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_constants.dart';

/// Reusable shimmer loader for asynchronous card and list skeletons.
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
    return Shimmer.fromColors(
      baseColor: AppColors.borderLight,
      highlightColor: AppColors.surfaceLight,
      period: AppConstants.shimmerDuration,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
