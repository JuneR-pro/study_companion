import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/study_session.dart';
import '../services/overlay_service.dart';
import '../services/pomodoro.dart';
import '../services/timer_state.dart';
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
  bool _notified = false;
  static const _reminder = MethodChannel('study_companion/reminder');
  bool _overlayPermissionGranted = false;

  Future<void> _checkOverlayPermission() async {
    final canDraw = await OverlayService.canDrawOverlays();
    if (mounted) {
      setState(() => _overlayPermissionGranted = canDraw);
    }
  }

  Future<void> _requestOverlayPermission() async {
    await OverlayService.requestOverlayPermission();
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkOverlayPermission();
  }

  Future<void> _startOverlayWithPermission() async {
    if (!_overlayPermissionGranted) {
      await _requestOverlayPermission();
    }
    if (_overlayPermissionGranted) {
      await OverlayService.startOverlay(subject: _subject);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请授予悬浮窗权限以启用后台计时功能'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _playReminder() async {
    try {
      final warning = await _reminder.invokeMethod<String>('play');
      if (mounted && warning != null && warning.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(warning)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('提醒调用失败，请安装最新 Android APK 后重试')),
        );
      }
    }
  }

  Future<void> _customTime() async {
    final duration = await showDialog<Duration>(
      context: context,
      builder: (_) => const _DurationDialog(),
    );
    if (!mounted || duration == null) return;
    setState(() {
      _timer.reset(customDuration: duration);
      _notified = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _subject = widget.initialSubject;
    _checkOverlayPermission();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_timer.status == PomodoroStatus.running && _timer.isFinished) {
        _notifyCompletion();
        _complete();
      }
      if (mounted) {
        setState(() {});
        final isRunning = await OverlayService.isOverlayRunning();
        if (isRunning) {
          final displayed = _timer.mode == PomodoroMode.countdown
              ? _timer.remaining
              : _timer.elapsed;
          OverlayService.updateOverlay(
            time: _format(displayed),
            subject: _subject,
          );
        }
      }
    });
  }

  void _selectPreset(PomodoroPreset preset) {
    if (_timer.status != PomodoroStatus.idle) return;
    setState(() => _timer.reset(newPreset: preset));
  }

  void _selectMode(PomodoroMode mode) {
    if (_timer.status != PomodoroStatus.idle) return;
    setState(() => _timer.reset(newMode: mode));
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
          TimerState.instance.setRunning(true, subject: _subject);
          _startOverlayWithPermission();
          break;
        case PomodoroStatus.running:
          _timer.pause();
          TimerState.instance.setRunning(false);
          break;
        case PomodoroStatus.paused:
          _timer.resume();
          _ensureTicker();
          TimerState.instance.setRunning(true, subject: _subject);
          break;
        case PomodoroStatus.completed:
          _timer.reset();
          _timer.start();
          _notified = false;
          _ensureTicker();
          TimerState.instance.setRunning(true, subject: _subject);
          _startOverlayWithPermission();
          break;
      }
    });
  }

  void _complete() {
    final session = _timer.complete(subject: _subject);
    if (session == null) return;
    TimerState.instance.setRunning(false);
    OverlayService.stopOverlay();
    setState(() {});
    widget.onCompleted?.call(session);
  }

  void _notifyCompletion() {
    if (_notified) return;
    _notified = true;
    unawaited(_playReminder());
  }

  String _format(Duration duration) {
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inMinutes.toString().padLeft(2, '0')}:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = StudySubject.fromLabel(_subject).color;
    final displayedDuration = _timer.mode == PomodoroMode.countdown
        ? _timer.remaining
        : _timer.elapsed;
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
            SegmentedButton<PomodoroMode>(
              segments: const [
                ButtonSegment(
                  value: PomodoroMode.countdown,
                  label: Text('倒计时'),
                  icon: Icon(Icons.timer_outlined),
                ),
                ButtonSegment(
                  value: PomodoroMode.countup,
                  label: Text('正计时'),
                  icon: Icon(Icons.more_time),
                ),
              ],
              selected: {_timer.mode},
              onSelectionChanged: (selection) =>
                  _selectMode(selection.first),
            ),
            if (_timer.mode == PomodoroMode.countdown) ...[
              const SizedBox(height: 12),
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
              TextButton.icon(
                onPressed: _timer.status == PomodoroStatus.idle ||
                    _timer.status == PomodoroStatus.completed ? _customTime : null,
                icon: const Icon(Icons.edit_outlined),
                label: Text('自定义时长（当前 ${_format(_timer.total)}）'),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  '自由计时，完成后点击勾号结束并记录',
                  style: TextStyle(color: StudyTheme.muted),
                ),
              ),
            TextButton.icon(
              onPressed: _playReminder,
              icon: const Icon(Icons.volume_up_outlined),
              label: const Text('测试铃声和震动（5秒）'),
            ),
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
                          _format(displayedDuration),
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
                  onPressed: () {
                    TimerState.instance.setRunning(false);
                    OverlayService.stopOverlay();
                    setState(() {
                      _timer.reset();
                      _notified = false;
                    });
                  },
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

class _DurationDialog extends StatefulWidget {
  const _DurationDialog();
  @override
  State<_DurationDialog> createState() => _DurationDialogState();
}

class _DurationDialogState extends State<_DurationDialog> {
  final _form = GlobalKey<FormState>();
  final _minutes = TextEditingController(text: '25');
  final _seconds = TextEditingController(text: '0');

  @override
  void dispose() {
    _minutes.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('自定义倒计时'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: _minutes,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: '分钟（0–1440）'),
            validator: (value) {
              final n = int.tryParse(value ?? '');
              return n == null || n < 0 || n > 1440 ? '请输入0–1440分钟' : null;
            },
          ),
          TextFormField(
            controller: _seconds,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: '秒（0–59）'),
            validator: (value) {
              final n = int.tryParse(value ?? '');
              if (n == null || n < 0 || n > 59) return '请输入0–59秒';
              if ((int.tryParse(_minutes.text) ?? 0) == 0 && n == 0) return '时长必须大于0';
              return null;
            },
          ),
        ]),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
      FilledButton(onPressed: () {
        if (!_form.currentState!.validate()) return;
        Navigator.pop(context, Duration(minutes: int.parse(_minutes.text), seconds: int.parse(_seconds.text)));
      }, child: const Text('确定')),
    ],
  );
}
