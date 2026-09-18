import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import 'package:farmer_market_app/core/routing/route_names.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/buttons/google_sign_in_button.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';

/// Screen for authenticating existing users with email and password.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isLoading || _isSubmitting) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(authNotifierProvider.notifier).signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (!success) {
        final error = ref.read(authNotifierProvider).errorMessage ?? 'Login failed. Please check your credentials.';
        AppSnackBar.show(context, message: error, type: SnackBarType.error);
      } else {
        _emailController.clear();
        _passwordController.clear();
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isLoading || _isSubmitting) return;

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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.agriculture_rounded, color: colorScheme.primary, size: 36),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.login,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  context.l10n.welcomeMessage,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                        label: context.l10n.email,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: context.l10n.password,
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.go(RouteNames.forgotPassword),
                          child: Text(
                            context.l10n.forgotPassword,
                            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: context.l10n.login,
                        isLoading: authState.isLoading || _isSubmitting,
                        onPressed: _handleLogin,
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
                          onPressed: () => context.go(RouteNames.register),
                          child: Text(
                            context.l10n.dontHaveAccount,
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
    );
  }
}
