import 'package:flutter/material.dart';

import '../models/exam.dart';
import '../models/study_session.dart';
import '../models/todo.dart';
import '../services/study_statistics.dart';
import '../utils/date_helpers.dart';
import '../utils/study_theme.dart';
import '../widgets/exam_countdown_card.dart';
import '../widgets/pomodoro_card.dart';
import '../widgets/recent_todo_card.dart';
import '../widgets/study_calendar_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.todos,
    required this.sessions,
    required this.exams,
    required this.onTodoToggle,
    required this.onSessionCompleted,
    required this.onManualCheckIn,
    required this.onDeleteSession,
    required this.onExamChanged,
    this.onOpenTodos,
    this.onOpenStatistics,
  });

  final List<Todo> todos;
  final List<StudySession> sessions;
  final List<Exam> exams;
  final ValueChanged<Todo> onTodoToggle;
  final ValueChanged<StudySession> onSessionCompleted;
  final ValueChanged<DateTime> onManualCheckIn;
  final ValueChanged<StudySession> onDeleteSession;
  final ValueChanged<Exam> onExamChanged;
  final VoidCallback? onOpenTodos;
  final VoidCallback? onOpenStatistics;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _editExam(Exam exam) async {
    final date = await showDatePicker(
      context: context,
      initialDate: exam.examDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) widget.onExamChanged(exam.copyWith(examDate: date));
  }

  void _showDayDetails(DateTime date) {
    final key = dateKey(date);
    final daySessions = widget.sessions
        .where((session) => dateKey(session.startTime) == key)
        .toList();
    final total = StudyStatistics.totalForDate(widget.sessions, date);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StudyTheme.background,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${date.month}月${date.day}日学习详情',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${total.inHours}小时${total.inMinutes.remainder(60)}分钟',
                    style: const TextStyle(
                      color: StudyTheme.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (daySessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    '这一天还没有学习记录，可以手动打卡。',
                    style: TextStyle(color: StudyTheme.muted),
                  ),
                )
              else
                ...daySessions.map(
                  (session) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: StudySubject.fromLabel(session.subject)
                          .color,
                      child: const Icon(
                        Icons.menu_book,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Text(session.subject),
                    subtitle: Text(
                      '${session.source == 'pomodoro' ? '番茄钟' : '手动录入'} · ${session.note ?? ''}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${session.duration.inMinutes}分钟'),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onDeleteSession(session);
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onManualCheckIn(date);
                  },
                  icon: const Icon(Icons.add_task),
                  label: const Text('手动打卡今天'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = StudyStatistics.totalForDate(widget.sessions, DateTime.now());
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            const Text(
              '龙哥公考学习工作台',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: StudyTheme.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '把每天的积累，变成上岸的底气',
              style: TextStyle(fontSize: 16, color: StudyTheme.muted),
            ),
            const SizedBox(height: 24),
            ExamCountdownCard(exams: widget.exams, onTap: _editExam),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '今日进度',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                TextButton(
                  onPressed: widget.onOpenStatistics,
                  child: Text(
                    '今日 ${today.inHours}小时${today.inMinutes.remainder(60)}分钟',
                  ),
                ),
              ],
            ),
            PomodoroCard(
              onCompleted: widget.onSessionCompleted,
              todayDuration: today,
            ),
            const SizedBox(height: 18),
            StudyCalendarCard(
              sessions: widget.sessions,
              onDateSelected: _showDayDetails,
            ),
            const SizedBox(height: 18),
            RecentTodoCard(
              todos: widget.todos,
              onToggle: widget.onTodoToggle,
              onTap: widget.onOpenTodos,
            ),
          ],
        ),
      ),
    );
  }
}
