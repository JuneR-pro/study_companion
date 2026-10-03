import '../models/study_session.dart';

enum PomodoroPreset {
  minutes25(25),
  minutes45(45),
  minutes60(60);

  const PomodoroPreset(this.minutes);
  final int minutes;
  Duration get duration => Duration(minutes: minutes);
}

enum PomodoroStatus { idle, running, paused, completed }

/// Timer business logic without Flutter widgets or a periodic Timer.
/// A Flutter controller can call [elapsed], [remaining] and [progress] on
/// rebuilds, and call [start], [pause], [resume], [reset] or [complete].
class PomodoroTimer {
  PomodoroTimer({
    PomodoroPreset preset = PomodoroPreset.minutes25,
    DateTime Function()? now,
  })  : preset = preset,
        _now = now ?? DateTime.now;

  PomodoroPreset preset;
  final DateTime Function() _now;
  PomodoroStatus status = PomodoroStatus.idle;
  DateTime? _sessionStartedAt;
  DateTime? _runningSince;
  Duration _accumulated = Duration.zero;

  Duration get total => preset.duration;

  Duration get elapsed {
    if (status == PomodoroStatus.running && _runningSince != null) {
      return _accumulated + _now().difference(_runningSince!);
    }
    return _accumulated;
  }

  Duration get remaining {
    final value = total - elapsed;
    return value.isNegative ? Duration.zero : value;
  }

  double get progress {
    if (total.inMilliseconds == 0) return 0;
    final value = elapsed.inMilliseconds / total.inMilliseconds;
    return value.clamp(0, 1).toDouble();
  }

  bool get isFinished => elapsed >= total;

  void start() {
    if (status != PomodoroStatus.idle) return;
    _sessionStartedAt = _now();
    _runningSince = _sessionStartedAt;
    _accumulated = Duration.zero;
    status = PomodoroStatus.running;
  }

  void pause() {
    if (status != PomodoroStatus.running || _runningSince == null) return;
    _accumulated += _now().difference(_runningSince!);
    _runningSince = null;
    status = PomodoroStatus.paused;
  }

  void resume() {
    if (status != PomodoroStatus.paused) return;
    _runningSince = _now();
    status = PomodoroStatus.running;
  }

  void reset({PomodoroPreset? newPreset}) {
    if (newPreset != null) preset = newPreset;
    status = PomodoroStatus.idle;
    _sessionStartedAt = null;
    _runningSince = null;
    _accumulated = Duration.zero;
  }

  StudySession? complete({
    required String subject,
    String? note,
    String? id,
  }) {
    if (_sessionStartedAt == null ||
        status == PomodoroStatus.idle ||
        status == PomodoroStatus.completed) {
      return null;
    }
    if (status == PomodoroStatus.running) pause();
    status = PomodoroStatus.completed;
    final end = _now();
    return StudySession(
      id: id ?? 'pomodoro-${end.microsecondsSinceEpoch}',
      subject: subject,
      startTime: _sessionStartedAt!,
      endTime: end,
      duration: elapsed,
      source: 'pomodoro',
      note: note,
    );
  }
}
