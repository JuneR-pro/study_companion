import 'package:flutter/material.dart';

import '../models/exam.dart';
import '../utils/study_theme.dart';

class ExamCountdownCard extends StatelessWidget {
  const ExamCountdownCard({super.key, required this.exams, this.onTap, this.onAdd, this.onDelete});

  final List<Exam> exams;
  final ValueChanged<Exam>? onTap;
  final VoidCallback? onAdd;
  final ValueChanged<Exam>? onDelete;

  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.sizeOf(context).width - 52) / 2.15;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('考试倒计时', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const Text('左右滑动查看更多', style: TextStyle(fontSize: 12, color: StudyTheme.muted)),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        height: 142,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: exams.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == exams.length) {
              return _addCard(cardWidth);
            }
            return _examCard(context, exams[index], index, cardWidth);
          },
        ),
      ),
    ]);
  }

  Widget _addCard(double width) => SizedBox(
    width: width,
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onAdd,
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFF1EEE9), borderRadius: BorderRadius.circular(24), border: Border.all(color: StudyTheme.accent.withValues(alpha: .35))),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline, size: 34, color: StudyTheme.accent), SizedBox(height: 6), Text('添加考试', style: TextStyle(fontWeight: FontWeight.w700, color: StudyTheme.accent))]),
      ),
    ),
  );

  Widget _examCard(BuildContext context, Exam exam, int index, double width) {
    final now = DateTime.now();
    final date = exam.examDate.toLocal();
    final days = DateTime(date.year, date.month, date.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    final colors = [const Color(0xFFEADBDD), const Color(0xFFD9E4EA), const Color(0xFFDCE8DE), const Color(0xFFE5DCCF)];
    final inks = [const Color(0xFFB89498), const Color(0xFF8EA7B7), const Color(0xFF95B29E), const Color(0xFFA58D70)];
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => onTap?.call(exam),
        onLongPress: () => onDelete?.call(exam),
        child: Container(
          decoration: BoxDecoration(color: colors[index % colors.length], borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(exam.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: inks[index % inks.length], fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            FittedBox(fit: BoxFit.scaleDown, child: Text('${days < 0 ? 0 : days}', maxLines: 1, style: TextStyle(color: inks[index % inks.length], fontSize: 38, height: 1.1, fontWeight: FontWeight.w900))),
            const Text('天 · 点击编辑', style: TextStyle(color: StudyTheme.muted, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}
