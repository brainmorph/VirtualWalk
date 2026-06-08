import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtualwalker/models/walk_point.dart';
import 'package:virtualwalker/providers/walk_recorder_provider.dart';

WalkPoint _point(double lat, double lng) => WalkPoint(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2024),
    );

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('WalkRecorder', () {
    test('initial state is idle with no points', () {
      final c = _container();
      final state = c.read(walkRecorderProvider);
      expect(state.status, RecordingStatus.idle);
      expect(state.points, isEmpty);
      expect(state.totalDistanceMeters, 0);
    });

    test('start() sets status to recording', () {
      final c = _container();
      c.read(walkRecorderProvider.notifier).start();
      expect(c.read(walkRecorderProvider).status, RecordingStatus.recording);
    });

    test('start() records a startTime', () {
      final c = _container();
      final before = DateTime.now();
      c.read(walkRecorderProvider.notifier).start();
      final after = DateTime.now();
      final startTime = c.read(walkRecorderProvider).startTime!;
      expect(
        startTime.isAfter(before.subtract(const Duration(milliseconds: 1))),
        isTrue,
      );
      expect(startTime.isBefore(after.add(const Duration(milliseconds: 1))),
          isTrue);
    });

    test('pause() sets status to paused', () {
      final c = _container();
      c.read(walkRecorderProvider.notifier).start();
      c.read(walkRecorderProvider.notifier).pause();
      expect(c.read(walkRecorderProvider).status, RecordingStatus.paused);
    });

    test('pause() is a no-op when idle', () {
      final c = _container();
      c.read(walkRecorderProvider.notifier).pause();
      expect(c.read(walkRecorderProvider).status, RecordingStatus.idle);
    });

    test('resume() sets status back to recording', () {
      final c = _container();
      c.read(walkRecorderProvider.notifier).start();
      c.read(walkRecorderProvider.notifier).pause();
      c.read(walkRecorderProvider.notifier).resume();
      expect(c.read(walkRecorderProvider).status, RecordingStatus.recording);
    });

    test('stop() sets status to idle', () {
      final c = _container();
      c.read(walkRecorderProvider.notifier).start();
      c.read(walkRecorderProvider.notifier).stop();
      expect(c.read(walkRecorderProvider).status, RecordingStatus.idle);
    });

    test('stop() is a no-op when already idle', () {
      final c = _container();
      c.read(walkRecorderProvider.notifier).stop();
      expect(c.read(walkRecorderProvider).status, RecordingStatus.idle);
    });

    test('addPoint() is ignored when idle', () {
      final c = _container();
      c.read(walkRecorderProvider.notifier).addPoint(_point(1, 1));
      expect(c.read(walkRecorderProvider).points, isEmpty);
    });

    test('addPoint() is ignored when paused', () {
      final c = _container();
      c.read(walkRecorderProvider.notifier).start();
      c.read(walkRecorderProvider.notifier).pause();
      c.read(walkRecorderProvider.notifier).addPoint(_point(1, 1));
      expect(c.read(walkRecorderProvider).points, isEmpty);
    });

    test('addPoint() accumulates points when recording', () {
      final c = _container();
      c.read(walkRecorderProvider.notifier).start();
      c.read(walkRecorderProvider.notifier).addPoint(_point(37.0, -122.0));
      c.read(walkRecorderProvider.notifier).addPoint(_point(37.001, -122.0));
      expect(c.read(walkRecorderProvider).points.length, 2);
    });

    test('addPoint() accumulates distance', () {
      final c = _container();
      c.read(walkRecorderProvider.notifier).start();
      c.read(walkRecorderProvider.notifier).addPoint(_point(37.0, -122.0));
      c.read(walkRecorderProvider.notifier).addPoint(_point(37.001, -122.0));
      expect(
        c.read(walkRecorderProvider).totalDistanceMeters,
        greaterThan(0),
      );
    });

    test('clear() resets to initial state', () {
      final c = _container();
      c.read(walkRecorderProvider.notifier).start();
      c.read(walkRecorderProvider.notifier).addPoint(_point(37.0, -122.0));
      c.read(walkRecorderProvider.notifier).clear();
      final state = c.read(walkRecorderProvider);
      expect(state.status, RecordingStatus.idle);
      expect(state.points, isEmpty);
      expect(state.totalDistanceMeters, 0);
    });

    test('elapsed is zero before starting', () {
      final c = _container();
      expect(c.read(walkRecorderProvider).elapsed, Duration.zero);
    });

    test('elapsed is positive while recording', () {
      // Test the elapsed getter directly with a known past startTime.
      final state = WalkRecorderState(
        status: RecordingStatus.recording,
        startTime: DateTime.now().subtract(const Duration(seconds: 5)),
      );
      expect(state.elapsed, greaterThan(Duration.zero));
      expect(state.elapsed.inSeconds, greaterThanOrEqualTo(4));
    });
  });
}
