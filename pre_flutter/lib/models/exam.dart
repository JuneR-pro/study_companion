import '../utils/date_helpers.dart';

class Exam {
  const Exam({
    required this.id,
    required this.name,
    required this.examDate,
  });

  final String id;
  final String name;
  final DateTime examDate;

  Exam copyWith({String? id, String? name, DateTime? examDate}) {
    return Exam(
      id: id ?? this.id,
      name: name ?? this.name,
      examDate: examDate ?? this.examDate,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'examDate': examDate.toUtc().toIso8601String(),
      };

  factory Exam.fromMap(Map<String, Object?> map) {
    return Exam(
      id: map['id']! as String,
      name: map['name']! as String,
      examDate: parseDateTime(map['examDate']),
    );
  }
}

