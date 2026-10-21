import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/wrong_custom_tag.dart';
import '../models/wrong_notebook.dart';
import '../models/wrong_question.dart';
import '../utils/study_theme.dart';
import '../utils/wrong_question_icons.dart';
import '../widgets/icon_color_picker.dart';
import '../widgets/wrong_question_detail_dialog.dart';

class WrongQuestionsScreen extends StatefulWidget {
  const WrongQuestionsScreen({
    super.key,
    required this.wrongQuestions,
    required this.notebooks,
    required this.customTags,
    required this.onQuestionCreated,
    required this.onQuestionDeleted,
    required this.onQuestionUpdated,
    required this.onNotebookCreated,
    required this.onNotebookUpdated,
    required this.onNotebookDeleted,
    required this.onTagCreated,
    required this.onTagUpdated,
    required this.onTagDeleted,
    required this.onQuestionTagsSet,
    required this.getQuestionTagIds,
  });

  final List<WrongQuestion> wrongQuestions;
  final List<WrongNotebook> notebooks;
  final List<WrongCustomTag> customTags;
  final ValueChanged<WrongQuestion> onQuestionCreated;
  final ValueChanged<String> onQuestionDeleted;
  final ValueChanged<WrongQuestion> onQuestionUpdated;
  final ValueChanged<WrongNotebook> onNotebookCreated;
  final ValueChanged<WrongNotebook> onNotebookUpdated;
  final ValueChanged<String> onNotebookDeleted;
  final ValueChanged<WrongCustomTag> onTagCreated;
  final ValueChanged<WrongCustomTag> onTagUpdated;
  final ValueChanged<String> onTagDeleted;
  final Future<void> Function(String questionId, List<String> tagIds) onQuestionTagsSet;
  final Future<List<String>> Function(String questionId) getQuestionTagIds;

  @override
  State<WrongQuestionsScreen> createState() => _WrongQuestionsScreenState();
}

class _WrongQuestionsScreenState extends State<WrongQuestionsScreen> {
  late List<WrongQuestion> _questions;
  late List<WrongNotebook> _notebooks;
  late List<WrongCustomTag> _customTags;
  String? _selectedNotebookId;
  String? _selectedSubject;
  final Set<String> _selectedTagIds = {};

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.wrongQuestions);
    _notebooks = List.from(widget.notebooks);
    _customTags = List.from(widget.customTags);
  }

  List<WrongQuestion> get _filteredQuestions {
    return _questions.where((q) {
      if (_selectedNotebookId != null && q.notebookId != _selectedNotebookId) return false;
      if (_selectedSubject != null && q.subject != _selectedSubject) return false;
      return true;
    }).toList();
  }

  Future<void> _createNotebook() async {
    final defaultNum = _notebooks.length + 1;
    final nameController = TextEditingController(text: '错题本$defaultNum');
    var iconName = 'folder';
    var color = StudyTheme.accent;

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          title: const Text('新建错题本'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: '错题本名称'), maxLength: 20),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final r = await IconColorPicker.show(ctx, title: '选择图标和颜色', iconName: iconName, color: color);
                      setDialogState(() { iconName = r.$1; color = r.$2; });
                    },
                    icon: Icon(WrongQuestionIcons.fromName(iconName), color: color),
                    label: const Text('图标和颜色'),
                  ),
                ),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(onPressed: () {
              final n = nameController.text.trim();
              if (n.isEmpty) return;
              Navigator.pop(ctx, n);
            }, child: const Text('创建')),
          ],
        );
      }),
    );
    nameController.dispose();
    if (name != null) {
      final nb = WrongNotebook(
        id: 'notebook-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        iconName: iconName,
        colorValue: color.value,
        createdAt: DateTime.now(),
      );
      setState(() => _notebooks.add(nb));
      widget.onNotebookCreated(nb);
    }
  }

  Future<void> _editNotebook(WrongNotebook notebook) async {
    final nameController = TextEditingController(text: notebook.name);
    var iconName = notebook.iconName;
    var color = notebook.color;
    var doDelete = false;

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          title: const Text('编辑错题本'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: '错题本名称'), maxLength: 20),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final r = await IconColorPicker.show(ctx, title: '选择图标和颜色', iconName: iconName, color: color);
                      setDialogState(() { iconName = r.$1; color = r.$2; });
                    },
                    icon: Icon(WrongQuestionIcons.fromName(iconName), color: color),
                    label: const Text('图标和颜色'),
                  ),
                ),
              ]),
            ]),
          ),
          actions: [
            if (notebook.id != 'default')
              TextButton(
                onPressed: () { doDelete = true; Navigator.pop(ctx); },
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(onPressed: () {
              final n = nameController.text.trim();
              if (n.isEmpty) return;
              Navigator.pop(ctx, n);
            }, child: const Text('保存')),
          ],
        );
      }),
    );
    nameController.dispose();
    if (doDelete) {
      setState(() {
        _notebooks.removeWhere((n) => n.id == notebook.id);
        _questions = _questions.map((q) => q.notebookId == notebook.id ? q.copyWith(notebookId: 'default') : q).toList();
        if (_selectedNotebookId == notebook.id) _selectedNotebookId = null;
      });
      widget.onNotebookDeleted(notebook.id);
    } else if (name != null) {
      final updated = notebook.copyWith(name: name, iconName: iconName, colorValue: color.value);
      setState(() => _notebooks = _notebooks.map((n) => n.id == notebook.id ? updated : n).toList());
      widget.onNotebookUpdated(updated);
    }
  }

  Future<void> _createTag() async {
    final defaultNum = _customTags.length + 1;
    final nameController = TextEditingController(text: '标签$defaultNum');
    var iconName = 'label';
    var color = StudyTheme.accent;

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          title: const Text('新建副标签'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: '标签名称'), maxLength: 10),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final r = await IconColorPicker.show(ctx, title: '选择图标和颜色', iconName: iconName, color: color);
                      setDialogState(() { iconName = r.$1; color = r.$2; });
                    },
                    icon: Icon(WrongQuestionIcons.fromName(iconName), color: color),
                    label: const Text('图标和颜色'),
                  ),
                ),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(onPressed: () {
              final n = nameController.text.trim();
              if (n.isEmpty) return;
              Navigator.pop(ctx, n);
            }, child: const Text('创建')),
          ],
        );
      }),
    );
    nameController.dispose();
    if (name != null) {
      final tag = WrongCustomTag(
        id: 'tag-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        iconName: iconName,
        colorValue: color.value,
        createdAt: DateTime.now(),
      );
      setState(() => _customTags.add(tag));
      widget.onTagCreated(tag);
    }
  }

  Future<void> _addWrongQuestion() async {
    var subject = StudySubject.language.label;
    var selectedNotebook = _selectedNotebookId ?? 'default';
    final selectedTagIds = <String>{};
    String? imagePath;
    final nameController = TextEditingController(text: '错题${_questions.length + 1}');
    final contentController = TextEditingController();
    var open = true;

    final result = await showDialog<WrongQuestion>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          title: const Text('新增错题'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: '错题名称'), maxLength: 20),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedNotebook,
                decoration: const InputDecoration(labelText: '错题本'),
                items: _notebooks.map((nb) => DropdownMenuItem(value: nb.id, child: Text(nb.name))).toList(),
                onChanged: (v) => setDialogState(() => selectedNotebook = v ?? selectedNotebook),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: subject,
                decoration: const InputDecoration(labelText: '主标签（学科）'),
                items: StudySubject.values.map((s) => DropdownMenuItem(value: s.label, child: Text(s.label))).toList(),
                onChanged: (v) => setDialogState(() => subject = v ?? subject),
              ),
              if (_customTags.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('副标签', style: TextStyle(fontSize: 13, color: StudyTheme.muted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: _customTags.map((tag) {
                    final selected = selectedTagIds.contains(tag.id);
                    return ChoiceChip(
                      label: Text(tag.name),
                      selected: selected,
                      selectedColor: tag.color,
                      avatar: Icon(WrongQuestionIcons.fromName(tag.iconName), size: 16, color: selected ? Colors.white : tag.color),
                      onSelected: (_) => setDialogState(() {
                        if (selected) { selectedTagIds.remove(tag.id); } else { selectedTagIds.add(tag.id); }
                      }),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              TextField(controller: contentController, minLines: 3, maxLines: 5, decoration: const InputDecoration(hintText: '手动输入错题内容')),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final image = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
                    if (image == null) return;
                    final dir = await getApplicationDocumentsDirectory();
                    final target = path.join(dir.path, 'wrong_${DateTime.now().microsecondsSinceEpoch}${path.extension(image.path)}');
                    await File(image.path).copy(target);
                    if (open && ctx.mounted) setDialogState(() => imagePath = target);
                  } catch (error) {
                    if (open && ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('拍照失败：$error')));
                  }
                },
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(imagePath == null ? '拍照录入' : '已保存照片 · 重新拍摄'),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () { open = false; Navigator.pop(ctx); }, child: const Text('取消')),
            FilledButton(onPressed: () {
              final text = contentController.text.trim();
              if (text.isEmpty && imagePath == null) return;
              open = false;
              Navigator.pop(ctx, WrongQuestion(
                id: 'wrong-${DateTime.now().microsecondsSinceEpoch}',
                name: nameController.text.trim(),
                subject: subject,
                content: text,
                notebookId: selectedNotebook,
                imagePath: imagePath,
                createdAt: DateTime.now(),
              ));
            }, child: const Text('保存')),
          ],
        );
      }),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    nameController.dispose();
    contentController.dispose();
    if (result != null) {
      setState(() => _questions = [result, ..._questions]);
      widget.onQuestionCreated(result);
    }
  }

  void _deleteQuestion(String id) {
    setState(() => _questions.removeWhere((q) => q.id == id));
    widget.onQuestionDeleted(id);
  }

  void _renameQuestion(String id, String newName) {
    final idx = _questions.indexWhere((q) => q.id == id);
    if (idx < 0) return;
    final updated = _questions[idx].copyWith(name: newName);
    setState(() => _questions[idx] = updated);
    widget.onQuestionUpdated(updated);
  }

  void _showDetail(WrongQuestion question) {
    final filtered = _filteredQuestions;
    final index = filtered.indexWhere((q) => q.id == question.id);
    if (index < 0) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => WrongQuestionDetailPage(
        questions: filtered,
        notebooks: _notebooks,
        initialIndex: index,
        onDelete: _deleteQuestion,
        onEditName: _renameQuestion,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final questions = _filteredQuestions;
    return Scaffold(
      appBar: AppBar(
        title: const Text('错题', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            // Notebook section
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._notebooks.map((nb) => _NotebookChip(
                    notebook: nb,
                    selected: _selectedNotebookId == nb.id,
                    count: _questions.where((q) => q.notebookId == nb.id).length,
                    onTap: () => setState(() => _selectedNotebookId = _selectedNotebookId == nb.id ? null : nb.id),
                    onLongPress: () => _editNotebook(nb),
                  )),
                  _AddChip(onTap: _createNotebook, label: '错题本'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Main tag filter box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7F4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: StudyTheme.line),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('主标签（学科）', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: StudyTheme.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: [
                    ChoiceChip(label: const Text('全部'), selected: _selectedSubject == null, onSelected: (_) => setState(() => _selectedSubject = null)),
                    ...StudySubject.values.map((s) => ChoiceChip(
                      label: Text(s.label),
                      selected: _selectedSubject == s.label,
                      selectedColor: s.color,
                      onSelected: (_) => setState(() => _selectedSubject = _selectedSubject == s.label ? null : s.label),
                    )),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: 8),
            // Custom tag filter box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7F4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: StudyTheme.line),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('副标签', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: StudyTheme.muted)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _createTag,
                    child: const Row(children: [
                      Icon(Icons.add_circle_outline, size: 16, color: StudyTheme.accent),
                      SizedBox(width: 2),
                      Text('添加', style: TextStyle(fontSize: 13, color: StudyTheme.accent, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 8),
                if (_customTags.isEmpty)
                  const Text('还没有自定义标签，点击上方"添加"创建', style: TextStyle(fontSize: 13, color: StudyTheme.muted))
                else
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: _customTags.map((tag) {
                      final selected = _selectedTagIds.contains(tag.id);
                      return ChoiceChip(
                        label: Text(tag.name),
                        selected: selected,
                        selectedColor: tag.color,
                        avatar: Icon(WrongQuestionIcons.fromName(tag.iconName), size: 16, color: selected ? Colors.white : tag.color),
                        onSelected: (_) => setState(() {
                          if (selected) { _selectedTagIds.remove(tag.id); } else { _selectedTagIds.add(tag.id); }
                        }),
                      );
                    }).toList(),
                  ),
              ]),
            ),
            const SizedBox(height: 16),
            // Question list
            if (questions.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('还没有记录错题。', style: TextStyle(color: StudyTheme.muted))))
            else
              ...questions.map((q) {
                final subjectColor = StudySubject.fromLabel(q.subject).color;
                final nb = _notebooks.where((n) => n.id == q.notebookId).firstOrNull;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: subjectColor,
                      child: Icon(WrongQuestionIcons.fromName(nb?.iconName ?? 'folder'), color: Colors.white, size: 18),
                    ),
                    title: Text(q.name.isNotEmpty ? q.name : q.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      q.content.isEmpty ? '图片错题 · 点击查看' : q.content,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: subjectColor.withValues(alpha: .15), borderRadius: BorderRadius.circular(8)),
                        child: Text(q.subject, style: TextStyle(fontSize: 11, color: subjectColor, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 4),
                      IconButton(onPressed: () => _deleteQuestion(q.id), icon: const Icon(Icons.delete_outline, size: 20)),
                    ]),
                    onTap: () => _showDetail(q),
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWrongQuestion,
        icon: const Icon(Icons.add),
        label: const Text('新增错题'),
      ),
    );
  }
}

class _NotebookChip extends StatelessWidget {
  const _NotebookChip({required this.notebook, required this.selected, required this.count, required this.onTap, required this.onLongPress});
  final WrongNotebook notebook;
  final bool selected;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? notebook.color.withValues(alpha: .18) : const Color(0xFFF5F2ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? notebook.color : Colors.transparent, width: 2),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(WrongQuestionIcons.fromName(notebook.iconName), color: selected ? notebook.color : StudyTheme.ink, size: 28),
          const SizedBox(height: 4),
          Text(notebook.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? notebook.color : StudyTheme.ink)),
          Text('$count题', style: const TextStyle(fontSize: 10, color: StudyTheme.muted)),
        ]),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap, required this.label});
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F2ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: StudyTheme.line),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add_circle_outline, size: 28, color: StudyTheme.muted),
          const SizedBox(height: 4),
          Text('新建$label', style: const TextStyle(fontSize: 12, color: StudyTheme.muted)),
        ]),
      ),
    );
  }
}
