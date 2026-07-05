import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

@pragma('vm:entry-point')
void gpsCallbackDispatcher() {
  FlutterForegroundTask.setTaskHandler(GpsTaskHandler());
}

/// Runs in the foreground service isolate. Streams GPS positions and sends
/// every one to the main isolate — no distance filter, no accuracy filter.
/// The snapshot interval (seconds, 0 = open loop) is read from saved data at
/// start and can be changed live via sendDataToTask({'interval': n}).
class GpsTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _subscription;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final intervalSeconds =
        await FlutterForegroundTask.getData<int>(key: 'gpsInterval') ?? 0;
    _startGps(intervalSeconds);
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map && data['interval'] is int) {
      _startGps(data['interval'] as int);
    }
  }

  void _startGps(int intervalSeconds) {
    _subscription?.cancel();

    final settings = AndroidSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
      intervalDuration:
          intervalSeconds > 0 ? Duration(seconds: intervalSeconds) : null,
    );

    _subscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        FlutterForegroundTask.sendDataToMain({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'speed': position.speed,
          'heading': position.heading,
          'timestamp': position.timestamp.millisecondsSinceEpoch,
        });
      },
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
