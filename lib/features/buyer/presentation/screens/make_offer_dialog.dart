import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_currency_field.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';

/// Modal dialog / sheet allowing a buyer to submit a price offer for a produce listing.
class MakeOfferDialog extends ConsumerStatefulWidget {
  final ProduceModel produce;

  const MakeOfferDialog({
    super.key,
    required this.produce,
  });

  static Future<bool?> show(BuildContext context, ProduceModel produce) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MakeOfferDialog(produce: produce),
    );
  }

  @override
  ConsumerState<MakeOfferDialog> createState() => _MakeOfferDialogState();
}

class _MakeOfferDialogState extends ConsumerState<MakeOfferDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.produce.expectedPrice > 0 ? widget.produce.expectedPrice.toStringAsFixed(2) : '',
    );
    _quantityController = TextEditingController(
      text: widget.produce.quantity > 0 ? widget.produce.quantity.toStringAsFixed(1) : '',
    );
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitOffer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(authNotifierProvider).state.user;
    if (user == null) {
      AppSnackBar.show(context, message: 'You must be logged in to make an offer', type: SnackBarType.error);
      return;
    }

    final offeredPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final offerQuantity = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final message = _messageController.text.trim();

    if (offeredPrice <= 0) {
      AppSnackBar.show(context, message: 'Offered price must be greater than 0', type: SnackBarType.error);
      return;
    }

    if (offerQuantity <= 0) {
      AppSnackBar.show(context, message: 'Quantity must be greater than 0', type: SnackBarType.error);
      return;
    }

    if (offerQuantity > widget.produce.quantity) {
      AppSnackBar.show(
        context,
        message: 'Quantity cannot exceed available produce quantity (${widget.produce.quantity} ${widget.produce.unit})',
        type: SnackBarType.error,
      );
      return;
    }

    final offer = OfferModel(
      id: '',
      produceId: widget.produce.id,
      farmerId: widget.produce.farmerId,
      buyerId: user.id,
      offeredPrice: offeredPrice,
      quantity: offerQuantity,
      status: 'pending',
      message: message.isNotEmpty ? message : null,
    );

    final success = await ref
        .read(buyerOfferControllerProvider.notifier)
        .makeOffer(offer);

    if (mounted) {
      if (success) {
        ref.read(buyerDashboardNotifierProvider.notifier).refreshDashboard();
        AppSnackBar.show(context, message: 'Offer submitted successfully!', type: SnackBarType.success);
        Navigator.of(context).pop(true);
      } else {
        final error = ref.read(buyerOfferControllerProvider).errorMessage ?? 'Failed to submit offer';
        AppSnackBar.show(context, message: error, type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final offerState = ref.watch(buyerOfferControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Make an Offer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          widget.produce.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),

              // Produce Info summary card
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Asking Price', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                        Text(
                          '₹${widget.produce.expectedPrice.toStringAsFixed(0)} / ${widget.produce.unit}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Available', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                        Text(
                          '${widget.produce.quantity} ${widget.produce.unit}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Offered Price Field
              AppCurrencyField(
                label: 'Offered Price (per ${widget.produce.unit})',
                controller: _priceController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Offered price is required';
                  final p = double.tryParse(v.trim());
                  if (p == null || p <= 0) return 'Enter a valid price greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Quantity Field
              AppTextField(
                label: 'Quantity (${widget.produce.unit})',
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.scale_outlined),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Quantity is required';
                  final q = double.tryParse(v.trim());
                  if (q == null || q <= 0) return 'Enter a valid quantity greater than 0';
                  if (q > widget.produce.quantity) {
                    return 'Exceeds available quantity (${widget.produce.quantity})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Message Field
              AppTextField(
                label: 'Message to Farmer (Optional)',
                controller: _messageController,
                hint: 'e.g. Can pick up from farm directly within 2 days.',
                maxLines: 3,
                validator: (v) {
                  if (v != null && v.length > 250) {
                    return 'Message cannot exceed 250 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              AppButton(
                label: 'Submit Offer',
                style: AppButtonStyle.secondary,
                isLoading: offerState.isSubmitting,
                onPressed: _submitOffer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
