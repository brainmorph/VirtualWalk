import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/hexagon.dart';
import '../services/hex_grid_generator.dart';

part 'hex_grid_provider.g.dart';

/// The play-mode hexagon grid: 12 hexagons generated around the GPS position
/// when a walk starts, each disappearing once the walker steps inside it.
@riverpod
class HexGrid extends _$HexGrid {
  @override
  List<Hexagon> build() => const [];

  void generate(LatLng center) {
    state = HexGridGenerator.generate(center);
  }

  /// Removes any hexagon containing [point]. No-op if none do.
  void clearContaining(LatLng point) {
    if (state.isEmpty) return;
    final remaining = state.where((h) => !h.contains(point)).toList();
    if (remaining.length != state.length) state = remaining;
  }

  void clear() {
    if (state.isNotEmpty) state = const [];
  }
}
