import 'package:flutter/material.dart';

import '../models/exam.dart';
import '../models/study_session.dart';
import '../models/todo.dart';
import '../services/study_statistics.dart';
import '../widgets/exam_countdown_card.dart';
import '../widgets/pomodoro_card.dart';
import '../widgets/recent_todo_card.dart';
import '../widgets/today_study_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.todos,
    required this.sessions,
    required this.exam,
    required this.onTodoToggle,
    required this.onSessionCompleted,
    this.onOpenTodos,
    this.onOpenStatistics,
  });

  final List<Todo> todos;
  final List<StudySession> sessions;
  final Exam? exam;
  final ValueChanged<Todo> onTodoToggle;
  final ValueChanged<StudySession> onSessionCompleted;
  final VoidCallback? onOpenTodos;
  final VoidCallback? onOpenStatistics;

  @override
  Widget build(BuildContext context) {
    final today = StudyStatistics.totalForDate(sessions, DateTime.now());
    return Scaffold(
      appBar: AppBar(title: const Text('学习管理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ExamCountdownCard(exam: exam),
          TodayStudyCard(duration: today, onTap: onOpenStatistics),
          PomodoroCard(onCompleted: onSessionCompleted),
          RecentTodoCard(todos: todos, onToggle: onTodoToggle, onTap: onOpenTodos),
        ],
      ),
    );
  }
}

