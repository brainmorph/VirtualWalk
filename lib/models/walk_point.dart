class WalkPoint {
  const WalkPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;

  /// Raw sensor extras, kept for export/analysis. Null when the source
  /// didn't provide them.
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
}
