import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gps_settings_provider.g.dart';

/// GPS snapshot interval in seconds. 0 means open loop — every fix the
/// hardware delivers is taken, as fast as it can go.
@riverpod
class GpsSettings extends _$GpsSettings {
  static const _boxName = 'settings';
  static const _intervalKey = 'gpsInterval';

  @override
  int build() {
    // The settings box is opened in main() before runApp, so synchronous
    // access here is safe.
    return Hive.box(_boxName).get(_intervalKey, defaultValue: 0) as int;
  }

  Future<void> setInterval(int seconds) async {
    await Hive.box(_boxName).put(_intervalKey, seconds);
    state = seconds;
  }
}
