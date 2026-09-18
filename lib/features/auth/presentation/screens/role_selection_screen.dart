import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/animations/animated_pressable.dart';
import 'package:farmer_market_app/core/animations/fade_slide_transition.dart';
import 'package:farmer_market_app/core/constants/app_radius.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';

/// Screen allowing new authenticated users to select Farmer vs Buyer role.
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selectedRole;

  Future<void> _handleConfirmRole() async {
    if (_selectedRole == null) return;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .selectRole(_selectedRole!);

    if (!success && mounted) {
      final error = ref.read(authNotifierProvider).errorMessage ?? 'Failed to update role';
      AppSnackBar.show(context, message: error, type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.selectRoleTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FadeSlideTransition(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.selectRoleTitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.selectRoleSubtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Farmer Role Option
                AnimatedPressable(
                  onTap: () => setState(() => _selectedRole = UserRole.farmer),
                  child: AppCard(
                    borderColor: _selectedRole == UserRole.farmer
                        ? colorScheme.primary
                        : colorScheme.outline,
                    backgroundColor: _selectedRole == UserRole.farmer
                        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : colorScheme.surface,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: AppRadius.borderMd,
                          ),
                          child: Icon(Icons.agriculture_rounded, color: colorScheme.primary, size: 36),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.farmerOptionTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                context.l10n.farmerOptionSubtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _selectedRole == UserRole.farmer
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: _selectedRole == UserRole.farmer
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Buyer Role Option
                AnimatedPressable(
                  onTap: () => setState(() => _selectedRole = UserRole.buyer),
                  child: AppCard(
                    borderColor: _selectedRole == UserRole.buyer
                        ? colorScheme.secondary
                        : colorScheme.outline,
                    backgroundColor: _selectedRole == UserRole.buyer
                        ? colorScheme.secondaryContainer.withValues(alpha: 0.5)
                        : colorScheme.surface,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: AppRadius.borderMd,
                          ),
                          child: Icon(Icons.storefront_rounded, color: colorScheme.secondary, size: 36),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.buyerOptionTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                context.l10n.buyerOptionSubtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _selectedRole == UserRole.buyer
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: _selectedRole == UserRole.buyer
                              ? colorScheme.secondary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                AppButton(
                  label: context.l10n.saveProfile,
                  isLoading: authState.isLoading,
                  onPressed: _selectedRole != null ? _handleConfirmRole : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
