import '../utils/date_helpers.dart';

class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.date,
    required this.completed,
    required this.createdAt,
  });

  final String id;
  final String title;
  final DateTime date;
  final bool completed;
  final DateTime createdAt;

  Todo copyWith({
    String? id,
    String? title,
    DateTime? date,
    bool? completed,
    DateTime? createdAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'date': dateKey(date),
    'completed': completed ? 1 : 0,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory Todo.fromMap(Map<String, Object?> map) {
    return Todo(
      id: map['id']! as String,
      title: map['title']! as String,
      date: parseDateOnly(map['date']),
      completed: boolFromMap(map['completed']),
      createdAt: parseDateTime(map['createdAt']),
    );
  }
}
