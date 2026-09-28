import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_bar/app_top_bar.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_providers.dart';

/// Map + list of produce listings and mandis around the farmer's current location.
class NearbyDiscoveryScreen extends ConsumerStatefulWidget {
  const NearbyDiscoveryScreen({super.key});

  @override
  ConsumerState<NearbyDiscoveryScreen> createState() => _NearbyDiscoveryScreenState();
}

class _NearbyDiscoveryScreenState extends ConsumerState<NearbyDiscoveryScreen> {
  double? _sliderValue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nearbyDiscoveryControllerProvider.notifier).detectLocationAndSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyDiscoveryControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final hasLocation = state.currentLat != null && state.currentLng != null;
    final radius = _sliderValue ?? state.radiusKm;

    Widget mapArea;
    if (hasLocation) {
      final center = LatLng(state.currentLat!, state.currentLng!);
      mapArea = FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: 10),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.kisansetu.app',
          ),
          CircleLayer(
            circles: [
              CircleMarker(
                point: center,
                radius: radius * 1000,
                useRadiusInMeter: true,
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderColor: colorScheme.primary.withValues(alpha: 0.5),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 40,
                height: 40,
                child: const Icon(Icons.my_location, color: Colors.blue, size: 28),
              ),
              ...state.nearbyProduce.map(
                (p) => Marker(
                  point: LatLng(p.latitude, p.longitude),
                  width: 36,
                  height: 36,
                  child: const Icon(Icons.eco, color: Colors.green, size: 28),
                ),
              ),
              ...state.nearbyMandis.map(
                (m) => Marker(
                  point: LatLng(m.latitude, m.longitude),
                  width: 36,
                  height: 36,
                  child: const Icon(Icons.storefront, color: Colors.deepOrange, size: 28),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (state.isLoading) {
      mapArea = const Center(child: CircularProgressIndicator());
    } else {
      mapArea = Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage ?? 'Turn on location to discover nearby produce and mandis.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Use My Location',
                icon: Icons.my_location,
                width: 220,
                onPressed: () => ref
                    .read(nearbyDiscoveryControllerProvider.notifier)
                    .detectLocationAndSearch(),
              ),
            ],
          ),
        ),
      );
    }

    final noResults = state.nearbyProduce.isEmpty && state.nearbyMandis.isEmpty;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Nearby Discovery',
        actions: [
          IconButton(
            tooltip: 'Refresh location',
            icon: const Icon(Icons.my_location),
            onPressed: () => ref
                .read(nearbyDiscoveryControllerProvider.notifier)
                .detectLocationAndSearch(),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 280, child: mapArea),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'Radius',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: radius.clamp(5, 150).toDouble(),
                    min: 5,
                    max: 150,
                    divisions: 29,
                    label: '${radius.round()} km',
                    onChanged: (val) => setState(() => _sliderValue = val),
                    onChangeEnd: (val) {
                      setState(() => _sliderValue = null);
                      ref.read(nearbyDiscoveryControllerProvider.notifier).updateRadius(val);
                    },
                  ),
                ),
                Text('${radius.round()} km'),
              ],
            ),
          ),
          Expanded(
            child: noResults
                ? EmptyStateWidget(
                    icon: Icons.explore_off_outlined,
                    title: 'Nothing nearby',
                    message: hasLocation
                        ? 'Try a larger radius. Listings only appear when a location is pinned on them.'
                        : 'Enable location to search around you.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.xxxl,
                    ),
                    children: [
                      if (state.nearbyProduce.isNotEmpty) ...[
                        _sectionTitle('Nearby Produce', colorScheme),
                        ...state.nearbyProduce.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: AppCard(
                              padding: EdgeInsets.zero,
                              child: ListTile(
                                leading: const Icon(Icons.eco, color: Colors.green),
                                title: Text(p.name),
                                subtitle: Text(
                                  '${p.quantity} ${p.unit} • ₹${p.expectedPrice.toStringAsFixed(0)}/${p.unit}${p.location != null ? ' • ${p.location}' : ''}',
                                ),
                                trailing: Text('${p.distanceKm.toStringAsFixed(1)} km'),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (state.nearbyMandis.isNotEmpty) ...[
                        _sectionTitle('Nearby Mandis', colorScheme),
                        ...state.nearbyMandis.map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: AppCard(
                              padding: EdgeInsets.zero,
                              child: ListTile(
                                leading: const Icon(Icons.storefront, color: Colors.deepOrange),
                                title: Text(m.name),
                                subtitle: Text(
                                  [m.district, m.state]
                                      .where((s) => s != null && s.isNotEmpty)
                                      .join(', '),
                                ),
                                trailing: Text('${m.distanceKm.toStringAsFixed(1)} km'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
