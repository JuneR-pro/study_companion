// Schema upgrades add tables without deleting historical records.
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/exam.dart';
import '../models/daily_summary.dart';
import '../models/material.dart';
import '../models/study_session.dart';
import '../models/todo.dart';
import '../models/wrong_question.dart';
import '../models/wrong_notebook.dart';
import '../models/wrong_custom_tag.dart';
import '../utils/date_helpers.dart';
import '../utils/study_theme.dart';

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
      version: 4,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createAdditionalSchema(db);
        if (oldVersion < 3) await _createSettingsSchema(db);
        if (oldVersion < 4) await _createWrongQuestionV4Schema(db);
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
    await _createSettingsSchema(db);
    await _createWrongQuestionV4Schema(db);
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

  static Future<void> _createSettingsSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<String> getSetting(String key, String defaultValue) async {
    final db = await database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return defaultValue;
    return rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> _createWrongQuestionV4Schema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wrong_notebooks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconName TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute(
      "INSERT OR IGNORE INTO wrong_notebooks (id, name, iconName, colorValue, createdAt) "
      "VALUES ('default', '默认错题本', 'folder', ${StudyTheme.accent.value}, '${DateTime.now().toUtc().toIso8601String()}')",
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS wrong_custom_tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconName TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS wrong_question_tags (
        questionId TEXT NOT NULL,
        tagId TEXT NOT NULL,
        PRIMARY KEY (questionId, tagId)
      )
    ''');

    try {
      await db.execute("ALTER TABLE wrong_questions ADD COLUMN name TEXT NOT NULL DEFAULT ''");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE wrong_questions ADD COLUMN notebookId TEXT NOT NULL DEFAULT 'default'");
    } catch (_) {}

    final rows = await db.query('wrong_questions', orderBy: 'createdAt ASC');
    for (var i = 0; i < rows.length; i++) {
      final id = rows[i]['id'] as String;
      await db.update(
        'wrong_questions',
        {'name': '错题${i + 1}', 'notebookId': 'default'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await db.execute(
      'CREATE INDEX IF NOT EXISTS wrong_questions_notebook_idx ON wrong_questions(notebookId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS wrong_question_tags_tag_idx ON wrong_question_tags(tagId)',
    );
  }

  // WrongNotebook CRUD -----------------------------------------------------
  Future<void> createWrongNotebook(WrongNotebook notebook) async {
    final db = await database;
    await db.insert('wrong_notebooks', notebook.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<WrongNotebook>> getWrongNotebooks() async {
    final db = await database;
    final rows = await db.query('wrong_notebooks', orderBy: 'createdAt ASC');
    return rows.map((r) => WrongNotebook.fromMap(Map<String, Object?>.from(r))).toList();
  }

  Future<void> updateWrongNotebook(WrongNotebook notebook) async {
    final db = await database;
    await db.update('wrong_notebooks', notebook.toMap(), where: 'id = ?', whereArgs: [notebook.id]);
  }

  Future<void> deleteWrongNotebook(String id) async {
    if (id == 'default') return;
    final db = await database;
    await db.update('wrong_questions', {'notebookId': 'default'}, where: 'notebookId = ?', whereArgs: [id]);
    await db.delete('wrong_notebooks', where: 'id = ?', whereArgs: [id]);
  }

  // WrongCustomTag CRUD ----------------------------------------------------
  Future<void> createWrongCustomTag(WrongCustomTag tag) async {
    final db = await database;
    await db.insert('wrong_custom_tags', tag.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<WrongCustomTag>> getWrongCustomTags() async {
    final db = await database;
    final rows = await db.query('wrong_custom_tags', orderBy: 'createdAt ASC');
    return rows.map((r) => WrongCustomTag.fromMap(Map<String, Object?>.from(r))).toList();
  }

  Future<void> updateWrongCustomTag(WrongCustomTag tag) async {
    final db = await database;
    await db.update('wrong_custom_tags', tag.toMap(), where: 'id = ?', whereArgs: [tag.id]);
  }

  Future<void> deleteWrongCustomTag(String id) async {
    final db = await database;
    await db.delete('wrong_question_tags', where: 'tagId = ?', whereArgs: [id]);
    await db.delete('wrong_custom_tags', where: 'id = ?', whereArgs: [id]);
  }

  // WrongQuestion tag associations -----------------------------------------
  Future<void> setWrongQuestionTags(String questionId, List<String> tagIds) async {
    final db = await database;
    await db.delete('wrong_question_tags', where: 'questionId = ?', whereArgs: [questionId]);
    for (final tagId in tagIds) {
      await db.insert('wrong_question_tags', {'questionId': questionId, 'tagId': tagId});
    }
  }

  Future<List<String>> getWrongQuestionTagIds(String questionId) async {
    final db = await database;
    final rows = await db.query('wrong_question_tags', where: 'questionId = ?', whereArgs: [questionId]);
    return rows.map((r) => r['tagId'] as String).toList();
  }

  // Enhanced WrongQuestion CRUD --------------------------------------------
  Future<void> createWrongQuestion(WrongQuestion question) async {
    final db = await database;
    await db.insert('wrong_questions', question.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateWrongQuestion(WrongQuestion question) async {
    final db = await database;
    await db.update('wrong_questions', question.toMap(), where: 'id = ?', whereArgs: [question.id]);
  }

  Future<List<WrongQuestion>> getWrongQuestions({String? subject, String? notebookId}) async {
    final db = await database;
    final conditions = <String>[];
    final args = <Object?>[];
    if (subject != null) { conditions.add('subject = ?'); args.add(subject); }
    if (notebookId != null) { conditions.add('notebookId = ?'); args.add(notebookId); }
    final rows = await db.query(
      'wrong_questions',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: conditions.isEmpty ? null : args,
      orderBy: 'createdAt DESC',
    );
    return rows.map((r) => WrongQuestion.fromMap(Map<String, Object?>.from(r))).toList();
  }

  Future<void> deleteWrongQuestion(String id) async {
    final db = await database;
    await db.delete('wrong_question_tags', where: 'questionId = ?', whereArgs: [id]);
    await db.delete('wrong_questions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
