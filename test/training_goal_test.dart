import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitness_app/core/auto_progression.dart';
import 'package:fitness_app/data/database.dart';
import 'package:fitness_app/data/seed/plan_templates.dart';
import 'package:fitness_app/data/seed/seed_data.dart';
import 'package:flutter_test/flutter_test.dart';

TemplateProgram _program(String slug) =>
    templatePrograms.firstWhere((p) => p.slug == slug);

List<int> _working(List<TemplateSet> sets) => [
      for (final s in sets)
        if (!s.isWarmup) s.reps
    ];

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('hotové programy', () {
    final bySlug = {for (final e in seedExercises) e.slug: e};

    test('7 programů s unikátními slugy a názvy plánů', () {
      expect(templatePrograms, hasLength(7));
      expect({for (final p in templatePrograms) p.slug}, hasLength(7));
      final names = [
        for (final p in templatePrograms)
          for (final plan in p.plans) plan.nameEn,
      ];
      expect(names.toSet(), hasLength(names.length));
    });

    test('cviky existují a role odpovídá typu cviku', () {
      for (final program in templatePrograms) {
        for (final plan in program.plans) {
          for (final item in plan.items) {
            final e = bySlug[item.slug];
            expect(e, isNotNull, reason: '${plan.nameEn}: ${item.slug}');
            final weighted = e!.type == ExerciseType.weightReps;
            expect(item.role == TemplateRole.bodyweight, !weighted,
                reason: '${plan.nameEn}: ${item.slug} (${e.type})');
            if (program.goal != null && weighted) {
              expect(item.range, isNotNull,
                  reason: 'pevný cíl ${program.slug}: ${item.slug}');
              expect(item.range!.min, item.reps);
            }
          }
        }
      }
    });

    test('svaly = hodnoty z programu, bez rozsahu', () {
      final item = _program('full_body').plans.first.items.first; // dřep
      final sets = templateSetsFor(item, TrainingFocus.muscle);
      expect(sets.first.isWarmup, isTrue);
      expect(_working(sets), [8, 8, 8]);
      expect(templateRangeFor(item, TrainingFocus.muscle), isNull);
    });

    test('síla: hlavní cvik 4 × 5 (5–6), mrtvý tah 3 × 5', () {
      final squat = _program('full_body').plans.first.items.first;
      expect(_working(templateSetsFor(squat, TrainingFocus.strength)),
          [5, 5, 5, 5]);
      expect(templateRangeFor(squat, TrainingFocus.strength), (min: 5, max: 6));
      final deadlift = _program('full_body').plans[1].items.first;
      expect(_working(templateSetsFor(deadlift, TrainingFocus.strength)),
          [5, 5, 5]);
    });

    test('výdrž: hodně opakování, delší výdrže, mrtvý tah méně', () {
      final a = _program('full_body').plans.first.items;
      expect(_working(templateSetsFor(a.first, TrainingFocus.conditioning)),
          [12, 12, 12]);
      expect(templateRangeFor(a.first, TrainingFocus.conditioning),
          (min: 12, max: 16));
      final plank = a.last;
      expect(
          _working(templateSetsFor(plank, TrainingFocus.conditioning,
              isDuration: true)),
          [45, 45, 45]);
      final deadlift = _program('full_body').plans[1].items.first;
      expect(templateRangeFor(deadlift, TrainingFocus.conditioning),
          (min: 10, max: 12));
    });

    test('pevný cíl programu přebije zvolený cíl', () {
      final p = _program('strength_5x5');
      expect(
          programGoal(p, TrainingFocus.conditioning), TrainingFocus.strength);
      final squat = p.plans.first.items.first;
      expect(
          _working(templateSetsFor(squat, TrainingFocus.strength, program: p)),
          [5, 5, 5, 5, 5]);
      expect(templateRangeFor(squat, TrainingFocus.strength, program: p),
          (min: 5, max: 5));
    });
  });

  group('přidání programu a zaměření', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('program na sílu: zaměření plánu, série a rozsah', () async {
      await db.addProgram(_program('full_body'),
          languageCode: 'cs', goal: TrainingFocus.strength);
      final plans = await db.select(db.workoutPlans).get();
      expect(plans.map((p) => p.name), ['Celé tělo A', 'Celé tělo B']);
      expect(plans.map((p) => p.focus), everyElement(TrainingFocus.strength));
      final items = await db.getPlanItems(plans.first.id);
      final squat = items.first;
      expect(squat.exercise.slug, 'back_squat');
      expect([
        for (final s in squat.sets)
          if (!s.isWarmup) s.reps
      ], [
        5,
        5,
        5,
        5
      ]);
      expect((squat.item.repRangeMin, squat.item.repRangeMax), (5, 6));
      expect(
          await db.focusForNewSession(plans.first.id), TrainingFocus.strength);
    });

    test('kruhový trénink: výdrž a supersérie', () async {
      await db.addProgram(_program('circuit'),
          languageCode: 'en', goal: TrainingFocus.strength);
      final plan = (await db.select(db.workoutPlans).get()).first;
      expect(plan.focus, TrainingFocus.conditioning);
      final items = await db.getPlanItems(plan.id);
      expect([for (final i in items) i.item.supersetGroup],
          [1, 1, 1, 2, 2, 2, null]);
    });

    test('bez zaměření plánu platí cíl z profilu', () async {
      final id = await db.createPlan('Můj plán');
      expect(await db.focusForNewSession(id), TrainingFocus.muscle);
      await db.setTrainingGoal(TrainingFocus.conditioning);
      expect(await db.focusForNewSession(id), TrainingFocus.conditioning);
      expect(await db.focusForNewSession(null), TrainingFocus.conditioning);
      await db.setPlanFocus(id, TrainingFocus.strength);
      expect(await db.focusForNewSession(id), TrainingFocus.strength);
    });

    test('změna zaměření tréninku nemění cíl v profilu', () async {
      final session = await db.startSession(focus: TrainingFocus.muscle);
      await db.setSessionFocus(session, TrainingFocus.strength);
      expect((await db.getSession(session)).focus, TrainingFocus.strength);
      expect(await db.focusForNewSession(null), TrainingFocus.muscle);
    });
  });

  group('progrese podle zaměření', () {
    TargetSet t(int reps, double kg) =>
        (reps: reps, weightKg: kg, isWarmup: false, isDrop: false);
    PerformedSet p(int reps, double kg) => (
          weightKg: kg,
          reps: reps,
          durationSeconds: null,
          isWarmup: false,
          isDrop: false,
        );
    ProgressionProposal? propose(
      List<TargetSet> targets,
      List<PerformedSet> performed,
      TrainingFocus focus, {
      int? min,
      int? max,
    }) =>
        proposeProgression(
          ProgressionInput(
            type: ExerciseType.weightReps,
            group: MuscleGroup.chest,
            equipment: Equipment.barbell,
            slug: 'bench_press',
            targets: targets,
            repRangeMin: min,
            repRangeMax: max,
            performed: performed,
            focus: focus,
          ),
          unit: UnitSystem.metric,
        );

    test('výchozí rozsah podle zaměření', () {
      expect(
          defaultRepRange(5, focus: TrainingFocus.strength), (min: 5, max: 6));
      expect(
          defaultRepRange(8, focus: TrainingFocus.strength), (min: 8, max: 10));
      expect(defaultRepRange(8), (min: 8, max: 10));
      expect(defaultRepRange(12), (min: 12, max: 16));
      expect(defaultRepRange(15, focus: TrainingFocus.conditioning),
          (min: 15, max: 20));
    });

    test('síla: 5 → 6 opakování a pak hned váha', () {
      final up = propose(
          [t(5, 80), t(5, 80)], [p(5, 80), p(5, 80)], TrainingFocus.strength)!;
      expect(up.kind, ProgressionKind.reps);
      expect(up.after.sets.map((s) => s.reps), [6, 6]);
      // Rozsah se při první změně uloží do plánu.
      expect((up.after.repRangeMin, up.after.repRangeMax), (5, 6));
      final next = propose(
          [t(6, 80), t(6, 80)], [p(6, 80), p(6, 80)], TrainingFocus.strength,
          min: 5, max: 6)!;
      expect(next.kind, ProgressionKind.increase);
      expect(next.after.sets.map((s) => s.weightKg), [82.5, 82.5]);
      expect(next.after.sets.map((s) => s.reps), [5, 5]);
    });

    test('svaly: stejný trénink jen +1 opakování', () {
      final up = propose(
          [t(5, 80), t(5, 80)], [p(5, 80), p(5, 80)], TrainingFocus.muscle)!;
      expect(up.kind, ProgressionKind.reps);
      expect(up.after.sets.map((s) => s.reps), [6, 6]);
      expect((up.after.repRangeMin, up.after.repRangeMax), (5, 7));
    });

    test('výdrž: opakování po 2 do horní hranice, pak váha', () {
      final up = propose([t(15, 20), t(15, 20)], [p(15, 20), p(15, 20)],
          TrainingFocus.conditioning)!;
      expect(up.kind, ProgressionKind.reps);
      expect(up.info.delta, 2);
      expect(up.after.sets.map((s) => s.reps), [17, 17]);
      expect((up.after.repRangeMin, up.after.repRangeMax), (15, 20));
      final capped = proposeProgression(
        ProgressionInput(
          type: ExerciseType.weightReps,
          group: MuscleGroup.chest,
          equipment: Equipment.barbell,
          targets: [t(19, 20)],
          repRangeMin: 15,
          repRangeMax: 20,
          performed: [p(19, 20)],
          focus: TrainingFocus.conditioning,
        ),
        unit: UnitSystem.metric,
      )!;
      expect(capped.after.sets.single.reps, 20);
      expect(capped.info.delta, 1);
    });

    test('výdrž: vlastní váha +2 opakování, čas +10 s', () {
      final bw = proposeProgression(
        const ProgressionInput(
          type: ExerciseType.bodyweightReps,
          group: MuscleGroup.chest,
          equipment: Equipment.bodyweight,
          targets: [(reps: 12, weightKg: null, isWarmup: false, isDrop: false)],
          performed: [
            (
              weightKg: null,
              reps: 12,
              durationSeconds: null,
              isWarmup: false,
              isDrop: false,
            ),
          ],
          focus: TrainingFocus.conditioning,
        ),
        unit: UnitSystem.metric,
      )!;
      expect(bw.after.sets.single.reps, 14);
      final plank = proposeProgression(
        const ProgressionInput(
          type: ExerciseType.duration,
          group: MuscleGroup.core,
          equipment: Equipment.bodyweight,
          targets: [(reps: 45, weightKg: null, isWarmup: false, isDrop: false)],
          performed: [
            (
              weightKg: null,
              reps: null,
              durationSeconds: 45,
              isWarmup: false,
              isDrop: false,
            ),
          ],
          focus: TrainingFocus.conditioning,
        ),
        unit: UnitSystem.metric,
      )!;
      expect(plank.after.sets.single.reps, 55);
    });
  });
}
