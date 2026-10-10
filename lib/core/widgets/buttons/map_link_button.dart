import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';

/// Small localized strings for the map feature (en / hi / gu).
///
/// Kept here rather than in the ARB files so the feature is self-contained;
/// they can be moved into app_*.arb later without changing any call site's
/// behaviour.
class MapStrings {
  MapStrings._();

  static String _pick(BuildContext context, String en, String hi, String gu) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'hi':
        return hi;
      case 'gu':
        return gu;
      default:
        return en;
    }
  }

  static String viewOnMap(BuildContext context) =>
      _pick(context, 'View on Map', 'नक्शे पर देखें', 'નકશા પર જુઓ');

  static String couldNotOpen(BuildContext context) => _pick(
        context,
        'Could not open maps. Please check your internet connection.',
        'नक्शा नहीं खुल सका। कृपया अपना इंटरनेट कनेक्शन जांचें।',
        'નકશો ખોલી શકાયો નથી. કૃપા કરીને તમારું ઇન્ટરનેટ કનેક્શન તપાસો.',
      );
}

/// Opens the supplied location text (for example, "Vasad, Anand, Gujarat")
/// in the device's maps app or browser using a Google Maps search URL.
///
/// This uses a plain search URL instead of an embedded map SDK: it needs no
/// API key, billing account, or location permission. The maps app geocodes the
/// text itself, which is sufficient for a buyer or farmer to view a location.
Future<void> openLocationOnMap(BuildContext context, String location) async {
  final uri = Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': location,
  });

  bool launched = false;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    launched = false;
  }

  if (!launched && context.mounted) {
    AppSnackBar.show(
      context,
      message: MapStrings.couldNotOpen(context),
      type: SnackBarType.error,
    );
  }
}

/// Compact location row that opens the location in a maps app or browser.
class MapLinkButton extends StatelessWidget {
  final String location;

  const MapLinkButton({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => openLocationOnMap(context, location),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: colorScheme.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.map_outlined, size: 15, color: colorScheme.primary),
            const SizedBox(width: 3),
            Text(
              MapStrings.viewOnMap(context),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
