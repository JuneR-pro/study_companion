import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/demo_data.dart';
import '../models/daily_summary.dart';
import '../models/exam.dart';
import '../models/material.dart' as study_material;
import '../models/study_session.dart';
import '../models/todo.dart';
import '../models/wrong_question.dart';
import '../utils/date_helpers.dart';
import 'home_screen.dart';
import 'material_screen.dart';
import 'statistics_screen.dart';
import 'todo_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.database, this.loadFromDatabase = true});
  final AppDatabase? database;
  final bool loadFromDatabase;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late final AppDatabase _database;
  int _index = 0;
  late List<Todo> _todos;
  late List<StudySession> _sessions;
  late List<Exam> _exams;
  late List<study_material.Material> _materials;
  late List<WrongQuestion> _wrongQuestions;
  late Map<String, DailySummary> _summaries;
  bool _loading = true;
  String? _loadError;
  Future<void> _pendingSave = Future.value();

  @override
  void initState() {
    super.initState();
    _database = widget.database ?? AppDatabase.instance;
    _todos = widget.loadFromDatabase ? [] : DemoData.todos();
    _sessions = widget.loadFromDatabase ? [] : DemoData.sessions();
    _exams = widget.loadFromDatabase ? [] : DemoData.exams();
    _materials = DemoData.materials();
    _wrongQuestions = [];
    _summaries = {};
    if (widget.loadFromDatabase) {
      unawaited(_loadLocalData());
    } else {
      _loading = false;
    }
  }

  Future<void> _loadLocalData() async {
    try {
      final todos = await _database.getTodos();
      final sessions = await _database.getSessions();
      final exams = await _database.getExams();
      final materials = await _database.getMaterials();
      final wrongQuestions = await _database.getWrongQuestions();
      final summaries = await _database.getDailySummaries();
      final knownNames = exams.map((exam) => exam.name).toSet();
      // Missing exams have no official date yet: never fabricate a deadline.
      for (final name in ['国考', '浙江省考', '浙江事业编']) {
        if (!knownNames.contains(name)) {
          final exam = Exam(
            id: 'exam-$name',
            name: name,
            examDate: DateTime(2100),
          );
          await _database.createExam(exam);
          exams.add(exam);
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _todos = todos;
        _sessions = sessions;
        _exams = exams
            .where((exam) => ['国考', '浙江省考', '浙江事业编'].contains(exam.name))
            .toList();
        if (materials.isNotEmpty) _materials = materials;
        _wrongQuestions = wrongQuestions;
        _summaries = {
          for (final summary in summaries) dateKey(summary.date): summary,
        };
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = '本地数据读取失败：$error';
        });
      }
    }
  }

  void _save(Future<void> Function() operation) {
    _pendingSave = _pendingSave.then((_) => operation()).catchError((
      Object error,
    ) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('自动保存失败，请重试：$error'),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: '重试',
              onPressed: () => _save(operation),
            ),
          ),
        );
      }
    });
  }

  void _examChanged(Exam exam) {
    setState(
      () => _exams = _exams
          .map((item) => item.id == exam.id ? exam : item)
          .toList(),
    );
    _save(() => _database.updateExam(exam));
  }

  void _todoCreated(Todo todo) {
    setState(() => _todos = [..._todos, todo]);
    _save(() => _database.createTodo(todo));
  }

  void _todoUpdated(Todo todo) {
    setState(() {
      _todos = _todos.map((item) => item.id == todo.id ? todo : item).toList();
    });
    _save(() => _database.updateTodo(todo));
  }

  void _todoDeleted(String id) {
    setState(() => _todos = _todos.where((todo) => todo.id != id).toList());
    _save(() => _database.deleteTodo(id));
  }

  void _toggleTodoFromHome(Todo todo) {
    final updated = todo.copyWith(completed: !todo.completed);
    _todoUpdated(updated);
  }

  void _sessionCreated(StudySession session) {
    setState(() => _sessions = [..._sessions, session]);
    _save(() => _database.createSession(session));
  }

  void _manualCheckIn(DateTime date) {
    final start = DateTime(date.year, date.month, date.day, 12);
    _sessionCreated(
      StudySession(
        id: 'checkin-${DateTime.now().microsecondsSinceEpoch}',
        subject: '常识',
        startTime: start,
        endTime: start,
        duration: Duration.zero,
        source: 'checkin',
        note: '手动打卡',
      ),
    );
  }

  void _sessionDeleted(StudySession session) {
    setState(
      () =>
          _sessions = _sessions.where((item) => item.id != session.id).toList(),
    );
    _save(() => _database.deleteSession(session.id));
  }

  void _summarySaved(DailySummary summary) {
    setState(
      () => _summaries = {..._summaries, dateKey(summary.date): summary},
    );
    _save(() => _database.upsertDailySummary(summary));
  }

  void _summaryAutosaved(DailySummary summary) {
    // Persist while the dialog is open without rebuilding its parent route.
    _save(() => _database.upsertDailySummary(summary));
  }

  void _wrongQuestionCreated(WrongQuestion question) {
    setState(() => _wrongQuestions = [question, ..._wrongQuestions]);
    _save(() => _database.createWrongQuestion(question));
  }

  void _wrongQuestionDeleted(String id) {
    setState(
      () => _wrongQuestions = _wrongQuestions
          .where((question) => question.id != id)
          .toList(),
    );
    _save(() => _database.deleteWrongQuestion(id));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pages = [
      HomeScreen(
        todos: _todos,
        sessions: _sessions,
        exams: _exams,
        onTodoToggle: _toggleTodoFromHome,
        onSessionCompleted: _sessionCreated,
        onManualCheckIn: _manualCheckIn,
        onDeleteSession: _sessionDeleted,
        onExamChanged: _examChanged,
        onOpenTodos: () => setState(() => _index = 1),
        onOpenStatistics: () => setState(() => _index = 2),
      ),
      TodoScreen(
        initialTodos: List<Todo>.from(_todos),
        onChanged: (_) {},
        onCreated: _todoCreated,
        onUpdated: _todoUpdated,
        onDeleted: _todoDeleted,
      ),
      StatisticsScreen(
        sessions: _sessions,
        summaries: _summaries,
        wrongQuestions: _wrongQuestions,
        onCreateSession: _sessionCreated,
        onDeleteSession: _sessionDeleted,
        onSummarySaved: _summarySaved,
        onSummaryAutosaved: _summaryAutosaved,
        onWrongQuestionCreated: _wrongQuestionCreated,
        onWrongQuestionDeleted: _wrongQuestionDeleted,
      ),
      MaterialScreen(initialMaterials: _materials),
    ];
    return Scaffold(
      body: Column(
        children: [
          if (_loadError != null)
            MaterialBanner(
              content: Text(_loadError!),
              leading: const Icon(Icons.warning_amber_outlined),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _loadError = null;
                    });
                    unawaited(_loadLocalData());
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(index: _index, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: '每日待办',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark),
            label: '积累',
          ),
        ],
      ),
    );
  }
}
