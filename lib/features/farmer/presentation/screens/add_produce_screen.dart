import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_bar/app_top_bar.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/dropdowns/app_dropdown.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_currency_field.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_providers.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';

class AddProduceScreen extends ConsumerStatefulWidget {
  const AddProduceScreen({super.key});

  @override
  ConsumerState<AddProduceScreen> createState() => _AddProduceScreenState();
}

class _AddProduceScreenState extends ConsumerState<AddProduceScreen> {
  /// Display label for a category dropdown item. The English value stays
  /// what is stored/sent to the backend; only the label is localized.
  String _categoryLabel(String cat) {
    switch (cat) {
      case 'Cereals':
        return context.l10n.cerealsCategory;
      case 'Pulses':
        return context.l10n.pulsesCategory;
      case 'Vegetables':
        return context.l10n.vegetablesCategory;
      case 'Fruits':
        return context.l10n.fruitsCategory;
      case 'Oilseeds':
        return context.l10n.oilseedsCategory;
      case 'Spices':
        return context.l10n.spicesCategory;
      case 'Cotton & Fiber':
        return context.l10n.cottonFiberCategory;
      case 'Other':
        return context.l10n.otherCategory;
      default:
        return cat;
    }
  }
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Cereals';
  String _selectedUnit = 'quintal';
  bool _isSubmitting = false;

  static const List<String> _categories = [
    'Cereals',
    'Pulses',
    'Vegetables',
    'Fruits',
    'Oilseeds',
    'Spices',
    'Cotton & Fiber',
    'Other',
  ];

  static const List<String> _units = [
    'kg',
    'quintal',
    'ton',
    'crate',
    'bag',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(authNotifierProvider).profile;
      if (profile != null) {
        final locParts = [profile.village, profile.district, profile.state]
            .where((s) => s != null && s.trim().isNotEmpty)
            .join(', ');
        if (locParts.isNotEmpty) {
          _locationController.text = locParts;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitProduce() async {
    if (_isSubmitting || ref.read(produceControllerProvider).isSubmitting) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(authNotifierProvider).profile;
    if (user == null) {
      AppSnackBar.show(context, message: context.l10n.authenticationRequired, type: SnackBarType.error);
      return;
    }

    setState(() => _isSubmitting = true);

    final produce = ProduceModel(
      id: '',
      farmerId: user.id,
      name: _nameController.text.trim(),
      category: _selectedCategory,
      quantity: double.parse(_quantityController.text.trim()),
      unit: _selectedUnit,
      expectedPrice: double.parse(_priceController.text.trim()),
      status: 'active',
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    final success = await ref
        .read(produceControllerProvider.notifier)
        .addProduce(produce);

    if (!mounted) return;

    if (success) {
      ref.read(farmerDashboardNotifierProvider.notifier).refreshDashboard();
      AppSnackBar.show(context, message: context.l10n.produceListedSuccessfully, type: SnackBarType.success);
      context.pop();
    } else {
      setState(() => _isSubmitting = false);
      final error = ref.read(produceControllerProvider).errorMessage;
      if (error != null) {
        AppSnackBar.show(context, message: error, type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(produceControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppTopBar(
        title: context.l10n.addProduceListingTitle,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.listYourCropProduce,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.provideAccurateCropDetails,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Produce Name
              AppTextField(
                label: context.l10n.cropProduceNameLabel,
                hint: 'e.g. Sharbati Wheat, Desi Chana, Tomatoes',
                controller: _nameController,
                prefixIcon: Icon(Icons.eco_rounded, color: colorScheme.primary),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return context.l10n.pleaseEnterCropName;
                  }
                  if (val.trim().length < 2) {
                    return context.l10n.nameMinTwoChars;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Category Dropdown
              AppDropdownFormField<String>(
                label: context.l10n.produceCategoryLabel,
                value: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(_categoryLabel(c))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Quantity & Unit
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      label: context.l10n.availableQuantityLabel,
                      hint: 'e.g. 50',
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icon(Icons.scale_rounded, color: colorScheme.primary),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return context.l10n.enterQuantity;
                        }
                        final numVal = double.tryParse(val.trim());
                        if (numVal == null || numVal <= 0) {
                          return context.l10n.enterValidQuantityLabel;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 1,
                    child: AppDropdownFormField<String>(
                      label: context.l10n.unitLabel,
                      value: _selectedUnit,
                      items: _units
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Expected Price
              AppCurrencyField(
                label: '${context.l10n.expectedPriceLabel} (₹ per $_selectedUnit)',
                hint: '2450',
                unitSuffix: '/ $_selectedUnit',
                controller: _priceController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return context.l10n.pleaseEnterExpectedPrice;
                  }
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) {
                    return context.l10n.enterValidPositivePrice;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Location
              AppTextField(
                label: context.l10n.harvestPickupLocation,
                hint: 'e.g. Vasad, Anand, Gujarat',
                controller: _locationController,
                prefixIcon: Icon(Icons.location_on_outlined, color: colorScheme.primary),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return context.l10n.pleaseEnterLocation;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Description
              AppTextField(
                label: context.l10n.additionalQualityDetailsOptional,
                hint: 'e.g. Organic certified, Grade A quality, harvested last week',
                controller: _descriptionController,
                maxLines: 3,
                prefixIcon: Icon(Icons.notes_rounded, color: colorScheme.primary),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              AppButton(
                label: context.l10n.publishListing,
                icon: Icons.check_circle_outline_rounded,
                isLoading: state.isSubmitting,
                onPressed: _submitProduce,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
