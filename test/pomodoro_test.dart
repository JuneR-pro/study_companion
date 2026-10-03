// Draft test; the fake clock makes the business logic deterministic.
import 'package:flutter_test/flutter_test.dart';

import 'package:study_companion/services/pomodoro.dart';

void main() {
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
}
