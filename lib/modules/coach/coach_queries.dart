import 'package:drift/drift.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

import '../../data/database.dart';
import '../../data/enums.dart';

/// Dotazy do lokální databáze pro trenéra a klienta (docs/coach.md):
/// převod plánu z/do tvaru [CoachPlan] a tréninky pro trenéra.
extension CoachQueries on AppDatabase {
  // -------------------------------------------------------------------
  // Plány
  // -------------------------------------------------------------------

  /// Plán z telefonu ve tvaru pro sdílení.
  Future<CoachPlan?> coachPlanFromLocal(int planId) async {
    final plan = await (select(workoutPlans)..where((p) => p.id.equals(planId)))
        .getSingleOrNull();
    if (plan == null) return null;
    final items = await getPlanItems(planId);
    return CoachPlan(
      name: plan.name,
      description: plan.description,
      weekdaysMask: plan.weekdaysMask,
      exercises: [
        for (final i in items)
          CoachPlanExercise(
            slug: i.exercise.slug,
            nameEn: i.exercise.nameEn,
            nameCs: i.exercise.nameCs,
            // U vestavěných cviků stačí slug.
            muscle: i.exercise.slug == null ? i.exercise.muscleGroup.name : null,
            equipment:
                i.exercise.slug == null ? i.exercise.equipment.name : null,
            type: i.exercise.slug == null ? i.exercise.type.name : null,
            restSeconds: i.item.restAuto ? null : i.item.restSeconds,
            restAuto: i.item.restAuto,
            superset: i.item.supersetGroup,
            repMin: i.item.repRangeMin,
            repMax: i.item.repRangeMax,
            note: i.item.note,
            sets: [
              for (final s in i.sets)
                CoachPlanSet(
                  reps: s.reps,
                  kg: s.weightKg,
                  warmup: s.isWarmup,
                  drop: s.isDrop,
                ),
            ],
          ),
      ],
    );
  }

  Future<WorkoutPlan?> planByRemoteId(String remoteId) =>
      (select(workoutPlans)..where((p) => p.remoteId.equals(remoteId)))
          .getSingleOrNull();

  /// Plány od trenéra (remoteId „coach:…“).
  Future<List<WorkoutPlan>> coachAssignedLocalPlans() =>
      (select(workoutPlans)..where((p) => p.remoteId.like('coach:%'))).get();

  /// Uloží plán od trenéra / ze sdíleného odkazu. Když už plán se stejným
  /// [remoteId] v telefonu je, přepíše ho (cviky a série), jinak založí
  /// nový. Vrací ID plánu v telefonu.
  Future<int> importCoachPlan(
    CoachPlan plan, {
    required String remoteId,
    required int version,
    required String from,
  }) =>
      transaction(() async {
        final existing = await planByRemoteId(remoteId);
        final int planId;
        if (existing == null) {
          planId = await into(workoutPlans).insert(WorkoutPlansCompanion.insert(
            name: plan.name,
            description: Value(plan.description),
            weekdaysMask: Value(plan.weekdaysMask),
            remoteId: Value(remoteId),
            remoteVersion: Value(version),
            remoteFrom: Value(from),
          ));
        } else {
          planId = existing.id;
          await (update(workoutPlans)..where((p) => p.id.equals(planId)))
              .write(WorkoutPlansCompanion(
            name: Value(plan.name),
            description: Value(plan.description),
            weekdaysMask: Value(plan.weekdaysMask),
            remoteVersion: Value(version),
            remoteFrom: Value(from),
          ));
          // Série se smažou s cviky (ON DELETE CASCADE).
          await (delete(planExercises)..where((pe) => pe.planId.equals(planId)))
              .go();
        }
        for (var i = 0; i < plan.exercises.length; i++) {
          final e = plan.exercises[i];
          final exerciseId = await _coachExerciseId(e);
          final sets = e.sets.isEmpty
              ? const [CoachPlanSet(reps: 10), CoachPlanSet(reps: 10), CoachPlanSet(reps: 10)]
              : e.sets;
          final itemId = await into(planExercises).insert(
            PlanExercisesCompanion.insert(
              planId: planId,
              exerciseId: exerciseId,
              position: i,
              targetSets: Value(sets.length),
              restSeconds: Value(e.restSeconds ?? 90),
              restAuto: Value(e.restAuto || e.restSeconds == null),
              supersetGroup: Value(e.superset),
              repRangeMin: Value(e.repMin),
              repRangeMax: Value(e.repMax),
              note: Value(e.note == null ? null : clipNote(e.note!)),
            ),
          );
          for (var j = 0; j < sets.length; j++) {
            await into(planSets).insert(PlanSetsCompanion.insert(
              planExerciseId: itemId,
              position: j,
              reps: sets[j].reps,
              weightKg: Value(sets[j].kg),
              isWarmup: Value(sets[j].warmup),
              isDrop: Value(sets[j].drop),
            ));
          }
        }
        return planId;
      });

  /// Cvik pro plán: vestavěný podle slugu, jinak vlastní se stejným
  /// názvem, jinak založí nový vlastní cvik.
  Future<int> _coachExerciseId(CoachPlanExercise e) async {
    final slug = e.slug;
    if (slug != null) {
      final builtIn = await (select(exercises)..where((x) => x.slug.equals(slug)))
          .getSingleOrNull();
      if (builtIn != null) return builtIn.id;
    }
    final custom = await (select(exercises)
          ..where((x) =>
              x.isCustom.equals(true) &
              (x.nameEn.equals(e.nameEn) | x.nameCs.equals(e.nameCs)))
          ..limit(1))
        .getSingleOrNull();
    if (custom != null) return custom.id;
    return into(exercises).insert(ExercisesCompanion.insert(
      nameEn: e.nameEn,
      nameCs: e.nameCs,
      muscleGroup:
          MuscleGroup.values.asNameMap()[e.muscle] ?? MuscleGroup.fullBody,
      equipment: Equipment.values.asNameMap()[e.equipment] ?? Equipment.machine,
      type: ExerciseType.values.asNameMap()[e.type] ?? ExerciseType.weightReps,
      isCustom: const Value(true),
    ));
  }

  // -------------------------------------------------------------------
  // Tréninky pro trenéra
  // -------------------------------------------------------------------

  /// Dokončené tréninky (bez „Plánu B“) od [from] ve tvaru pro trenéra.
  Future<List<CoachWorkout>> coachWorkoutsSince(DateTime from) async {
    final sessions = await (select(workoutSessions)
          ..where((s) =>
              s.endedAt.isNotNull() &
              s.kind.equalsValue(SessionKind.full) &
              s.startedAt.isBiggerOrEqualValue(from))
          ..orderBy([(s) => OrderingTerm.asc(s.startedAt)]))
        .get();
    return [for (final s in sessions) await _coachWorkout(s)];
  }

  Future<CoachWorkout?> coachWorkoutById(int sessionId) async {
    final s = await (select(workoutSessions)
          ..where((x) => x.id.equals(sessionId)))
        .getSingleOrNull();
    if (s == null || s.endedAt == null || s.kind != SessionKind.full) {
      return null;
    }
    return _coachWorkout(s);
  }

  Future<CoachWorkout> _coachWorkout(WorkoutSession s) async {
    final rows = await (select(setEntries).join([
      innerJoin(exercises, exercises.id.equalsExp(setEntries.exerciseId)),
    ])
          ..where(setEntries.sessionId.equals(s.id))
          ..orderBy([OrderingTerm.asc(setEntries.position)]))
        .get();
    // Cviky v pořadí prvního výskytu.
    final order = <int>[];
    final byExercise = <int, (Exercise, List<CoachSet>)>{};
    for (final r in rows) {
      final e = r.readTable(exercises);
      final set = r.readTable(setEntries);
      final entry = byExercise.putIfAbsent(e.id, () {
        order.add(e.id);
        return (e, <CoachSet>[]);
      });
      entry.$2.add(CoachSet(
        kg: set.weightKg,
        reps: set.reps,
        seconds: set.durationSeconds,
        warmup: set.isWarmup,
        drop: set.isDrop,
      ));
    }
    String? title;
    final planId = s.planId;
    if (planId != null) {
      title = (await (select(workoutPlans)..where((p) => p.id.equals(planId)))
              .getSingleOrNull())
          ?.name;
    }
    final end = s.endedAt;
    return CoachWorkout(
      id: coachWorkoutId(s.id),
      startedAt: s.startedAt,
      durationMin: end == null ? null : end.difference(s.startedAt).inMinutes,
      title: title,
      exercises: [
        for (final id in order)
          CoachWorkoutExercise(
            slug: byExercise[id]!.$1.slug,
            nameEn: byExercise[id]!.$1.nameEn,
            nameCs: byExercise[id]!.$1.nameCs,
            sets: byExercise[id]!.$2,
          ),
      ],
    );
  }

  /// Tělesná váha od [from] (jen se zvláštním souhlasem klienta).
  Future<List<CoachWeightPoint>> coachWeightsSince(DateTime from) async {
    final rows = await (select(bodyWeightEntries)
          ..where((b) => b.day.isBiggerOrEqualValue(from))
          ..orderBy([(b) => OrderingTerm.asc(b.day)]))
        .get();
    final points = [for (final r in rows) CoachWeightPoint(r.day, r.weightKg)];
    return points.length > coachWeightMaxPoints
        ? points.sublist(points.length - coachWeightMaxPoints)
        : points;
  }
}
