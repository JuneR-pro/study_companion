import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/study_session.dart';
import '../models/todo.dart';
import 'home_screen.dart';
import 'material_screen.dart';
import 'statistics_screen.dart';
import 'todo_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  late List<Todo> _todos;
  late List<StudySession> _sessions;

  @override
  void initState() {
    super.initState();
    _todos = DemoData.todos();
    _sessions = DemoData.sessions();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        todos: _todos,
        sessions: _sessions,
        exam: DemoData.exam(),
        onTodoToggle: (todo) {
          setState(() {
            final index = _todos.indexWhere((item) => item.id == todo.id);
            if (index >= 0) _todos[index] = todo.copyWith(completed: !todo.completed);
          });
        },
        onSessionCompleted: (session) => setState(() => _sessions.add(session)),
      ),
      TodoScreen(initialTodos: _todos, onChanged: (value) => setState(() => _todos = value)),
      StatisticsScreen(sessions: _sessions),
      MaterialScreen(initialMaterials: DemoData.materials()),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: '待办'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: '统计'),
          NavigationDestination(icon: Icon(Icons.collections_bookmark_outlined), selectedIcon: Icon(Icons.collections_bookmark), label: '积累'),
        ],
      ),
    );
  }
}

