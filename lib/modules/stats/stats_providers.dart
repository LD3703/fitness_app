import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../data/database.dart';
import '../../providers.dart';
import 'insights.dart';
import 'stats_math.dart';
import 'stats_queries.dart';
import 'streak.dart';

/// Počet týdnů v grafu objemu a v kalendáři aktivity.
const statsVolumeWeeks = 12;
const statsHeatmapWeeks = 16;

/// Okno pro rozpad podle partií (dny).
const statsGroupDays = 30;

DateTime _daysAgo(int days) => addDays(startOfDay(DateTime.now()), -days);

/// Nejlepší série každého cviku v každém tréninku (celá historie).
final statsSessionBestsProvider = StreamProvider<List<SessionBest>>(
  (ref) => ref.watch(databaseProvider).watchSessionBests(),
);

/// Odhad 1RM po trénincích, podle ID cviku (seřazené podle data).
final statsOneRepMaxByExerciseProvider =
    Provider<Map<int, List<StatPoint>>?>((ref) {
  final bests = ref.watch(statsSessionBestsProvider).valueOrNull;
  if (bests == null) return null;
  final result = <int, List<StatPoint>>{};
  for (final b in bests) {
    (result[b.exerciseId] ??= []).add((x: b.date, y: b.oneRepMax));
  }
  for (final list in result.values) {
    list.sort((a, b) => a.x.compareTo(b.x));
  }
  return result;
});

/// Osobní rekord každého cviku (nejvyšší odhad 1RM a série, ze které je).
final statsRecordsProvider = Provider<List<SessionBest>?>((ref) {
  final bests = ref.watch(statsSessionBestsProvider).valueOrNull;
  if (bests == null) return null;
  final best = <int, SessionBest>{};
  for (final b in bests) {
    final current = best[b.exerciseId];
    if (current == null || b.oneRepMax > current.oneRepMax) {
      best[b.exerciseId] = b;
    }
  }
  return best.values.toList();
});

/// Začátky všech dokončených tréninků (plných i plánu B).
final statsWorkoutDatesProvider = StreamProvider<List<DateTime>>(
  (ref) => ref.watch(databaseProvider).watchWorkoutDatesSince(DateTime(2000)),
);

final statsExerciseMapProvider = StreamProvider<Map<int, Exercise>>(
  (ref) => ref.watch(databaseProvider).watchExerciseMap(),
);

/// Objem po trénincích za posledních [statsVolumeWeeks] týdnů.
final statsSessionVolumesProvider =
    StreamProvider<List<({DateTime x, double y})>>((ref) {
  final from = addDays(weekStartOf(DateTime.now()), -7 * (statsVolumeWeeks - 1));
  return ref.watch(databaseProvider).watchSessionVolumesSince(from);
});

/// Objem a počet tréninků po partiích za posledních 30 dní.
final statsGroupStatsProvider = StreamProvider<List<GroupStat>>(
  (ref) => ref
      .watch(databaseProvider)
      .watchGroupStatsSince(_daysAgo(statsGroupDays - 1)),
);

/// Tréninky po partiích za posledních 70 dní (zanedbané partie).
final statsGroupSessionsProvider =
    StreamProvider<List<({DateTime day, MuscleGroup group})>>(
  (ref) => ref.watch(databaseProvider).watchGroupSessionsSince(_daysAgo(70)),
);

/// Tělesná váha za poslední rok (shrnutí diet, rychlost hubnutí).
final statsWeightsProvider = StreamProvider<List<BodyWeightEntry>>(
  (ref) => ref.watch(databaseProvider).watchWeightsSince(_daysAgo(400)),
);

List<StatPoint> _weightPoints(List<BodyWeightEntry> entries) =>
    [for (final e in entries) (x: e.day, y: e.weightKg)];

/// Automatické postřehy (null, dokud se data načítají).
final statsInsightsProvider = Provider<List<Insight>?>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  final e1rm = ref.watch(statsOneRepMaxByExerciseProvider);
  final dates = ref.watch(statsWorkoutDatesProvider).valueOrNull;
  final groups = ref.watch(statsGroupSessionsProvider).valueOrNull;
  if (profile == null || e1rm == null || dates == null || groups == null) {
    return null;
  }
  final weights = profile.trackWeight
      ? ref.watch(statsWeightsProvider).valueOrNull ?? const <BodyWeightEntry>[]
      : const <BodyWeightEntry>[];
  final periods = profile.trackPeriods
      ? ref.watch(periodsProvider).valueOrNull ?? const <Period>[]
      : const <Period>[];
  final plans = ref.watch(plansProvider).valueOrNull ?? const <WorkoutPlan>[];
  return computeInsights(InsightInput(
    now: DateTime.now(),
    trackWeight: profile.trackWeight,
    trackPeriods: profile.trackPeriods,
    periods: [
      for (final p in periods)
        (type: p.type, start: p.startDate, end: p.endDate),
    ],
    weights: _weightPoints(weights),
    oneRepMaxByExercise: e1rm,
    groupSessions: groups,
    sessionDates: dates,
    weekdayMasks: [for (final p in plans) p.weekdaysMask],
    injuredGroups: ref.watch(injuredGroupsProvider),
  ));
});

/// Úbytek váhy v % za týden, když je rychlejší než ~1 % (jinak null).
/// Jen když uživatel sleduje váhu.
final statsFastWeightLossProvider = Provider<double?>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  if (profile == null || !profile.trackWeight) return null;
  final weights = ref.watch(statsWeightsProvider).valueOrNull;
  if (weights == null) return null;
  final rate = weeklyWeightLossPercent(_weightPoints(weights), DateTime.now());
  if (rate == null || rate <= fastWeightLossPercentPerWeek) return null;
  return rate;
});

/// Série splněných týdnů (null, dokud se data načítají).
final statsStreakProvider = Provider<StreakState?>((ref) {
  final dates = ref.watch(statsWorkoutDatesProvider).valueOrNull;
  final plans = ref.watch(plansProvider).valueOrNull;
  if (dates == null || plans == null) return null;
  return weekStreak(
    dates,
    DateTime.now(),
    goal: requiredSessionsPerWeek([for (final p in plans) p.weekdaysMask]),
  );
});

/// Posledních 5 tréninků s daným cvikem.
final statsRecentExerciseSessionsProvider = StreamProvider.autoDispose
    .family<List<ExerciseSessionSets>, int>(
  (ref, exerciseId) =>
      ref.watch(databaseProvider).watchRecentExerciseSessions(exerciseId),
);
