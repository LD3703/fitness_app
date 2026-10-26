// Úvodní průvodce (lib/features/onboarding/onboarding_screen.dart): projde
// všechny kroky a ověří, co se uložilo do databáze.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitness_app/data/database.dart';
import 'package:fitness_app/features/onboarding/onboarding_screen.dart';
import 'package:fitness_app/l10n/app_localizations.dart';
import 'package:fitness_app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(AppDatabase db) => ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(
        locale: Locale('cs'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingScreen(),
      ),
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;

  setUp(() => db = AppDatabase(DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      )));
  tearDown(() => db.close());

  Future<void> next(WidgetTester tester, [String label = 'Další']) async {
    await tester.tap(find.widgetWithText(FilledButton, label));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('průvodce krok za krokem uloží profil a první plán',
      (tester) async {
    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    // Vítej
    expect(find.text('Vítej!'), findsOneWidget);
    await next(tester, 'Začít');

    // O tobě
    expect(find.text('Krok 1 z 11'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Jméno'), 'Alex');
    await tester.enterText(
        find.widgetWithText(TextField, 'Rok narození (nepovinné)'), '1800');
    await next(tester);
    expect(find.textContaining('1920'), findsOneWidget); // neplatný rok
    await tester.enterText(
        find.widgetWithText(TextField, 'Rok narození (nepovinné)'), '1999');
    await tapText(tester, 'Žena');
    await next(tester);

    // Cíl
    expect(find.text('Na co trénuješ?'), findsOneWidget);
    await tapText(tester, 'Výdrž');
    await next(tester);

    // Úroveň
    expect(find.text('Jak dlouho cvičíš?'), findsOneWidget);
    await tapText(tester, 'Mírně pokročilý');
    await next(tester);

    // Jak často a jak dlouho
    expect(find.text('Jak často a jak dlouho?'), findsOneWidget);
    await tapText(tester, '4×');
    await tapText(tester, '45 min');
    await next(tester);

    // Co sledovat → voda a váha
    await next(tester);
    expect(find.text('Pitný režim a váha'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '70');
    await next(tester);

    // Vzhled, tón zpráv, připomínky
    expect(find.text('Vyber si vzhled'), findsOneWidget);
    await next(tester);
    await next(tester);
    expect(find.text('Ranní připomínka tréninku'), findsOneWidget);
    await next(tester);

    // První plán
    expect(find.text('Tvůj první plán'), findsOneWidget);
    // Jen programy pro zvolenou úroveň.
    expect(find.text('Celé tělo (začátečník)'), findsNothing);
    // Nejlépe sedí program na 4 dny týdně.
    expect(find.text('Sedí ti nejlépe'), findsOneWidget);
    await tapText(tester, 'Horní / dolní polovina');
    expect(find.textContaining('Varianta: Výdrž'), findsWidgets);
    expect(find.textContaining('4× týdně · ~'), findsWidgets);
    await next(tester);

    // Hotovo
    expect(find.text('Hotovo!'), findsOneWidget);
    await next(tester, 'Jdeme na to');

    final (profile, plans, weights) = (await tester.runAsync(() async => (
          await db.select(db.userProfiles).getSingle(),
          await db.select(db.workoutPlans).get(),
          await db.select(db.bodyWeightEntries).get(),
        )))!;
    expect(profile.onboardingDone, isTrue);
    expect(profile.name, 'Alex');
    expect(profile.birthYear, 1999);
    expect(profile.sex, Sex.female.index);
    expect(profile.trainingFocus, TrainingFocus.conditioning.index);
    expect(profile.experienceLevel, ExperienceLevel.intermediate.index);
    expect(profile.experienceSince, isNotNull);
    expect(profile.trainingDaysPerWeek, 4);
    expect(profile.sessionMinutes, 45);
    expect(plans.map((p) => p.name), ['Horní polovina', 'Dolní polovina']);
    expect(plans.map((p) => p.focus), everyElement(TrainingFocus.conditioning));
    expect(weights.single.weightKg, 70);
  });

  testWidgets('bez vody a váhy se krok přeskočí, Zpět vrací', (tester) async {
    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();
    await next(tester, 'Začít');
    await next(tester); // o tobě
    await next(tester); // cíl
    await next(tester); // úroveň
    await next(tester); // jak často
    expect(find.text('Krok 5 z 11'), findsOneWidget);
    await tapText(tester, 'Pitný režim');
    await tapText(tester, 'Tělesná váha');
    expect(find.text('Krok 5 z 10'), findsOneWidget);
    await next(tester);
    expect(find.text('Vyber si vzhled'), findsOneWidget);
    await tester.tap(find.text('Zpět'));
    await tester.pumpAndSettle();
    expect(find.text('Krok 5 z 10'), findsOneWidget);
  });
}
