import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_bar/app_top_bar.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/dropdowns/app_dropdown.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/error_state_widget.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_currency_field.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/buyer/domain/models/rfq_model.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/screens/rfq_detail_screen.dart';

/// Buyer's bulk-requirement (RFQ) postings and where they get farmer quotes.
class RfqListScreen extends ConsumerStatefulWidget {
  const RfqListScreen({super.key});

  @override
  ConsumerState<RfqListScreen> createState() => _RfqListScreenState();
}

class _RfqListScreenState extends ConsumerState<RfqListScreen> {
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
  static const List<String> _units = ['kg', 'quintal', 'ton', 'crate', 'bag'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final buyerId = ref.read(authNotifierProvider).profile?.id;
    if (buyerId != null) {
      ref.read(rfqControllerProvider.notifier).fetchMyRfqs(buyerId);
    }
  }

  Color _statusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'fulfilled':
        return colorScheme.primary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  Future<void> _openCreateRfqSheet() async {
    final buyerId = ref.read(authNotifierProvider).profile?.id;
    if (buyerId == null) return;

    final produceNameController = TextEditingController();
    final quantityController = TextEditingController();
    final targetPriceController = TextEditingController();
    final locationController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var category = _categories.first;
    var unit = _units.first;
    DateTime? neededBy;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Post a Bulk Requirement (RFQ)', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Farmers matching this will be able to send you a quote.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Produce Needed',
                        hint: 'e.g. Sharbati Wheat',
                        controller: produceNameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter produce name' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownFormField<String>(
                        label: 'Category',
                        value: category,
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setSheetState(() => category = v ?? category),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: AppTextField(
                              label: 'Quantity Needed',
                              controller: quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) {
                                final n = double.tryParse((v ?? '').trim());
                                if (n == null || n <= 0) return 'Enter valid quantity';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppDropdownFormField<String>(
                              label: 'Unit',
                              value: unit,
                              items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (v) => setSheetState(() => unit = v ?? unit),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppCurrencyField(
                        label: 'Target Price (Optional)',
                        hint: 'Max price you are willing to pay',
                        unitSuffix: '/ $unit',
                        controller: targetPriceController,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Delivery Location',
                        hint: 'e.g. Ahmedabad, Gujarat',
                        controller: locationController,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 180)),
                          );
                          if (picked != null) setSheetState(() => neededBy = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Needed By (Optional)',
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(
                            neededBy != null ? DateFormat('dd MMM yyyy').format(neededBy!) : 'Any time',
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Consumer(
                        builder: (context, ref, _) {
                          final isSubmitting = ref.watch(rfqControllerProvider).isSubmitting;
                          return AppButton(
                            label: 'Post RFQ',
                            icon: Icons.send_rounded,
                            isLoading: isSubmitting,
                            onPressed: () async {
                              if (!(formKey.currentState?.validate() ?? false)) return;
                              final rfq = RfqModel(
                                id: '',
                                buyerId: buyerId,
                                produceName: produceNameController.text.trim(),
                                category: category,
                                quantityNeeded: double.parse(quantityController.text.trim()),
                                unit: unit,
                                targetPrice: double.tryParse(targetPriceController.text.trim()),
                                deliveryLocation: locationController.text.trim().isEmpty
                                    ? null
                                    : locationController.text.trim(),
                                neededBy: neededBy,
                              );
                              final ok = await ref.read(rfqControllerProvider.notifier).createRfq(rfq);
                              if (!context.mounted) return;
                              if (ok) {
                                Navigator.of(context).pop();
                                AppSnackBar.show(this.context, message: 'RFQ posted!', type: SnackBarType.success);
                              } else {
                                final err = ref.read(rfqControllerProvider).errorMessage;
                                if (err != null) AppSnackBar.show(context, message: err, type: SnackBarType.error);
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    produceNameController.dispose();
    quantityController.dispose();
    targetPriceController.dispose();
    locationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rfqControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    Widget body;
    if (state.isLoading && state.myRfqs.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.errorMessage != null && state.myRfqs.isEmpty) {
      body = ErrorStateWidget(title: 'Unable to load RFQs', message: state.errorMessage!, onRetry: _load);
    } else if (state.myRfqs.isEmpty) {
      body = const EmptyStateWidget(
        icon: Icons.request_quote_outlined,
        title: 'No RFQs posted yet',
        message: 'Post a bulk requirement and let farmers send you competitive quotes.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.huge + AppSpacing.xxxl),
          itemCount: state.myRfqs.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final rfq = state.myRfqs[index];
            return AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RfqDetailScreen(rfq: rfq)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          rfq.produceName,
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor(rfq.status, colorScheme).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rfq.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _statusColor(rfq.status, colorScheme),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${rfq.quantityNeeded} ${rfq.unit}${rfq.targetPrice != null ? ' • up to ₹${rfq.targetPrice!.toStringAsFixed(0)}/${rfq.unit}' : ''}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${rfq.responseCount ?? 0} quote(s) received',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: const AppTopBar(title: 'My RFQs'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateRfqSheet,
        icon: const Icon(Icons.add),
        label: const Text('Post RFQ'),
      ),
      body: body,
    );
  }
}
