// Draft test; not executed until Dart/Flutter is available.
import 'package:flutter_test/flutter_test.dart';

import 'package:study_companion/models/study_session.dart';
import 'package:study_companion/services/study_statistics.dart';

void main() {
  test('aggregates duration and percentage by subject', () {
    final sessions = [
      StudySession(
        id: '1',
        subject: '数学',
        startTime: DateTime(2026, 2, 10, 8),
        endTime: DateTime(2026, 2, 10, 9),
        duration: const Duration(hours: 1),
        source: 'manual',
      ),
      StudySession(
        id: '2',
        subject: '英语',
        startTime: DateTime(2026, 2, 10, 10),
        endTime: DateTime(2026, 2, 10, 10, 30),
        duration: const Duration(minutes: 30),
        source: 'manual',
      ),
    ];

    expect(
      StudyStatistics.subjectTotals(sessions)['数学'],
      const Duration(hours: 1),
    );
    expect(
      StudyStatistics.subjectPercentages(sessions)['数学'],
      closeTo(2 / 3, 0.0001),
    );
    expect(
      StudyStatistics.subjectPercentages(sessions)['英语'],
      closeTo(1 / 3, 0.0001),
    );
  });
}
