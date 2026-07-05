import '../models/walk_point.dart';

class WalkImporter {
  WalkImporter._();

  /// Parses CSV produced by [WalkExporter.toCsvBytes]. Tolerant of missing
  /// optional columns and blank cells; rows that don't parse are skipped.
  static List<WalkPoint> fromCsv(String csv) {
    final lines = csv.split(RegExp(r'\r?\n'));
    final points = <WalkPoint>[];

    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final cells = line.split(',');
      if (cells.length < 3) continue;

      final timestamp = DateTime.tryParse(cells[0]);
      final lat = double.tryParse(cells[1]);
      final lng = double.tryParse(cells[2]);
      if (timestamp == null || lat == null || lng == null) continue;

      double? optional(int index) =>
          index < cells.length ? double.tryParse(cells[index]) : null;

      points.add(WalkPoint(
        latitude: lat,
        longitude: lng,
        timestamp: timestamp,
        accuracy: optional(3),
        altitude: optional(4),
        speed: optional(5),
        heading: optional(6),
      ));
    }
    return points;
  }
}
