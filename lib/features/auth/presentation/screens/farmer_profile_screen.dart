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

/// Screen for completing farmer profile, location, and farm details.
class FarmerProfileScreen extends ConsumerStatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  ConsumerState<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends ConsumerState<FarmerProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _stateController;
  late TextEditingController _districtController;
  late TextEditingController _villageController;
  late TextEditingController _landSizeController;
  late TextEditingController _cropController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
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
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final profile = ref.read(authNotifierProvider).profile;
      if (profile != null) {
        _nameController.text = profile.fullName;
        _phoneController.text = profile.phone ?? '';
        if (profile.state != null && profile.state!.isNotEmpty) {
          _stateController.text = profile.state!;
        }
        _districtController.text = profile.district ?? '';
        _villageController.text = profile.village ?? '';
        _landSizeController.text = profile.landSizeAcres?.toString() ?? '';
        _cropController.text = profile.primaryCrop ?? '';
        _latitudeController.text = profile.latitude?.toString() ?? '';
        _longitudeController.text = profile.longitude?.toString() ?? '';
        _selectedLanguage = profile.language.isNotEmpty ? profile.language : 'en';
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
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final currentProfile = ref.read(authNotifierProvider).profile;
    if (currentProfile == null) return;

    final latText = _latitudeController.text.trim();
    final lngText = _longitudeController.text.trim();
    final latitude = latText.isEmpty ? null : double.tryParse(latText);
    final longitude = lngText.isEmpty ? null : double.tryParse(lngText);
    if ((latText.isEmpty) != (lngText.isEmpty) ||
        (latitude != null && (!latitude.isFinite || latitude < -90 || latitude > 90)) ||
        (longitude != null && (!longitude.isFinite || longitude < -180 || longitude > 180))) {
      AppSnackBar.show(context, message: 'Enter valid latitude and longitude together, or leave both empty.', type: SnackBarType.error);
      return;
    }

    ref.read(localeControllerProvider.notifier).setLocale(_selectedLanguage);

    final updatedProfile = currentProfile.copyWith(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      language: _selectedLanguage,
      state: _stateController.text.trim(),
      district: _districtController.text.trim(),
      village: _villageController.text.trim(),
      landSizeAcres: double.tryParse(_landSizeController.text.trim()),
      primaryCrop: _cropController.text.trim(),
      latitude: latitude,
      longitude: longitude,
      isProfileComplete: true,
    );

    final success = await ref
        .read(authNotifierProvider.notifier)
        .updateProfile(updatedProfile);

    if (!success && mounted) {
      final error = ref.read(authNotifierProvider).errorMessage ?? context.l10n.failedToSaveProfile;
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
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(Icons.agriculture_rounded, color: colorScheme.primary, size: 32),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.farmerProfileSetupTitle,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                context.l10n.completeFarmContactInfo,
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: context.l10n.fullName,
                      controller: _nameController,
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (v) => v == null || v.trim().isEmpty ? context.l10n.fullNameRequired : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: context.l10n.phone,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return context.l10n.phoneNumberRequired;
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) return context.l10n.enterValid10DigitMobile;
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppDropdownFormField<String>(
                      label: context.l10n.preferredLanguage,
                      value: _selectedLanguage,
                      items: [
                        DropdownMenuItem(value: 'en', child: Text(context.l10n.english)),
                        DropdownMenuItem(value: 'hi', child: Text(context.l10n.hindi)),
                        DropdownMenuItem(value: 'gu', child: Text(context.l10n.gujarati)),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLanguage = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: context.l10n.state,
                      controller: _stateController,
                      validator: (v) => v == null || v.trim().isEmpty ? context.l10n.stateRequired : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: context.l10n.district,
                      controller: _districtController,
                      hint: 'e.g. Anand, Rajkot, Junagadh',
                      validator: (v) => v == null || v.trim().isEmpty ? context.l10n.districtRequired : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: context.l10n.village,
                      controller: _villageController,
                      hint: context.l10n.enterYourVillageName,
                      validator: (v) => v == null || v.trim().isEmpty ? context.l10n.villageRequired : null,
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
                      label: 'Map Latitude (optional)',
                      controller: _latitudeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      hint: 'e.g. 22.123456',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Map Longitude (optional)',
                      controller: _longitudeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      hint: 'e.g. 70.123456',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: context.l10n.primaryCrop,
                      controller: _cropController,
                      hint: 'e.g. Wheat, Cotton, Mustard, Groundnut',
                      validator: (v) => v == null || v.trim().isEmpty ? context.l10n.primaryCropRequired : null,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppButton(
                      label: context.l10n.saveProfile,
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
