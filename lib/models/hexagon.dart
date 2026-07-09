import 'package:latlong2/latlong.dart';

/// A single cell of the play-mode hex grid.
class Hexagon {
  const Hexagon({required this.id, required this.vertices});

  final int id;
  final List<LatLng> vertices;

  /// Ray-casting point-in-polygon test (PNPOLY), treating lng/lat as a flat
  /// plane — accurate enough at hexagon scale (~100 m).
  bool contains(LatLng point) {
    var inside = false;
    for (var i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
      final vi = vertices[i];
      final vj = vertices[j];
      final crosses =
          (vi.latitude > point.latitude) != (vj.latitude > point.latitude);
      if (!crosses) continue;
      final lngAtPointLat = vi.longitude +
          (point.latitude - vi.latitude) *
              (vj.longitude - vi.longitude) /
              (vj.latitude - vi.latitude);
      if (point.longitude < lngAtPointLat) inside = !inside;
    }
    return inside;
  }
}
