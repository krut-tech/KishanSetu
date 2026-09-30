import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/badges/app_status_badge.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/dropdowns/app_dropdown.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/core/widgets/price/app_price_text.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/buyer/domain/models/subscription_model.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/screens/make_offer_dialog.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen displaying complete details for a farmer's produce listing.
class ProduceDetailsScreen extends ConsumerStatefulWidget {
  final ProduceModel produce;

  const ProduceDetailsScreen({
    super.key,
    required this.produce,
  });

  @override
  ConsumerState<ProduceDetailsScreen> createState() => _ProduceDetailsScreenState();
}

class _ProduceDetailsScreenState extends ConsumerState<ProduceDetailsScreen> {
  late ProduceModel _produce;
  RealtimeChannel? _detailsChannel;
  bool _isFavorite = false;
  String? _wishlistItemId;
  bool _isTogglingWishlist = false;

  @override
  void initState() {
    super.initState();
    _produce = widget.produce;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authNotifierProvider).state.user;
      if (user != null) {
        ref.read(buyerOfferControllerProvider.notifier).fetchOffers(user.id);
      }

      final buyerId = ref.read(authNotifierProvider).profile?.id;
      if (buyerId != null) {
        final wishlistState = ref.read(wishlistControllerProvider);
        final match = wishlistState.items.where((i) => i.produce.id == _produce.id);
        if (match.isNotEmpty) {
          setState(() {
            _isFavorite = true;
            _wishlistItemId = match.first.id;
          });
        }
      }

      final repo = ref.read(buyerRepositoryProvider);
      _detailsChannel = repo.subscribeToProduceDetails(_produce.id, (updated) {
        if (mounted) {
          setState(() {
            if (updated != null) {
              _produce = updated;
            } else {
              _produce = _produce.copyWith(status: 'deleted');
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _detailsChannel?.unsubscribe();
    super.dispose();
  }

  AppStatusType _getStatusType(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppStatusType.active;
      case 'sold':
        return AppStatusType.completed;
      case 'draft':
        return AppStatusType.draft;
      default:
        return AppStatusType.pending;
    }
  }

  Future<void> _toggleWishlist() async {
    final buyerId = ref.read(authNotifierProvider).profile?.id;
    if (buyerId == null || _isTogglingWishlist) return;
    setState(() => _isTogglingWishlist = true);

    if (_isFavorite && _wishlistItemId != null) {
      final ok = await ref.read(wishlistControllerProvider.notifier).remove(_wishlistItemId!, buyerId);
      if (mounted) {
        setState(() {
          _isTogglingWishlist = false;
          if (ok) {
            _isFavorite = false;
            _wishlistItemId = null;
          }
        });
      }
    } else {
      final ok = await ref.read(wishlistControllerProvider.notifier).add(buyerId: buyerId, produceId: _produce.id);
      if (!mounted) return;
      if (ok) {
        final match = ref.read(wishlistControllerProvider).items.where((i) => i.produce.id == _produce.id);
        setState(() {
          _isTogglingWishlist = false;
          _isFavorite = true;
          _wishlistItemId = match.isNotEmpty ? match.first.id : null;
        });
        AppSnackBar.show(context, message: 'Added to wishlist', type: SnackBarType.success);
      } else {
        setState(() => _isTogglingWishlist = false);
      }
    }
  }

  Future<void> _openSubscribeSheet() async {
    final buyerId = ref.read(authNotifierProvider).profile?.id;
    if (buyerId == null) return;

    final quantityController = TextEditingController(text: '1');
    var frequency = 'weekly';
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
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Set Up Recurring Order', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${_produce.name} will be auto-requested from this farmer on your chosen schedule.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Quantity per order (${_produce.unit})',
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return 'Enter valid quantity';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownFormField<String>(
                        label: 'Frequency',
                        value: frequency,
                        items: const [
                          DropdownMenuItem(value: 'weekly', child: Text('Every week')),
                          DropdownMenuItem(value: 'biweekly', child: Text('Every 2 weeks')),
                          DropdownMenuItem(value: 'monthly', child: Text('Every month')),
                        ],
                        onChanged: (v) => setSheetState(() => frequency = v ?? frequency),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Consumer(
                        builder: (context, ref, _) {
                          final isSubmitting = ref.watch(subscriptionControllerProvider).isSubmitting;
                          return AppButton(
                            label: 'Start Subscription',
                            icon: Icons.autorenew_rounded,
                            isLoading: isSubmitting,
                            onPressed: () async {
                              if (!(formKey.currentState?.validate() ?? false)) return;
                              final sub = SubscriptionModel(
                                id: '',
                                buyerId: buyerId,
                                farmerId: _produce.farmerId,
                                produceId: _produce.id,
                                quantity: double.parse(quantityController.text.trim()),
                                frequency: frequency,
                                nextDeliveryDate: DateTime.now().add(const Duration(days: 1)),
                              );
                              final ok = await ref.read(subscriptionControllerProvider.notifier).create(sub);
                              if (!context.mounted) return;
                              if (ok) {
                                Navigator.of(context).pop();
                                AppSnackBar.show(
                                  this.context,
                                  message: 'Recurring order set up!',
                                  type: SnackBarType.success,
                                );
                              } else {
                                final err = ref.read(subscriptionControllerProvider).errorMessage;
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

    quantityController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final produce = _produce;
    final farmerName = produce.farmerName ?? 'Farmer';
    final locationText = produce.location ?? produce.farmerDistrict ?? 'Gujarat';
    final listingDateText = produce.createdAt != null
        ? '${produce.createdAt!.day}/${produce.createdAt!.month}/${produce.createdAt!.year}'
        : 'Recently';

    final isActive = produce.status == 'active';

    final buyerOffers = ref.watch(buyerOfferControllerProvider).offers;
    OfferModel? existingOffer;
    for (final o in buyerOffers) {
      if (o.produceId == produce.id && (o.status.toLowerCase() == 'pending' || o.status.toLowerCase() == 'countered')) {
        existingOffer = o;
        break;
      }
    }

    final hasActiveOffer = existingOffer != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produce Details'),
        actions: [
          IconButton(
            tooltip: _isFavorite ? 'Remove from wishlist' : 'Add to wishlist',
            icon: _isTogglingWishlist
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isFavorite ? Colors.redAccent : null,
                  ),
            onPressed: _isTogglingWishlist ? null : _toggleWishlist,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Offer Info Banner
                    if (hasActiveOffer) ...[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 18, color: colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'You have an active offer',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const AppStatusBadge(type: AppStatusType.pending),
                              ],
                            ),
                            const Divider(),
                            Text(
                              'Offered Price: ₹${existingOffer.offeredPrice.toStringAsFixed(2)} / ${produce.unit}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text('Quantity: ${existingOffer.quantity} ${produce.unit}'),
                            if (existingOffer.message != null && existingOffer.message!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Message: "${existingOffer.message}"',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Top Title Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  produce.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              AppStatusBadge(type: _getStatusType(produce.status)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            produce.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              Icon(Icons.location_on_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                              Text(
                                locationText,
                                style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                              ),
                              Text(' • ', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                              Icon(Icons.calendar_today_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                              Text(
                                'Listed $listingDateText',
                                style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          if (produce.qualityTags.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: produce.qualityTags
                                  .map((t) => Chip(
                                        label: Text(t, style: const TextStyle(fontSize: 11)),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Pricing & Quantity Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quantity & Pricing',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          ),
                          const Divider(),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Available Quantity',
                                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${produce.quantity} ${produce.unit}',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Expected Price',
                                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    AppPriceText(
                                      price: produce.expectedPrice,
                                      priceStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Seller Information Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Farmer & Location Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(Icons.person, color: colorScheme.primary),
                            ),
                            title: Text(farmerName, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                            subtitle: Text('Verified Seller • Location: $locationText', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Crop Description
                    if (produce.description != null && produce.description!.trim().isNotEmpty)
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crop Description',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                            ),
                            const Divider(),
                            Text(
                              produce.description!,
                              style: TextStyle(fontSize: 14, height: 1.4, color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (isActive)
                    Expanded(
                      child: AppButton(
                        label: 'Subscribe',
                        style: AppButtonStyle.outlined,
                        icon: Icons.autorenew_rounded,
                        onPressed: _openSubscribeSheet,
                      ),
                    ),
                  if (isActive) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: hasActiveOffer
                          ? 'Edit Offer'
                          : (isActive ? 'Make Offer' : 'Produce Listing Inactive'),
                      style: AppButtonStyle.secondary,
                      icon: hasActiveOffer ? Icons.edit_outlined : Icons.local_offer_rounded,
                      onPressed: isActive
                          ? () async {
                              final submitted = await MakeOfferDialog.show(
                                context,
                                produce,
                                existingOffer: existingOffer,
                              );
                              if (submitted == true && context.mounted) {
                                final user = ref.read(authNotifierProvider).state.user;
                                if (user != null) {
                                  ref.read(buyerOfferControllerProvider.notifier).fetchOffers(user.id);
                                }
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
