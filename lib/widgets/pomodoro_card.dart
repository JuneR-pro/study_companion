import 'dart:async';

import 'package:flutter/material.dart';

import '../models/study_session.dart';
import '../services/pomodoro.dart';
import '../utils/study_theme.dart';

class PomodoroCard extends StatefulWidget {
  const PomodoroCard({
    super.key,
    this.initialSubject = '言语理解',
    this.onCompleted,
    this.todayDuration = Duration.zero,
  });

  final String initialSubject;
  final ValueChanged<StudySession>? onCompleted;
  final Duration todayDuration;

  @override
  State<PomodoroCard> createState() => _PomodoroCardState();
}

class _PomodoroCardState extends State<PomodoroCard> {
  late String _subject;
  final PomodoroTimer _timer = PomodoroTimer();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _subject = widget.initialSubject;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timer.status == PomodoroStatus.running && _timer.isFinished) {
        _complete();
      }
      if (mounted) setState(() {});
    });
  }

  void _selectPreset(PomodoroPreset preset) {
    if (_timer.status != PomodoroStatus.idle) return;
    setState(() => _timer.reset(newPreset: preset));
  }

  void _selectSubject(String subject) {
    if (_timer.status != PomodoroStatus.idle) return;
    setState(() => _subject = subject);
  }

  void _toggle() {
    setState(() {
      switch (_timer.status) {
        case PomodoroStatus.idle:
          _timer.start();
          _ensureTicker();
          break;
        case PomodoroStatus.running:
          _timer.pause();
          break;
        case PomodoroStatus.paused:
          _timer.resume();
          _ensureTicker();
          break;
        case PomodoroStatus.completed:
          _timer.reset();
          _timer.start();
          _ensureTicker();
          break;
      }
    });
  }

  void _complete() {
    final session = _timer.complete(subject: _subject);
    if (session == null) return;
    setState(() {});
    widget.onCompleted?.call(session);
  }

  String _format(Duration duration) {
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inMinutes.toString().padLeft(2, '0')}:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = StudySubject.fromLabel(_subject).color;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '番茄钟',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '今日 ${widget.todayDuration.inHours}小时${widget.todayDuration.inMinutes.remainder(60)}分',
                  style: const TextStyle(color: StudyTheme.muted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: PomodoroPreset.values.map((preset) {
                final selected = preset.duration == _timer.total;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Center(child: Text('${preset.minutes}分钟')),
                      selected: selected,
                      onSelected: (_) => _selectPreset(preset),
                      selectedColor: activeColor,
                      backgroundColor: const Color(0xFFF1EFEC),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : StudyTheme.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: StudySubject.values.map((subject) {
                final selected = subject.label == _subject;
                return ChoiceChip(
                  label: Text(subject.label),
                  selected: selected,
                  onSelected: (_) => _selectSubject(subject.label),
                  selectedColor: subject.color,
                  backgroundColor: subject.color.withValues(alpha: .28),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : StudyTheme.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 248,
                height: 248,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 230,
                      height: 230,
                      child: CircularProgressIndicator(
                        value: _timer.progress,
                        strokeWidth: 13,
                        backgroundColor: activeColor.withValues(alpha: .2),
                        color: activeColor,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _format(_timer.remaining),
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _subject,
                          style: TextStyle(
                            color: activeColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: () => setState(() => _timer.reset()),
                  icon: const Icon(Icons.refresh),
                  tooltip: '重置',
                ),
                const SizedBox(width: 18),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: activeColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(64, 64),
                  ),
                  onPressed: _toggle,
                  icon: Icon(
                    _timer.status == PomodoroStatus.running
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 18),
                IconButton.filledTonal(
                  onPressed: _timer.status == PomodoroStatus.idle
                      ? null
                      : _complete,
                  icon: const Icon(Icons.check),
                  tooltip: '完成并记录',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
