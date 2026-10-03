import 'package:flutter/material.dart';

class TodayStudyCard extends StatelessWidget {
  const TodayStudyCard({super.key, required this.duration, this.onTap});

  final Duration duration;
  final VoidCallback? onTap;

  String _format(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    if (hours == 0) return '$minutes 分钟';
    return '$hours 小时 $minutes 分钟';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule),
        title: const Text('今日学习时长'),
        subtitle: Text(_format(duration)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

