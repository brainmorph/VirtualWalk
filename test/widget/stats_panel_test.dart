import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtualwalker/providers/walk_recorder_provider.dart';
import 'package:virtualwalker/widgets/stats_panel.dart';

Widget _buildPanel({WalkRecorderState? state}) {
  return ProviderScope(
    overrides: [
      if (state != null)
        walkRecorderProvider.overrideWith(() => _FakeRecorder(state)),
    ],
    child: const MaterialApp(
      home: Scaffold(body: StatsPanel()),
    ),
  );
}

class _FakeRecorder extends WalkRecorder {
  _FakeRecorder(this._initial);
  final WalkRecorderState _initial;

  @override
  WalkRecorderState build() => _initial;
}

void main() {
  group('StatsPanel', () {
    testWidgets('shows Start, Pause, Stop buttons', (tester) async {
      await tester.pumpWidget(_buildPanel());
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
    });

    testWidgets('Start is enabled and Pause/Stop disabled when idle',
        (tester) async {
      await tester.pumpWidget(_buildPanel(
        state: const WalkRecorderState(status: RecordingStatus.idle),
      ));
      final startBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Start'),
      );
      final pauseBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Pause'),
      );
      final stopBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Stop'),
      );
      expect(startBtn.onPressed, isNotNull);
      expect(pauseBtn.onPressed, isNull);
      expect(stopBtn.onPressed, isNull);
    });

    testWidgets('Pause and Stop enabled when recording', (tester) async {
      await tester.pumpWidget(_buildPanel(
        state: WalkRecorderState(
          status: RecordingStatus.recording,
          startTime: DateTime.now(),
        ),
      ));
      final pauseBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Pause'),
      );
      final stopBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Stop'),
      );
      expect(pauseBtn.onPressed, isNotNull);
      expect(stopBtn.onPressed, isNotNull);
    });

    testWidgets('shows Resume label when paused', (tester) async {
      await tester.pumpWidget(_buildPanel(
        state: WalkRecorderState(
          status: RecordingStatus.paused,
          startTime: DateTime.now(),
          pausedAt: DateTime.now(),
        ),
      ));
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Pause'), findsNothing);
    });

    testWidgets('formats distance under 1 km as metres', (tester) async {
      await tester.pumpWidget(_buildPanel(
        state: const WalkRecorderState(totalDistanceMeters: 450),
      ));
      expect(find.text('450 m'), findsOneWidget);
    });

    testWidgets('formats distance over 1 km in kilometres', (tester) async {
      await tester.pumpWidget(_buildPanel(
        state: const WalkRecorderState(totalDistanceMeters: 2345.6),
      ));
      expect(find.text('2.35 km'), findsOneWidget);
    });
  });
}
