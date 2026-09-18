import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmer_market_app/core/animations/fade_slide_transition.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import 'package:farmer_market_app/core/routing/route_names.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/buttons/google_sign_in_button.dart';
import 'package:farmer_market_app/core/widgets/dropdowns/app_dropdown.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';

/// Screen for new user registration and account creation.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole? _selectedRole;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final authNotifier = ref.read(authNotifierProvider);
    if (authNotifier.isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedRole == null) {
      AppSnackBar.show(context, message: 'Please select an account type', type: SnackBarType.error);
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole!,
        );

    if (!success && mounted) {
      final error = ref.read(authNotifierProvider).errorMessage ?? 'Registration failed';
      AppSnackBar.show(context, message: error, type: SnackBarType.error);
    }
  }

  Future<void> _handleGoogleLogin() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isLoading) return;

    final success = await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (!success && mounted) {
      final error = ref.read(authNotifierProvider).errorMessage ?? 'Google authentication failed.';
      AppSnackBar.show(context, message: error, type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.register),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.login),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FadeSlideTransition(
              child: Form(
                key: _formKey,
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.register,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        context.l10n.tagline,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (authState.errorMessage != null && authState.errorMessage!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.rejectedBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  authState.errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      AppTextField(
                        label: context.l10n.fullName,
                        controller: _nameController,
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          if (v.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: context.l10n.email,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(v.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: context.l10n.phone,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          final phoneRegex = RegExp(r'^[6-9]\d{9}$');
                          if (!phoneRegex.hasMatch(v.trim())) {
                            return 'Enter valid 10-digit Indian mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownFormField<UserRole>(
                        label: 'Account Type',
                        value: _selectedRole,
                        hint: 'Select Account Type',
                        items: [
                          DropdownMenuItem(
                            value: UserRole.farmer,
                            child: Row(
                              children: [
                                Icon(Icons.agriculture_rounded, size: 20, color: colorScheme.primary),
                                const SizedBox(width: AppSpacing.xs),
                                Text(context.l10n.farmerRole),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: UserRole.buyer,
                            child: Row(
                              children: [
                                Icon(Icons.storefront_rounded, size: 20, color: colorScheme.secondary),
                                const SizedBox(width: AppSpacing.xs),
                                Text(context.l10n.buyerRole),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (UserRole? role) {
                          setState(() {
                            _selectedRole = role;
                          });
                        },
                        validator: (role) {
                          if (role == null) {
                            return 'Please select an account type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: context.l10n.password,
                        controller: _passwordController,
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (v.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Confirm Password',
                        controller: _confirmPasswordController,
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (v != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: 'Create Account',
                        isLoading: authState.isLoading,
                        onPressed: _handleRegister,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.3))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.3))),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      GoogleSignInButton(
                        isLoading: authState.isLoading,
                        onPressed: _handleGoogleLogin,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go(RouteNames.login),
                          child: Text(
                            context.l10n.alreadyHaveAccount,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
