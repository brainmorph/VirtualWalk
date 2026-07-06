/// One point of a walk expressed as a geodesic displacement from the walk's
/// origin: "d meters from the origin, along initial bearing θ degrees true".
///
/// This is the portable "shape" of a walk. It contains no absolute
/// coordinates, so it can be re-anchored anywhere on Earth with the WGS84
/// direct geodesic problem, and rotated by simply offsetting every bearing.
class WalkDisplacement {
  const WalkDisplacement({
    required this.distanceMeters,
    required this.bearingDegrees,
    required this.timestamp,
  });

  /// Geodesic (ellipsoidal surface) distance from the walk origin.
  final double distanceMeters;

  /// Initial azimuth at the origin of the geodesic to this point,
  /// degrees clockwise from true north.
  final double bearingDegrees;

  /// Original capture time, preserved so a projected walk can still be
  /// replayed / exported with real timing.
  final DateTime timestamp;
}
