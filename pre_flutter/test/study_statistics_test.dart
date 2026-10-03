// Draft test. Run after installing Dart/Flutter with `dart test` or
// `flutter test`; it has not been executed in the current environment.
import 'package:test/test.dart';

import '../lib/models/study_session.dart';
import '../lib/services/study_statistics.dart';

StudySession session(String id, String subject, DateTime start, int minutes) {
  return StudySession(
    id: id,
    subject: subject,
    startTime: start,
    endTime: start.add(Duration(minutes: minutes)),
    duration: Duration(minutes: minutes),
    source: 'manual',
  );
}

void main() {
  final day = DateTime(2026, 2, 10);
  final sessions = [
    session('1', '数学', day.add(const Duration(hours: 8)), 45),
    session('2', '英语', day.add(const Duration(hours: 10)), 30),
    session('3', '数学', day.add(const Duration(days: 1, hours: 8)), 60),
  ];

  test('calculates total study time for a date', () {
    expect(StudyStatistics.totalForDate(sessions, day), const Duration(minutes: 75));
  });

  test('calculates daily durations for a month', () {
    final daily = StudyStatistics.dailyDurationsForMonth(sessions, day);
    expect(daily['2026-02-10'], const Duration(minutes: 75));
    expect(daily['2026-02-11'], const Duration(minutes: 60));
    expect(daily['2026-02-12'], Duration.zero);
  });
}

