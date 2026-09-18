import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';

/// Top header banner displaying authenticated buyer business details.
class BuyerHeader extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;

  const BuyerHeader({
    super.key,
    this.profile,
    this.onNotificationPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final displayName = profile?.companyName ?? profile?.fullName ?? 'Buyer';
    final locationText = [
      if (profile?.district != null && profile!.district!.isNotEmpty) profile!.district,
      if (profile?.state != null && profile!.state!.isNotEmpty) profile!.state,
    ].join(', ');

    return Row(
      children: [
        GestureDetector(
          onTap: onProfilePressed,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            child: Icon(
              Icons.storefront_rounded,
              color: isDark ? const Color(0xFF4ADE80) : AppColors.primary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (locationText.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: secondaryText),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        locationText,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: onNotificationPressed,
        ),
      ],
    );
  }
}
