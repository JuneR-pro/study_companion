import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../services/todo_filters.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key, required this.initialTodos, this.onChanged});

  final List<Todo> initialTodos;
  final ValueChanged<List<Todo>>? onChanged;

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  late List<Todo> _todos;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _todos = List<Todo>.from(widget.initialTodos);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  List<Todo> get _visibleTodos => TodoFilters.byDate(_todos, _selectedDate);

  void _notifyChanged() => widget.onChanged?.call(List<Todo>.from(_todos));

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  void _addTodo() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final now = DateTime.now();
    setState(() {
      _todos.add(Todo(
        id: 'todo-${now.microsecondsSinceEpoch}',
        title: title,
        date: _selectedDate,
        completed: false,
        createdAt: now,
      ));
      _titleController.clear();
    });
    _notifyChanged();
  }

  void _toggle(Todo todo) {
    setState(() {
      final index = _todos.indexWhere((item) => item.id == todo.id);
      if (index >= 0) _todos[index] = todo.copyWith(completed: !todo.completed);
    });
    _notifyChanged();
  }

  Future<bool> _confirmDelete(Todo todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除待办？'),
        content: Text(todo.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    return confirmed == true;
  }

  void _remove(Todo todo) {
    setState(() => _todos.removeWhere((item) => item.id == todo.id));
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('待办'),
        actions: [IconButton(onPressed: _chooseDate, icon: const Icon(Icons.calendar_today))],
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('日期：${_selectedDate.toLocal().toString().split(' ').first}'),
            trailing: Text('${_visibleTodos.length} 条'),
          ),
          Expanded(
            child: _visibleTodos.isEmpty
                ? const Center(child: Text('这一天还没有待办'))
                : ListView.builder(
                    itemCount: _visibleTodos.length,
                    itemBuilder: (context, index) {
                      final todo = _visibleTodos[index];
                      return Dismissible(
                        key: ValueKey(todo.id),
                        background: Container(color: Colors.red),
                        confirmDismiss: (_) => _confirmDelete(todo),
                        onDismissed: (_) => _remove(todo),
                        child: CheckboxListTile(
                          value: todo.completed,
                          title: Text(todo.title),
                          onChanged: (_) => _toggle(todo),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: '新增待办', border: OutlineInputBorder()),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: _addTodo, icon: const Icon(Icons.add_circle)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
