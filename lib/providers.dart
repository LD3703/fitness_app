import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/experience_level.dart';
import 'core/injury.dart';
import 'core/muscle_sets.dart';
import 'core/wellbeing.dart';
import 'data/database.dart';
import 'features/workout/workout_service.dart' show previousSetsForSlot;

/// Jediná instance databáze pro celou aplikaci.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final profileProvider = StreamProvider<UserProfile>(
  (ref) => ref.watch(databaseProvider).watchProfile(),
);

/// Dnešní den (půlnoc). Změní se o půlnoci a po návratu aplikace do
/// popředí, pokud mezitím začal nový den. Providery „na dnešek“ ho
/// sledují, aby se po půlnoci nepočítalo dál se včerejškem (aplikace
/// může běžet v pozadí i několik dní).
class CurrentDayNotifier extends Notifier<DateTime> {
  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  DateTime build() {
    try {
      _lifecycle ??= AppLifecycleListener(onResume: _refresh);
    } catch (e) {
      // Bez WidgetsBinding (čisté testy) jen bez sledování návratu.
      debugPrint('CurrentDay: lifecycle listener unavailable: $e');
    }
    ref.onDispose(() {
      _timer?.cancel();
      _lifecycle?.dispose();
      _lifecycle = null;
    });
    _scheduleMidnight();
    return _today();
  }

  void _scheduleMidnight() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    // +1 s rezerva, ať je po probuzení časovače opravdu nový den.
    _timer = Timer(next.difference(now) + const Duration(seconds: 1), _refresh);
  }

  void _refresh() {
    final today = _today();
    if (today != state) state = today;
    _scheduleMidnight();
  }
}

final currentDayProvider =
    NotifierProvider<CurrentDayNotifier, DateTime>(CurrentDayNotifier.new);

final waterTodayProvider = StreamProvider<int>((ref) {
  ref.watch(currentDayProvider);
  return ref.watch(databaseProvider).watchWaterTotal(DateTime.now());
});

final latestWeightProvider = StreamProvider<BodyWeightEntry?>(
  (ref) => ref.watch(databaseProvider).watchLatestWeight(),
);

final activePeriodProvider = StreamProvider<Period?>((ref) {
  ref.watch(currentDayProvider);
  return ref.watch(databaseProvider).watchActivePeriod(DateTime.now());
});

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

/// Hlavní a vedlejší partie plánu (mapa těla u plánu). Null = načítá se.
final planMusclesProvider = Provider.family<MuscleSets?, int>((ref, planId) {
  final items = ref.watch(planItemsProvider(planId)).valueOrNull;
  if (items == null) return null;
  return muscleSetsOf(items.map((i) => i.exercise));
});

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
    // Jen série prvního výskytu cviku (další výskyty v jednom tréninku
    // mají pozice od 1000, viz blockPositionStride) – jinak by „podle
    // minula“ v editoru plánu dalo série obou výskytů za sebou.
    lastSets: previousSetsForSlot(await db.previousSetsFor(exerciseId), 0),
  );
});

// Období a situace (nemoc, po nemoci, zranění, dieta)
final periodsProvider = StreamProvider<List<Period>>(
  (ref) => ref.watch(databaseProvider).watchPeriods(),
);

/// Aktuální situace uživatele podle zapsaných období.
final situationProvider = Provider<WellbeingSituation>((ref) {
  // Když uživatel období nesleduje, žádné hlášky k nim nezobrazujeme.
  ref.watch(currentDayProvider);
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
  ref.watch(currentDayProvider);
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
final scheduledTodayProvider = StreamProvider<List<ScheduledWorkout>>((ref) {
  ref.watch(currentDayProvider);
  return ref.watch(databaseProvider).watchScheduledForDay(DateTime.now());
});

final finishedPlanIdsTodayProvider = StreamProvider<Set<int>>((ref) {
  ref.watch(currentDayProvider);
  return ref.watch(databaseProvider).watchFinishedPlanIds(DateTime.now());
});

// Grafy pokroku
const chartDays = 90;

final weightHistoryProvider = StreamProvider<List<BodyWeightEntry>>((ref) {
  ref.watch(currentDayProvider);
  return ref.watch(databaseProvider).watchWeightsSince(
        DateTime.now().subtract(const Duration(days: chartDays)),
      );
});

final exercisesWithHistoryProvider = StreamProvider<List<Exercise>>(
  (ref) => ref.watch(databaseProvider).watchExercisesWithHistory(),
);

/// Vybraný cvik v grafu síly (null = první cvik s historií).
final chartExerciseProvider = StateProvider<int?>((ref) => null);

final topWeightSeriesProvider = StreamProvider.family<List<SeriesPoint>, int>(
  (ref, exerciseId) =>
      ref.watch(databaseProvider).watchTopWeightSeries(exerciseId),
);

final workoutDatesProvider = StreamProvider<List<DateTime>>((ref) {
  ref.watch(currentDayProvider);
  return ref.watch(databaseProvider).watchWorkoutDatesSince(
        DateTime.now().subtract(const Duration(days: 7 * 12 + 7)),
      );
});

/// Úroveň pokročilosti: plnění podmínek pro další úroveň a návrh změny
/// (core/experience_level.dart).
final experienceStatusProvider = StreamProvider<
    ({
      ExperienceLevel level,
      LevelProgress? progress,
      LevelSuggestion? suggestion,
    })>((ref) {
  ref.watch(currentDayProvider);
  final profile = ref.watch(profileProvider).valueOrNull;
  if (profile == null) return const Stream.empty();
  final level = experienceLevelOf(profile.experienceLevel);
  final since = profile.experienceSince;
  return ref
      .watch(databaseProvider)
      .watchFullWorkoutDatesSince(since ?? DateTime(2000))
      .map((dates) {
    final now = DateTime.now();
    return (
      level: level,
      progress: levelProgress(
          current: level, since: since, workouts: dates, now: now),
      suggestion: suggestLevelChange(
        current: level,
        since: since,
        workouts: dates,
        now: now,
        promptAt: profile.experiencePromptAt,
      ),
    );
  });
});

/// Byl dnes dokončen nějaký trénink? (navýšení cíle pitného režimu)
final workoutDoneTodayProvider = StreamProvider<bool>((ref) {
  ref.watch(currentDayProvider);
  return ref.watch(databaseProvider).watchWorkoutDoneOn(DateTime.now());
});
