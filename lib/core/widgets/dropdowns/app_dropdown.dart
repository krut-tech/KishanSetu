import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';

/// Reusable dropdown form field widget for crop category, grade, and mandi selection.
class AppDropdownFormField<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;

  const AppDropdownFormField({
    super.key,
    required this.label,
    required this.items,
    this.hint,
    this.value,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          dropdownColor: colorScheme.surface,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }
}
