import '../utils/date_helpers.dart';

class WrongQuestion {
  const WrongQuestion({
    required this.id,
    required this.subject,
    required this.content,
    required this.createdAt,
    this.name = '',
    this.notebookId = 'default',
    this.imagePath,
  });

  final String id;
  final String name;
  final String subject;
  final String content;
  final String notebookId;
  final DateTime createdAt;
  final String? imagePath;

  WrongQuestion copyWith({
    String? id,
    String? name,
    String? subject,
    String? content,
    String? notebookId,
    DateTime? createdAt,
    String? imagePath,
  }) => WrongQuestion(
    id: id ?? this.id,
    name: name ?? this.name,
    subject: subject ?? this.subject,
    content: content ?? this.content,
    notebookId: notebookId ?? this.notebookId,
    createdAt: createdAt ?? this.createdAt,
    imagePath: imagePath ?? this.imagePath,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'subject': subject,
    'content': content,
    'notebookId': notebookId,
    'imagePath': imagePath,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory WrongQuestion.fromMap(Map<String, Object?> map) {
    return WrongQuestion(
      id: map['id']! as String,
      name: (map['name'] as String?) ?? '',
      subject: map['subject']! as String,
      content: (map['content'] as String?) ?? '',
      notebookId: (map['notebookId'] as String?) ?? 'default',
      imagePath: map['imagePath'] as String?,
      createdAt: parseDateTime(map['createdAt']),
    );
  }
}
