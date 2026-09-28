import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/routing/route_names.dart';
import 'package:farmer_market_app/core/widgets/app_bar/app_top_bar.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/dropdowns/app_dropdown.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_currency_field.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_providers.dart';
import 'package:farmer_market_app/features/farmer/presentation/widgets/quality_tag_selector.dart';

class AddProduceScreen extends ConsumerStatefulWidget {
  const AddProduceScreen({super.key});

  @override
  ConsumerState<AddProduceScreen> createState() => _AddProduceScreenState();
}

class _AddProduceScreenState extends ConsumerState<AddProduceScreen> {
  static const int _maxImages = 5;

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lowStockController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  String _selectedCategory = 'Cereals';
  String _selectedUnit = 'quintal';
  List<String> _qualityTags = [];
  final List<XFile> _images = [];
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
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
    _lowStockController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) {
      AppSnackBar.show(
        context,
        message: 'You can add up to $_maxImages photos.',
        type: SnackBarType.error,
      );
      return;
    }
    try {
      final picked = await _imagePicker.pickMultiImage(imageQuality: 80, limit: remaining);
      if (picked.isEmpty || !mounted) return;
      setState(() => _images.addAll(picked.take(remaining)));
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Could not open the photo gallery.', type: SnackBarType.error);
    }
  }

  Future<void> _pinCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Location services are disabled. Please turn on GPS.';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permission denied.';
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      AppSnackBar.show(context, message: 'Location pinned on this listing.', type: SnackBarType.success);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: e is String ? e : 'Could not fetch your location.',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _submitProduce() async {
    if (_isSubmitting || ref.read(produceControllerProvider).isSubmitting) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(authNotifierProvider).profile;
    if (user == null) {
      AppSnackBar.show(context, message: 'Authentication required', type: SnackBarType.error);
      return;
    }

    setState(() => _isSubmitting = true);

    // Upload photos first so the listing is only created with working URLs.
    final imageUrls = <String>[];
    final repository = ref.read(farmerRepositoryProvider);
    for (final image in _images) {
      final uploadResult = await repository.uploadProduceImage(
        farmerId: user.id,
        file: File(image.path),
      );
      if (!mounted) return;
      String? uploadError;
      uploadResult.fold((f) => uploadError = f.message, imageUrls.add);
      if (uploadError != null) {
        setState(() => _isSubmitting = false);
        AppSnackBar.show(
          context,
          message: 'Photo upload failed: $uploadError',
          type: SnackBarType.error,
        );
        return;
      }
    }

    final lowStock = double.tryParse(_lowStockController.text.trim());

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
      imageUrls: imageUrls,
      qualityTags: _qualityTags,
      lowStockThreshold: lowStock,
      latitude: _latitude,
      longitude: _longitude,
    );

    final success = await ref
        .read(produceControllerProvider.notifier)
        .addProduce(produce);

    if (!mounted) return;

    if (success) {
      ref.read(farmerDashboardNotifierProvider.notifier).refreshDashboard();
      AppSnackBar.show(context, message: 'Produce listed successfully!', type: SnackBarType.success);
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
        title: 'Add Produce Listing',
        actions: [
          IconButton(
            tooltip: 'Bulk upload (CSV)',
            icon: const Icon(Icons.upload_file_rounded),
            onPressed: () => context.push(RouteNames.bulkUploadProduce),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'List Your Crop Produce',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Provide accurate crop details so interested buyers can make offers.',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Produce Name
              AppTextField(
                label: 'Crop / Produce Name',
                hint: 'e.g. Sharbati Wheat, Desi Chana, Tomatoes',
                controller: _nameController,
                prefixIcon: Icon(Icons.eco_rounded, color: colorScheme.primary),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter crop produce name';
                  }
                  if (val.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Category Dropdown
              AppDropdownFormField<String>(
                label: 'Produce Category',
                value: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
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
                      label: 'Available Quantity',
                      hint: 'e.g. 50',
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icon(Icons.scale_rounded, color: colorScheme.primary),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter quantity';
                        }
                        final numVal = double.tryParse(val.trim());
                        if (numVal == null || numVal <= 0) {
                          return 'Enter valid quantity';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 1,
                    child: AppDropdownFormField<String>(
                      label: 'Unit',
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

              // Low stock alert threshold
              AppTextField(
                label: 'Low Stock Alert Below (Optional)',
                hint: 'e.g. 10 - get notified when stock drops below this',
                controller: _lowStockController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icon(Icons.notifications_active_outlined, color: colorScheme.primary),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal < 0) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Expected Price
              AppCurrencyField(
                label: 'Expected Price (₹ per $_selectedUnit)',
                hint: '2450',
                unitSuffix: '/ $_selectedUnit',
                controller: _priceController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter expected price';
                  }
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) {
                    return 'Enter valid positive price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Location
              AppTextField(
                label: 'Harvest / Pickup Location',
                hint: 'e.g. Vasad, Anand, Gujarat',
                controller: _locationController,
                prefixIcon: Icon(Icons.location_on_outlined, color: colorScheme.primary),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: _latitude == null ? 'Pin Current Location on Map' : 'Location Pinned ✓',
                icon: Icons.my_location,
                style: AppButtonStyle.outlined,
                isLoading: _isLocating,
                onPressed: _pinCurrentLocation,
              ),
              const SizedBox(height: AppSpacing.md),

              // Quality tags
              QualityTagSelector(
                selectedTags: _qualityTags,
                onChanged: (tags) => setState(() => _qualityTags = tags),
              ),
              const SizedBox(height: AppSpacing.md),

              // Photos
              Text(
                'Photos (up to $_maxImages)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 92,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    InkWell(
                      onTap: _pickImages,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 92,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outline),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: colorScheme.primary),
                            const SizedBox(height: 4),
                            Text(
                              'Add',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ..._images.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(entry.value.path),
                                width: 92,
                                height: 92,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => setState(() => _images.removeAt(entry.key)),
                                child: const CircleAvatar(
                                  radius: 11,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Description
              AppTextField(
                label: 'Additional Quality Details (Optional)',
                hint: 'e.g. Organic certified, Grade A quality, harvested last week',
                controller: _descriptionController,
                maxLines: 3,
                prefixIcon: Icon(Icons.notes_rounded, color: colorScheme.primary),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              AppButton(
                label: 'Publish Listing',
                icon: Icons.check_circle_outline_rounded,
                isLoading: state.isSubmitting || _isSubmitting,
                onPressed: _submitProduce,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
