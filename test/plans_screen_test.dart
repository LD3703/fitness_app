// Seznam plánů: smazání přejetím s „Vrátit“ a rychlé akce po podržení
// (lib/features/plans/plans_screen.dart).
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitness_app/data/database.dart';
import 'package:fitness_app/features/plans/plans_screen.dart';
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
        home: PlansScreen(),
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

  Future<List<WorkoutPlan>> plans(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.workoutPlans).get()))!;

  testWidgets('přejetí smaže plán, Vrátit ho vrátí', (tester) async {
    await tester.runAsync(() => db.createPlan('Nohy'));
    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();
    expect(find.text('Nohy'), findsOneWidget);

    await tester.drag(find.text('Nohy'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Nohy'), findsNothing);
    await tester.tap(find.text('Vrátit'));
    await tester.pumpAndSettle();
    expect(find.text('Nohy'), findsOneWidget);
    expect(await plans(tester), hasLength(1));

    await tester.drag(find.text('Nohy'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(await plans(tester), isEmpty);
  });

  testWidgets('podržení ukáže rychlé akce a přejmenuje plán', (tester) async {
    await tester.runAsync(() => db.createPlan('Záda'));
    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Záda'));
    await tester.pumpAndSettle();
    expect(find.text('Začít'), findsWidgets);
    expect(find.text('Upravit plán'), findsOneWidget);
    expect(find.text('Smazat'), findsOneWidget);

    await tester.tap(find.text('Přejmenovat plán'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Záda a biceps');
    await tester.tap(find.text('Uložit'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect((await plans(tester)).single.name, 'Záda a biceps');
  });
}
