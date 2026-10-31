// Kalendář tréninků: jednorázové naplánování do dne
// (AppDatabase.addPlanToDay, plannedWorkouts, PlanCalendarScreen).
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitness_app/data/database.dart';
import 'package:fitness_app/features/plans/plan_calendar_screen.dart';
import 'package:fitness_app/l10n/app_localizations.dart';
import 'package:fitness_app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;

  setUp(() => db = AppDatabase(DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      )));
  tearDown(() => db.close());

  group('databáze', () {
    test('trénink přidaný do dne mimo pravidelné dny, s časem', () async {
      final planId = await db.createPlan('Nohy');
      await db.setPlanWeekdays(planId, 1); // jen pondělí
      final wed = DateTime(2026, 11, 4); // středa
      var planned = await db.plannedWorkouts(wed, 1);
      expect(planned, isEmpty);

      final id = await db.addPlanToDay(planId, wed, minutes: 18 * 60 + 30);
      planned = await db.plannedWorkouts(wed, 1);
      expect(planned.single.plan.id, planId);
      expect(planned.single.minutes, 18 * 60 + 30);
      expect(planned.single.scheduleId, id);

      await db.removeScheduled(id);
      expect(await db.plannedWorkouts(wed, 1), isEmpty);
    });

    test('bez času platí čas plánu, pravidelný den nemá scheduleId',
        () async {
      final planId = await db.createPlan('Záda');
      await db.setPlanWeekdays(planId, 1);
      await db.setPlanTime(planId, 7 * 60);
      final mon = DateTime(2026, 11, 2);
      final thu = DateTime(2026, 11, 5);
      await db.addPlanToDay(planId, thu);
      final planned = await db.plannedWorkouts(mon, 7);
      expect(planned.map((w) => w.day), [mon, thu]);
      expect(planned.map((w) => w.minutes), [7 * 60, 7 * 60]);
      expect(planned.first.scheduleId, isNull);
      expect(planned.last.scheduleId, isNotNull);
    });

    test('vynechaný pravidelný den v kalendáři chybí', () async {
      final planId = await db.createPlan('Push');
      await db.setPlanWeekdays(planId, 1);
      final mon = DateTime(2026, 11, 2);
      await db.skipPlan(planId, mon);
      expect(await db.plannedWorkouts(mon, 1), isEmpty);
    });
  });

  testWidgets('kalendář: naplánování do dne a odebrání přejetím',
      (tester) async {
    await initializeDateFormatting('cs');
    final planId = (await tester.runAsync(() => db.createPlan('Nohy')))!;
    await tester.pumpWidget(ProviderScope(
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
        home: PlanCalendarScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Žádný trénink'), findsOneWidget);

    // Dnešek je vybraný – naplánovat přes tlačítko.
    await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 50))); // plány z databáze
    await tester.pumpAndSettle();
    await tester.tap(find.text('Naplánovat trénink'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Nohy'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    final today = DateTime.now();
    final planned = (await tester.runAsync(() => db.plannedWorkouts(today, 1)))!;
    expect(planned.single.plan.id, planId);
    expect(find.text('Z kalendáře'), findsOneWidget);

    // Přejetí doleva odebere, po vypršení snackbaru i z databáze.
    await tester.drag(find.text('Nohy'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Žádný trénink'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(await tester.runAsync(() => db.plannedWorkouts(today, 1)), isEmpty);
  });
}
