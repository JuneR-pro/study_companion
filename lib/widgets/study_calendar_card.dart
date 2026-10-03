import 'package:flutter/material.dart';

import '../models/study_session.dart';
import '../services/study_statistics.dart';
import '../utils/date_helpers.dart';
import '../utils/study_theme.dart';

class StudyCalendarCard extends StatefulWidget {
  const StudyCalendarCard({
    super.key,
    required this.sessions,
    required this.onDateSelected,
  });

  final List<StudySession> sessions;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<StudyCalendarCard> createState() => _StudyCalendarCardState();
}

class _StudyCalendarCardState extends State<StudyCalendarCard> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _changeMonth(int offset) {
    setState(() => _month = DateTime(_month.year, _month.month + offset));
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month, 1);
    final leading = first.weekday % 7;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final totals = StudyStatistics.dailyDurationsForMonth(
      widget.sessions,
      _month,
    );
    final cells = <Widget>[];
    for (var index = 0; index < leading; index++) {
      cells.add(const SizedBox.expand());
    }
    for (var day = 1; day <= days; day++) {
      final date = DateTime(_month.year, _month.month, day);
      final key = dateKey(date);
      final duration = totals[key] ?? Duration.zero;
      final daySessions = widget.sessions
          .where((session) => dateKey(session.startTime) == key)
          .toList();
      final color = daySessions.isEmpty
          ? null
          : StudySubject.fromLabel(daySessions.first.subject).color
                .withValues(alpha: .42);
      cells.add(
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => widget.onDateSelected(date),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              border: dateKey(DateTime.now()) == key
                  ? Border.all(color: StudyTheme.accent, width: 2)
                  : null,
            ),
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              children: [
                Text(
                  '$day',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (duration > Duration.zero)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatDuration(duration),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: StudyTheme.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    while (cells.length < 42) {
      cells.add(const SizedBox.expand());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '学习日历',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${_month.year}年${_month.month}月',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('日'),
                Text('一'),
                Text('二'),
                Text('三'),
                Text('四'),
                Text('五'),
                Text('六'),
              ],
            ),
            const SizedBox(height: 8),
            GridView.custom(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 48,
                mainAxisSpacing: 6,
                crossAxisSpacing: 4,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childrenDelegate: SliverChildListDelegate(cells),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '点击日期查看学习详情，也可以手动打卡',
                style: TextStyle(color: StudyTheme.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h${minutes}m';
  }
}
