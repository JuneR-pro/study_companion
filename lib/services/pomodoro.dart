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

/// The timer can either count down from the selected preset or count up from
/// zero until the user finishes it manually.
enum PomodoroMode { countdown, countup }

/// Timer business logic without Flutter widgets or a periodic Timer.
/// A Flutter controller can call [elapsed], [remaining] and [progress] on
/// rebuilds, and call [start], [pause], [resume], [reset] or [complete].
class PomodoroTimer {
  PomodoroTimer({
    this.preset = PomodoroPreset.minutes25,
    this.mode = PomodoroMode.countdown,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  PomodoroPreset preset;
  PomodoroMode mode;
  final DateTime Function() _now;
  PomodoroStatus status = PomodoroStatus.idle;
  DateTime? _sessionStartedAt;
  DateTime? _runningSince;
  Duration _accumulated = Duration.zero;

  Duration? _customDuration;
  Duration get total => _customDuration ?? preset.duration;

  Duration get elapsed {
    if (status == PomodoroStatus.running && _runningSince != null) {
      return _accumulated + _now().difference(_runningSince!);
    }
    return _accumulated;
  }

  Duration get remaining {
    if (mode == PomodoroMode.countup) return elapsed;
    final value = total - elapsed;
    return value.isNegative ? Duration.zero : value;
  }

  double get progress {
    // A count-up timer has no target duration. The UI uses the empty ring as
    // a visual container and the elapsed time as the only source of truth.
    if (mode == PomodoroMode.countup) return 0;
    if (total.inMilliseconds == 0) return 0;
    final value = elapsed.inMilliseconds / total.inMilliseconds;
    return value.clamp(0, 1).toDouble();
  }

  bool get isFinished =>
      mode == PomodoroMode.countdown && elapsed >= total;

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

  void reset({PomodoroPreset? newPreset, PomodoroMode? newMode, Duration? customDuration}) {
    if (customDuration != null && customDuration <= Duration.zero) {
      throw ArgumentError.value(customDuration, 'customDuration');
    }
    if (newPreset != null) {
      preset = newPreset;
      _customDuration = null;
    }
    if (customDuration != null) _customDuration = customDuration;
    if (newMode != null) mode = newMode;
    status = PomodoroStatus.idle;
    _sessionStartedAt = null;
    _runningSince = null;
    _accumulated = Duration.zero;
  }

  StudySession? complete({required String subject, String? note, String? id}) {
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
      duration: mode == PomodoroMode.countdown && elapsed > total
          ? total
          : elapsed,
      source: 'pomodoro',
      note: note,
    );
  }
}
