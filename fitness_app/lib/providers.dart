import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/injury.dart';
import 'core/wellbeing.dart';
import 'data/database.dart';

/// Jediná instance databáze pro celou aplikaci.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final profileProvider = StreamProvider<UserProfile>(
  (ref) => ref.watch(databaseProvider).watchProfile(),
);

final waterTodayProvider = StreamProvider<int>(
  (ref) => ref.watch(databaseProvider).watchWaterTotal(DateTime.now()),
);

final latestWeightProvider = StreamProvider<BodyWeightEntry?>(
  (ref) => ref.watch(databaseProvider).watchLatestWeight(),
);

final activePeriodProvider = StreamProvider<Period?>(
  (ref) => ref.watch(databaseProvider).watchActivePeriod(DateTime.now()),
);

// Knihovna cviků: text hledání a filtr partie.
final exerciseQueryProvider = StateProvider<String>((ref) => '');
final exerciseGroupFilterProvider = StateProvider<MuscleGroup?>((ref) => null);

final exercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchExercises(
    query: ref.watch(exerciseQueryProvider),
    group: ref.watch(exerciseGroupFilterProvider),
  );
});

final exerciseProvider = StreamProvider.family<Exercise?, int>(
  (ref, id) => ref.watch(databaseProvider).watchExercise(id),
);

// Plány
final plansProvider = StreamProvider<List<WorkoutPlan>>(
  (ref) => ref.watch(databaseProvider).watchPlans(),
);

final planProvider = StreamProvider.family<WorkoutPlan?, int>(
  (ref, id) => ref.watch(databaseProvider).watchPlan(id),
);

final planItemsProvider = StreamProvider.family<List<PlanItem>, int>(
  (ref, planId) => ref.watch(databaseProvider).watchPlanItems(planId),
);

// Tréninky
final activeSessionProvider = StreamProvider<WorkoutSession?>(
  (ref) => ref.watch(databaseProvider).watchActiveSession(),
);

final sessionHistoryProvider = StreamProvider<List<SessionSummary>>(
  (ref) => ref.watch(databaseProvider).watchSessionHistory(),
);

/// Rekord a poslední výkon cviku (pro editor plánu a trénink).
typedef ExerciseStats = ({ExerciseRecord? record, List<SetEntry> lastSets});

final exerciseStatsProvider =
    FutureProvider.autoDispose.family<ExerciseStats, int>((ref, exerciseId) async {
  final db = ref.watch(databaseProvider);
  return (
    record: await db.exerciseRecord(exerciseId),
    lastSets: await db.previousSetsFor(exerciseId),
  );
});

// Období a situace (nemoc, po nemoci, zranění, dieta)
final periodsProvider = StreamProvider<List<Period>>(
  (ref) => ref.watch(databaseProvider).watchPeriods(),
);

/// Aktuální situace uživatele podle zapsaných období.
final situationProvider = Provider<WellbeingSituation>((ref) {
  // Když uživatel období nesleduje, žádné hlášky k nim nezobrazujeme.
  final tracks = ref.watch(profileProvider).valueOrNull?.trackPeriods ?? true;
  if (!tracks) return WellbeingSituation.normal;
  final periods = ref.watch(periodsProvider).valueOrNull ?? const [];
  return determineSituation(
    periods.map((p) => (type: p.type, start: p.startDate, end: p.endDate)),
    DateTime.now(),
  );
});

/// Partie, které má uživatel právě zraněné (pro upozornění v tréninku).
final injuredGroupsProvider = Provider<Set<MuscleGroup>>((ref) {
  final tracks = ref.watch(profileProvider).valueOrNull?.trackPeriods ?? true;
  if (!tracks) return const {};
  final periods = ref.watch(periodsProvider).valueOrNull ?? const [];
  return activeInjuredGroups(
    periods.map((p) => (
          type: p.type,
          start: p.startDate,
          end: p.endDate,
          groups: p.injuredGroups,
        )),
    DateTime.now(),
  );
});

// Dnešní den: odložené / vynechané / dokončené tréninky
final scheduledTodayProvider = StreamProvider<List<ScheduledWorkout>>(
  (ref) => ref.watch(databaseProvider).watchScheduledForDay(DateTime.now()),
);

final finishedPlanIdsTodayProvider = StreamProvider<Set<int>>(
  (ref) => ref.watch(databaseProvider).watchFinishedPlanIds(DateTime.now()),
);

// Grafy pokroku
const chartDays = 90;

final weightHistoryProvider = StreamProvider<List<BodyWeightEntry>>(
  (ref) => ref.watch(databaseProvider).watchWeightsSince(
        DateTime.now().subtract(const Duration(days: chartDays)),
      ),
);

final exercisesWithHistoryProvider = StreamProvider<List<Exercise>>(
  (ref) => ref.watch(databaseProvider).watchExercisesWithHistory(),
);

/// Vybraný cvik v grafu síly (null = první cvik s historií).
final chartExerciseProvider = StateProvider<int?>((ref) => null);

final oneRepMaxSeriesProvider = StreamProvider.family<List<SeriesPoint>, int>(
  (ref, exerciseId) =>
      ref.watch(databaseProvider).watchOneRepMaxSeries(exerciseId),
);

final workoutDatesProvider = StreamProvider<List<DateTime>>(
  (ref) => ref.watch(databaseProvider).watchWorkoutDatesSince(
        DateTime.now().subtract(const Duration(days: 7 * 12 + 7)),
      ),
);

/// Byl dnes dokončen nějaký trénink? (navýšení cíle pitného režimu)
final workoutDoneTodayProvider = StreamProvider<bool>(
  (ref) => ref.watch(databaseProvider).watchWorkoutDoneOn(DateTime.now()),
);
