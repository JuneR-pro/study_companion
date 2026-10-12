import '../models/exam.dart';
import '../models/material.dart';
import '../models/study_session.dart';
import '../models/todo.dart';

class DemoData {
  const DemoData._();

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static List<Todo> todos() {
    final today = _today;
    return [
      Todo(id: 'demo-todo-1', title: '完成一组练习题', date: today, completed: false, createdAt: today.add(const Duration(hours: 8))),
      Todo(id: 'demo-todo-2', title: '整理错题笔记', date: today, completed: true, createdAt: today.add(const Duration(hours: 7))),
    ];
  }

  static List<StudySession> sessions() {
    final today = _today;
    return [
      StudySession(id: 'demo-session-1', subject: '言语理解', startTime: today.add(const Duration(hours: 8)), endTime: today.add(const Duration(hours: 8, minutes: 45)), duration: const Duration(minutes: 45), source: 'pomodoro', note: '示例学习记录'),
      StudySession(id: 'demo-session-2', subject: '逻辑判断', startTime: today.subtract(const Duration(days: 1)).add(const Duration(hours: 20)), endTime: today.subtract(const Duration(days: 1)).add(const Duration(hours: 20, minutes: 30)), duration: const Duration(minutes: 30), source: 'manual'),
    ];
  }

  static List<Material> materials() {
    return [
      Material(id: 'demo-material-test', title: '测试示例：如何使用积累板块', content: '在这里记录需要长期积累的知识点、解题方法或复习资料。新增条目时可选择类别，并用标签补充检索关键词。', category: '测试类别', tags: const ['示例', '使用说明'], favorite: true, createdAt: DateTime.now()),
    ];
  }

  static List<Exam> exams() {
    final today = _today;
    return [
      Exam(id: 'demo-exam-national', name: '国考', examDate: today.add(const Duration(days: 116))),
      Exam(id: 'demo-exam-zhejiang', name: '浙江省考', examDate: today.add(const Duration(days: 123))),
      Exam(id: 'demo-exam-public', name: '浙江事业编', examDate: today.add(const Duration(days: 45))),
    ];
  }
}
