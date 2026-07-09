import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/hexagon.dart';

/// Builds the play-mode hex grid: a tight, edge-to-edge tiling of 12 regular
/// hexagons (100 m sides) surrounding a center point.
///
/// The center point is placed on a lattice vertex shared by three hexagons —
/// not inside any single one — so the grid surrounds the walker instead of
/// starting under their feet. Vertices are placed with the same WGS84
/// geodesic offset used by WalkProjector, so the tiling is correct at any
/// latitude rather than a flat-earth approximation.
class HexGridGenerator {
  HexGridGenerator._();

  /// Vincenty on the WGS84 ellipsoid; roundResult off so tiny offsets at
  /// hexagon scale don't get quantized to whole meters.
  static const _geodesic = Distance(roundResult: false);

  static const sideMeters = 100.0;
  static const hexCount = 12;
  static const _vertexAnglesDeg = [30, 90, 150, 210, 270, 330];

  static List<Hexagon> generate(LatLng center) {
    const s = sideMeters;

    // Pointy-top axial hex grid, centers expressed as (east, north) meters
    // from `center`. The `-s` shift on y moves the lattice vertex that would
    // sit above hex (0,0) down onto the origin, so `center` becomes a shared
    // vertex of three hexagons rather than the center of one.
    final centers = <(double east, double north)>[];
    for (var q = -3; q <= 3; q++) {
      for (var r = -3; r <= 3; r++) {
        final east = s * math.sqrt(3) * (q + r / 2);
        final north = s * 1.5 * r - s;
        centers.add((east, north));
      }
    }
    centers.sort((a, b) =>
        (a.$1 * a.$1 + a.$2 * a.$2).compareTo(b.$1 * b.$1 + b.$2 * b.$2));

    return [
      for (var i = 0; i < hexCount; i++)
        Hexagon(
          id: i,
          vertices: _hexagonVertices(center, centers[i].$1, centers[i].$2, s),
        ),
    ];
  }

  static List<LatLng> _hexagonVertices(
      LatLng center, double east, double north, double s) {
    return [
      for (final angleDeg in _vertexAnglesDeg)
        _offset(
          center,
          east + s * math.cos(angleDeg * math.pi / 180),
          north + s * math.sin(angleDeg * math.pi / 180),
        ),
    ];
  }

  /// Converts a local east/north meter offset from [origin] to a geographic
  /// point via the WGS84 direct geodesic problem.
  static LatLng _offset(LatLng origin, double eastMeters, double northMeters) {
    final distance =
        math.sqrt(eastMeters * eastMeters + northMeters * northMeters);
    if (distance == 0) return origin;
    final bearing =
        (math.atan2(eastMeters, northMeters) * 180 / math.pi + 360) % 360;
    return _geodesic.offset(origin, distance, bearing);
  }
}
