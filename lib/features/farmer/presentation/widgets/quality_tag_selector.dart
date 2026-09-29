import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/chips/app_chip.dart';

/// Multi-select chip group used to tag produce quality (organic, grade, etc.).
class QualityTagSelector extends StatelessWidget {
  static const List<String> availableTags = [
    'Organic',
    'Pesticide-Free',
    'Grade A',
    'Freshly Harvested',
    'Non-GMO',
    'Sun-Dried',
    'Export Quality',
  ];

  final List<String> selectedTags;
  final ValueChanged<List<String>> onChanged;

  const QualityTagSelector({
    super.key,
    required this.selectedTags,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quality Tags',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: availableTags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return AppChip(
              label: tag,
              isSelected: isSelected,
              onTap: () {
                final updated = List<String>.from(selectedTags);
                if (isSelected) {
                  updated.remove(tag);
                } else {
                  updated.add(tag);
                }
                onChanged(updated);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
