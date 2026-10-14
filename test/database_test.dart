import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitness_app/data/database.dart';
import 'package:fitness_app/modules/coach/coach_queries.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

/// Sloupce všech tabulek: tabulka → seřazené „název typ notnull default pk“.
Future<Map<String, List<String>>> _schema(AppDatabase db) async {
  final tables = await db
      .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name")
      .map((r) => r.read<String>('name'))
      .get();
  return {
    for (final t in tables)
      t: (await db
          .customSelect('PRAGMA table_info("$t")')
          .map((r) => '${r.read<String>('name')} ${r.read<String>('type')} '
              '${r.read<int>('notnull')} ${r.readNullable<String>('dflt_value')} '
              '${r.read<int>('pk')}')
          .get())
        ..sort(),
  };
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('migrace', () {
    late Directory dir;
    late AppDatabase db;

    // test/fixtures/schema_v11.sqlite vytvořil starý kód (commit ba8a32d,
    // schéma 11): vlastní cvik „Můj tlak“, plán „Push“ (bench press + můj
    // tlak, 3 × 8 × 60 kg) a trénink 1. 9. 2026 18–19 h (bench 3 × 8 × 60).
    setUp(() {
      dir = Directory.systemTemp.createTempSync('gymbar_db');
      final file = File('${dir.path}/db.sqlite');
      File('test/fixtures/schema_v11.sqlite').copySync(file.path);
      db = AppDatabase(NativeDatabase(file));
    });

    tearDown(() async {
      await db.close();
      dir.deleteSync(recursive: true);
    });

    test('v11 → v17 zachová plány, série i tréninky', () async {
      final version = await db
          .customSelect('PRAGMA user_version')
          .map((r) => r.read<int>('user_version'))
          .getSingle();
      expect(version, db.schemaVersion);

      final plan = await (db.select(db.workoutPlans)
            ..where((p) => p.name.equals('Push')))
          .getSingle();
      expect(plan.weekdaysMask, 5);
      expect(plan.remoteId, isNull);
      expect(plan.remoteVersion, isNull);
      expect(plan.remoteFrom, isNull);

      final items = await db.getPlanItems(plan.id);
      expect(items.map((i) => i.exercise.slug), ['bench_press', null]);
      expect(items[1].exercise.nameCs, 'Můj tlak');
      expect(items[1].exercise.note, isNull);
      for (final i in items) {
        expect(i.item.note, isNull);
        expect(i.sets.map((s) => (s.reps, s.weightKg)),
            List.filled(3, (8, 60.0)));
      }

      final workouts = await db.coachWorkoutsSince(DateTime(2026));
      expect(workouts, hasLength(1));
      expect(workouts.single.title, 'Push');
      expect(workouts.single.durationMin, 60);
      expect(workouts.single.exercises.single.slug, 'bench_press');
      expect(workouts.single.exercises.single.sets, hasLength(3));
    });

    test('po migraci jdou zapsat poznámky a plán od trenéra', () async {
      final plan = await (db.select(db.workoutPlans)
            ..where((p) => p.name.equals('Push')))
          .getSingle();
      final items = await db.getPlanItems(plan.id);
      await (db.update(db.planExercises)
            ..where((pe) => pe.id.equals(items.first.item.id)))
          .write(const PlanExercisesCompanion(note: Value('Lokty u těla')));
      await (db.update(db.exercises)
            ..where((e) => e.id.equals(items.first.exercise.id)))
          .write(const ExercisesCompanion(note: Value('Lavice č. 3')));

      final shared = await db.coachPlanFromLocal(plan.id);
      expect(shared!.exercises.first.note, 'Lokty u těla');

      final id = await db.importCoachPlan(shared,
          remoteId: 'coach:abc', version: 1, from: 'Trenér');
      expect((await db.planByRemoteId('coach:abc'))!.id, id);
      expect(
          (await db.getPlanItems(id)).first.exercise.note, 'Lavice č. 3');
    });

    test('schéma po migraci je stejné jako u nové instalace', () async {
      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      expect(await _schema(db), await _schema(fresh));
    });
  });

  group('plán od trenéra', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    CoachPlan plan({int reps = 10, String? note}) => CoachPlan(
          name: 'Nohy',
          weekdaysMask: 1,
          exercises: [
            CoachPlanExercise(
              slug: 'back_squat',
              nameEn: 'Back squat',
              nameCs: 'Dřep',
              restSeconds: 120,
              restAuto: false,
              note: note,
              sets: [
                const CoachPlanSet(reps: 5, kg: 40, warmup: true),
                CoachPlanSet(reps: reps, kg: 80),
              ],
            ),
            const CoachPlanExercise(
              nameEn: 'Sled push',
              nameCs: 'Tlačení saní',
              muscle: 'quads',
              equipment: 'machine',
              type: 'weightReps',
            ),
          ],
        );

    test('nový plán: cviky, série, vlastní cvik a výchozí 3 × 10', () async {
      final id = await db.importCoachPlan(plan(note: 'Hluboko'),
          remoteId: 'coach:p1', version: 1, from: 'Trenér Tom');
      final p = (await db.planByRemoteId('coach:p1'))!;
      expect(p.id, id);
      expect((p.remoteVersion, p.remoteFrom), (1, 'Trenér Tom'));
      expect(await db.coachAssignedLocalPlans(), hasLength(1));

      final items = await db.getPlanItems(id);
      expect(items, hasLength(2));
      expect(items[0].exercise.slug, 'back_squat');
      expect(items[0].item.note, 'Hluboko');
      expect(items[0].item.restSeconds, 120);
      expect(items[0].item.restAuto, isFalse);
      expect(items[0].sets.map((s) => (s.reps, s.weightKg, s.isWarmup)),
          [(5, 40.0, true), (10, 80.0, false)]);
      expect(items[1].exercise.isCustom, isTrue);
      expect(items[1].item.restAuto, isTrue);
      expect(items[1].sets.map((s) => s.reps), [10, 10, 10]);
    });

    test('nová verze přepíše plán, vlastní cvik se nezdvojí', () async {
      final id = await db.importCoachPlan(plan(),
          remoteId: 'coach:p1', version: 1, from: 'Tom');
      final again = await db.importCoachPlan(plan(reps: 6),
          remoteId: 'coach:p1', version: 2, from: 'Tom');
      expect(again, id);
      expect((await db.planByRemoteId('coach:p1'))!.remoteVersion, 2);

      final items = await db.getPlanItems(id);
      expect(items, hasLength(2));
      expect(items[0].sets.last.reps, 6);
      final customs = await (db.select(db.exercises)
            ..where((e) => e.nameCs.equals('Tlačení saní')))
          .get();
      expect(customs, hasLength(1));
    });

    test('dlouhá poznámka se ořízne', () async {
      final id = await db.importCoachPlan(plan(note: 'x' * 500),
          remoteId: 'shared:p2', version: 1, from: 'Odkaz');
      final note = (await db.getPlanItems(id)).first.item.note!;
      expect(note.length, exerciseNoteMax);
      expect(await db.coachAssignedLocalPlans(), isEmpty);
    });

    test('export a import plánu dá stejný plán', () async {
      final id = await db.importCoachPlan(plan(note: 'Pomalu dolů'),
          remoteId: 'coach:p1', version: 1, from: 'Tom');
      final exported = (await db.coachPlanFromLocal(id))!;
      final copy = await db.importCoachPlan(exported,
          remoteId: 'shared:copy', version: 1, from: 'Já');
      final back = (await db.coachPlanFromLocal(copy))!;
      expect(back.toJson(), exported.toJson());
    });
  });
}
