import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_bar/app_top_bar.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_providers.dart';

/// Lets a farmer list many crops at once by importing a CSV file.
class BulkUploadProduceScreen extends ConsumerStatefulWidget {
  const BulkUploadProduceScreen({super.key});

  @override
  ConsumerState<BulkUploadProduceScreen> createState() => _BulkUploadProduceScreenState();
}

class _BulkUploadProduceScreenState extends ConsumerState<BulkUploadProduceScreen> {
  static const String _sampleCsv =
      'name,category,quantity,unit,expected_price,location,description\n'
      'Sharbati Wheat,Cereals,50,quintal,2450,"Vasad, Anand",Grade A harvested last week\n'
      'Tomatoes,Vegetables,300,kg,18,"Anand, Gujarat",Fresh farm tomatoes\n';

  static const List<String> _validUnits = ['kg', 'quintal', 'ton', 'crate', 'bag'];
  static const List<String> _validCategories = [
    'Cereals',
    'Pulses',
    'Vegetables',
    'Fruits',
    'Oilseeds',
    'Spices',
    'Cotton & Fiber',
    'Other',
  ];

  String? _fileName;
  List<ProduceModel> _validRows = [];
  List<String> _errors = [];
  bool _isSubmitting = false;

  Future<void> _pickCsv() async {
    final farmerId = ref.read(authNotifierProvider).profile?.id;
    if (farmerId == null) {
      AppSnackBar.show(context, message: 'Authentication required', type: SnackBarType.error);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Could not read the selected file.', type: SnackBarType.error);
      return;
    }

    final content = utf8.decode(bytes, allowMalformed: true).replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    _parse(content, farmerId, file.name);
  }

  void _parse(String content, String farmerId, String fileName) {
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(content);
    final errors = <String>[];
    final valid = <ProduceModel>[];

    if (rows.length < 2) {
      setState(() {
        _fileName = fileName;
        _validRows = [];
        _errors = ['The file has no data rows. Use the sample format.'];
      });
      return;
    }

    final header = rows.first.map((c) => c.toString().trim().toLowerCase()).toList();
    int col(String name) => header.indexOf(name);
    final nameIdx = col('name');
    final qtyIdx = col('quantity');
    final priceIdx = col('expected_price');

    if (nameIdx < 0 || qtyIdx < 0 || priceIdx < 0) {
      setState(() {
        _fileName = fileName;
        _validRows = [];
        _errors = ['Header must include: name, quantity, expected_price (see sample).'];
      });
      return;
    }
    final catIdx = col('category');
    final unitIdx = col('unit');
    final locIdx = col('location');
    final descIdx = col('description');

    String cell(List<dynamic> row, int idx) =>
        (idx >= 0 && idx < row.length) ? row[idx].toString().trim() : '';

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((c) => c.toString().trim().isEmpty)) continue;
      final line = i + 1;

      final name = cell(row, nameIdx);
      final qty = double.tryParse(cell(row, qtyIdx));
      final price = double.tryParse(cell(row, priceIdx));
      var unit = cell(row, unitIdx).toLowerCase();
      var category = cell(row, catIdx);

      if (name.length < 2) {
        errors.add('Row $line: name is required (min 2 characters).');
        continue;
      }
      if (qty == null || qty <= 0) {
        errors.add('Row $line: quantity must be a positive number.');
        continue;
      }
      if (price == null || price <= 0) {
        errors.add('Row $line: expected_price must be a positive number.');
        continue;
      }
      if (unit.isEmpty) unit = 'kg';
      if (!_validUnits.contains(unit)) {
        errors.add('Row $line: unit "$unit" must be one of ${_validUnits.join(', ')}.');
        continue;
      }
      if (category.isEmpty) category = 'Other';
      final matchedCategory = _validCategories.firstWhere(
        (c) => c.toLowerCase() == category.toLowerCase(),
        orElse: () => 'Other',
      );

      final location = cell(row, locIdx);
      final description = cell(row, descIdx);

      valid.add(ProduceModel(
        id: '',
        farmerId: farmerId,
        name: name,
        category: matchedCategory,
        quantity: qty,
        unit: unit,
        expectedPrice: price,
        status: 'active',
        location: location.isEmpty ? null : location,
        description: description.isEmpty ? null : description,
      ));
    }

    setState(() {
      _fileName = fileName;
      _validRows = valid;
      _errors = errors;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting || _validRows.isEmpty) return;
    setState(() => _isSubmitting = true);

    final result = await ref.read(farmerRepositoryProvider).bulkAddProduce(_validRows);
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isSubmitting = false);
        AppSnackBar.show(context, message: failure.message, type: SnackBarType.error);
      },
      (created) {
        ref.read(farmerDashboardNotifierProvider.notifier).refreshDashboard();
        final farmerId = ref.read(authNotifierProvider).profile?.id;
        if (farmerId != null) {
          ref.read(produceControllerProvider.notifier).fetchProduce(farmerId);
        }
        AppSnackBar.show(
          context,
          message: '${created.length} listings published!',
          type: SnackBarType.success,
        );
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const AppTopBar(title: 'Bulk Upload Produce'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import many listings from a CSV file',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Required columns: name, quantity, expected_price. Optional: category, unit, location, description.',
              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              backgroundColor: colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample format',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SelectableText(
                    _sampleCsv,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Copy Sample',
                    icon: Icons.copy_rounded,
                    style: AppButtonStyle.outlined,
                    onPressed: () async {
                      await Clipboard.setData(const ClipboardData(text: _sampleCsv));
                      if (!context.mounted) return;
                      AppSnackBar.show(
                        context,
                        message: 'Sample CSV copied',
                        type: SnackBarType.success,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: _fileName == null ? 'Choose CSV File' : 'Choose Another File',
              icon: Icons.upload_file_rounded,
              style: AppButtonStyle.outlined,
              onPressed: _isSubmitting ? null : _pickCsv,
            ),
            if (_fileName != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'File: $_fileName',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${_validRows.length} valid row(s), ${_errors.length} with errors',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                borderColor: colorScheme.error,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _errors
                      .take(15)
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              e,
                              style: TextStyle(fontSize: 12, color: colorScheme.error),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
            if (_validRows.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              ..._validRows.take(20).map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: Icon(Icons.eco_rounded, color: colorScheme.primary),
                          title: Text(p.name),
                          subtitle: Text(
                            '${p.category} • ${p.quantity} ${p.unit} • ₹${p.expectedPrice.toStringAsFixed(0)}/${p.unit}',
                          ),
                        ),
                      ),
                    ),
                  ),
              if (_validRows.length > 20)
                Text(
                  '+ ${_validRows.length - 20} more rows',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Publish ${_validRows.length} Listings',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
