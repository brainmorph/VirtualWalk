import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

@pragma('vm:entry-point')
void gpsCallbackDispatcher() {
  FlutterForegroundTask.setTaskHandler(GpsTaskHandler());
}

/// Runs in the foreground service isolate. Streams GPS positions and sends
/// every one to the main isolate — no distance filter, no accuracy filter.
class GpsTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _subscription;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final settings = AndroidSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );

    _subscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        FlutterForegroundTask.sendDataToMain({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
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
