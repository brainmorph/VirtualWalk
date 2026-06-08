import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/walk_point.dart';

part 'walk_recorder_provider.g.dart';

enum RecordingStatus { idle, recording, paused }

class WalkRecorderState {
  const WalkRecorderState({
    this.status = RecordingStatus.idle,
    this.points = const [],
    this.totalDistanceMeters = 0,
    this.startTime,
    this.pausedAt,
    this.stoppedAt,
    this.pausedDuration = Duration.zero,
  });

  final RecordingStatus status;
  final List<WalkPoint> points;
  final double totalDistanceMeters;
  final DateTime? startTime;
  final DateTime? pausedAt;
  final DateTime? stoppedAt;
  final Duration pausedDuration;

  Duration get elapsed {
    if (startTime == null) return Duration.zero;
    final end = stoppedAt ??
        (status == RecordingStatus.paused ? pausedAt : null) ??
        DateTime.now();
    final raw = end.difference(startTime!) - pausedDuration;
    return raw.isNegative ? Duration.zero : raw;
  }

  WalkRecorderState copyWith({
    RecordingStatus? status,
    List<WalkPoint>? points,
    double? totalDistanceMeters,
    DateTime? startTime,
    Object? pausedAt = _absent,
    Object? stoppedAt = _absent,
    Duration? pausedDuration,
  }) =>
      WalkRecorderState(
        status: status ?? this.status,
        points: points ?? this.points,
        totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
        startTime: startTime ?? this.startTime,
        pausedAt: pausedAt == _absent ? this.pausedAt : pausedAt as DateTime?,
        stoppedAt:
            stoppedAt == _absent ? this.stoppedAt : stoppedAt as DateTime?,
        pausedDuration: pausedDuration ?? this.pausedDuration,
      );

  static const _absent = Object();
}

@riverpod
class WalkRecorder extends _$WalkRecorder {
  @override
  WalkRecorderState build() => const WalkRecorderState();

  void start() {
    state = WalkRecorderState(
      status: RecordingStatus.recording,
      startTime: DateTime.now(),
    );
  }

  void pause() {
    if (state.status != RecordingStatus.recording) return;
    state = state.copyWith(
      status: RecordingStatus.paused,
      pausedAt: DateTime.now(),
    );
  }

  void resume() {
    if (state.status != RecordingStatus.paused || state.pausedAt == null) {
      return;
    }
    final pausedFor = DateTime.now().difference(state.pausedAt!);
    state = state.copyWith(
      status: RecordingStatus.recording,
      pausedDuration: state.pausedDuration + pausedFor,
      pausedAt: null,
    );
  }

  void stop() {
    if (state.status == RecordingStatus.idle) return;
    // If currently paused, fold the current pause into pausedDuration.
    if (state.status == RecordingStatus.paused && state.pausedAt != null) {
      final pausedFor = DateTime.now().difference(state.pausedAt!);
      state = state.copyWith(
        status: RecordingStatus.idle,
        stoppedAt: DateTime.now(),
        pausedDuration: state.pausedDuration + pausedFor,
        pausedAt: null,
      );
    } else {
      state = state.copyWith(
        status: RecordingStatus.idle,
        stoppedAt: DateTime.now(),
      );
    }
  }

  void addPoint(WalkPoint point) {
    if (state.status != RecordingStatus.recording) return;
    var additionalDistance = 0.0;
    if (state.points.isNotEmpty) {
      final last = state.points.last;
      additionalDistance = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        point.latitude,
        point.longitude,
      );
    }
    state = state.copyWith(
      points: [...state.points, point],
      totalDistanceMeters: state.totalDistanceMeters + additionalDistance,
    );
  }

  void clear() => state = const WalkRecorderState();
}
