import 'dart:io';

import 'package:flutter/material.dart';

import '../models/wrong_notebook.dart';
import '../models/wrong_question.dart';
import '../utils/study_theme.dart';
import '../utils/wrong_question_icons.dart';

class WrongQuestionDetailPage extends StatefulWidget {
  const WrongQuestionDetailPage({
    super.key,
    required this.questions,
    required this.notebooks,
    required this.initialIndex,
    this.onDelete,
    this.onEditName,
  });

  final List<WrongQuestion> questions;
  final List<WrongNotebook> notebooks;
  final int initialIndex;
  final ValueChanged<String>? onDelete;
  final void Function(String id, String newName)? onEditName;

  @override
  State<WrongQuestionDetailPage> createState() => _WrongQuestionDetailPageState();
}

class _WrongQuestionDetailPageState extends State<WrongQuestionDetailPage> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  WrongQuestion get _current => widget.questions[_index];

  WrongNotebook? get _currentNotebook {
    for (final nb in widget.notebooks) {
      if (nb.id == _current.notebookId) return nb;
    }
    return null;
  }

  void _prev() {
    if (_index > 0) setState(() => _index--);
  }

  void _next() {
    if (_index < widget.questions.length - 1) setState(() => _index++);
  }

  Future<void> _rename() async {
    final q = _current;
    final controller = TextEditingController(text: q.name.isNotEmpty ? q.name : q.subject);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: '名称'), maxLength: 20, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () {
            final n = controller.text.trim();
            if (n.isEmpty) return;
            Navigator.pop(ctx, n);
          }, child: const Text('保存')),
        ],
      ),
    );
    controller.dispose();
    if (newName != null) {
      widget.onEditName?.call(q.id, newName);
      setState(() {
        final idx = widget.questions.indexWhere((q2) => q2.id == q.id);
        if (idx >= 0) {
          widget.questions[idx] = widget.questions[idx].copyWith(name: newName);
        }
      });
    }
  }

  void _viewImage(String imagePath) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _FullscreenImageView(imagePath: imagePath),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final q = _current;
    final nb = _currentNotebook;
    final subjectColor = StudySubject.fromLabel(q.subject).color;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: _rename, icon: const Icon(Icons.edit_outlined), tooltip: '重命名'),
          if (widget.onDelete != null)
            IconButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onDelete?.call(q.id);
              },
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (nb != null)
                Row(children: [
                  Icon(WrongQuestionIcons.fromName(nb.iconName), size: 16, color: nb.color),
                  const SizedBox(width: 4),
                  Text(nb.name, style: TextStyle(fontSize: 13, color: nb.color, fontWeight: FontWeight.w600)),
                ]),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: Text(
                    q.name.isNotEmpty ? q.name : q.subject,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: StudyTheme.ink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.questions.length > 1) ...[
                  const SizedBox(width: 4),
                  IconButton.filledTonal(onPressed: _index > 0 ? _prev : null, icon: const Icon(Icons.chevron_left, size: 20)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text('${_index + 1}/${widget.questions.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: StudyTheme.muted)),
                  ),
                  IconButton.filledTonal(onPressed: _index < widget.questions.length - 1 ? _next : null, icon: const Icon(Icons.chevron_right, size: 20)),
                ],
              ]),
            ]),
          ),
          const Divider(height: 1, color: StudyTheme.line),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: subjectColor.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(q.subject, style: TextStyle(color: subjectColor, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                if (q.content.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(q.content, style: const TextStyle(fontSize: 16, height: 1.6)),
                ],
                if (q.imagePath != null) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _viewImage(q.imagePath!),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 360, maxWidth: double.infinity),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(q.imagePath!), fit: BoxFit.contain),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _FullscreenImageView extends StatelessWidget {
  const _FullscreenImageView({required this.imagePath});
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onDoubleTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 5.0,
            child: Image.file(File(imagePath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
