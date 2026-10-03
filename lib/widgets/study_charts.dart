import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/study_theme.dart';

class SubjectPieChart extends StatelessWidget {
  const SubjectPieChart({super.key, required this.values});

  final Map<String, Duration> values;

  @override
  Widget build(BuildContext context) {
    final totalSeconds = values.values.fold<int>(
      0,
      (sum, value) => sum + value.inSeconds,
    );
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: CustomPaint(
            painter: _PiePainter(values: values),
            child: Center(
              child: Text(
                _formatTotal(Duration(seconds: totalSeconds)),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: values.entries.map((entry) {
            final subject = StudySubject.fromLabel(entry.key);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: subject.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(subject.label, style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatTotal(Duration duration) {
    if (duration == Duration.zero) return '暂无学习';
    return '${duration.inHours}小时${duration.inMinutes.remainder(60)}分钟';
  }
}

class MonthlySubjectBars extends StatelessWidget {
  const MonthlySubjectBars({super.key, required this.values});

  final Map<String, Duration> values;

  @override
  Widget build(BuildContext context) {
    final maxSeconds = values.values.fold<int>(
      0,
      (max, value) => math.max(max, value.inSeconds),
    );
    return SizedBox(
      height: 230,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: StudySubject.values.map((subject) {
          final value = values[subject.label] ?? Duration.zero;
          final ratio = maxSeconds == 0 ? 0.0 : value.inSeconds / maxSeconds;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${(value.inMinutes / 60).toStringAsFixed(1)}h',
                    style: const TextStyle(
                      fontSize: 10,
                      color: StudyTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: math.max(3, ratio * 160),
                    width: 24,
                    decoration: BoxDecoration(
                      color: subject.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subject.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({required this.values});

  final Map<String, Duration> values;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.values.fold<int>(
      0,
      (sum, value) => sum + value.inSeconds,
    );
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    if (total == 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = const Color(0xFFE9E4DE),
      );
      canvas.drawCircle(center, radius * .62, Paint()..color = Colors.white);
      return;
    }
    var start = -math.pi / 2;
    for (final entry in values.entries) {
      if (entry.value.inSeconds == 0) continue;
      final sweep = entry.value.inSeconds / total * math.pi * 2;
      final paint = Paint()..color = StudySubject.fromLabel(entry.key).color;
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }
    canvas.drawCircle(center, radius * .61, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) =>
      oldDelegate.values != values;
}
