import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/strings.dart';
import 'gps_settings_provider.dart';

part 'location_provider.g.dart';

@riverpod
Stream<Position> locationStream(LocationStreamRef ref) async* {
  // Watching means the stream restarts automatically when the user changes
  // the GPS snapshot interval.
  final intervalSeconds = ref.watch(gpsSettingsProvider);

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied) {
    throw Exception(AppStrings.locationPermissionDenied);
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception(AppStrings.locationPermissionPermanentlyDenied);
  }

  // intervalDuration null = open loop, every fix as fast as it arrives.
  yield* Geolocator.getPositionStream(
    locationSettings: AndroidSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
      intervalDuration:
          intervalSeconds > 0 ? Duration(seconds: intervalSeconds) : null,
    ),
  );
}
