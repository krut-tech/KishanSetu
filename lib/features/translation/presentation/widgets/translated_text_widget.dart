import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import '../controllers/translation_providers.dart';

/// Non-blocking widget that renders user-generated dynamic text and
/// provides an optional inline translate / show original toggle.
class TranslatedTextWidget extends ConsumerStatefulWidget {
  final String text;
  final TextStyle? style;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool showToggle;

  const TranslatedTextWidget({
    super.key,
    required this.text,
    this.style,
    this.overflow,
    this.maxLines,
    this.showToggle = true,
  });

  @override
  ConsumerState<TranslatedTextWidget> createState() =>
      _TranslatedTextWidgetState();
}

class _TranslatedTextWidgetState extends ConsumerState<TranslatedTextWidget> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.text.trim();
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      final translationAsync = ref.watch(dynamicTranslationProvider(text));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          translationAsync.when(
            data: (translated) {
              final isSame =
                  translated.trim().toLowerCase() == text.toLowerCase();
              final displayText = (_showOriginal || isSame) ? text : translated;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayText,
                    style: widget.style,
                    overflow: widget.overflow,
                    maxLines: widget.maxLines,
                  ),
                  if (widget.showToggle && !isSame) ...[
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showOriginal = !_showOriginal;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.g_translate_rounded,
                              size: 13,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showOriginal
                                  ? context.l10n.translateText
                                  : '${context.l10n.showOriginal} • ${context.l10n.translatedByKisanSetu}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontSize: 11,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => Text(
              text,
              style: widget.style,
              overflow: widget.overflow,
              maxLines: widget.maxLines,
            ),
            error: (_, __) => Text(
              text,
              style: widget.style,
              overflow: widget.overflow,
              maxLines: widget.maxLines,
            ),
          ),
        ],
      );
    } catch (_) {
      // Fallback if ProviderScope is absent in widget tests or uninitialized
      return Text(
        text,
        style: widget.style,
        overflow: widget.overflow,
        maxLines: widget.maxLines,
      );
    }
  }
}
