import 'package:drift/drift.dart';

import '../../data/database.dart';

/// Řádek exportu tréninků.
typedef ExportWorkoutRow = ({WorkoutSession session, String? planName});

/// Řádek exportu sérií.
typedef ExportSetRow = ({
  SetEntry set,
  WorkoutSession session,
  Exercise exercise,
});

/// Nový nebo upravený vlastní cvik.
typedef CustomExerciseDraft = ({
  String name,
  MuscleGroup muscleGroup,
  Equipment equipment,
  ExerciseType type,
  String? instructions,
  double met,
});

/// Kde všude je cvik použitý.
typedef ExerciseUsage = ({int sets, int planItems});

/// Dotazy modulu „data“ (export, záloha, vlastní cviky).
extension DataQueries on AppDatabase {
  // -------------------------------------------------------------------
  // Export CSV
  // -------------------------------------------------------------------

  Future<List<ExportWorkoutRow>> exportWorkouts() async {
    final q = select(workoutSessions).join([
      leftOuterJoin(
        workoutPlans,
        workoutPlans.id.equalsExp(workoutSessions.planId),
      ),
    ])
      ..orderBy([OrderingTerm.asc(workoutSessions.startedAt)]);
    final rows = await q.get();
    return [
      for (final r in rows)
        (
          session: r.readTable(workoutSessions),
          planName: r.readTableOrNull(workoutPlans)?.name,
        ),
    ];
  }

  Future<List<ExportSetRow>> exportSets() async {
    final q = select(setEntries).join([
      innerJoin(
        workoutSessions,
        workoutSessions.id.equalsExp(setEntries.sessionId),
      ),
      innerJoin(exercises, exercises.id.equalsExp(setEntries.exerciseId)),
    ])
      ..orderBy([
        OrderingTerm.asc(workoutSessions.startedAt),
        OrderingTerm.asc(setEntries.id),
      ]);
    final rows = await q.get();
    return [
      for (final r in rows)
        (
          set: r.readTable(setEntries),
          session: r.readTable(workoutSessions),
          exercise: r.readTable(exercises),
        ),
    ];
  }

  Future<List<BodyWeightEntry>> exportBodyWeights() => (select(bodyWeightEntries)
        ..orderBy([(b) => OrderingTerm.asc(b.day)]))
      .get();

  Future<List<WaterEntry>> exportWater() => (select(waterEntries)
        ..orderBy([(w) => OrderingTerm.asc(w.loggedAt)]))
      .get();

  Future<List<Period>> exportPeriods() => (select(periods)
        ..orderBy([(p) => OrderingTerm.asc(p.startDate)]))
      .get();

  // -------------------------------------------------------------------
  // Vlastní cviky
  // -------------------------------------------------------------------

  Future<Exercise?> dataExerciseById(int id) =>
      (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<int> insertCustomExercise(CustomExerciseDraft d) =>
      into(exercises).insert(ExercisesCompanion.insert(
        nameEn: d.name,
        nameCs: d.name,
        muscleGroup: d.muscleGroup,
        equipment: d.equipment,
        type: d.type,
        instructionsEn: Value(d.instructions),
        instructionsCs: Value(d.instructions),
        isCustom: const Value(true),
        met: Value(d.met),
      ));

  /// Upraví jen vlastní cvik (vestavěné se nemění).
  Future<void> updateCustomExercise(int id, CustomExerciseDraft d) =>
      (update(exercises)
            ..where((e) => e.id.equals(id) & e.isCustom.equals(true)))
          .write(ExercisesCompanion(
        nameEn: Value(d.name),
        nameCs: Value(d.name),
        muscleGroup: Value(d.muscleGroup),
        equipment: Value(d.equipment),
        type: Value(d.type),
        instructionsEn: Value(d.instructions),
        instructionsCs: Value(d.instructions),
        met: Value(d.met),
      ));

  Future<ExerciseUsage> exerciseUsage(int id) async {
    final setCount = setEntries.id.count();
    final sets = await (selectOnly(setEntries)
          ..addColumns([setCount])
          ..where(setEntries.exerciseId.equals(id)))
        .map((r) => r.read(setCount) ?? 0)
        .getSingle();
    final itemCount = planExercises.id.count();
    final items = await (selectOnly(planExercises)
          ..addColumns([itemCount])
          ..where(planExercises.exerciseId.equals(id)))
        .map((r) => r.read(itemCount) ?? 0)
        .getSingle();
    return (sets: sets, planItems: items);
  }

  /// Smaže vlastní cvik, který není v žádné odcvičené sérii.
  /// Z plánů (a domácích rutin) se odebere. Vrací false, když smazat nejde.
  Future<bool> deleteCustomExercise(int id) => transaction(() async {
        final usage = await exerciseUsage(id);
        if (usage.sets > 0) return false;
        final e = await dataExerciseById(id);
        if (e == null || !e.isCustom) return false;
        await (delete(planExercises)..where((p) => p.exerciseId.equals(id)))
            .go();
        await (delete(homeRoutineExercises)
              ..where((h) => h.exerciseId.equals(id)))
            .go();
        await (delete(exercises)..where((x) => x.id.equals(id))).go();
        return true;
      });
}
