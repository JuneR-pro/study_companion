import 'dart:convert';

import '../utils/date_helpers.dart';

class Material {
  const Material({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    required this.favorite,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final bool favorite;
  final DateTime createdAt;

  Material copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    List<String>? tags,
    bool? favorite,
    DateTime? createdAt,
  }) {
    return Material(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? List<String>.from(this.tags),
      favorite: favorite ?? this.favorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'category': category,
    // SQLite stores the list as JSON in one TEXT column for V0.1.
    'tags': jsonEncode(tags),
    'favorite': favorite ? 1 : 0,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory Material.fromMap(Map<String, Object?> map) {
    final rawTags = map['tags'];
    final parsedTags = rawTags is List
        ? rawTags.map((tag) => tag.toString()).toList()
        : (rawTags is String && rawTags.isNotEmpty
              ? _decodeTags(rawTags)
              : <String>[]);
    return Material(
      id: map['id']! as String,
      title: map['title']! as String,
      content: (map['content'] as String?) ?? '',
      category: (map['category'] as String?) ?? '',
      tags: parsedTags,
      favorite: boolFromMap(map['favorite']),
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  static List<String> _decodeTags(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((tag) => tag.toString()).toList();
      }
    } on FormatException {
      // Fall through to the simple legacy comma-separated format.
    }
    return raw
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }
}
