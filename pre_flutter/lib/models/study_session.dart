import '../utils/date_helpers.dart';

class StudySession {
  const StudySession({
    required this.id,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.source,
    this.note,
  });

  final String id;
  final String subject;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final String source;
  final String? note;

  StudySession copyWith({
    String? id,
    String? subject,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    String? source,
    String? note,
  }) {
    return StudySession(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      source: source ?? this.source,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'subject': subject,
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime?.toUtc().toIso8601String(),
        'duration': duration.inSeconds,
        'source': source,
        'note': note,
      };

  factory StudySession.fromMap(Map<String, Object?> map) {
    return StudySession(
      id: map['id']! as String,
      subject: map['subject']! as String,
      startTime: parseDateTime(map['startTime']),
      endTime: map['endTime'] == null ? null : parseDateTime(map['endTime']),
      duration: Duration(seconds: durationSeconds(map['duration'])),
      source: map['source']! as String,
      note: map['note'] as String?,
    );
  }
}

