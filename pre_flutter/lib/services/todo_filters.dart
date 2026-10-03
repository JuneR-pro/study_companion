import '../models/todo.dart';
import '../utils/date_helpers.dart';

class TodoFilters {
  const TodoFilters._();

  static List<Todo> byDate(Iterable<Todo> todos, DateTime date) {
    final key = dateKey(date);
    return todos.where((todo) => dateKey(todo.date) == key).toList();
  }
}

