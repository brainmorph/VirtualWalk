import 'dart:convert';
import 'dart:typed_data';

import '../models/walk_point.dart';

class WalkExporter {
  WalkExporter._();

  /// One row per GPS point, raw values, empty cell when a sensor value is
  /// unavailable. Timestamps are ISO 8601 UTC.
  static Uint8List toCsvBytes(List<WalkPoint> points) {
    final buffer = StringBuffer(
        'timestamp,latitude,longitude,accuracy_m,altitude_m,speed_mps,heading_deg\n');
    for (final p in points) {
      buffer
        ..write(p.timestamp.toUtc().toIso8601String())
        ..write(',')
        ..write(p.latitude)
        ..write(',')
        ..write(p.longitude)
        ..write(',')
        ..write(p.accuracy ?? '')
        ..write(',')
        ..write(p.altitude ?? '')
        ..write(',')
        ..write(p.speed ?? '')
        ..write(',')
        ..write(p.heading ?? '')
        ..write('\n');
    }
    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  /// walk_2026-07-05_0830.csv
  static String suggestedFileName(DateTime start) {
    final local = start.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'walk_${local.year}-${two(local.month)}-${two(local.day)}'
        '_${two(local.hour)}${two(local.minute)}.csv';
  }
}
