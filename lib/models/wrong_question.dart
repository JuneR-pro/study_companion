import '../utils/date_helpers.dart';

class WrongQuestion {
  const WrongQuestion({
    required this.id,
    required this.subject,
    required this.content,
    required this.createdAt,
    this.imagePath,
  });

  final String id;
  final String subject;
  final String content;
  final DateTime createdAt;
  final String? imagePath;

  Map<String, Object?> toMap() => {
    'id': id,
    'subject': subject,
    'content': content,
    'imagePath': imagePath,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory WrongQuestion.fromMap(Map<String, Object?> map) {
    return WrongQuestion(
      id: map['id']! as String,
      subject: map['subject']! as String,
      content: (map['content'] as String?) ?? '',
      imagePath: map['imagePath'] as String?,
      createdAt: parseDateTime(map['createdAt']),
    );
  }
}
