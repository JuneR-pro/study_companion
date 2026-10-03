import 'package:flutter/material.dart';

import '../models/study_session.dart';
import '../services/study_statistics.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key, required this.sessions});

  final List<StudySession> sessions;

  String _format(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    return hours == 0 ? '$minutes 分钟' : '$hours 小时 $minutes 分钟';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = StudyStatistics.totalForDate(sessions, now);
    final month = StudyStatistics.dailyDurationsForMonth(sessions, now);
    final subjects = StudyStatistics.subjectTotals(sessions);
    final percentages = StudyStatistics.subjectPercentages(sessions);
    final streak = StudyStatistics.consecutiveLearningDays(sessions, through: now);
    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(title: const Text('今日学习'), trailing: Text(_format(today)))),
          Card(child: ListTile(title: const Text('连续学习'), trailing: Text('$streak 天'))),
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: Text('本月每天'),
          ),
          ...month.entries.where((entry) => entry.value > Duration.zero).map(
                (entry) => ListTile(title: Text(entry.key), trailing: Text(_format(entry.value))),
              ),
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: Text('按科目'),
          ),
          ...subjects.entries.map(
            (entry) => ListTile(
              title: Text(entry.key),
              subtitle: Text('占比 ${(percentages[entry.key]! * 100).toStringAsFixed(1)}%'),
              trailing: Text(_format(entry.value)),
            ),
          ),
        ],
      ),
    );
  }
}

