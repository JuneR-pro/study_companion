import 'package:flutter/material.dart';

enum StudySubject {
  language('言语理解', Color(0xFFC7B38F)),
  logic('逻辑判断', Color(0xFFA6B9C5)),
  data('资料分析', Color(0xFFA9BFAF)),
  quantity('数量关系', Color(0xFFB2A5BD)),
  politics('政治理论', Color(0xFFC7B0B0)),
  common('常识', Color(0xFFC1C1C1)),
  essay('申论', Color(0xFFD4B8BD));

  const StudySubject(this.label, this.color);

  final String label;
  final Color color;

  static StudySubject fromLabel(String label) {
    return values.firstWhere(
      (subject) => subject.label == label,
      orElse: () => StudySubject.common,
    );
  }
}

class StudyTheme {
  const StudyTheme._();

  static const background = Color(0xFFF5F2ED);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF4B4947);
  static const muted = Color(0xFF8F8B87);
  static const line = Color(0xFFE7E1DA);
  static const accent = Color(0xFF9A8769);

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: accent,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: ink,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'sans',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
    );
  }
}
