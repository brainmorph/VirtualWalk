import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../constants/strings.dart';
import '../models/walk_point.dart';
import '../providers/location_provider.dart';
import '../providers/walk_recorder_provider.dart';
import '../widgets/stats_panel.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  LatLng? _currentPosition;
  bool _centered = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recorder = ref.watch(walkRecorderProvider);
    final recorderNotifier = ref.read(walkRecorderProvider.notifier);

    ref.listen(locationStreamProvider, (_, next) {
      next.whenData((position) {
        final latLng = LatLng(position.latitude, position.longitude);
        setState(() => _currentPosition = latLng);
        if (!_centered) {
          _mapController.move(latLng, 16);
          _centered = true;
        }
        recorderNotifier.addPoint(WalkPoint(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: position.timestamp,
        ));
      });

      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    final routePoints = recorder.points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(37.7749, -122.4194),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.virtualwalker.app',
              ),
              if (routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: Colors.blue,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              if (_currentPosition != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentPosition!,
                      radius: 10,
                      color: Colors.blue.withValues(alpha: 0.8),
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(AppStrings.osmAttribution),
                ],
              ),
            ],
          ),
          if (_currentPosition == null)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: const StatsPanel(),
          ),
        ],
      ),
    );
  }
}
