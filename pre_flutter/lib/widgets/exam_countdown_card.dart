import 'package:flutter/material.dart';

import '../models/exam.dart';

class ExamCountdownCard extends StatelessWidget {
  const ExamCountdownCard({super.key, this.exam, this.onTap});

  final Exam? exam;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (exam == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.event_available),
          title: const Text('还没有考试'),
          subtitle: const Text('添加一场考试开始倒计时'),
          onTap: onTap,
        ),
      );
    }
    final days = exam!.examDate.difference(DateTime.now()).inDays;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event),
        title: Text(exam!.name),
        subtitle: Text('还有 ${days < 0 ? 0 : days} 天 · ${exam!.examDate.toLocal()}'),
        onTap: onTap,
      ),
    );
  }
}

