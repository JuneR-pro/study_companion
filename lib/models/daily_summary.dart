import '../utils/date_helpers.dart';

class DailySummary {
  const DailySummary({
    required this.date,
    required this.content,
    required this.updatedAt,
  });

  final DateTime date;
  final String content;
  final DateTime updatedAt;

  DailySummary copyWith({String? content, DateTime? updatedAt}) {
    return DailySummary(
      date: date,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'date': dateKey(date),
    'content': content,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  factory DailySummary.fromMap(Map<String, Object?> map) {
    return DailySummary(
      date: parseDateOnly(map['date']),
      content: (map['content'] as String?) ?? '',
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }
}
