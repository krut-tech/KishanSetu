import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/animations/fade_slide_transition.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/localization/locale_controller.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/dropdowns/app_dropdown.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';

/// Screen for completing buyer company, contact, and procurement capacity details.
class BuyerProfileScreen extends ConsumerStatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  ConsumerState<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends ConsumerState<BuyerProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _companyNameController;
  late TextEditingController _gstController;
  late TextEditingController _capacityController;
  late TextEditingController _stateController;
  late TextEditingController _districtController;
  String _businessType = 'Wholesaler / Trader';
  String _selectedLanguage = 'en';
  final _formKey = GlobalKey<FormState>();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _companyNameController = TextEditingController();
    _gstController = TextEditingController();
    _capacityController = TextEditingController();
    _stateController = TextEditingController(text: 'Gujarat');
    _districtController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final profile = ref.read(authNotifierProvider).profile;
      if (profile != null) {
        _nameController.text = profile.fullName;
        _phoneController.text = profile.phone ?? '';
        _companyNameController.text = profile.companyName ?? '';
        _gstController.text = profile.gstNumber ?? '';
        _capacityController.text = profile.buyingCapacityQuintals?.toString() ?? '';
        if (profile.state != null && profile.state!.isNotEmpty) {
          _stateController.text = profile.state!;
        }
        _districtController.text = profile.district ?? '';
        if (profile.businessType != null && profile.businessType!.isNotEmpty) {
          _businessType = profile.businessType!;
        }
        _selectedLanguage = profile.language.isNotEmpty ? profile.language : 'en';
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _gstController.dispose();
    _capacityController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final currentProfile = ref.read(authNotifierProvider).profile;
    if (currentProfile == null) return;

    ref.read(localeControllerProvider.notifier).setLocale(_selectedLanguage);

    final updatedProfile = currentProfile.copyWith(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      companyName: _companyNameController.text.trim(),
      gstNumber: _gstController.text.trim(),
      businessType: _businessType,
      buyingCapacityQuintals: double.tryParse(_capacityController.text.trim()),
      state: _stateController.text.trim(),
      district: _districtController.text.trim(),
      language: _selectedLanguage,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.completeProfile),
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
            child: Form(
              key: _formKey,
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: colorScheme.secondaryContainer,
                          child: Icon(Icons.storefront_rounded, color: colorScheme.onSecondaryContainer, size: 32),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Buyer Profile Setup',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Provide business & contact details to connect with farmers',
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Contact Name / Full Name',
                      controller: _nameController,
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Contact name is required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: context.l10n.phone,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Phone number is required';
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) return 'Enter valid 10-digit mobile number';
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
                      controller: _stateController,
                      validator: (v) => v == null || v.trim().isEmpty ? 'State is required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: context.l10n.district,
                      controller: _districtController,
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
                    const SizedBox(height: AppSpacing.xxl),
                    AppButton(
                      label: context.l10n.saveProfile,
                      style: AppButtonStyle.secondary,
                      isLoading: authState.isLoading,
                      onPressed: _handleSaveProfile,
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
