import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:virtualwalker/models/walk_point.dart';
import 'package:virtualwalker/services/walk_projector.dart';

void main() {
  const geodesic = Distance(roundResult: false);

  final t0 = DateTime.utc(2026, 7, 5, 14);
  WalkPoint wp(double lat, double lng, int seconds) => WalkPoint(
      latitude: lat, longitude: lng, timestamp: t0.add(Duration(seconds: seconds)));

  double segment(WalkPoint a, WalkPoint b) => geodesic.as(LengthUnit.Meter,
      LatLng(a.latitude, a.longitude), LatLng(b.latitude, b.longitude));

  // Roughly a 4-leg loop near downtown Champaign, IL (~40.1°N).
  final champaignWalk = [
    wp(40.11380, -88.24310, 0),
    wp(40.11560, -88.24310, 60), // ~200 m north
    wp(40.11560, -88.24075, 120), // ~200 m east
    wp(40.11380, -88.24075, 180), // ~200 m south
    wp(40.11380, -88.24310, 240), // back to start
  ];

  test('round trip at the source origin reproduces the walk', () {
    final shape = WalkProjector.toShape(champaignWalk);
    final projected = WalkProjector.project(
        shape, const LatLng(40.11380, -88.24310));

    for (var i = 0; i < champaignWalk.length; i++) {
      expect(projected[i].latitude,
          closeTo(champaignWalk[i].latitude, 1e-9));
      expect(projected[i].longitude,
          closeTo(champaignWalk[i].longitude, 1e-9));
      expect(projected[i].timestamp, champaignWalk[i].timestamp);
    }
  });

  test('projection to Tromsø (69.6°N) preserves segment lengths', () {
    final shape = WalkProjector.toShape(champaignWalk);
    final projected = WalkProjector.project(
        shape, const LatLng(69.6492, 18.9553));

    // Same shape: every leg length must survive the move to high latitude.
    // Tolerance 5 cm on ~200 m legs (the tiny residual is the inherent
    // curvature difference between the two anchor latitudes).
    for (var i = 1; i < champaignWalk.length; i++) {
      final original = segment(champaignWalk[i - 1], champaignWalk[i]);
      final moved = segment(projected[i - 1], projected[i]);
      expect(moved, closeTo(original, 0.05),
          reason: 'segment $i changed length');
    }

    // A naive fixed lat/lng offset would fail exactly here: at 69.6°N one
    // degree of longitude is ~39 km instead of ~85 km, so the east-west legs
    // would shrink to less than half their length.
  });

  test('projection to Cape Town (33.9°S) preserves segment lengths', () {
    final shape = WalkProjector.toShape(champaignWalk);
    final projected = WalkProjector.project(
        shape, const LatLng(-33.9249, 18.4241));

    for (var i = 1; i < champaignWalk.length; i++) {
      expect(segment(projected[i - 1], projected[i]),
          closeTo(segment(champaignWalk[i - 1], champaignWalk[i]), 0.05));
    }
  });

  test('90° rotation turns the northbound first leg eastbound', () {
    final shape = WalkProjector.toShape(champaignWalk);
    const chicago = LatLng(41.8781, -87.6298);
    final projected =
        WalkProjector.project(shape, chicago, rotationDegrees: 90);

    final firstLegBearing = geodesic.bearing(
      LatLng(projected[0].latitude, projected[0].longitude),
      LatLng(projected[1].latitude, projected[1].longitude),
    );
    // Original first leg heads ~0° (north); rotated it must head ~90° (east).
    expect((firstLegBearing - 90).abs(), lessThan(0.5));

    // Rotation is rigid: lengths unchanged.
    for (var i = 1; i < champaignWalk.length; i++) {
      expect(segment(projected[i - 1], projected[i]),
          closeTo(segment(champaignWalk[i - 1], champaignWalk[i]), 0.05));
    }
  });

  test('walk projected across the antimeridian stays continuous', () {
    final shape = WalkProjector.toShape(champaignWalk);
    // Taveuni, Fiji — the 180° meridian runs through the island.
    final projected = WalkProjector.project(
        shape, const LatLng(-16.8500, 179.9990));

    for (var i = 1; i < champaignWalk.length; i++) {
      expect(segment(projected[i - 1], projected[i]),
          closeTo(segment(champaignWalk[i - 1], champaignWalk[i]), 0.05));
    }
  });
}
