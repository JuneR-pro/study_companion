import '../models/study_session.dart';
import '../utils/date_helpers.dart';

/// Pure Dart aggregation logic. It has no Flutter or database dependency.
class StudyStatistics {
  const StudyStatistics._();

  static Duration totalForDate(Iterable<StudySession> sessions, DateTime date) {
    final key = dateKey(date);
    return sessions
        .where((session) => dateKey(session.startTime) == key)
        .fold(Duration.zero, (sum, session) => sum + session.duration);
  }

  static Duration totalForMonth(
    Iterable<StudySession> sessions,
    DateTime month,
  ) {
    return dailyDurationsForMonth(
      sessions,
      month,
    ).values.fold(Duration.zero, (sum, duration) => sum + duration);
  }

  /// Includes zero-duration entries for every day in the requested month.
  static Map<String, Duration> dailyDurationsForMonth(
    Iterable<StudySession> sessions,
    DateTime month,
  ) {
    final first = DateTime(month.year, month.month);
    final nextMonth = DateTime(month.year, month.month + 1);
    final result = <String, Duration>{};
    for (
      var day = first;
      day.isBefore(nextMonth);
      day = day.add(const Duration(days: 1))
    ) {
      result[dateKey(day)] = Duration.zero;
    }
    for (final session in sessions) {
      final local = session.startTime.toLocal();
      if (local.year == month.year && local.month == month.month) {
        final key = dateKey(local);
        result[key] = (result[key] ?? Duration.zero) + session.duration;
      }
    }
    return result;
  }

  static Map<String, Duration> subjectTotals(Iterable<StudySession> sessions) {
    final result = <String, Duration>{};
    for (final session in sessions) {
      result[session.subject] =
          (result[session.subject] ?? Duration.zero) + session.duration;
    }
    return result;
  }

  static Map<String, double> subjectPercentages(
    Iterable<StudySession> sessions,
  ) {
    final totals = subjectTotals(sessions);
    final totalSeconds = totals.values.fold<int>(
      0,
      (sum, value) => sum + value.inSeconds,
    );
    if (totalSeconds == 0) {
      return {for (final subject in totals.keys) subject: 0};
    }
    return {
      for (final entry in totals.entries)
        entry.key: entry.value.inSeconds / totalSeconds,
    };
  }

  /// Counts consecutive calendar days with at least one non-zero session,
  /// ending on [through]. If omitted, the device's current local date is used.
  static int consecutiveLearningDays(
    Iterable<StudySession> sessions, {
    DateTime? through,
  }) {
    final learningDays = <String>{
      for (final session in sessions)
        if (session.duration > Duration.zero) dateKey(session.startTime),
    };
    final endDate = (through ?? DateTime.now()).toLocal();
    var day = DateTime(endDate.year, endDate.month, endDate.day);
    var count = 0;
    while (learningDays.contains(dateKey(day))) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }
}
