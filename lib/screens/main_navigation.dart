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
import '../models/wrong_notebook.dart';
import '../models/wrong_custom_tag.dart';
import '../utils/date_helpers.dart';
import 'home_screen.dart';
import 'material_screen.dart';
import 'statistics_screen.dart';
import 'todo_screen.dart';
import 'wrong_questions_screen.dart';

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
  late List<WrongNotebook> _notebooks;
  late List<WrongCustomTag> _customTags;
  late Map<String, DailySummary> _summaries;
  String _workspaceName = '龙哥公考学习工作台';
  String _signature = '把每天的积累，变成上岸的底气';
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
    _notebooks = [];
    _customTags = [];
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
      // Remove only the two old built-in examples; user-created materials remain intact.
      final oldDemoMaterials = materials
          .where((item) => item.id == 'demo-material-1' || item.id == 'demo-material-2')
          .toList();
      for (final item in oldDemoMaterials) {
        await _database.deleteMaterial(item.id);
      }
      materials.removeWhere((item) => item.id == 'demo-material-1' || item.id == 'demo-material-2');
      final wrongQuestions = await _database.getWrongQuestions();
      final notebooks = await _database.getWrongNotebooks();
      final customTags = await _database.getWrongCustomTags();
      final summaries = await _database.getDailySummaries();
      final workspaceName = await _database.getSetting('workspaceName', '龙哥公考学习工作台');
      final signature = await _database.getSetting('signature', '把每天的积累，变成上岸的底气');
      if (!mounted) {
        return;
      }
      setState(() {
        _todos = todos;
        _sessions = sessions;
        _exams = exams;
        if (materials.isNotEmpty) _materials = materials;
        _wrongQuestions = wrongQuestions;
        _notebooks = notebooks;
        _customTags = customTags;
        _summaries = {
          for (final summary in summaries) dateKey(summary.date): summary,
        };
        _workspaceName = workspaceName;
        _signature = signature;
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = '鏈湴鏁版嵁璇诲彇澶辫触锛?error';
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
            content: Text('鑷姩淇濆瓨澶辫触锛岃閲嶈瘯锛?error'),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: '閲嶈瘯',
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

  void _examAdded(Exam exam) {
    setState(() => _exams = [..._exams, exam]);
    _save(() => _database.createExam(exam));
  }

  void _examDeleted(Exam exam) {
    setState(() => _exams = _exams.where((item) => item.id != exam.id).toList());
    _save(() => _database.deleteExam(exam.id));
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
        subject: '甯歌瘑',
        startTime: start,
        endTime: start,
        duration: Duration.zero,
        source: 'checkin',
        note: '鎵嬪姩鎵撳崱',
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

  void _wrongQuestionUpdated(WrongQuestion question) {
    setState(
      () => _wrongQuestions = _wrongQuestions.map((q) => q.id == question.id ? question : q).toList(),
    );
    _save(() => _database.updateWrongQuestion(question));
  }

  void _notebookCreated(WrongNotebook notebook) {
    setState(() => _notebooks = [..._notebooks, notebook]);
    _save(() => _database.createWrongNotebook(notebook));
  }

  void _notebookUpdated(WrongNotebook notebook) {
    setState(() => _notebooks = _notebooks.map((n) => n.id == notebook.id ? notebook : n).toList());
    _save(() => _database.updateWrongNotebook(notebook));
  }

  void _notebookDeleted(String id) {
    setState(() {
      _notebooks = _notebooks.where((n) => n.id != id).toList();
      _wrongQuestions = _wrongQuestions.map((q) => q.notebookId == id ? q.copyWith(notebookId: 'default') : q).toList();
    });
    _save(() => _database.deleteWrongNotebook(id));
  }

  void _tagCreated(WrongCustomTag tag) {
    setState(() => _customTags = [..._customTags, tag]);
    _save(() => _database.createWrongCustomTag(tag));
  }

  void _tagUpdated(WrongCustomTag tag) {
    setState(() => _customTags = _customTags.map((t) => t.id == tag.id ? tag : t).toList());
    _save(() => _database.updateWrongCustomTag(tag));
  }

  void _tagDeleted(String id) {
    setState(() => _customTags = _customTags.where((t) => t.id != id).toList());
    _save(() => _database.deleteWrongCustomTag(id));
  }

  Future<void> _questionTagsSet(String questionId, List<String> tagIds) async {
    await _database.setWrongQuestionTags(questionId, tagIds);
  }

  Future<List<String>> _getQuestionTagIds(String questionId) async {
    return _database.getWrongQuestionTagIds(questionId);
  }

  void _openWrongQuestions() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => WrongQuestionsScreen(
        wrongQuestions: _wrongQuestions,
        notebooks: _notebooks,
        customTags: _customTags,
        onQuestionCreated: _wrongQuestionCreated,
        onQuestionDeleted: _wrongQuestionDeleted,
        onQuestionUpdated: _wrongQuestionUpdated,
        onNotebookCreated: _notebookCreated,
        onNotebookUpdated: _notebookUpdated,
        onNotebookDeleted: _notebookDeleted,
        onTagCreated: _tagCreated,
        onTagUpdated: _tagUpdated,
        onTagDeleted: _tagDeleted,
        onQuestionTagsSet: _questionTagsSet,
        getQuestionTagIds: _getQuestionTagIds,
      ),
    ));
  }

  void _materialCreated(study_material.Material material) {
    setState(() => _materials = [material, ..._materials]);
    _save(() => _database.createMaterial(material));
  }

  void _materialUpdated(study_material.Material material) {
    setState(() {
      _materials = _materials.map((item) => item.id == material.id ? material : item).toList();
    });
    _save(() => _database.updateMaterial(material));
  }

  void _materialDeleted(String id) {
    setState(() => _materials = _materials.where((item) => item.id != id).toList());
    _save(() => _database.deleteMaterial(id));
  }

  void _profileChanged(String name, String signature) {
    setState(() {
      _workspaceName = name;
      _signature = signature;
    });
    _save(() => _database.setSetting('workspaceName', name));
    _save(() => _database.setSetting('signature', signature));
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
        onExamAdded: _examAdded,
        onExamDeleted: _examDeleted,
        workspaceName: _workspaceName,
        signature: _signature,
        onProfileChanged: _profileChanged,
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
        onOpenWrongQuestions: _openWrongQuestions,
      ),
      MaterialScreen(
        initialMaterials: _materials,
        onCreated: _materialCreated,
        onUpdated: _materialUpdated,
        onDeleted: _materialDeleted,
      ),
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
                  child: const Text('閲嶈瘯'),
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
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: '每日待办'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: '统计'),
          NavigationDestination(icon: Icon(Icons.collections_bookmark_outlined), selectedIcon: Icon(Icons.collections_bookmark), label: '积累'),
        ],
      ),
    );
  }
}




