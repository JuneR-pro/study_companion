import 'package:flutter/material.dart';

import '../utils/date_helpers.dart';

class WrongNotebook {
  const WrongNotebook({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String iconName;
  final int colorValue;
  final DateTime createdAt;

  Color get color => Color(colorValue);

  WrongNotebook copyWith({
    String? id,
    String? name,
    String? iconName,
    int? colorValue,
    DateTime? createdAt,
  }) => WrongNotebook(
    id: id ?? this.id,
    name: name ?? this.name,
    iconName: iconName ?? this.iconName,
    colorValue: colorValue ?? this.colorValue,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'iconName': iconName,
    'colorValue': colorValue,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory WrongNotebook.fromMap(Map<String, Object?> map) {
    return WrongNotebook(
      id: map['id']! as String,
      name: map['name']! as String,
      iconName: map['iconName']! as String,
      colorValue: map['colorValue']! as int,
      createdAt: parseDateTime(map['createdAt']),
    );
  }
}
