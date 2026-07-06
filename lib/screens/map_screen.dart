import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../constants/strings.dart';
import '../models/walk_point.dart';
import '../providers/gps_settings_provider.dart';
import '../providers/location_provider.dart';
import '../providers/walk_recorder_provider.dart';
import '../services/foreground_service.dart';
import '../services/walk_exporter.dart';
import '../services/walk_importer.dart';
import '../services/walk_projector.dart';
import '../widgets/stats_panel.dart';

/// Selectable GPS snapshot intervals: seconds paired with their menu label.
/// 0 seconds means open loop — no throttling at all.
const _gpsRateOptions = <(int, String)>[
  (0, AppStrings.gpsRateOpenLoop),
  (1, AppStrings.gpsRateEverySecond),
  (2, AppStrings.gpsRateEvery2s),
  (5, AppStrings.gpsRateEvery5s),
  (10, AppStrings.gpsRateEvery10s),
  (30, AppStrings.gpsRateEvery30s),
  (60, AppStrings.gpsRateEveryMinute),
];

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

  // A previously exported walk loaded from CSV, shown as its own route.
  List<WalkPoint>? _importedWalk;

  // Where the current walk shape is projected (set by long-press), and the
  // last projected point, which acts as the "projected current position".
  LatLng? _anchor;
  LatLng? _projectedPosition;

  // Which position the recenter button targets: real GPS or projected.
  bool _centerOnProjected = false;

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
          accuracy: data['accuracy'] as double?,
          altitude: data['altitude'] as double?,
          speed: data['speed'] as double?,
          heading: data['heading'] as double?,
        ));

    if (mounted) {
      setState(() => _currentPosition = latLng);
      if (!_centered) {
        _mapController.move(latLng, 16);
        _centered = true;
      }
    }
  }

  Future<void> _offerSaveWalk(WalkRecorderState walk) async {
    final pointCount = walk.points.length;
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.saveWalkTitle),
        content: Text('$pointCount points recorded.\n${AppStrings.saveWalkBody}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.saveWalkDiscard),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.saveWalkSave),
          ),
        ],
      ),
    );
    if (save != true) return;

    // System save dialog: the user picks the destination (Downloads, Drive,
    // SD card …), so the file lives outside the app and survives uninstall.
    final savedPath = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: WalkExporter.toCsvBytes(walk.points),
        fileName: WalkExporter.suggestedFileName(
            walk.startTime ?? walk.points.first.timestamp),
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(savedPath != null
            ? AppStrings.saveWalkDone
            : AppStrings.saveWalkCancelled),
      ),
    );
  }

  Future<void> _importWalk() async {
    final path = await FlutterFileDialog.pickFile(
      params: const OpenFileDialogParams(
        dialogType: OpenFileDialogType.document,
        fileExtensionsFilter: ['csv'],
      ),
    );
    if (path == null) return; // user cancelled

    List<WalkPoint> points = const [];
    try {
      points = WalkImporter.fromCsv(await File(path).readAsString());
    } on FileSystemException {
      // fall through to the empty-points error below
    }
    if (!mounted) return;

    if (points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.importWalkFailed)),
      );
      return;
    }

    setState(() => _importedWalk = points);
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates:
            points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
        padding: const EdgeInsets.all(48),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported walk: ${points.length} points.')),
    );
  }

  void _clearImportedWalk() {
    setState(() => _importedWalk = null);
  }

  /// The walk whose shape gets projected at the anchor: the recorded walk if
  /// it has points, otherwise an imported walk.
  List<WalkPoint>? _projectionSource() {
    final recorded = ref.read(walkRecorderProvider).points;
    if (recorded.isNotEmpty) return recorded;
    return _importedWalk;
  }

  void _setAnchor(LatLng point) {
    if (_projectionSource() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.projectNoWalk)),
      );
      return;
    }
    setState(() => _anchor = point);
  }

  void _clearAnchor() {
    setState(() {
      _anchor = null;
      _projectedPosition = null;
      _centerOnProjected = false;
    });
  }

  void _toggleCenterTarget() {
    setState(() => _centerOnProjected = !_centerOnProjected);
    _recenter();
  }

  void _recenter() {
    final position =
        _centerOnProjected ? _projectedPosition : _currentPosition;
    if (position == null) return;
    _mapController.move(position, _mapController.camera.zoom);
  }

  Future<void> _showGpsRateDialog() async {
    final current = ref.read(gpsSettingsProvider);
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text(AppStrings.gpsRateTitle),
        children: [
          RadioGroup<int>(
            groupValue: current,
            onChanged: (value) => Navigator.pop(ctx, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (seconds, label) in _gpsRateOptions)
                  RadioListTile<int>(
                    value: seconds,
                    title: Text(label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected != null && selected != current) {
      await ref.read(gpsSettingsProvider.notifier).setInterval(selected);
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
        ForegroundService.startService(ref.read(gpsSettingsProvider))
            .then((result) {
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

      // Walk just ended with data on board — offer to export it before the
      // next start clears it.
      if (next.status == RecordingStatus.idle &&
          prev?.status != RecordingStatus.idle &&
          next.points.isNotEmpty) {
        _offerSaveWalk(next);
      }
    });

    // When the GPS rate changes while recording, forward it to the task
    // handler so it restarts its stream without stopping the service.
    ref.listen(gpsSettingsProvider, (prev, next) {
      if (prev != next && _serviceGpsActive) {
        FlutterForegroundTask.sendDataToTask({'interval': next});
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
              accuracy: position.accuracy,
              altitude: position.altitude,
              speed: position.speed,
              heading: position.heading,
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

    // Project the current walk shape at the anchor. Recomputed each build so
    // the projected route and position grow live while recording.
    var projectedRoute = const <LatLng>[];
    final anchor = _anchor;
    if (anchor != null) {
      final source = _projectionSource();
      if (source != null && source.isNotEmpty) {
        projectedRoute = WalkProjector.project(
                WalkProjector.toShape(source), anchor)
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
      }
    }
    _projectedPosition = projectedRoute.isEmpty ? null : projectedRoute.last;

    final importedRoute = _importedWalk
        ?.map((p) => LatLng(p.latitude, p.longitude))
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
        actions: [
          if (_anchor != null)
            IconButton(
              icon: const Icon(Icons.wrong_location),
              tooltip: AppStrings.clearAnchorTooltip,
              onPressed: _clearAnchor,
            ),
          if (_importedWalk != null)
            IconButton(
              icon: const Icon(Icons.layers_clear),
              tooltip: AppStrings.clearImportTooltip,
              onPressed: _clearImportedWalk,
            ),
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: AppStrings.importWalkTooltip,
            onPressed: _importWalk,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: AppStrings.gpsRateTooltip,
            onPressed: _showGpsRateDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(37.7749, -122.4194),
              initialZoom: 13,
              onLongPress: (_, point) => _setAnchor(point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.virtualwalker.app',
              ),
              if (importedRoute != null && importedRoute.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: importedRoute,
                      color: Colors.purple,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              if (projectedRoute.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: projectedRoute,
                      color: Colors.deepOrange,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              if (_projectedPosition != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _projectedPosition!,
                      radius: 10,
                      color: Colors.deepOrange.withValues(alpha: 0.8),
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                    ),
                  ],
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_projectedPosition != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 8),
                    child: FloatingActionButton.small(
                      heroTag: 'centerTargetToggle',
                      tooltip: _centerOnProjected
                          ? AppStrings.centerOnRealTooltip
                          : AppStrings.centerOnProjectedTooltip,
                      backgroundColor:
                          _centerOnProjected ? Colors.deepOrange : null,
                      onPressed: _toggleCenterTarget,
                      child: const Icon(Icons.public),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 12),
                  child: FloatingActionButton(
                    heroTag: 'recenter',
                    tooltip: AppStrings.recenterTooltip,
                    onPressed: (_centerOnProjected
                                ? _projectedPosition
                                : _currentPosition) ==
                            null
                        ? null
                        : _recenter,
                    child: const Icon(Icons.my_location),
                  ),
                ),
                const StatsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
