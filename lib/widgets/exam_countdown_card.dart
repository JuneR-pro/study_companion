import 'package:flutter/material.dart';

import '../models/exam.dart';
import '../utils/study_theme.dart';

class ExamCountdownCard extends StatelessWidget {
  const ExamCountdownCard({super.key, required this.exams, this.onTap});

  final List<Exam> exams;
  final ValueChanged<Exam>? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '考试倒计时',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Text(
              '点击修改日期',
              style: TextStyle(fontSize: 12, color: StudyTheme.muted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 142,
          child: Row(
            children: List.generate(exams.length, (index) {
              final exam = exams[index];
              final now = DateTime.now();
              final date = exam.examDate.toLocal();
              final days = DateTime.utc(
                date.year,
                date.month,
                date.day,
              ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
              final color = [
                const Color(0xFFEADBDD),
                const Color(0xFFD9E4EA),
                const Color(0xFFDCE8DE),
              ][index % 3];
              final ink = [
                const Color(0xFFB89498),
                const Color(0xFF8EA7B7),
                const Color(0xFF95B29E),
              ][index % 3];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == exams.length - 1 ? 0 : 8,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => onTap?.call(exam),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 13,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            exam.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              exam.examDate.year == 2100
                                  ? '待设置'
                                  : '${days < 0 ? 0 : days}',
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                color: ink,
                                fontSize: exam.examDate.year == 2100 ? 22 : 38,
                                height: 1.15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            exam.examDate.year == 2100 ? '点击选择日期' : '天',
                            style: TextStyle(
                              color: StudyTheme.ink.withValues(alpha: .72),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
