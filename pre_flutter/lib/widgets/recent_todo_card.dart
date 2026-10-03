import 'package:flutter/material.dart';

import '../models/todo.dart';

class RecentTodoCard extends StatelessWidget {
  const RecentTodoCard({
    super.key,
    required this.todos,
    required this.onToggle,
    this.onTap,
  });

  final List<Todo> todos;
  final ValueChanged<Todo> onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final recent = todos.where((todo) => !todo.completed).take(3).toList();
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.checklist),
            title: const Text('最近待办'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
          ),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('今天没有未完成待办'),
              ),
            )
          else
            ...recent.map(
              (todo) => CheckboxListTile(
                dense: true,
                value: todo.completed,
                title: Text(todo.title),
                onChanged: (_) => onToggle(todo),
              ),
            ),
        ],
      ),
    );
  }
}

