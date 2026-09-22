import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/badges/app_status_badge.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/price/app_price_text.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
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

  @override
  void initState() {
    super.initState();
    _produce = widget.produce;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authNotifierProvider).state.user;
      if (user != null) {
        ref.read(buyerOfferControllerProvider.notifier).fetchOffers(user.id);
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
    );
  }
}
