import 'package:flutter/material.dart';

import 'screens/main_navigation.dart';
import 'data/app_database.dart';
import 'utils/study_theme.dart';

class StudyCompanionApp extends StatelessWidget {
  const StudyCompanionApp({super.key, this.database, this.loadFromDatabase = true});
  final AppDatabase? database;
  final bool loadFromDatabase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '龙哥公考学习工作台',
      debugShowCheckedModeBanner: false,
      theme: StudyTheme.theme(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.noScaling),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: MainNavigation(database: database, loadFromDatabase: loadFromDatabase),
    );
  }
}
