import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../constants/strings.dart';
import '../models/walk_point.dart';
import '../providers/location_provider.dart';
import '../providers/walk_recorder_provider.dart';
import '../services/foreground_service.dart';
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

  // True while the foreground service is running (recording active).
  // When true, walk points come from the task handler, not locationStreamProvider.
  bool _serviceGpsActive = false;

  // Location stream startup is deferred until the sequential permission flow
  // completes — two simultaneous permission dialogs cause one to be denied.
  bool _permissionsReady = false;

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    _requestServicePermissions();
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    _mapController.dispose();
    super.dispose();
  }

  // Receives position data from GpsTaskHandler running in the service isolate.
  // Called on the main isolate — safe to call setState and ref.read.
  void _onTaskData(Object data) {
    if (data is! Map) return;
    final lat = data['latitude'] as double?;
    final lng = data['longitude'] as double?;
    final tsMs = data['timestamp'] as int?;
    if (lat == null || lng == null || tsMs == null) return;

    final latLng = LatLng(lat, lng);
    ref.read(walkRecorderProvider.notifier).addPoint(WalkPoint(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.fromMillisecondsSinceEpoch(tsMs),
        ));

    if (mounted) {
      setState(() => _currentPosition = latLng);
      if (!_centered) {
        _mapController.move(latLng, 16);
        _centered = true;
      }
    }
  }

  Future<void> _requestServicePermissions() async {
    // Location first: locationStreamProvider would otherwise request it
    // concurrently with the dialogs below and could get auto-denied.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (await FlutterForegroundTask.checkNotificationPermission() !=
        NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    if (mounted) setState(() => _permissionsReady = true);
  }

  @override
  Widget build(BuildContext context) {
    final recorder = ref.watch(walkRecorderProvider);
    final recorderNotifier = ref.read(walkRecorderProvider.notifier);

    // Start/stop the foreground service and its GPS task handler when
    // recording status transitions. The task handler sends positions back
    // via _onTaskData, which handles addPoint while the screen is off.
    ref.listen(walkRecorderProvider, (prev, next) {
      if (next.status == RecordingStatus.recording &&
          prev?.status != RecordingStatus.recording) {
        setState(() => _serviceGpsActive = true);
        ForegroundService.startService().then((result) {
          if (result is! ServiceRequestFailure || !context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('GPS service failed to start: ${result.error}'),
            ),
          );
        });
      } else if (next.status != RecordingStatus.recording &&
          prev?.status == RecordingStatus.recording) {
        setState(() => _serviceGpsActive = false);
        ForegroundService.stopService();
      }
    });

    // locationStreamProvider drives the map marker while idle. addPoint is
    // suppressed when the service is active because the task handler is
    // already doing that work (avoids double-counting points). Not subscribed
    // until the sequential permission flow in initState has finished, so the
    // stream's own permission check never races the other dialogs.
    if (_permissionsReady) {
      ref.listen(locationStreamProvider, (_, next) {
        next.whenData((position) {
          final latLng = LatLng(position.latitude, position.longitude);
          setState(() => _currentPosition = latLng);
          if (!_centered) {
            _mapController.move(latLng, 16);
            _centered = true;
          }
          if (!_serviceGpsActive) {
            recorderNotifier.addPoint(WalkPoint(
              latitude: position.latitude,
              longitude: position.longitude,
              timestamp: position.timestamp,
            ));
          }
        });

        if (next is AsyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error.toString())),
          );
        }
      });
    }

    final routePoints = recorder.points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.appName),
            Text(
              AppStrings.version,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
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
