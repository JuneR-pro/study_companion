// Schema upgrades add tables without deleting historical records.
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/exam.dart';
import '../models/daily_summary.dart';
import '../models/material.dart';
import '../models/study_session.dart';
import '../models/todo.dart';
import '../models/wrong_question.dart';
import '../utils/date_helpers.dart';

class AppDatabase {
  AppDatabase({this.databasePath});

  static final AppDatabase instance = AppDatabase();
  final String? databasePath;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final filePath =
        databasePath ??
        path.join(await getDatabasesPath(), 'study_companion.db');
    _database = await openDatabase(
      filePath,
      version: 2,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createAdditionalSchema(db);
      },
    );
    return _database!;
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE todos (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX todos_date_idx ON todos(date)');
    await db.execute(
      'CREATE INDEX todos_date_completed_idx ON todos(date, completed)',
    );

    await db.execute('''
      CREATE TABLE study_sessions (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        duration INTEGER NOT NULL,
        source TEXT NOT NULL,
        note TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX sessions_start_idx ON study_sessions(startTime)',
    );
    await db.execute(
      'CREATE INDEX sessions_subject_idx ON study_sessions(subject)',
    );

    await db.execute('''
      CREATE TABLE materials (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        tags TEXT NOT NULL,
        favorite INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX materials_created_idx ON materials(createdAt)',
    );
    await db.execute(
      'CREATE INDEX materials_favorite_idx ON materials(favorite)',
    );
    await db.execute(
      'CREATE INDEX materials_category_idx ON materials(category)',
    );

    await db.execute('''
      CREATE TABLE exams (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        examDate TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX exams_date_idx ON exams(examDate)');
    await _createAdditionalSchema(db);
  }

  static Future<void> _createAdditionalSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_summaries (
        date TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wrong_questions (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        content TEXT NOT NULL,
        imagePath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS wrong_questions_subject_idx ON wrong_questions(subject)',
    );
  }

  // Todo CRUD --------------------------------------------------------------
  Future<void> createTodo(Todo todo) async {
    final db = await database;
    await db.insert(
      'todos',
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Todo>> getTodos() async {
    final db = await database;
    final rows = await db.query(
      'todos',
      orderBy: 'date ASC, completed ASC, createdAt DESC',
    );
    return rows
        .map((row) => Todo.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  Future<List<Todo>> getTodosByDate(DateTime date) async {
    final db = await database;
    final rows = await db.query(
      'todos',
      where: 'date = ?',
      whereArgs: [dateKey(date)],
      orderBy: 'completed ASC, createdAt DESC',
    );
    return rows
        .map((row) => Todo.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  Future<void> updateTodo(Todo todo) async {
    final db = await database;
    await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<void> deleteTodo(String id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  Future<Todo?> toggleTodo(String id) async {
    final db = await database;
    final rows = await db.query(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final current = Todo.fromMap(Map<String, Object?>.from(rows.first));
    final updated = current.copyWith(completed: !current.completed);
    await updateTodo(updated);
    return updated;
  }

  // StudySession CRUD and date queries ------------------------------------
  Future<void> createSession(StudySession session) async {
    final db = await database;
    await db.insert(
      'study_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StudySession>> getSessions() async {
    final db = await database;
    final rows = await db.query('study_sessions', orderBy: 'startTime DESC');
    return rows
        .map((row) => StudySession.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  Future<List<StudySession>> getSessionsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return getSessionsByDateRange(start, end);
  }

  /// [end] is exclusive.
  Future<List<StudySession>> getSessionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final rows = await db.query(
      'study_sessions',
      where: 'startTime >= ? AND startTime < ?',
      whereArgs: [
        start.toUtc().toIso8601String(),
        end.toUtc().toIso8601String(),
      ],
      orderBy: 'startTime ASC',
    );
    return rows
        .map((row) => StudySession.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete('study_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> upsertDailySummary(DailySummary summary) async {
    final db = await database;
    await db.insert(
      'daily_summaries',
      summary.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DailySummary?> getDailySummary(DateTime date) async {
    final db = await database;
    final rows = await db.query(
      'daily_summaries',
      where: 'date = ?',
      whereArgs: [dateKey(date)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DailySummary.fromMap(Map<String, Object?>.from(rows.first));
  }

  Future<List<DailySummary>> getDailySummaries() async {
    final db = await database;
    final rows = await db.query('daily_summaries', orderBy: 'date DESC');
    return rows
        .map((row) => DailySummary.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  Future<void> createWrongQuestion(WrongQuestion question) async {
    final db = await database;
    await db.insert(
      'wrong_questions',
      question.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WrongQuestion>> getWrongQuestions({String? subject}) async {
    final db = await database;
    final rows = await db.query(
      'wrong_questions',
      where: subject == null ? null : 'subject = ?',
      whereArgs: subject == null ? null : [subject],
      orderBy: 'createdAt DESC',
    );
    return rows
        .map((row) => WrongQuestion.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  Future<void> deleteWrongQuestion(String id) async {
    final db = await database;
    await db.delete('wrong_questions', where: 'id = ?', whereArgs: [id]);
  }

  // Material CRUD ----------------------------------------------------------
  Future<void> createMaterial(Material material) async {
    final db = await database;
    await db.insert(
      'materials',
      material.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Material>> getMaterials() async {
    final db = await database;
    final rows = await db.query('materials', orderBy: 'createdAt DESC');
    return rows
        .map((row) => Material.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  Future<void> updateMaterial(Material material) async {
    final db = await database;
    await db.update(
      'materials',
      material.toMap(),
      where: 'id = ?',
      whereArgs: [material.id],
    );
  }

  Future<void> deleteMaterial(String id) async {
    final db = await database;
    await db.delete('materials', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Material>> getFavoriteMaterials() async {
    final db = await database;
    final rows = await db.query(
      'materials',
      where: 'favorite = 1',
      orderBy: 'createdAt DESC',
    );
    return rows
        .map((row) => Material.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  // Exam CRUD --------------------------------------------------------------
  Future<void> createExam(Exam exam) async {
    final db = await database;
    await db.insert(
      'exams',
      exam.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Exam>> getExams() async {
    final db = await database;
    final rows = await db.query('exams', orderBy: 'examDate ASC');
    return rows
        .map((row) => Exam.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  Future<void> updateExam(Exam exam) async {
    final db = await database;
    await db.update(
      'exams',
      exam.toMap(),
      where: 'id = ?',
      whereArgs: [exam.id],
    );
  }

  Future<void> deleteExam(String id) async {
    final db = await database;
    await db.delete('exams', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
