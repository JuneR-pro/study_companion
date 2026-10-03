import 'package:flutter/material.dart';

import 'screens/main_navigation.dart';

class StudyCompanionApp extends StatelessWidget {
  const StudyCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Companion',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const MainNavigation(),
    );
  }
}

void main() {
  runApp(const StudyCompanionApp());
}
