import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../core/date_utils.dart';
import '../core/formulas.dart';
import '../core/injury.dart';
import 'enums.dart';
import 'seed/content_i18n.dart';
import 'seed/plan_templates.dart';
import 'seed/seed_data.dart';
import 'seed/seed_instructions.dart';
import 'tables.dart';

export 'enums.dart';

part 'database.g.dart';

/// Zraněné partie období (prázdné u ostatních typů nebo když nejsou zadané).
extension PeriodInjuryX on Period {
  Set<MuscleGroup> get injuredGroups => decodeMuscleGroups(muscleGroups);
}

/// Cvik v plánu spolu s daty cviku a jeho cílovými sériemi.
typedef PlanItem = ({PlanExercise item, Exercise exercise, List<PlanSet> sets});

/// Cílová série při ukládání z editoru (bez ID).
typedef PlanSetDraft = ({int reps, double? weightKg, bool isWarmup});

/// Osobní rekord cviku: nejlepší odhad 1RM a série, ze které pochází.
typedef ExerciseRecord = ({
  double oneRepMax,
  double weightKg,
  int reps,
  DateTime date,
});

/// Domácí rutina (plán B) s cviky v pořadí.
typedef HomeRoutineWithExercises = ({
  HomeRoutine routine,
  List<({Exercise exercise, int workSeconds, int restSeconds})> items,
});

/// Naplánovaný trénink v konkrétní den.
typedef PlannedWorkout = ({DateTime day, WorkoutPlan plan});

/// Bod časové řady pro grafy.
typedef SeriesPoint = ({DateTime x, double y});

/// Řádek historie tréninků.
typedef SessionSummary = ({
  int id,
  DateTime startedAt,
  DateTime? endedAt,
  SessionKind kind,
  String? planName,
  int setCount,
  double volumeKg,
});

@DriftDatabase(
  tables: [
    UserProfiles,
    Exercises,
    WorkoutPlans,
    PlanExercises,
    PlanSets,
    WorkoutSessions,
    SetEntries,
    WaterEntries,
    BodyWeightEntries,
    Periods,
    ScheduledWorkouts,
    HomeRoutines,
    HomeRoutineExercises,
    CalendarLinks,
    Challenges,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'fitness_app'));

  static const _profileId = 1;

  @override
  int get schemaVersion => 6;

  /// Výchozí série pro nově přidaný cvik: 3 × 10.
  static const defaultPlanSets = <PlanSetDraft>[
    (reps: 10, weightKg: null, isWarmup: false),
    (reps: 10, weightKg: null, isWarmup: false),
    (reps: 10, weightKg: null, isWarmup: false),
  ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seed();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Verze 2: cíle po sériích. Stávající „N × opakování“ převedeme
            // na N stejných sérií, aby uživatelé o nic nepřišli.
            await m.createTable(planSets);
            final items = await select(planExercises).get();
            for (final it in items) {
              for (var i = 0; i < it.targetSets; i++) {
                await into(planSets).insert(PlanSetsCompanion.insert(
                  planExerciseId: it.id,
                  position: i,
                  reps: it.targetReps,
                ));
              }
            }
          }
          if (from < 3) {
            // Verze 3: volba sledovaných modulů a úvodní průvodce.
            await m.addColumn(userProfiles, userProfiles.trackWater);
            await m.addColumn(userProfiles, userProfiles.trackWeight);
            await m.addColumn(userProfiles, userProfiles.trackPeriods);
            await m.addColumn(userProfiles, userProfiles.showCalories);
            await m.addColumn(userProfiles, userProfiles.onboardingDone);
          }
          if (from < 4) {
            // Verze 4: připomínky, kalendář, rozšířená knihovna cviků.
            await m.addColumn(userProfiles, userProfiles.morningReminderEnabled);
            await m.addColumn(userProfiles, userProfiles.waterRemindersEnabled);
            await m.addColumn(userProfiles, userProfiles.calendarSyncEnabled);
            await m.createTable(calendarLinks);
            await _syncSeedExercises();
          }
          if (from < 5) {
            // Verze 5: zranění s konkrétní partií.
            await m.addColumn(periods, periods.muscleGroups);
          }
          if (from < 6) {
            // Verze 6: funkce v2 a v3.
            for (final c in [
              userProfiles.calendarReadEnabled,
              userProfiles.healthSyncEnabled,
              userProfiles.waterReminderStartMinutes,
              userProfiles.waterReminderEndMinutes,
              userProfiles.waterReminderIntervalMinutes,
              userProfiles.glassMl,
              userProfiles.bottleMl,
              userProfiles.shareRecordsWithFriends,
              userProfiles.shareWorkoutStatsWithFriends,
            ]) {
              await m.addColumn(userProfiles, c);
            }
            await m.addColumn(workoutSessions, workoutSessions.healthExportedAt);
            await m.createTable(challenges);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _seed() async {
    await into(userProfiles)
        .insert(const UserProfilesCompanion(id: Value(_profileId)));

    final idsBySlug = await _syncSeedExercises();

    for (final r in seedHomeRoutines) {
      final routineId = await into(homeRoutines).insert(
        HomeRoutinesCompanion.insert(
          slug: Value(r.slug),
          nameEn: r.nameEn,
          nameCs: r.nameCs,
          targetMuscleGroup: r.target,
        ),
      );
      for (var i = 0; i < r.exerciseSlugs.length; i++) {
        await into(homeRoutineExercises).insert(
          HomeRoutineExercisesCompanion.insert(
            routineId: routineId,
            exerciseId: idsBySlug[r.exerciseSlugs[i]]!,
            position: i,
            workSeconds: Value(r.workSeconds),
            restSeconds: Value(r.restSeconds),
          ),
        );
      }
    }
  }

  /// Doplní chybějící vestavěné cviky a aktualizuje jejich názvy a návody.
  /// Je idempotentní – lze volat opakovaně. Vrací ID cviků podle slugu.
  Future<Map<String, int>> _syncSeedExercises() async {
    final existing = {
      for (final e in await (select(exercises)..where((e) => e.slug.isNotNull()))
          .get())
        e.slug!: e.id,
    };
    for (final e in seedExercises) {
      final instr = seedInstructions[e.slug];
      final id = existing[e.slug];
      if (id == null) {
        existing[e.slug] = await into(exercises).insert(
          ExercisesCompanion.insert(
            slug: Value(e.slug),
            nameEn: e.nameEn,
            nameCs: e.nameCs,
            muscleGroup: e.muscleGroup,
            equipment: e.equipment,
            type: e.type,
            met: Value(e.met),
            instructionsEn: Value(instr?.$1),
            instructionsCs: Value(instr?.$2),
          ),
        );
      } else {
        await (update(exercises)..where((x) => x.id.equals(id))).write(
          ExercisesCompanion(
            nameEn: Value(e.nameEn),
            nameCs: Value(e.nameCs),
            instructionsEn: Value(instr?.$1),
            instructionsCs: Value(instr?.$2),
          ),
        );
      }
    }
    return existing;
  }

  // ---------------------------------------------------------------------
  // Profil
  // ---------------------------------------------------------------------

  Stream<UserProfile> watchProfile() =>
      (select(userProfiles)..where((u) => u.id.equals(_profileId)))
          .watchSingle();

  /// Uloží libovolnou změnu profilu (jméno, moduly, průvodce…).
  Future<void> updateProfile(UserProfilesCompanion changes) =>
      (update(userProfiles)..where((u) => u.id.equals(_profileId)))
          .write(changes);

  Future<void> updateWaterGoal(int ml) =>
      (update(userProfiles)..where((u) => u.id.equals(_profileId)))
          .write(UserProfilesCompanion(waterGoalMl: Value(ml)));

  // ---------------------------------------------------------------------
  // Cviky
  // ---------------------------------------------------------------------

  /// Pozn.: SQLite `lower()` nepřevádí české znaky s diakritikou,
  /// proto hledání „Ř“ vs „ř“ nemusí fungovat. Vyřešíme později
  /// normalizovaným sloupcem pro vyhledávání.
  Stream<List<Exercise>> watchExercises({
    String query = '',
    MuscleGroup? group,
  }) {
    final q = select(exercises);
    if (group != null) q.where((e) => e.muscleGroup.equalsValue(group));
    // Hledá se v Dartu, aby šlo najít cvik podle názvu v kterémkoli
    // jazyce aplikace a bez ohledu na diakritiku.
    if (query.trim().isEmpty) return q.watch();
    return q.watch().map((list) => [
          for (final e in list)
            if (exerciseMatchesQuery(
              slug: e.slug,
              nameEn: e.nameEn,
              nameCs: e.nameCs,
              query: query,
            ))
              e,
        ]);
  }

  Stream<Exercise?> watchExercise(int id) =>
      (select(exercises)..where((e) => e.id.equals(id))).watchSingleOrNull();

  // ---------------------------------------------------------------------
  // Pitný režim
  // ---------------------------------------------------------------------

  Stream<int> watchWaterTotal(DateTime day) {
    final total = waterEntries.amountMl.sum();
    final q = selectOnly(waterEntries)
      ..addColumns([total])
      ..where(waterEntries.loggedAt.isBiggerOrEqualValue(startOfDay(day)) &
          waterEntries.loggedAt.isSmallerThanValue(endOfDayExclusive(day)));
    return q.map((row) => row.read(total) ?? 0).watchSingle();
  }

  Future<void> addWater(int ml) => into(waterEntries).insert(
        WaterEntriesCompanion.insert(loggedAt: DateTime.now(), amountMl: ml),
      );

  /// Smaže poslední dnešní záznam (tlačítko „Zpět“ při překliknutí).
  Future<void> undoLastWater() async {
    final now = DateTime.now();
    final last = await (select(waterEntries)
          ..where((w) => w.loggedAt.isBiggerOrEqualValue(startOfDay(now)))
          ..orderBy([(w) => OrderingTerm.desc(w.loggedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (last != null) {
      await (delete(waterEntries)..where((w) => w.id.equals(last.id))).go();
    }
  }

  // ---------------------------------------------------------------------
  // Tělesná váha
  // ---------------------------------------------------------------------

  Stream<BodyWeightEntry?> watchLatestWeight() => (select(bodyWeightEntries)
        ..orderBy([(b) => OrderingTerm.desc(b.day)])
        ..limit(1))
      .watchSingleOrNull();

  /// Uloží váhu pro daný den; pokud už záznam existuje, přepíše ho.
  Future<void> logWeight(DateTime day, double kg) =>
      into(bodyWeightEntries).insert(
        BodyWeightEntriesCompanion.insert(day: startOfDay(day), weightKg: kg),
        onConflict: DoUpdate(
          (old) => BodyWeightEntriesCompanion(weightKg: Value(kg)),
          target: [bodyWeightEntries.day],
        ),
      );

  // ---------------------------------------------------------------------
  // Období
  // ---------------------------------------------------------------------

  /// Právě probíhající období (nejnověji začaté), nebo null.
  Stream<Period?> watchActivePeriod(DateTime now) => (select(periods)
        ..where((p) =>
            p.startDate.isSmallerOrEqualValue(now) &
            (p.endDate.isNull() |
                p.endDate.isBiggerOrEqualValue(startOfDay(now))))
        ..orderBy([(p) => OrderingTerm.desc(p.startDate)])
        ..limit(1))
      .watchSingleOrNull();

  Stream<List<Period>> watchPeriods() => (select(periods)
        ..orderBy([(p) => OrderingTerm.desc(p.startDate)]))
      .watch();

  Future<int> addPeriod({
    required PeriodType type,
    required DateTime start,
    DateTime? end,
    String? note,
    Set<MuscleGroup> muscleGroups = const {},
  }) =>
      into(periods).insert(PeriodsCompanion.insert(
        type: type,
        startDate: startOfDay(start),
        endDate: Value(end == null ? null : startOfDay(end)),
        note: Value(note),
        muscleGroups: Value(_injuryGroups(type, muscleGroups)),
      ));

  static String? _injuryGroups(PeriodType type, Set<MuscleGroup> groups) =>
      type == PeriodType.injury ? encodeMuscleGroups(groups) : null;

  Future<void> updatePeriod(
    int id, {
    required PeriodType type,
    required DateTime start,
    DateTime? end,
    String? note,
    Set<MuscleGroup> muscleGroups = const {},
  }) =>
      (update(periods)..where((p) => p.id.equals(id))).write(PeriodsCompanion(
        type: Value(type),
        startDate: Value(startOfDay(start)),
        endDate: Value(end == null ? null : startOfDay(end)),
        note: Value(note),
        muscleGroups: Value(_injuryGroups(type, muscleGroups)),
      ));

  /// Ukončí probíhající období k danému dni.
  Future<void> endPeriod(int id, DateTime day) =>
      (update(periods)..where((p) => p.id.equals(id)))
          .write(PeriodsCompanion(endDate: Value(startOfDay(day))));

  Future<void> deletePeriod(int id) =>
      (delete(periods)..where((p) => p.id.equals(id))).go();

  // ---------------------------------------------------------------------
  // Plánování dne: odložení a vynechání tréninku
  // ---------------------------------------------------------------------

  Stream<List<ScheduledWorkout>> watchScheduledForDay(DateTime day) =>
      (select(scheduledWorkouts)
            ..where((s) =>
                s.scheduledAt.isBiggerOrEqualValue(startOfDay(day)) &
                s.scheduledAt.isSmallerThanValue(endOfDayExclusive(day))))
          .watch();

  /// Odloží trénink z [day] na následující den.
  Future<void> postponePlan(int planId, DateTime day) => transaction(() async {
        await into(scheduledWorkouts).insert(ScheduledWorkoutsCompanion.insert(
          planId: planId,
          scheduledAt: startOfDay(day),
          status: const Value(ScheduleStatus.moved),
        ));
        await into(scheduledWorkouts).insert(ScheduledWorkoutsCompanion.insert(
          planId: planId,
          scheduledAt: endOfDayExclusive(day),
          status: const Value(ScheduleStatus.planned),
        ));
      });

  /// Označí trénink v daný den jako vynechaný.
  Future<void> skipPlan(int planId, DateTime day) =>
      into(scheduledWorkouts).insert(ScheduledWorkoutsCompanion.insert(
        planId: planId,
        scheduledAt: startOfDay(day),
        status: const Value(ScheduleStatus.skipped),
      ));

  /// Vrátí odložení/vynechání tréninku v daný den (včetně přesunu na zítřek).
  Future<void> undoPlanChange(int planId, DateTime day) =>
      transaction(() async {
        final moved = await (select(scheduledWorkouts)
              ..where((s) =>
                  s.planId.equals(planId) &
                  s.status.equalsValue(ScheduleStatus.moved) &
                  s.scheduledAt.equals(startOfDay(day))))
            .get();
        await (delete(scheduledWorkouts)
              ..where((s) =>
                  s.planId.equals(planId) &
                  s.scheduledAt.equals(startOfDay(day)) &
                  (s.status.equalsValue(ScheduleStatus.moved) |
                      s.status.equalsValue(ScheduleStatus.skipped))))
            .go();
        if (moved.isNotEmpty) {
          final tomorrow = endOfDayExclusive(day);
          final planned = await (select(scheduledWorkouts)
                ..where((s) =>
                    s.planId.equals(planId) &
                    s.status.equalsValue(ScheduleStatus.planned) &
                    s.scheduledAt.equals(tomorrow))
                ..limit(1))
              .getSingleOrNull();
          if (planned != null) {
            await (delete(scheduledWorkouts)
                  ..where((s) => s.id.equals(planned.id)))
                .go();
          }
        }
      });

  /// ID plánů, jejichž trénink byl v daný den dokončen.
  Stream<Set<int>> watchFinishedPlanIds(DateTime day) =>
      (select(workoutSessions)
            ..where((s) =>
                s.planId.isNotNull() &
                s.endedAt.isNotNull() &
                s.startedAt.isBiggerOrEqualValue(startOfDay(day)) &
                s.startedAt.isSmallerThanValue(endOfDayExclusive(day))))
          .watch()
          .map((rows) => {for (final r in rows) r.planId!});

  // ---------------------------------------------------------------------
  // Plány
  // ---------------------------------------------------------------------

  Stream<List<WorkoutPlan>> watchPlans() => (select(workoutPlans)
        ..orderBy([(p) => OrderingTerm.asc(p.name)]))
      .watch();

  Stream<WorkoutPlan?> watchPlan(int id) =>
      (select(workoutPlans)..where((p) => p.id.equals(id))).watchSingleOrNull();

  Future<int> createPlan(String name) =>
      into(workoutPlans).insert(WorkoutPlansCompanion.insert(name: name));

  Future<void> renamePlan(int id, String name) =>
      (update(workoutPlans)..where((p) => p.id.equals(id)))
          .write(WorkoutPlansCompanion(name: Value(name)));

  Future<void> setPlanWeekdays(int id, int mask) =>
      (update(workoutPlans)..where((p) => p.id.equals(id)))
          .write(WorkoutPlansCompanion(weekdaysMask: Value(mask)));

  /// [minutes] = minuty od půlnoci, null = bez pevného času.
  Future<void> setPlanTime(int id, int? minutes) =>
      (update(workoutPlans)..where((p) => p.id.equals(id)))
          .write(WorkoutPlansCompanion(plannedTimeMinutes: Value(minutes)));

  Future<void> deletePlan(int id) =>
      (delete(workoutPlans)..where((p) => p.id.equals(id))).go();

  /// Cviky plánu i s jejich sériemi. Stream reaguje i na změny sérií.
  Stream<List<PlanItem>> watchPlanItems(int planId) {
    final trigger = customSelect(
      'SELECT COUNT(*) AS c FROM plan_sets',
      readsFrom: {planSets, planExercises, exercises},
    ).watch();
    return trigger.asyncMap((_) => getPlanItems(planId));
  }

  Future<List<PlanItem>> getPlanItems(int planId) async {
    final rows = await (select(planExercises).join([
      innerJoin(exercises, exercises.id.equalsExp(planExercises.exerciseId)),
    ])
          ..where(planExercises.planId.equals(planId))
          ..orderBy([OrderingTerm.asc(planExercises.position)]))
        .get();
    final result = <PlanItem>[];
    for (final r in rows) {
      final item = r.readTable(planExercises);
      result.add((
        item: item,
        exercise: r.readTable(exercises),
        sets: await getPlanSets(item.id),
      ));
    }
    return result;
  }

  Future<List<PlanSet>> getPlanSets(int planExerciseId) => (select(planSets)
        ..where((s) => s.planExerciseId.equals(planExerciseId))
        ..orderBy([(s) => OrderingTerm.asc(s.position)]))
      .get();

  Future<void> addExerciseToPlan(int planId, int exerciseId) =>
      transaction(() async {
        final count = await (select(planExercises)
              ..where((pe) => pe.planId.equals(planId)))
            .get()
            .then((l) => l.length);
        final id = await into(planExercises).insert(
          PlanExercisesCompanion.insert(
            planId: planId,
            exerciseId: exerciseId,
            position: count,
          ),
        );
        await _insertPlanSets(id, defaultPlanSets);
      });

  /// Uloží série cviku v plánu (nahradí stávající) a pauzu mezi sériemi.
  Future<void> savePlanItem(
    int planExerciseId, {
    required List<PlanSetDraft> sets,
    required int restSeconds,
  }) =>
      transaction(() async {
        await (delete(planSets)
              ..where((s) => s.planExerciseId.equals(planExerciseId)))
            .go();
        await _insertPlanSets(planExerciseId, sets);
        await (update(planExercises)
              ..where((pe) => pe.id.equals(planExerciseId)))
            .write(PlanExercisesCompanion(
          restSeconds: Value(restSeconds),
          targetSets: Value(sets.length),
        ));
      });

  Future<void> _insertPlanSets(int planExerciseId, List<PlanSetDraft> sets) async {
    for (var i = 0; i < sets.length; i++) {
      await into(planSets).insert(PlanSetsCompanion.insert(
        planExerciseId: planExerciseId,
        position: i,
        reps: sets[i].reps,
        weightKg: Value(sets[i].weightKg),
        isWarmup: Value(sets[i].isWarmup),
      ));
    }
  }

  Future<void> removePlanItem(int planExerciseId) =>
      (delete(planExercises)..where((pe) => pe.id.equals(planExerciseId)))
          .go();

  /// Uloží nové pořadí cviků v plánu (ID v požadovaném pořadí).
  Future<void> reorderPlanItems(List<int> planExerciseIdsInOrder) =>
      transaction(() async {
        for (var i = 0; i < planExerciseIdsInOrder.length; i++) {
          await (update(planExercises)
                ..where((pe) => pe.id.equals(planExerciseIdsInOrder[i])))
              .write(PlanExercisesCompanion(position: Value(i)));
        }
      });

  // ---------------------------------------------------------------------
  // Tréninky a série
  // ---------------------------------------------------------------------

  /// Rozpracovaný (neukončený) trénink, nebo null.
  Stream<WorkoutSession?> watchActiveSession() => (select(workoutSessions)
        ..where((s) => s.endedAt.isNull())
        ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
        ..limit(1))
      .watchSingleOrNull();

  Future<WorkoutSession?> getActiveSession() => (select(workoutSessions)
        ..where((s) => s.endedAt.isNull())
        ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
        ..limit(1))
      .getSingleOrNull();

  Future<WorkoutSession> getSession(int id) =>
      (select(workoutSessions)..where((s) => s.id.equals(id))).getSingle();

  Future<int> startSession({
    int? planId,
    SessionKind kind = SessionKind.full,
    DateTime? startedAt,
  }) =>
      into(workoutSessions).insert(
        WorkoutSessionsCompanion.insert(
          startedAt: startedAt ?? DateTime.now(),
          planId: Value(planId),
          kind: Value(kind),
        ),
      );

  Future<void> finishSession(int id, {double? estimatedKcal}) =>
      (update(workoutSessions)..where((s) => s.id.equals(id))).write(
        WorkoutSessionsCompanion(
          endedAt: Value(DateTime.now()),
          estimatedKcal: Value(estimatedKcal),
        ),
      );

  /// Zahodí trénink včetně zapsaných sérií.
  Future<void> discardSession(int id) =>
      (delete(workoutSessions)..where((s) => s.id.equals(id))).go();

  Future<List<SetEntry>> getSessionSets(int sessionId) => (select(setEntries)
        ..where((e) => e.sessionId.equals(sessionId))
        ..orderBy([
          (e) => OrderingTerm.asc(e.exerciseId),
          (e) => OrderingTerm.asc(e.position),
        ]))
      .get();

  Future<int> insertSet({
    required int sessionId,
    required int exerciseId,
    required int position,
    double? weightKg,
    int? reps,
    int? durationSeconds,
    bool isWarmup = false,
  }) =>
      into(setEntries).insert(SetEntriesCompanion.insert(
        sessionId: sessionId,
        exerciseId: exerciseId,
        position: position,
        weightKg: Value(weightKg),
        reps: Value(reps),
        durationSeconds: Value(durationSeconds),
        isWarmup: Value(isWarmup),
      ));

  Future<void> updateSet(
    int id, {
    double? weightKg,
    int? reps,
    int? durationSeconds,
  }) =>
      (update(setEntries)..where((e) => e.id.equals(id))).write(
        SetEntriesCompanion(
          weightKg: Value(weightKg),
          reps: Value(reps),
          durationSeconds: Value(durationSeconds),
        ),
      );

  Future<void> deleteSet(int id) =>
      (delete(setEntries)..where((e) => e.id.equals(id))).go();

  /// Série daného cviku z posledního dokončeného tréninku (pro předvyplnění).
  Future<List<SetEntry>> previousSetsFor(
    int exerciseId, {
    int? excludeSessionId,
  }) async {
    Expression<bool> cond = setEntries.exerciseId.equals(exerciseId) &
        workoutSessions.endedAt.isNotNull();
    if (excludeSessionId != null) {
      cond = cond & workoutSessions.id.equals(excludeSessionId).not();
    }
    final last = await (select(setEntries).join([
      innerJoin(
        workoutSessions,
        workoutSessions.id.equalsExp(setEntries.sessionId),
      ),
    ])
          ..where(cond)
          ..orderBy([OrderingTerm.desc(workoutSessions.startedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (last == null) return [];
    final sessionId = last.readTable(setEntries).sessionId;
    return (select(setEntries)
          ..where((e) =>
              e.sessionId.equals(sessionId) & e.exerciseId.equals(exerciseId))
          ..orderBy([(e) => OrderingTerm.asc(e.position)]))
        .get();
  }

  /// Osobní rekord cviku (nejvyšší odhad 1RM) ze všech dokončených
  /// tréninků kromě [excludeSessionId]. Rozcvičkové série se nepočítají.
  /// Null, pokud cvik ještě nebyl zapsán s vahou.
  Future<ExerciseRecord?> exerciseRecord(
    int exerciseId, {
    int? excludeSessionId,
  }) async {
    Expression<bool> cond = setEntries.exerciseId.equals(exerciseId) &
        setEntries.isWarmup.equals(false) &
        setEntries.weightKg.isNotNull() &
        setEntries.reps.isNotNull() &
        workoutSessions.endedAt.isNotNull();
    if (excludeSessionId != null) {
      cond = cond & workoutSessions.id.equals(excludeSessionId).not();
    }
    final rows = await (select(setEntries).join([
      innerJoin(
        workoutSessions,
        workoutSessions.id.equalsExp(setEntries.sessionId),
      ),
    ])
          ..where(cond))
        .get();
    ExerciseRecord? best;
    for (final r in rows) {
      final s = r.readTable(setEntries);
      final e1rm = estimateOneRepMax(s.weightKg!, s.reps!);
      if (e1rm != null && (best == null || e1rm > best.oneRepMax)) {
        best = (
          oneRepMax: e1rm,
          weightKg: s.weightKg!,
          reps: s.reps!,
          date: r.readTable(workoutSessions).startedAt,
        );
      }
    }
    return best;
  }

  Future<List<Exercise>> getExercisesByIds(Iterable<int> ids) =>
      (select(exercises)..where((e) => e.id.isIn(ids))).get();

  // ---------------------------------------------------------------------
  // Historie
  // ---------------------------------------------------------------------

  Stream<List<SessionSummary>> watchSessionHistory({int limit = 100}) {
    return customSelect(
      'SELECT s.id, s.started_at, s.ended_at, s.kind, p.name AS plan_name, '
      'COUNT(e.id) AS set_count, '
      'COALESCE(SUM(e.weight_kg * e.reps), 0.0) AS volume '
      'FROM workout_sessions s '
      'LEFT JOIN workout_plans p ON p.id = s.plan_id '
      'LEFT JOIN set_entries e ON e.session_id = s.id AND e.is_warmup = 0 '
      'WHERE s.ended_at IS NOT NULL '
      'GROUP BY s.id '
      'ORDER BY s.started_at DESC '
      'LIMIT ?',
      variables: [Variable.withInt(limit)],
      readsFrom: {workoutSessions, workoutPlans, setEntries},
    ).watch().map((rows) => [
          for (final r in rows)
            (
              id: r.read<int>('id'),
              startedAt: r.read<DateTime>('started_at'),
              endedAt: r.readNullable<DateTime>('ended_at'),
              kind: SessionKind.values[r.read<int>('kind')],
              planName: r.readNullable<String>('plan_name'),
              setCount: r.read<int>('set_count'),
              volumeKg: r.read<double>('volume'),
            ),
        ]);
  }

  // ---------------------------------------------------------------------
  // Hotové programy
  // ---------------------------------------------------------------------

  /// Vytvoří plány uživatele z hotového programu. [languageCode] určuje
  /// jazyk názvů plánů.
  Future<void> addProgram(
    TemplateProgram program, {
    required String languageCode,
  }) =>
      transaction(() async {
        final ids = {
          for (final e in await (select(exercises)
                ..where((e) => e.slug.isNotNull()))
              .get())
            e.slug!: e.id,
        };
        for (final plan in program.plans) {
          final planId = await into(workoutPlans).insert(
            WorkoutPlansCompanion.insert(
              name: seedText(
                languageCode,
                en: plan.nameEn,
                cs: plan.nameCs,
                other: (t) => t.planNames[plan.nameEn],
              ),
              weekdaysMask: Value(plan.weekdaysMask),
            ),
          );
          var position = 0;
          for (final item in plan.items) {
            final exerciseId = ids[item.slug];
            if (exerciseId == null) continue;
            final peId = await into(planExercises).insert(
              PlanExercisesCompanion.insert(
                planId: planId,
                exerciseId: exerciseId,
                position: position++,
                restSeconds: Value(item.restSeconds),
                targetSets: Value(item.sets.length),
              ),
            );
            await _insertPlanSets(peId, item.sets);
          }
        }
      });

  // ---------------------------------------------------------------------
  // Plán B – domácí rutiny
  // ---------------------------------------------------------------------

  Future<List<HomeRoutineWithExercises>> getHomeRoutines() async {
    final routines = await select(homeRoutines).get();
    final result = <HomeRoutineWithExercises>[];
    for (final r in routines) {
      final rows = await (select(homeRoutineExercises).join([
        innerJoin(
          exercises,
          exercises.id.equalsExp(homeRoutineExercises.exerciseId),
        ),
      ])
            ..where(homeRoutineExercises.routineId.equals(r.id))
            ..orderBy([OrderingTerm.asc(homeRoutineExercises.position)]))
          .get();
      result.add((
        routine: r,
        items: [
          for (final row in rows)
            (
              exercise: row.readTable(exercises),
              workSeconds: row.readTable(homeRoutineExercises).workSeconds,
              restSeconds: row.readTable(homeRoutineExercises).restSeconds,
            ),
        ],
      ));
    }
    return result;
  }

  /// Uloží dokončenou domácí rutinu jako trénink typu plán B.
  Future<void> savePlanBSession({
    required DateTime startedAt,
    required List<({int exerciseId, int seconds})> done,
    double? estimatedKcal,
  }) =>
      transaction(() async {
        final id = await startSession(
          kind: SessionKind.planB,
          startedAt: startedAt,
        );
        for (var i = 0; i < done.length; i++) {
          await insertSet(
            sessionId: id,
            exerciseId: done[i].exerciseId,
            position: i,
            durationSeconds: done[i].seconds,
          );
        }
        await finishSession(id, estimatedKcal: estimatedKcal);
      });

  /// Průměr MET hodnot cviků (pro odhad kalorií plánu B).
  Future<double> averageMet(Iterable<int> exerciseIds) async {
    final list = await getExercisesByIds(exerciseIds);
    if (list.isEmpty) return 5;
    return list.map((e) => e.met).reduce((a, b) => a + b) / list.length;
  }

  // ---------------------------------------------------------------------
  // Plánované tréninky na další dny (notifikace, kalendář)
  // ---------------------------------------------------------------------

  /// Tréninky naplánované na [days] dní od [from]: podle dnů v týdnu
  /// plus odložené, minus odložené jinam a vynechané.
  Future<List<PlannedWorkout>> plannedWorkouts(DateTime from, int days) async {
    final start = startOfDay(from);
    final end = DateTime(start.year, start.month, start.day + days);
    final plans = await select(workoutPlans).get();
    final scheduled = await (select(scheduledWorkouts)
          ..where((s) =>
              s.scheduledAt.isBiggerOrEqualValue(start) &
              s.scheduledAt.isSmallerThanValue(end)))
        .get();
    final result = <PlannedWorkout>[];
    for (var d = 0; d < days; d++) {
      final day = DateTime(start.year, start.month, start.day + d);
      final dayIndex = day.weekday - 1;
      final forDay = scheduled.where((s) => startOfDay(s.scheduledAt) == day);
      final added = {
        for (final s in forDay)
          if (s.status == ScheduleStatus.planned) s.planId,
      };
      final removed = {
        for (final s in forDay)
          if (s.status == ScheduleStatus.moved ||
              s.status == ScheduleStatus.skipped)
            s.planId,
      };
      for (final p in plans) {
        final byWeekday = p.weekdaysMask & (1 << dayIndex) != 0;
        if ((byWeekday || added.contains(p.id)) && !removed.contains(p.id)) {
          result.add((day: day, plan: p));
        }
      }
    }
    return result;
  }

  Stream<bool> watchWorkoutDoneOn(DateTime day) => (select(workoutSessions)
        ..where((s) =>
            s.endedAt.isNotNull() &
            s.startedAt.isBiggerOrEqualValue(startOfDay(day)) &
            s.startedAt.isSmallerThanValue(endOfDayExclusive(day)))
        ..limit(1))
      .watch()
      .map((rows) => rows.isNotEmpty);

  // ---------------------------------------------------------------------
  // Odkazy na události v kalendáři telefonu
  // ---------------------------------------------------------------------

  Future<List<CalendarLink>> calendarLinksFrom(DateTime day) =>
      (select(calendarLinks)
            ..where((c) => c.day.isBiggerOrEqualValue(startOfDay(day))))
          .get();

  Future<void> addCalendarLink(String eventId, int planId, DateTime day) =>
      into(calendarLinks).insert(CalendarLinksCompanion.insert(
        eventId: eventId,
        planId: Value(planId),
        day: startOfDay(day),
      ));

  Future<void> deleteCalendarLink(int id) =>
      (delete(calendarLinks)..where((c) => c.id.equals(id))).go();

  // ---------------------------------------------------------------------
  // Data pro grafy
  // ---------------------------------------------------------------------

  Stream<List<BodyWeightEntry>> watchWeightsSince(DateTime from) =>
      (select(bodyWeightEntries)
            ..where((b) => b.day.isBiggerOrEqualValue(startOfDay(from)))
            ..orderBy([(b) => OrderingTerm.asc(b.day)]))
          .watch();

  /// Cviky, které mají alespoň jednu dokončenou sérii s vahou.
  Stream<List<Exercise>> watchExercisesWithHistory() {
    final query = select(exercises).join([
      innerJoin(setEntries, setEntries.exerciseId.equalsExp(exercises.id)),
      innerJoin(
        workoutSessions,
        workoutSessions.id.equalsExp(setEntries.sessionId),
      ),
    ])
      ..where(setEntries.weightKg.isNotNull() &
          setEntries.reps.isNotNull() &
          workoutSessions.endedAt.isNotNull())
      ..groupBy([exercises.id]);
    return query.watch().map((rows) => [
          for (final r in rows) r.readTable(exercises),
        ]);
  }

  /// Nejlepší odhad 1RM cviku v každém dokončeném tréninku.
  Stream<List<SeriesPoint>> watchOneRepMaxSeries(int exerciseId) {
    final query = select(setEntries).join([
      innerJoin(
        workoutSessions,
        workoutSessions.id.equalsExp(setEntries.sessionId),
      ),
    ])
      ..where(setEntries.exerciseId.equals(exerciseId) &
          setEntries.isWarmup.equals(false) &
          setEntries.weightKg.isNotNull() &
          setEntries.reps.isNotNull() &
          workoutSessions.endedAt.isNotNull())
      ..orderBy([OrderingTerm.asc(workoutSessions.startedAt)]);
    return query.watch().map((rows) {
      final bestBySession = <int, SeriesPoint>{};
      for (final r in rows) {
        final s = r.readTable(setEntries);
        final e1rm = estimateOneRepMax(s.weightKg!, s.reps!);
        if (e1rm == null) continue;
        final current = bestBySession[s.sessionId];
        if (current == null || e1rm > current.y) {
          bestBySession[s.sessionId] =
              (x: r.readTable(workoutSessions).startedAt, y: e1rm);
        }
      }
      return bestBySession.values.toList()..sort((a, b) => a.x.compareTo(b.x));
    });
  }

  /// Začátky dokončených tréninků od data (pro graf frekvence).
  Stream<List<DateTime>> watchWorkoutDatesSince(DateTime from) =>
      (select(workoutSessions)
            ..where((s) =>
                s.endedAt.isNotNull() &
                s.startedAt.isBiggerOrEqualValue(startOfDay(from))))
          .watch()
          .map((rows) => [for (final r in rows) r.startedAt]);

  // ---------------------------------------------------------------------
  // Smazání všech dat
  // ---------------------------------------------------------------------

  /// Smaže všechna data uživatele a vrátí profil do výchozího stavu.
  /// Knihovna vestavěných cviků a domácí rutiny zůstávají.
  Future<void> deleteAllUserData() => transaction(() async {
        await delete(setEntries).go();
        await delete(workoutSessions).go();
        await delete(scheduledWorkouts).go();
        await delete(planSets).go();
        await delete(planExercises).go();
        await delete(workoutPlans).go();
        await delete(waterEntries).go();
        await delete(bodyWeightEntries).go();
        await delete(periods).go();
        await delete(calendarLinks).go();
        await delete(challenges).go();
        await (delete(exercises)..where((e) => e.isCustom.equals(true))).go();
        await delete(userProfiles).go();
        await into(userProfiles)
            .insert(const UserProfilesCompanion(id: Value(_profileId)));
      });
}
