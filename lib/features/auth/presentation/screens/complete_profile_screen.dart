import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/animations/animated_pressable.dart';
import 'package:farmer_market_app/core/animations/fade_slide_transition.dart';
import 'package:farmer_market_app/core/constants/app_radius.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/localization/locale_controller.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/dropdowns/app_dropdown.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';

/// Progressive multi-step screen for completing profile after Google / Auth login.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  int _currentStep = 0; // 0: Select Account Type, 1: Details
  UserRole? _selectedRole;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _stateController;
  late TextEditingController _districtController;
  late TextEditingController _villageController;
  late TextEditingController _landSizeController;
  late TextEditingController _cropController;

  late TextEditingController _companyNameController;
  late TextEditingController _gstController;
  late TextEditingController _capacityController;
  late TextEditingController _buyerStateController;
  late TextEditingController _buyerDistrictController;

  String _businessType = 'Wholesaler / Trader';
  String _selectedLanguage = 'en';
  final _formKey = GlobalKey<FormState>();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _stateController = TextEditingController(text: 'Gujarat');
    _districtController = TextEditingController();
    _villageController = TextEditingController();
    _landSizeController = TextEditingController();
    _cropController = TextEditingController();

    _companyNameController = TextEditingController();
    _gstController = TextEditingController();
    _capacityController = TextEditingController();
    _buyerStateController = TextEditingController(text: 'Gujarat');
    _buyerDistrictController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final authState = ref.read(authNotifierProvider).state;
      final profile = authState.profile;
      final user = authState.user;

      final googleName = user?.userMetadata?['full_name'] as String? ??
          user?.userMetadata?['name'] as String? ??
          profile?.fullName ??
          '';

      _nameController.text = googleName;

      if (profile != null) {
        if (profile.fullName.isNotEmpty) _nameController.text = profile.fullName;
        _phoneController.text = profile.phone ?? '';
        if (profile.state != null && profile.state!.isNotEmpty) {
          _stateController.text = profile.state!;
          _buyerStateController.text = profile.state!;
        }
        _districtController.text = profile.district ?? '';
        _buyerDistrictController.text = profile.district ?? '';
        _villageController.text = profile.village ?? '';
        _landSizeController.text = profile.landSizeAcres?.toString() ?? '';
        _cropController.text = profile.primaryCrop ?? '';

        _companyNameController.text = profile.companyName ?? '';
        _gstController.text = profile.gstNumber ?? '';
        _capacityController.text = profile.buyingCapacityQuintals?.toString() ?? '';
        if (profile.businessType != null && profile.businessType!.isNotEmpty) {
          _businessType = profile.businessType!;
        }
        _selectedLanguage = profile.language.isNotEmpty ? profile.language : 'en';

        if (profile.role != null) {
          _selectedRole = profile.role;
        }
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _villageController.dispose();
    _landSizeController.dispose();
    _cropController.dispose();

    _companyNameController.dispose();
    _gstController.dispose();
    _capacityController.dispose();
    _buyerStateController.dispose();
    _buyerDistrictController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedRole == null) return;

    final user = ref.read(authNotifierProvider).state.user;
    if (user == null) return;

    final profile = ref.read(authNotifierProvider).profile;
    final googleAvatar = user.userMetadata?['avatar_url'] as String? ??
        user.userMetadata?['picture'] as String?;

    ref.read(localeControllerProvider.notifier).setLocale(_selectedLanguage);

    final updatedProfile = UserProfile(
      id: user.id,
      role: _selectedRole,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      avatarUrl: profile?.avatarUrl ?? googleAvatar,
      language: _selectedLanguage,
      state: _selectedRole == UserRole.farmer
          ? _stateController.text.trim()
          : _buyerStateController.text.trim(),
      district: _selectedRole == UserRole.farmer
          ? _districtController.text.trim()
          : _buyerDistrictController.text.trim(),
      village: _selectedRole == UserRole.farmer ? _villageController.text.trim() : null,
      landSizeAcres: _selectedRole == UserRole.farmer
          ? double.tryParse(_landSizeController.text.trim())
          : null,
      primaryCrop: _selectedRole == UserRole.farmer ? _cropController.text.trim() : null,
      companyName: _selectedRole == UserRole.buyer ? _companyNameController.text.trim() : null,
      gstNumber: _selectedRole == UserRole.buyer ? _gstController.text.trim() : null,
      businessType: _selectedRole == UserRole.buyer ? _businessType : null,
      buyingCapacityQuintals: _selectedRole == UserRole.buyer
          ? double.tryParse(_capacityController.text.trim())
          : null,
      isProfileComplete: true,
    );

    final success = await ref
        .read(authNotifierProvider.notifier)
        .updateProfile(updatedProfile);

    if (!success && mounted) {
      final error = ref.read(authNotifierProvider).errorMessage ?? 'Failed to save profile';
      AppSnackBar.show(context, message: error, type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final profile = authState.profile;
    final colorScheme = Theme.of(context).colorScheme;

    final avatarUrl = profile?.avatarUrl ??
        user?.userMetadata?['avatar_url'] as String? ??
        user?.userMetadata?['picture'] as String?;
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FadeSlideTransition(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Indicator Header
                  Row(
                    children: [
                      _StepBadge(stepNumber: 1, label: 'Account Type', isActive: _currentStep == 0, isDone: _currentStep > 0),
                      const Expanded(child: Divider(indent: 8, endIndent: 8)),
                      _StepBadge(stepNumber: 2, label: 'Profile Details', isActive: _currentStep == 1, isDone: false),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (_currentStep == 0) ...[
                    // Step 1: Select Account Type
                    Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tell us a little about yourself to personalize your KisanSetu experience.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Farmer Role Card
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
                                  Row(
                                    children: [
                                      Text(
                                        '🌾 Farmer',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Sell produce and discover market prices.',
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

                    // Buyer Role Card
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
                                    '🏢 Buyer',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Discover produce and connect with farmers.',
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
                      label: 'Continue →',
                      onPressed: _selectedRole != null
                          ? () => setState(() => _currentStep = 1)
                          : null,
                    ),
                  ] else ...[
                    // Step 2: Complete Personal / Business Information
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => setState(() => _currentStep = 0),
                        ),
                        Text(
                          _selectedRole == UserRole.farmer
                              ? 'Complete Your Farmer Profile'
                              : 'Complete Your Buyer Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // User Google Info Card
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: colorScheme.primaryContainer,
                            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Icon(Icons.person_rounded, color: colorScheme.primary, size: 28)
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Google Account',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text
                                      : 'Google User',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                if (email.isNotEmpty)
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    AppTextField(
                      label: context.l10n.fullName,
                      controller: _nameController,
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Full name is required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      label: context.l10n.phone,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Phone number is required';
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) {
                          return 'Enter valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppDropdownFormField<String>(
                      label: 'Preferred Language',
                      value: _selectedLanguage,
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'hi', child: Text('Hindi (हिंदी)')),
                        DropdownMenuItem(value: 'gu', child: Text('Gujarati (ગુજરાતી)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLanguage = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (_selectedRole == UserRole.farmer) ...[
                      // Farmer Profile Fields
                      AppTextField(
                        label: context.l10n.state,
                        controller: _stateController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'State is required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: context.l10n.district,
                        controller: _districtController,
                        hint: 'e.g. Anand, Rajkot, Junagadh',
                        validator: (v) => v == null || v.trim().isEmpty ? 'District is required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: context.l10n.village,
                        controller: _villageController,
                        hint: 'Enter your village name',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Village is required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: '${context.l10n.landSize} (Farming Experience)',
                        controller: _landSizeController,
                        keyboardType: TextInputType.number,
                        hint: 'e.g. 5.5 Acres',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: context.l10n.primaryCrop,
                        controller: _cropController,
                        hint: 'e.g. Wheat, Cotton, Mustard, Groundnut',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Primary crop is required' : null,
                      ),
                    ] else ...[
                      // Buyer Profile Fields
                      AppTextField(
                        label: context.l10n.companyName,
                        controller: _companyNameController,
                        hint: 'e.g. Patel Agro Traders',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Company name is required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownFormField<String>(
                        label: context.l10n.businessType,
                        value: _businessType,
                        items: const [
                          DropdownMenuItem(value: 'Wholesaler / Trader', child: Text('Wholesaler / Trader')),
                          DropdownMenuItem(value: 'Processor / Mill Owner', child: Text('Processor / Mill Owner')),
                          DropdownMenuItem(value: 'Exporter', child: Text('Exporter')),
                          DropdownMenuItem(value: 'Retailer', child: Text('Retailer')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _businessType = val);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: context.l10n.state,
                        controller: _buyerStateController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'State is required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: context.l10n.district,
                        controller: _buyerDistrictController,
                        hint: 'Primary Mandi District / City',
                        validator: (v) => v == null || v.trim().isEmpty ? 'District / City is required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'GST Number (Optional)',
                        controller: _gstController,
                        hint: '24AAAAA0000A1Z5',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: context.l10n.buyingCapacity,
                        controller: _capacityController,
                        keyboardType: TextInputType.number,
                        hint: 'e.g. 500 Quintals',
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xxl),

                    AppButton(
                      label: context.l10n.saveProfile,
                      style: _selectedRole == UserRole.farmer
                          ? AppButtonStyle.primary
                          : AppButtonStyle.secondary,
                      isLoading: authState.isLoading,
                      onPressed: _handleSaveProfile,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int stepNumber;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepBadge({
    required this.stepNumber,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bg = isDone
        ? colorScheme.primary
        : (isActive ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest);
    final fg = isDone
        ? colorScheme.onPrimary
        : (isActive ? colorScheme.primary : colorScheme.onSurfaceVariant);

    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: bg,
          child: isDone
              ? Icon(Icons.check, size: 14, color: fg)
              : Text(
                  '$stepNumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
            color: isActive || isDone ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
