import 'dart:async';

import 'package:flutter/material.dart';

import '../models/study_session.dart';
import '../services/pomodoro.dart';

class PomodoroCard extends StatefulWidget {
  const PomodoroCard({super.key, this.subject = '未分类', this.onCompleted});

  final String subject;
  final ValueChanged<StudySession>? onCompleted;

  @override
  State<PomodoroCard> createState() => _PomodoroCardState();
}

class _PomodoroCardState extends State<PomodoroCard> {
  final PomodoroTimer _timer = PomodoroTimer();
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _refreshEverySecond() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _toggleRunning() {
    setState(() {
      switch (_timer.status) {
        case PomodoroStatus.idle:
          _timer.start();
          _refreshEverySecond();
          break;
        case PomodoroStatus.running:
          _timer.pause();
          break;
        case PomodoroStatus.paused:
          _timer.resume();
          break;
        case PomodoroStatus.completed:
          _timer.reset();
          _timer.start();
          break;
      }
    });
  }

  void _complete() {
    final session = _timer.complete(subject: widget.subject);
    if (session == null) return;
    setState(() {});
    widget.onCompleted?.call(session);
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inHours.toString().padLeft(2, '0')}:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('番茄钟', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('科目：${widget.subject}'),
            DropdownButton<PomodoroPreset>(
              value: _timer.preset,
              onChanged: _timer.status == PomodoroStatus.idle
                  ? (value) {
                      if (value == null) return;
                      setState(() => _timer.reset(newPreset: value));
                    }
                  : null,
              items: PomodoroPreset.values
                  .map((preset) => DropdownMenuItem(
                        value: preset,
                        child: Text('${preset.minutes} 分钟'),
                      ))
                  .toList(),
            ),
            LinearProgressIndicator(value: _timer.progress),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _format(_timer.remaining),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _toggleRunning,
                  child: Text(_timer.status == PomodoroStatus.running ? '暂停' : '开始/继续'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _timer.status == PomodoroStatus.idle ? null : _complete,
                  child: const Text('完成并记录'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _timer.reset()),
                  tooltip: '重置',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
