import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/walk_recorder_provider.dart';

class StatsPanel extends ConsumerStatefulWidget {
  const StatsPanel({super.key});

  @override
  ConsumerState<StatsPanel> createState() => _StatsPanelState();
}

class _StatsPanelState extends ConsumerState<StatsPanel> {
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker(RecordingStatus status) {
    if (status == RecordingStatus.recording && _ticker == null) {
      _ticker =
          Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    } else if (status != RecordingStatus.recording) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recorder = ref.watch(walkRecorderProvider);
    final notifier = ref.read(walkRecorderProvider.notifier);
    _syncTicker(recorder.status);

    // Extra bottom padding keeps the buttons above the system navigation bar
    // (the app draws edge-to-edge under it on Android 15+).
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.white.withValues(alpha: 0.93),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(
                label: 'Distance',
                value: _formatDistance(recorder.totalDistanceMeters),
              ),
              _Stat(
                label: 'Time',
                value: _formatDuration(recorder.elapsed),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                label: 'Start',
                color: Colors.green,
                enabled: recorder.status == RecordingStatus.idle,
                onPressed: notifier.start,
              ),
              _ControlButton(
                label: recorder.status == RecordingStatus.paused
                    ? 'Resume'
                    : 'Pause',
                color: Colors.amber.shade700,
                enabled: recorder.status == RecordingStatus.recording ||
                    recorder.status == RecordingStatus.paused,
                onPressed: recorder.status == RecordingStatus.paused
                    ? notifier.resume
                    : notifier.pause,
              ),
              _ControlButton(
                label: 'Stop',
                color: Colors.red,
                enabled: recorder.status != RecordingStatus.idle,
                onPressed: notifier.stop,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey.shade300,
        foregroundColor: enabled ? Colors.white : Colors.grey.shade500,
        minimumSize: const Size(88, 44),
      ),
      child: Text(label),
    );
  }
}
