import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/daily_summary.dart';
import '../models/study_session.dart';
import '../models/wrong_question.dart';
import '../services/study_statistics.dart';
import '../utils/date_helpers.dart';
import '../utils/study_theme.dart';
import '../widgets/study_charts.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key, required this.sessions, required this.summaries, required this.wrongQuestions, this.onCreateSession, this.onDeleteSession, this.onSummarySaved, this.onSummaryAutosaved, this.onWrongQuestionCreated, this.onWrongQuestionDeleted});
  final List<StudySession> sessions;
  final Map<String, DailySummary> summaries;
  final List<WrongQuestion> wrongQuestions;
  final ValueChanged<StudySession>? onCreateSession;
  final ValueChanged<StudySession>? onDeleteSession;
  final ValueChanged<DailySummary>? onSummarySaved;
  final ValueChanged<DailySummary>? onSummaryAutosaved;
  final ValueChanged<WrongQuestion>? onWrongQuestionCreated;
  final ValueChanged<String>? onWrongQuestionDeleted;
  @override State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late DateTime _selectedDate;
  late DateTime _selectedMonth;
  String? _wrongSubject;
  Timer? _summaryDebounce;

  @override
  void initState() { super.initState(); final now = DateTime.now(); _selectedDate = DateTime(now.year, now.month, now.day); _selectedMonth = DateTime(now.year, now.month); }
  @override
  void dispose() { _summaryDebounce?.cancel(); super.dispose(); }

  Map<String, Duration> _subjectValues(Iterable<StudySession> input) {
    final result = {for (final s in StudySubject.values) s.label: Duration.zero};
    result.addAll(StudyStatistics.subjectTotals(input));
    return result;
  }
  List<StudySession> get _daySessions => widget.sessions.where((s) => dateKey(s.startTime) == dateKey(_selectedDate)).toList();

  Future<void> _manualEntry() async {
    var subject = StudySubject.language.label;
    final controller = TextEditingController(text: '30');
    final result = await showDialog<StudySession>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text('手动录入学习时长'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(initialValue: subject, decoration: const InputDecoration(labelText: '学习板块'), items: StudySubject.values.map((s) => DropdownMenuItem(value: s.label, child: Text(s.label))).toList(), onChanged: (v) => setDialogState(() => subject = v ?? subject)),
        const SizedBox(height: 12),
        TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '学习分钟数')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
        FilledButton(onPressed: () { final minutes = int.tryParse(controller.text) ?? 0; if (minutes <= 0) return; final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 20); Navigator.pop(dialogContext, StudySession(id: 'manual-${DateTime.now().microsecondsSinceEpoch}', subject: subject, startTime: start, endTime: start.add(Duration(minutes: minutes)), duration: Duration(minutes: minutes), source: 'manual')); }, child: const Text('保存')),
      ],
    )));
    await Future<void>.delayed(const Duration(milliseconds: 250)); controller.dispose();
    if (result != null) widget.onCreateSession?.call(result);
  }

  Future<void> _editSummary() async {
    final controller = TextEditingController(text: widget.summaries[dateKey(_selectedDate)]?.content ?? '');
    void autosave(String value) { _summaryDebounce?.cancel(); final summary = DailySummary(date: _selectedDate, content: value, updatedAt: DateTime.now()); _summaryDebounce = Timer(const Duration(milliseconds: 450), () => widget.onSummaryAutosaved?.call(summary)); }
    final content = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text('${_selectedDate.month}月${_selectedDate.day}日小结'),
      content: TextField(controller: controller, autofocus: true, maxLines: 6, onChanged: autosave, decoration: const InputDecoration(hintText: '今天完成了什么？明天准备做什么？（自动保存）')),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('保存'))],
    ));
    _summaryDebounce?.cancel(); await Future<void>.delayed(const Duration(milliseconds: 250)); controller.dispose();
    if (content != null) widget.onSummarySaved?.call(DailySummary(date: _selectedDate, content: content, updatedAt: DateTime.now()));
  }

  Future<void> _addWrongQuestion() async {
    var subject = StudySubject.language.label; String? imagePath; var open = true; final controller = TextEditingController();
    final result = await showDialog<WrongQuestion>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text('新增错题'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(initialValue: subject, decoration: const InputDecoration(labelText: '错题板块'), items: StudySubject.values.map((s) => DropdownMenuItem(value: s.label, child: Text(s.label))).toList(), onChanged: (v) => setDialogState(() => subject = v ?? subject)),
        const SizedBox(height: 12),
        TextField(controller: controller, minLines: 3, maxLines: 5, decoration: const InputDecoration(hintText: '手动输入错题内容')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () async { try { final image = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85); if (image == null) return; final dir = await getApplicationDocumentsDirectory(); final target = path.join(dir.path, 'wrong_${DateTime.now().microsecondsSinceEpoch}${path.extension(image.path)}'); await File(image.path).copy(target); if (open && dialogContext.mounted) setDialogState(() => imagePath = target); } catch (error) { if (open && dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('拍照失败：$error'))); } }, icon: const Icon(Icons.camera_alt_outlined), label: Text(imagePath == null ? '拍照录入' : '已保存照片 · 重新拍摄')),
      ])),
      actions: [
        TextButton(onPressed: () { open = false; Navigator.pop(dialogContext); }, child: const Text('取消')),
        FilledButton(onPressed: () { final text = controller.text.trim(); if (text.isEmpty && imagePath == null) return; open = false; Navigator.pop(dialogContext, WrongQuestion(id: 'wrong-${DateTime.now().microsecondsSinceEpoch}', subject: subject, content: text, imagePath: imagePath, createdAt: DateTime.now())); }, child: const Text('保存')),
      ],
    )));
    await Future<void>.delayed(const Duration(milliseconds: 250)); controller.dispose(); if (result != null) widget.onWrongQuestionCreated?.call(result);
  }

  void _showWrongQuestion(WrongQuestion question) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(question.subject),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (question.content.isNotEmpty) Text(question.content),
              if (question.imagePath != null) ...[
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: Image.file(File(question.imagePath!), fit: BoxFit.contain),
                ),
              ],
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('关闭'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayValues = _subjectValues(_daySessions);
    final monthSessions = widget.sessions.where((s) { final d = s.startTime.toLocal(); return d.year == _selectedMonth.year && d.month == _selectedMonth.month; });
    final summary = widget.summaries[dateKey(_selectedDate)];
    return Scaffold(body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 28), children: [
      const Text('学习统计', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: StudyTheme.ink)),
      const SizedBox(height: 4), const Text('看看你的学习成果', style: TextStyle(fontSize: 16, color: StudyTheme.muted)), const SizedBox(height: 20),
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('每日学习时长', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), FilledButton.tonalIcon(onPressed: _manualEntry, icon: const Icon(Icons.add, size: 18), label: const Text('手动录入'))]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton.filledTonal(onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))), icon: const Icon(Icons.chevron_left)), TextButton(onPressed: () async { final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (d != null) setState(() => _selectedDate = DateTime(d.year, d.month, d.day)); }, child: Text('${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日', style: const TextStyle(fontWeight: FontWeight.w800))), IconButton.filledTonal(onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))), icon: const Icon(Icons.chevron_right))]),
        SubjectPieChart(values: dayValues),
        ..._daySessions.map((s) => ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(s.subject), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('${s.duration.inMinutes}分钟'), IconButton(onPressed: () => widget.onDeleteSession?.call(s), icon: const Icon(Icons.delete_outline))]))),
      ]))),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('月度学习时长', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Row(children: [IconButton(onPressed: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)), icon: const Icon(Icons.chevron_left)), Text('${_selectedMonth.year}.${_selectedMonth.month}'), IconButton(onPressed: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)), icon: const Icon(Icons.chevron_right))])]), MonthlySubjectBars(values: _subjectValues(monthSessions))]))),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('每日小结', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), FilledButton.tonalIcon(onPressed: _editSummary, icon: const Icon(Icons.edit_note), label: const Text('复查 / 编辑'))]), const SizedBox(height: 10), Text(summary?.content.isNotEmpty == true ? summary!.content : '还没有写下今天的小结。', style: const TextStyle(height: 1.5, color: StudyTheme.muted))]))),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('错题板块', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), FilledButton.tonalIcon(onPressed: _addWrongQuestion, icon: const Icon(Icons.add), label: const Text('新增错题'))]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, children: [ChoiceChip(label: const Text('全部'), selected: _wrongSubject == null, onSelected: (_) => setState(() => _wrongSubject = null)), ...StudySubject.values.map((s) => ChoiceChip(label: Text(s.label), selected: _wrongSubject == s.label, selectedColor: s.color, onSelected: (_) => setState(() => _wrongSubject = s.label)))]),
        const SizedBox(height: 10),
        if (widget.wrongQuestions.isEmpty) const Text('还没有记录错题。', style: TextStyle(color: StudyTheme.muted))
        else ...widget.wrongQuestions.where((q) => _wrongSubject == null || q.subject == _wrongSubject).map((question) => ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: () => _showWrongQuestion(question),
          leading: CircleAvatar(backgroundColor: StudySubject.fromLabel(question.subject).color, child: const Icon(Icons.priority_high, color: Colors.white, size: 18)),
          title: Text(question.subject),
          subtitle: Text(question.content.isEmpty ? '图片错题 · 点击查看' : question.content, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: IconButton(onPressed: () => widget.onWrongQuestionDeleted?.call(question.id), icon: const Icon(Icons.delete_outline)),
        )),
      ]))),
    ])));
  }
}
