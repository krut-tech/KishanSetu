import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/cards/produce_card.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';

/// Featured/Latest Produce section for the Buyer Dashboard.
class FeaturedProduceList extends StatelessWidget {
  final List<ProduceModel> produceList;
  final VoidCallback? onViewAll;
  final ValueChanged<ProduceModel>? onProduceTap;

  const FeaturedProduceList({
    super.key,
    required this.produceList,
    this.onViewAll,
    this.onProduceTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Produce',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (produceList.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Icon(Icons.storefront_outlined, size: 40, color: secondaryText),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No Produce Listed Yet',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryText),
                ),
                const SizedBox(height: 2),
                Text(
                  'Active farmer crop listings will appear here dynamically.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: produceList.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final item = produceList[index];
              return ProduceCard(
                cropName: item.name,
                grade: item.category,
                quantity: '${item.quantity} ${item.unit}',
                askingPrice: item.expectedPrice,
                netRealizationPrice: item.expectedPrice * 0.95,
                location: item.location ?? item.farmerDistrict ?? 'Gujarat',
                farmerName: item.farmerName ?? 'Farmer',
                onTap: () => onProduceTap?.call(item),
              );
            },
          ),
      ],
    );
  }
}
