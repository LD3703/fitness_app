import 'package:flutter/material.dart';

/// Barevné téma aplikace (Material 3). Hlavní barvu stačí změnit tady.
class AppTheme {
  static const _seed = Color(0xFF2E7D6B);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  /// Nastavení vzhledu z profilu (UserProfile.themeMode): 0 = podle
  /// systému, 1 = světlý, 2 = tmavý.
  static ThemeMode themeModeOf(int? setting) => switch (setting) {
        1 => ThemeMode.light,
        2 => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static ThemeData _build(Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    final dark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // V tmavém režimu jsou karty o stupeň světlejší než pozadí, aby byly
      // vidět i bez stínu.
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: dark ? scheme.surfaceContainer : scheme.surfaceContainerLow,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
