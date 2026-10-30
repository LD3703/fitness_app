// Výběr cviku podle partie: pruh s postavičkami a seznam v sekcích
// (lib/ui/muscle_group_strip.dart).
import 'package:drift/native.dart';
import 'package:fitness_app/data/database.dart';
import 'package:fitness_app/l10n/app_localizations.dart';
import 'package:fitness_app/ui/muscle_group_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('cs'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('klepnutí vybere partii, druhé klepnutí filtr zruší',
      (tester) async {
    MuscleGroup? picked = MuscleGroup.back;
    await tester.pumpWidget(_app(StatefulBuilder(
      builder: (context, setState) => MuscleGroupStrip(
        selected: picked,
        onSelected: (g) => setState(() => picked = g),
      ),
    )));
    await tester.tap(find.text('Hrudník'));
    await tester.pump();
    expect(picked, MuscleGroup.chest);
    await tester.tap(find.text('Hrudník'));
    await tester.pump();
    expect(picked, isNull);
    await tester.tap(find.text('Záda'));
    await tester.pump();
    await tester.tap(find.text('Vše'));
    await tester.pump();
    expect(picked, isNull);
  });

  test('nohy zvýrazní i stehna, hamstringy a lýtka', () {
    final legs = muscleGroupHighlight(MuscleGroup.legs).primary;
    expect(legs, containsAll(legMuscleGroups));
    expect(muscleGroupHighlight(MuscleGroup.chest).primary,
        {MuscleGroup.chest});
  });

  testWidgets('seznam v sekcích podle partie, s filtrem bez nadpisů',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final all = (await tester.runAsync(() => db.select(db.exercises).get()))!;
    late List<ExerciseListEntry> withHeaders;
    late List<ExerciseListEntry> plain;
    await tester.pumpWidget(_app(Builder(builder: (context) {
      withHeaders = exerciseListEntries(context, all, withHeaders: true);
      plain = exerciseListEntries(context, all, withHeaders: false);
      return const SizedBox();
    })));
    final headers = [
      for (final e in withHeaders)
        if (e.header != null) e.header!,
    ];
    // Každá partie jednou a v pořadí jako v pruhu.
    expect(headers.toSet(), hasLength(headers.length));
    final order = [for (final g in headers) muscleGroupsUiOrder.indexOf(g)];
    expect(order, [...order]..sort());
    expect(withHeaders.first.header, MuscleGroup.chest);
    // Každý cvik je pod nadpisem své partie.
    MuscleGroup? current;
    for (final e in withHeaders) {
      if (e.header != null) {
        current = e.header;
      } else {
        expect(e.exercise!.muscleGroup, current);
      }
    }
    expect(plain.every((e) => e.header == null), isTrue);
    expect(plain, hasLength(all.length));
  });
}
