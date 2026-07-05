import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'gps_task_handler.dart';

class ForegroundService {
  ForegroundService._();

  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'vw_walk_recording',
        channelName: 'Walk Recording',
        channelDescription: 'Active GPS walk recording',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        autoRunOnBoot: false,
        allowAutoRestart: false,
        // stopWithTask in this plugin version stops the service as soon as
        // the activity is paused (home / screen off), not just on task
        // removal — it must stay false or background GPS dies instantly.
        stopWithTask: false,
      ),
    );
  }

  static Future<ServiceRequestResult> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return const ServiceRequestSuccess();
    }
    return FlutterForegroundTask.startService(
      serviceTypes: [ForegroundServiceTypes.location],
      notificationTitle: 'VirtualWalker',
      notificationText: 'Recording your walk…',
      callback: gpsCallbackDispatcher,
    );
  }

  static Future<void> stopService() async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }
}
