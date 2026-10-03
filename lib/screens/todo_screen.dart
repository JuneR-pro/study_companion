import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../services/todo_filters.dart';
import '../utils/study_theme.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({
    super.key,
    required this.initialTodos,
    this.onChanged,
    this.onCreated,
    this.onUpdated,
    this.onDeleted,
  });

  final List<Todo> initialTodos;
  final ValueChanged<List<Todo>>? onChanged;
  final ValueChanged<Todo>? onCreated;
  final ValueChanged<Todo>? onUpdated;
  final ValueChanged<String>? onDeleted;

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  late List<Todo> _todos;
  late DateTime _selectedDate;
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _todos = List<Todo>.from(widget.initialTodos);
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void didUpdateWidget(covariant TodoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTodos != widget.initialTodos) {
      _todos = List<Todo>.from(widget.initialTodos);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  List<Todo> get _visibleTodos => TodoFilters.byDate(_todos, _selectedDate);
  int get _completedCount =>
      _visibleTodos.where((todo) => todo.completed).length;

  void _notifyChanged() => widget.onChanged?.call(List<Todo>.from(_todos));

  void _moveDate(int offset) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: offset)));
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _selectedDate = DateTime(date.year, date.month, date.day));
    }
  }

  void _addTodo() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final now = DateTime.now();
    final todo = Todo(
      id: 'todo-${now.microsecondsSinceEpoch}',
      title: title,
      date: _selectedDate,
      completed: false,
      createdAt: now,
    );
    setState(() {
      _todos.add(todo);
      _titleController.clear();
    });
    widget.onCreated?.call(todo);
    _notifyChanged();
  }

  void _toggle(Todo todo) {
    final updated = todo.copyWith(completed: !todo.completed);
    setState(() {
      final index = _todos.indexWhere((item) => item.id == todo.id);
      if (index >= 0) _todos[index] = updated;
    });
    widget.onUpdated?.call(updated);
    _notifyChanged();
  }

  Future<void> _edit(Todo todo) async {
    final controller = TextEditingController(text: todo.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑待办'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          onChanged: (value) {
            final title = value.trim();
            if (title.isEmpty) return;
            final updated = todo.copyWith(title: title);
            setState(
              () => _todos = _todos
                  .map((item) => item.id == todo.id ? updated : item)
                  .toList(),
            );
            widget.onUpdated?.call(updated);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty || title == todo.title) return;
    final updated = todo.copyWith(title: title);
    setState(() {
      final index = _todos.indexWhere((item) => item.id == todo.id);
      if (index >= 0) _todos[index] = updated;
    });
    widget.onUpdated?.call(updated);
    _notifyChanged();
  }

  Future<bool> _confirmDelete(Todo todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除待办？'),
        content: Text(todo.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  void _remove(Todo todo) {
    setState(() => _todos.removeWhere((item) => item.id == todo.id));
    widget.onDeleted?.call(todo.id);
    _notifyChanged();
  }

  String _dateLabel() {
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    if (_selectedDate == date) return '今天';
    return '${_selectedDate.month}月${_selectedDate.day}日';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '每日待办',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: StudyTheme.ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '把今天要做的事，一件件完成',
                        style: TextStyle(color: StudyTheme.muted),
                      ),
                    ],
                  ),
                  Text(
                    '$_completedCount/${_visibleTodos.length} 项完成',
                    style: const TextStyle(color: StudyTheme.muted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _moveDate(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    TextButton(
                      onPressed: _chooseDate,
                      child: Text(
                        _dateLabel(),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: StudyTheme.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _moveDate(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _visibleTodos.isEmpty
                  ? const Center(
                      child: Text(
                        '这一天还没有待办',
                        style: TextStyle(color: StudyTheme.muted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      itemCount: _visibleTodos.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final todo = _visibleTodos[index];
                        return Dismissible(
                          key: ValueKey(todo.id),
                          confirmDismiss: (_) => _confirmDelete(todo),
                          onDismissed: (_) => _remove(todo),
                          background: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5C5C5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: const Icon(Icons.delete_outline),
                          ),
                          child: Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              leading: Checkbox(
                                value: todo.completed,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                onChanged: (_) => _toggle(todo),
                              ),
                              title: Text(
                                todo.title,
                                style: TextStyle(
                                  decoration: todo.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: todo.completed
                                      ? StudyTheme.muted
                                      : StudyTheme.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: IconButton(
                                onPressed: () => _edit(todo),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: '添加待办事项…',
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                      onSubmitted: (_) => _addTodo(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: StudyTheme.accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(56, 56),
                    ),
                    onPressed: _addTodo,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
