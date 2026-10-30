// Opakování posuvníkem (lib/ui/reps_field.dart).
import 'package:fitness_app/l10n/app_localizations.dart';
import 'package:fitness_app/ui/reps_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(TextEditingController c, {bool isDuration = false,
        VoidCallback? onChanged}) =>
    MaterialApp(
      locale: const Locale('cs'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 80,
            child: RepsField(
              controller: c,
              isDuration: isDuration,
              onChanged: onChanged ?? () {},
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('klepnutí otevře posuvník, volba nastaví a zavře',
      (tester) async {
    final c = TextEditingController(text: '8');
    var changes = 0;
    await tester.pumpWidget(_app(c, onChanged: () => changes++));
    await tester.tap(find.byType(RepsField));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse); // bez klávesnice

    await tester.tap(find.widgetWithText(ChoiceChip, '12'));
    await tester.pumpAndSettle();
    expect(c.text, '12');
    expect(changes, 1);
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('tlačítka −/+ mění hodnotu, panel zůstane', (tester) async {
    final c = TextEditingController(text: '10');
    await tester.pumpWidget(_app(c));
    await tester.tap(find.byType(RepsField));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pumpAndSettle();
    expect(c.text, '11');
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('posuvník: přetažení změní hodnotu a puštění zavře panel',
      (tester) async {
    final c = TextEditingController(text: '5');
    await tester.pumpWidget(_app(c));
    await tester.tap(find.byType(RepsField));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(int.parse(c.text), greaterThan(5));
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('sekundy po 5, Zadat číslem vrátí klávesnici', (tester) async {
    final c = TextEditingController(text: '30');
    await tester.pumpWidget(_app(c, isDuration: true));
    await tester.tap(find.byType(RepsField));
    await tester.pumpAndSettle();
    expect(find.text('30 s'), findsWidgets);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(c.text, '35');

    await tester.tap(find.text('Zadat číslem'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNothing);
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(find.byType(RepsField), '42');
    expect(c.text, '42');
  });
}
