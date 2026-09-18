import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_radius.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';

enum AppStatusType {
  pending,
  accepted,
  rejected,
  expired,
  inTransit,
  completed,
  active,
  draft,
}

/// Reusable status badge with visual state indicators for offers and orders.
class AppStatusBadge extends StatelessWidget {
  final AppStatusType type;
  final String? customLabel;

  const AppStatusBadge({
    super.key,
    required this.type,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (type) {
      case AppStatusType.pending:
        bg = isDark ? const Color(0xFF78350F) : AppColors.pendingBg;
        fg = isDark ? const Color(0xFFFBBF24) : AppColors.pendingFg;
        label = customLabel ?? 'Pending';
        icon = Icons.hourglass_top_rounded;
        break;
      case AppStatusType.accepted:
        bg = isDark ? const Color(0xFF14532D) : AppColors.acceptedBg;
        fg = isDark ? const Color(0xFF4ADE80) : AppColors.acceptedFg;
        label = customLabel ?? 'Accepted';
        icon = Icons.check_circle_outline_rounded;
        break;
      case AppStatusType.rejected:
        bg = isDark ? const Color(0xFF7F1D1D) : AppColors.rejectedBg;
        fg = isDark ? const Color(0xFFF87171) : AppColors.rejectedFg;
        label = customLabel ?? 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      case AppStatusType.expired:
        bg = isDark ? AppColors.borderDark : AppColors.expiredBg;
        fg = isDark ? AppColors.textSecondaryDark : AppColors.expiredFg;
        label = customLabel ?? 'Expired';
        icon = Icons.timer_off_outlined;
        break;
      case AppStatusType.inTransit:
        bg = isDark ? const Color(0xFF0C4A6E) : AppColors.inTransitBg;
        fg = isDark ? const Color(0xFF38BDF8) : AppColors.inTransitFg;
        label = customLabel ?? 'In Transit';
        icon = Icons.local_shipping_outlined;
        break;
      case AppStatusType.completed:
        bg = isDark ? const Color(0xFF064E3B) : AppColors.completedBg;
        fg = isDark ? const Color(0xFF34D399) : AppColors.completedFg;
        label = customLabel ?? 'Completed';
        icon = Icons.task_alt_rounded;
        break;
      case AppStatusType.active:
        bg = isDark ? const Color(0xFF064E3B) : AppColors.activeBg;
        fg = isDark ? const Color(0xFF10B981) : AppColors.activeFg;
        label = customLabel ?? 'Active';
        icon = Icons.radio_button_checked_rounded;
        break;
      case AppStatusType.draft:
        bg = isDark ? AppColors.borderDark : AppColors.draftBg;
        fg = isDark ? AppColors.textSecondaryDark : AppColors.draftFg;
        label = customLabel ?? 'Draft';
        icon = Icons.edit_note_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.borderPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
