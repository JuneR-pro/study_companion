// Draft test; Flutter/Dart test tooling is not installed yet.
import 'package:test/test.dart';

import '../lib/models/todo.dart';
import '../lib/services/todo_filters.dart';

void main() {
  test('filters todos by calendar date', () {
    final todos = [
      Todo(
        id: '1',
        title: '今天',
        date: DateTime(2026, 2, 10),
        completed: false,
        createdAt: DateTime(2026, 2, 9),
      ),
      Todo(
        id: '2',
        title: '明天',
        date: DateTime(2026, 2, 11),
        completed: false,
        createdAt: DateTime(2026, 2, 9),
      ),
    ];

    final result = TodoFilters.byDate(todos, DateTime(2026, 2, 10, 20));
    expect(result.map((todo) => todo.id), ['1']);
  });
}

