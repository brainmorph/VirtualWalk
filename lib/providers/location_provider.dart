import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/strings.dart';

part 'location_provider.g.dart';

@riverpod
Stream<Position> locationStream(LocationStreamRef ref) async* {
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

  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    ),
  );
}
