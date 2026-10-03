import 'package:flutter/material.dart';

/// Barevné téma aplikace (Material 3). Hlavní barvu stačí změnit tady.
class AppTheme {
  static const _seed = Color(0xFF2E7D6B);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      cardTheme: const CardThemeData(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
