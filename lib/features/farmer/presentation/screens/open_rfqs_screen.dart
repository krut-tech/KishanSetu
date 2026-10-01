import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_bar/app_top_bar.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/error_state_widget.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_currency_field.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/buyer/domain/models/rfq_model.dart';
import 'package:farmer_market_app/features/buyer/domain/models/rfq_response_model.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_providers.dart';

/// Lets a farmer browse buyers' open bulk requirements and send a quote.
class OpenRfqsScreen extends ConsumerStatefulWidget {
  const OpenRfqsScreen({super.key});

  @override
  ConsumerState<OpenRfqsScreen> createState() => _OpenRfqsScreenState();
}

class _OpenRfqsScreenState extends ConsumerState<OpenRfqsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    ref.read(openRfqsControllerProvider.notifier).fetch();
  }

  Future<void> _openQuoteSheet(RfqModel rfq) async {
    final farmerId = ref.read(authNotifierProvider).profile?.id;
    if (farmerId == null) return;

    final priceController = TextEditingController(
      text: rfq.targetPrice != null ? rfq.targetPrice!.toStringAsFixed(0) : '',
    );
    final quantityController = TextEditingController(text: rfq.quantityNeeded.toStringAsFixed(0));
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

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
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Send a Quote', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${rfq.produceName} • ${rfq.quantityNeeded} ${rfq.unit} needed',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCurrencyField(
                    label: 'Your Price',
                    unitSuffix: '/ ${rfq.unit}',
                    controller: priceController,
                    validator: (v) {
                      final n = double.tryParse((v ?? '').trim());
                      if (n == null || n <= 0) return 'Enter valid price';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Quantity You Can Supply',
                    controller: quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').trim());
                      if (n == null || n <= 0) return 'Enter valid quantity';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Message (Optional)',
                    controller: messageController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Consumer(
                    builder: (context, ref, _) {
                      final isSubmitting = ref.watch(openRfqsControllerProvider).isSubmitting;
                      return AppButton(
                        label: 'Send Quote',
                        icon: Icons.send_rounded,
                        isLoading: isSubmitting,
                        onPressed: () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;
                          final response = RfqResponseModel(
                            id: '',
                            rfqId: rfq.id,
                            farmerId: farmerId,
                            offeredPrice: double.parse(priceController.text.trim()),
                            offeredQuantity: double.parse(quantityController.text.trim()),
                            message: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
                          );
                          final ok = await ref.read(openRfqsControllerProvider.notifier).sendQuote(response);
                          if (!context.mounted) return;
                          if (ok) {
                            Navigator.of(context).pop();
                            AppSnackBar.show(this.context, message: 'Quote sent!', type: SnackBarType.success);
                          } else {
                            final err = ref.read(openRfqsControllerProvider).errorMessage;
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
          ),
        );
      },
    );

    priceController.dispose();
    quantityController.dispose();
    messageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(openRfqsControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    Widget body;
    if (state.isLoading && state.rfqs.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.errorMessage != null && state.rfqs.isEmpty) {
      body = ErrorStateWidget(title: 'Unable to load RFQs', message: state.errorMessage!, onRetry: _load);
    } else if (state.rfqs.isEmpty) {
      body = const EmptyStateWidget(
        icon: Icons.inbox_outlined,
        title: 'No open requirements right now',
        message: 'Check back later — buyer bulk requirements will show up here.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
          itemCount: state.rfqs.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final rfq = state.rfqs[index];
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rfq.produceName, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(
                    '${rfq.quantityNeeded} ${rfq.unit} needed'
                    '${rfq.targetPrice != null ? ' • up to ₹${rfq.targetPrice!.toStringAsFixed(0)}/${rfq.unit}' : ''}',
                  ),
                  if (rfq.deliveryLocation != null)
                    Text('Delivery to: ${rfq.deliveryLocation}', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  if (rfq.buyerName != null)
                    Text('From: ${rfq.buyerName}', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Send Quote',
                    icon: Icons.send_rounded,
                    onPressed: () => _openQuoteSheet(rfq),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: const AppTopBar(title: 'Open Buyer Requirements'),
      body: body,
    );
  }
}
