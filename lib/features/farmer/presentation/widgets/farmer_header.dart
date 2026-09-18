import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_radius.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';

class FarmerHeader extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;

  const FarmerHeader({
    super.key,
    required this.profile,
    this.onNotificationPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final name = profile?.fullName.isNotEmpty == true ? profile!.fullName : 'Farmer';
    final locationParts = [
      profile?.village,
      profile?.district,
      profile?.state,
    ].where((s) => s != null && s.trim().isNotEmpty).join(', ');

    final locationText = locationParts.isNotEmpty ? locationParts : 'Location not set';

    return Row(
      children: [
        GestureDetector(
          onTap: onProfilePressed,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            backgroundImage: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                ? NetworkImage(profile!.avatarUrl!)
                : null,
            child: profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty
                ? Text(
                    name.characters.first.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFDCFCE7) : AppColors.primaryDark,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Namaste, $name 🙏',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: isDark ? const Color(0xFF4ADE80) : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      locationText,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryText,
                        fontWeight: FontWeight.w500,
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
          onPressed: onNotificationPressed,
          icon: Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              borderRadius: AppRadius.borderSm,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: isDark ? const Color(0xFF4ADE80) : AppColors.primary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}
