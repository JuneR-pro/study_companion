import 'package:flutter/foundation.dart';

class TimerState extends ChangeNotifier {
  static final TimerState instance = TimerState._();

  TimerState._();

  bool _isRunning = false;
  String _subject = '';

  bool get isRunning => _isRunning;
  String get subject => _subject;

  void setRunning(bool running, {String subject = ''}) {
    _isRunning = running;
    _subject = subject;
    notifyListeners();
  }
}
