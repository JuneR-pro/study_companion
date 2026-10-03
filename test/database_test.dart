import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_companion/data/app_database.dart';
import 'package:study_companion/models/daily_summary.dart';
import 'package:study_companion/models/todo.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('SQLite CRUD preserves local records and supports new summary table', () async {
    final database = AppDatabase(databasePath: inMemoryDatabasePath);
    final todo = Todo(id: 'todo-1', title: '保存测试', date: DateTime(2026, 10, 3), completed: false, createdAt: DateTime(2026, 10, 3));
    await database.createTodo(todo);
    expect((await database.getTodosByDate(todo.date)).single.title, '保存测试');
    final summary = DailySummary(date: todo.date, content: '完成一次迁移测试', updatedAt: DateTime(2026, 10, 3));
    await database.upsertDailySummary(summary);
    expect((await database.getDailySummary(todo.date))?.content, summary.content);
    await database.close();
  });
}
