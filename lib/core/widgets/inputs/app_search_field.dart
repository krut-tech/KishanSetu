import 'dart:async';
import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_radius.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';

/// Touch-friendly search bar widget with clear action button.
///
/// [onChanged] is debounced by [debounce] (default 350ms) so typing a word
/// fires one query instead of one query per keystroke - the single biggest
/// cause of the app feeling slow while searching market prices / produce /
/// marketplace, since every one of those screens calls a Supabase query
/// directly from this callback.
class AppSearchField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Duration debounce;

  const AppSearchField({
    super.key,
    this.hint = 'Search crop, mandi, district...',
    this.controller,
    this.onChanged,
    this.onClear,
    this.debounce = const Duration(milliseconds: 350),
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () {
      widget.onChanged?.call(value);
    });
    // Rebuild immediately so the clear (x) button appears/disappears without
    // waiting for the debounce - only the actual query is delayed.
    setState(() {});
  }

  void _handleClear() {
    _debounceTimer?.cancel();
    widget.controller?.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = widget.controller;

    return TextField(
      controller: controller,
      onChanged: _handleChanged,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant),
        suffixIcon: controller != null && controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                onPressed: _handleClear,
              )
            : null,
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderPill,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderPill,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderPill,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
