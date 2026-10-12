import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_currency_field.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';

class CounterOfferTerms {
  final double offeredPrice;
  final double quantity;
  final String? message;

  const CounterOfferTerms({
    required this.offeredPrice,
    required this.quantity,
    this.message,
  });
}

/// Collects the revised price/quantity before a farmer sends a counter-offer.
class CounterOfferDialog extends StatefulWidget {
  final OfferModel offer;

  const CounterOfferDialog({super.key, required this.offer});

  static Future<CounterOfferTerms?> show(
    BuildContext context,
    OfferModel offer,
  ) {
    return showModalBottomSheet<CounterOfferTerms>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CounterOfferDialog(offer: offer),
    );
  }

  @override
  State<CounterOfferDialog> createState() => _CounterOfferDialogState();
}

class _CounterOfferDialogState extends State<CounterOfferDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.offer.offeredPrice.toStringAsFixed(2),
    );
    _quantityController = TextEditingController(
      text: widget.offer.quantity.toStringAsFixed(2),
    );
    _messageController = TextEditingController(text: widget.offer.message ?? '');
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final price = double.parse(_priceController.text.trim());
    final quantity = double.parse(_quantityController.text.trim());
    final message = _messageController.text.trim();
    Navigator.of(context).pop(CounterOfferTerms(
      offeredPrice: price,
      quantity: quantity,
      message: message.isEmpty ? null : message,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final unit = widget.offer.produceUnit ?? 'unit';
    final available = widget.offer.produceAvailableQuantity;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Counter Offer',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Set the revised price and quantity for ${widget.offer.produceName ?? 'this produce'}.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCurrencyField(
                label: 'Counter price (per $unit)',
                controller: _priceController,
                unitSuffix: '/ $unit',
                validator: (value) {
                  final price = double.tryParse(value?.trim() ?? '');
                  if (price == null || price <= 0) {
                    return 'Enter a price greater than zero.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Counter quantity ($unit)',
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.scale_outlined),
                validator: (value) {
                  final quantity = double.tryParse(value?.trim() ?? '');
                  if (quantity == null || quantity <= 0) {
                    return 'Enter a quantity greater than zero.';
                  }
                  if (available != null && quantity > available) {
                    return 'Available quantity is ${available.toStringAsFixed(2)} $unit.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Message to buyer (optional)',
                controller: _messageController,
                maxLines: 3,
                validator: (value) => (value?.length ?? 0) > 250
                    ? 'Message cannot exceed 250 characters.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Send Counter Offer',
                style: AppButtonStyle.primary,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: 'Keep Original Offer',
                style: AppButtonStyle.outlined,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
