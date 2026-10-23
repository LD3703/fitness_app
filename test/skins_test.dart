// Motivy vzhledu (lib/ui/skins.dart): klíče, témata a čitelnost barev.
import 'package:fitness_app/features/profile/skin_picker.dart';
import 'package:fitness_app/l10n/app_localizations.dart';
import 'package:fitness_app/ui/skins.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kontrastní poměr podle WCAG.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('klíč motivu: neznámý nebo prázdný = Klasik', () {
    expect(AppSkin.fromKey(null), AppSkin.classic);
    expect(AppSkin.fromKey('nesmysl'), AppSkin.classic);
    for (final s in AppSkin.values) {
      expect(AppSkin.fromKey(s.key), s);
    }
  });

  test('každý motiv má téma s písmy a barvami ze šablony', () {
    for (final skin in AppSkin.values) {
      final theme = skinTheme(skin);
      final spec = skinSpec(skin);
      if (spec == null) continue;
      expect(theme.colorScheme.primary, spec.primary, reason: skin.key);
      expect(theme.scaffoldBackgroundColor, spec.background, reason: skin.key);
      expect(theme.textTheme.bodyMedium?.fontFamily, spec.bodyFont, reason: skin.key);
      expect(theme.textTheme.titleLarge?.fontFamily, spec.displayFont, reason: skin.key);
      expect(theme.brightness, spec.brightness, reason: skin.key);
    }
    expect(skinTheme(AppSkin.original, brightness: Brightness.dark).brightness,
        Brightness.dark);
  });

  test('text je čitelný (aspoň 4,5 : 1)', () {
    for (final skin in AppSkin.values) {
      final s = skinSpec(skin);
      if (s == null) continue;
      expect(contrast(s.text, s.background), greaterThanOrEqualTo(4.5), reason: '${skin.key} text/pozadí');
      expect(contrast(s.text, s.card), greaterThanOrEqualTo(4.5), reason: '${skin.key} text/karta');
      expect(contrast(s.muted, s.card), greaterThanOrEqualTo(4.5), reason: '${skin.key} popisky/karta');
      expect(contrast(s.onPrimary, s.primary), greaterThanOrEqualTo(4.5), reason: '${skin.key} tlačítko');
      expect(contrast(s.onHeader, s.header), greaterThanOrEqualTo(4.5), reason: '${skin.key} záhlaví');
      expect(contrast(s.tertiary, s.card), greaterThanOrEqualTo(3), reason: '${skin.key} rekordy');
    }
  });

  testWidgets('výběr motivu vrátí zvolený motiv', (tester) async {
    AppSkin? picked;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('cs'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => picked = await showSkinPicker(context, AppSkin.classic),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(SkinPreviewTile), findsWidgets);
    final skulls = find.byWidgetPredicate(
        (w) => w is SkinPreviewTile && w.skin == AppSkin.skulls);
    await tester.ensureVisible(skulls);
    await tester.pumpAndSettle();
    await tester.tap(skulls);
    await tester.pumpAndSettle();
    expect(picked, AppSkin.skulls);
  });
}
