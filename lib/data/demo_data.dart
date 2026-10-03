import '../models/exam.dart';
import '../models/material.dart';
import '../models/study_session.dart';
import '../models/todo.dart';

/// Small deterministic-enough samples for first UI wiring.
/// The dates intentionally follow the current local day so the home cards
/// show useful content when the Flutter app is first opened.
class DemoData {
  const DemoData._();

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static List<Todo> todos() {
    final today = _today;
    return [
      Todo(
        id: 'demo-todo-1',
        title: '复习高等数学第一章',
        date: today,
        completed: false,
        createdAt: today.add(const Duration(hours: 8)),
      ),
      Todo(
        id: 'demo-todo-2',
        title: '整理错题笔记',
        date: today,
        completed: true,
        createdAt: today.add(const Duration(hours: 7)),
      ),
      Todo(
        id: 'demo-todo-3',
        title: '完成英语阅读练习',
        date: today.add(const Duration(days: 1)),
        completed: false,
        createdAt: today.add(const Duration(hours: 9)),
      ),
    ];
  }

  static List<StudySession> sessions() {
    final today = _today;
    return [
      StudySession(
        id: 'demo-session-1',
        subject: '数学',
        startTime: today.add(const Duration(hours: 8)),
        endTime: today.add(const Duration(hours: 8, minutes: 45)),
        duration: const Duration(minutes: 45),
        source: 'pomodoro',
        note: '极限与连续',
      ),
      StudySession(
        id: 'demo-session-2',
        subject: '英语',
        startTime: today
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 20)),
        endTime: today
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 20, minutes: 30)),
        duration: const Duration(minutes: 30),
        source: 'manual',
      ),
      StudySession(
        id: 'demo-session-3',
        subject: '数学',
        startTime: today
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 19)),
        endTime: today
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 20)),
        duration: const Duration(hours: 1),
        source: 'pomodoro',
      ),
    ];
  }

  static List<Material> materials() {
    final now = DateTime.now();
    return [
      Material(
        id: 'demo-material-1',
        title: '极限的定义',
        content: '当 x 趋近于 a 时，函数值无限接近 L。',
        category: '数学',
        tags: const ['高等数学', '概念'],
        favorite: true,
        createdAt: now,
      ),
      Material(
        id: 'demo-material-2',
        title: '英语写作连接词',
        content: 'however, therefore, in addition, on the other hand',
        category: '英语',
        tags: const ['写作', '词汇'],
        favorite: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static Exam exam() {
    return Exam(
      id: 'demo-exam-1',
      name: '期末考试',
      examDate: _today.add(const Duration(days: 28, hours: 9)),
    );
  }

  static List<Exam> exams() {
    final today = _today;
    return [
      Exam(
        id: 'demo-exam-national',
        name: '国考',
        examDate: today.add(const Duration(days: 116)),
      ),
      Exam(
        id: 'demo-exam-zhejiang',
        name: '浙江省考',
        examDate: today.add(const Duration(days: 123)),
      ),
      Exam(
        id: 'demo-exam-public',
        name: '浙江事业编',
        examDate: today.add(const Duration(days: 45)),
      ),
    ];
  }
}
