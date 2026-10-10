import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens an explicitly saved point in Maps; falls back to a typed address.
/// This widget does not request or track the device location.
class CoordinateMapButton extends StatelessWidget {
  final String label;
  final String? address;
  final double? latitude, longitude;
  final bool compact;
  const CoordinateMapButton({super.key, required this.label, this.address, this.latitude, this.longitude, this.compact = false});

  Future<void> _open(BuildContext context) async {
    final valid = latitude != null && longitude != null && latitude!.isFinite && longitude!.isFinite &&
        latitude! >= -90 && latitude! <= 90 && longitude! >= -180 && longitude! <= 180;
    final query = valid ? '${latitude!.toStringAsFixed(6)},${longitude!.toStringAsFixed(6)}' : (address ?? '').trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a village, district or map location to your profile first.')));
      return;
    }
    final uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': query});
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Google Maps. Check your connection.')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Google Maps. Check your connection.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return IconButton(tooltip: label, onPressed: () => _open(context), icon: const Icon(Icons.map_outlined));
    return OutlinedButton.icon(onPressed: () => _open(context), icon: const Icon(Icons.location_on_outlined), label: Text(label));
  }
}
