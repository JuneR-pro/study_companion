// Draft test; the fake clock makes the business logic deterministic.
import 'package:flutter_test/flutter_test.dart';

import 'package:study_companion/services/pomodoro.dart';

void main() {
  test('custom countdown excludes pauses and completes only once', () {
    var now = DateTime(2026, 10, 12);
    final timer = PomodoroTimer(now: () => now);
    timer.reset(customDuration: const Duration(seconds: 10));
    timer.start();
    now = now.add(const Duration(seconds: 4));
    timer.pause();
    now = now.add(const Duration(minutes: 1));
    expect(timer.remaining, const Duration(seconds: 6));
    timer.resume();
    now = now.add(const Duration(seconds: 7));
    expect(timer.isFinished, isTrue);
    expect(timer.complete(subject: '常识')!.duration, const Duration(seconds: 10));
    expect(timer.complete(subject: '常识'), isNull);
    timer.reset(newPreset: PomodoroPreset.minutes45);
    expect(timer.total, const Duration(minutes: 45));
    expect(() => timer.reset(customDuration: Duration.zero), throwsArgumentError);
  });

  test('count-up continues beyond all presets', () {
    var now = DateTime(2026, 10, 12);
    final timer = PomodoroTimer(now: () => now, mode: PomodoroMode.countup);
    timer.start();
    now = now.add(const Duration(hours: 2));
    expect(timer.isFinished, isFalse);
    expect(timer.complete(subject: '常识')!.duration, const Duration(hours: 2));
  });
  test('starts, pauses, resumes, and creates a study session', () {
    var now = DateTime(2026, 2, 10, 8);
    final timer = PomodoroTimer(
      now: () => now,
      preset: PomodoroPreset.minutes25,
    );

    timer.start();
    now = now.add(const Duration(minutes: 10));
    timer.pause();
    expect(timer.elapsed, const Duration(minutes: 10));

    now = now.add(const Duration(minutes: 5));
    timer.resume();
    now = now.add(const Duration(minutes: 15));
    final session = timer.complete(subject: '数学');

    expect(session, isNotNull);
    expect(session!.duration, const Duration(minutes: 25));
    expect(session.source, 'pomodoro');
  });

  test('count-up mode records the actual elapsed duration', () {
    var now = DateTime(2026, 2, 10, 9);
    final timer = PomodoroTimer(
      now: () => now,
      mode: PomodoroMode.countup,
    );

    timer.start();
    now = now.add(const Duration(minutes: 17, seconds: 30));

    expect(timer.isFinished, isFalse);
    final session = timer.complete(subject: '逻辑判断');

    expect(session, isNotNull);
    expect(session!.duration, const Duration(minutes: 17, seconds: 30));
  });

  test('count-down mode reaches finished at the selected preset', () {
    var now = DateTime(2026, 2, 10, 10);
    final timer = PomodoroTimer(
      now: () => now,
      preset: PomodoroPreset.minutes25,
    );

    timer.start();
    now = now.add(const Duration(minutes: 25));

    expect(timer.isFinished, isTrue);
    expect(timer.remaining, Duration.zero);
  });
}
