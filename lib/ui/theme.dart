import 'package:flutter/material.dart';

/// Barevné téma aplikace (Material 3). Hlavní barvu stačí změnit tady.
class AppTheme {
  /// Teal z loga GymBar – hlavní barva.
  static const _seed = Color(0xFF2E7D6B);

  /// Žlutá z loga – doplňková barva (tertiary) pro rekordy, odznaky,
  /// výzvy a Premium.
  static const _accent = Color(0xFFFFC857);

  /// Písmo z loga – jen pro nadpisy, ostatní text zůstává systémový.
  static const brandFont = 'Archivo';

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
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(seedColor: _seed, brightness: brightness)
            .copyWith(
      // Ve světlém režimu tmavě zlatá (text a ikony čitelné na bílé)
      // a světle žlutý podklad; v tmavém přímo žlutá z loga.
      tertiary: dark ? _accent : const Color(0xFF7B5800),
      onTertiary: dark ? const Color(0xFF3F2E00) : Colors.white,
      tertiaryContainer:
          dark ? const Color(0xFF5C4300) : const Color(0xFFFFE6B0),
      onTertiaryContainer:
          dark ? const Color(0xFFFFDFA0) : const Color(0xFF3F2E00),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme).textTheme;
    final background = dark ? scheme.surface : scheme.surfaceContainer;
    TextStyle? brand(TextStyle? style, FontWeight weight) =>
        style?.copyWith(fontFamily: brandFont, fontWeight: weight);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Nadpisy písmem z loga; běžný text, popisky a tlačítka systémovým.
      textTheme: base.copyWith(
        displayLarge: brand(base.displayLarge, FontWeight.w800),
        displayMedium: brand(base.displayMedium, FontWeight.w800),
        displaySmall: brand(base.displaySmall, FontWeight.w800),
        headlineLarge: brand(base.headlineLarge, FontWeight.w800),
        headlineMedium: brand(base.headlineMedium, FontWeight.w800),
        headlineSmall: brand(base.headlineSmall, FontWeight.w700),
        titleLarge: brand(base.titleLarge, FontWeight.w700),
      ),
      // Sekce (karty) jsou od pozadí zřetelně oddělené: světlý režim má
      // lehce tónované pozadí a bílé karty, tmavý režim tmavé pozadí
      // a o stupeň světlejší karty. Navíc jemný okraj a větší mezery.
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: dark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: dark ? 0.5 : 0.8),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            dark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
