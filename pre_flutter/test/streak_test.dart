// Draft test; not executed until Dart/Flutter is available.
import 'package:test/test.dart';

import '../lib/models/study_session.dart';
import '../lib/services/study_statistics.dart';

void main() {
  test('counts consecutive learning days ending at a date', () {
    final sessions = [
      for (var offset = 0; offset < 3; offset++)
        StudySession(
          id: '$offset',
          subject: '数学',
          startTime: DateTime(2026, 2, 10 + offset, 8),
          endTime: DateTime(2026, 2, 10 + offset, 8, 30),
          duration: const Duration(minutes: 30),
          source: 'manual',
        ),
    ];
    expect(
      StudyStatistics.consecutiveLearningDays(sessions, through: DateTime(2026, 2, 12)),
      3,
    );
    expect(
      StudyStatistics.consecutiveLearningDays(sessions, through: DateTime(2026, 2, 13)),
      0,
    );
  });
}

