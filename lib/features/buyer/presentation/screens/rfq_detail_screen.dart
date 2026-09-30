import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_bar/app_top_bar.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/buyer/domain/models/rfq_model.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';

/// Shows quotes farmers have submitted against one of the buyer's RFQs.
class RfqDetailScreen extends ConsumerStatefulWidget {
  final RfqModel rfq;

  const RfqDetailScreen({super.key, required this.rfq});

  @override
  ConsumerState<RfqDetailScreen> createState() => _RfqDetailScreenState();
}

class _RfqDetailScreenState extends ConsumerState<RfqDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rfqControllerProvider.notifier).fetchResponses(widget.rfq.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rfqControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final rfq = widget.rfq;

    return Scaffold(
      appBar: AppTopBar(
        title: rfq.produceName,
        actions: [
          if (rfq.status == 'open')
            IconButton(
              tooltip: 'Close RFQ',
              icon: const Icon(Icons.close_rounded),
              onPressed: () async {
                await ref.read(rfqControllerProvider.notifier).closeRfq(rfq.id);
                if (!context.mounted) return;
                AppSnackBar.show(context, message: 'RFQ closed', type: SnackBarType.success);
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Requirement', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text('${rfq.quantityNeeded} ${rfq.unit} of ${rfq.produceName}'),
                if (rfq.targetPrice != null) Text('Target price: ₹${rfq.targetPrice!.toStringAsFixed(0)}/${rfq.unit}'),
                if (rfq.deliveryLocation != null) Text('Delivery to: ${rfq.deliveryLocation}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Farmer Quotes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (state.selectedRfqResponses.isEmpty)
            const EmptyStateWidget(
              icon: Icons.hourglass_empty_rounded,
              title: 'No quotes yet',
              message: 'Farmers browsing open RFQs will be able to send you a quote here.',
            )
          else
            ...state.selectedRfqResponses.map((r) {
              final isAccepted = r.status == 'accepted';
              final isRejected = r.status == 'rejected';
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              r.farmerName ?? 'Farmer',
                              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                            ),
                          ),
                          Text(
                            r.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAccepted
                                  ? Colors.green
                                  : isRejected
                                      ? colorScheme.error
                                      : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Text('₹${r.offeredPrice.toStringAsFixed(0)}/${rfq.unit} • ${r.offeredQuantity} ${rfq.unit}'),
                      if (r.message != null && r.message!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '"${r.message}"',
                            style: TextStyle(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      if (r.status == 'pending' && rfq.status == 'open') ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Accept',
                                icon: Icons.check_rounded,
                                onPressed: () => ref
                                    .read(rfqControllerProvider.notifier)
                                    .acceptResponse(r.id, rfq.id),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppButton(
                                label: 'Reject',
                                style: AppButtonStyle.outlined,
                                icon: Icons.close_rounded,
                                onPressed: () => ref
                                    .read(rfqControllerProvider.notifier)
                                    .rejectResponse(r.id, rfq.id),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
