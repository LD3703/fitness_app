// Odznaky: katalog a vyhodnocení (čistý Dart bez Flutteru, testy:
// test/badges_test.dart). Texty a ikony jsou v badge_labels.dart, ukládání
// do databáze (tabulka Achievements) v achievements_service.dart.

import 'dart:math' as math;

import '../../core/progressive_overload.dart';
import '../../data/enums.dart';
import '../../modules/stats/stats_math.dart';

enum BadgeKind {
  /// Týdny v řadě s progresem (viz OverloadHistory.longestStreak).
  overloadStreak,

  /// Mistrovství jedné partie (viz masteryProgress).
  mastery,

  /// Počet osobních rekordů (odhad 1RM, bez drop sérií a rozcvičky).
  records,

  /// Týdny v řadě se splněným plánem (počet tréninků za týden).
  consistency,
}

/// Odznak z katalogu. [threshold] = potřebný počet týdnů / rekordů,
/// u mistrovství [masteryWeeks].
class BadgeDef {
  const BadgeDef(this.kind, this.threshold, {this.group});

  final BadgeKind kind;
  final int threshold;

  /// Partie u mistrovství, jinak null.
  final MuscleGroup? group;

  /// Stabilní kód uložený v databázi (Achievements.code). Neměnit!
  String get code => switch (kind) {
        BadgeKind.overloadStreak => 'overload_streak_$threshold',
        BadgeKind.mastery => 'mastery_${group?.name}',
        BadgeKind.records => 'records_$threshold',
        BadgeKind.consistency => 'consistency_$threshold',
      };
}

const overloadStreakBadgeWeeks = [2, 4, 8, 12, 26, 52];
const recordBadgeCounts = [1, 10, 50];
const consistencyBadgeWeeks = [4, 12, 26];

/// Všechny odznaky v pořadí, v jakém se ukazují v galerii.
final List<BadgeDef> badgeCatalog = List.unmodifiable([
  for (final w in overloadStreakBadgeWeeks)
    BadgeDef(BadgeKind.overloadStreak, w),
  for (final g in overloadGroups)
    BadgeDef(BadgeKind.mastery, masteryWeeks, group: g),
  for (final c in recordBadgeCounts) BadgeDef(BadgeKind.records, c),
  for (final w in consistencyBadgeWeeks) BadgeDef(BadgeKind.consistency, w),
]);

BadgeDef? badgeByCode(String code) {
  for (final b in badgeCatalog) {
    if (b.code == code) return b;
  }
  return null;
}

/// Nejlepší dosažené hodnoty pro odznaky.
class BadgeProgress {
  const BadgeProgress({
    this.overloadStreak = 0,
    this.masteryRuns = const {},
    this.masteredGroups = const {},
    this.personalRecords = 0,
    this.consistencyStreak = 0,
  });

  /// Nejdelší série týdnů s progresem.
  final int overloadStreak;

  /// Nejdelší řada týdnů v progresu / „drží“ po partiích (max. 8).
  final Map<MuscleGroup, int> masteryRuns;
  final Set<MuscleGroup> masteredGroups;

  /// Počet osobních rekordů (překonání předchozího nejlepšího odhadu 1RM).
  final int personalRecords;

  /// Nejdelší série týdnů se splněným plánem.
  final int consistencyStreak;

  bool isEarned(BadgeDef b) => switch (b.kind) {
        BadgeKind.overloadStreak => overloadStreak >= b.threshold,
        BadgeKind.mastery => masteredGroups.contains(b.group),
        BadgeKind.records => personalRecords >= b.threshold,
        BadgeKind.consistency => consistencyStreak >= b.threshold,
      };

  /// Postup k odznaku (pro zamčené odznaky v galerii).
  ({int current, int target}) progressOf(BadgeDef b) {
    final current = switch (b.kind) {
      BadgeKind.overloadStreak => overloadStreak,
      BadgeKind.mastery => masteredGroups.contains(b.group)
          ? b.threshold
          : masteryRuns[b.group] ?? 0,
      BadgeKind.records => personalRecords,
      BadgeKind.consistency => consistencyStreak,
    };
    return (current: math.min(current, b.threshold), target: b.threshold);
  }
}

/// Odznaky splněné podle [progress].
List<BadgeDef> earnedBadges(BadgeProgress progress) =>
    [for (final b in badgeCatalog) if (progress.isEarned(b)) b];

/// Nově získané odznaky (splněné a ještě neuložené v [existingCodes]).
List<BadgeDef> newBadges(BadgeProgress progress, Set<String> existingCodes) => [
      for (final b in earnedBadges(progress))
        if (!existingCodes.contains(b.code)) b,
    ];

/// Počet osobních rekordů ze série nejlepších odhadů 1RM v jednotlivých
/// trénincích (podle cviku). Stejně jako v souhrnu tréninku: rekord je
/// překonání předchozího nejlepšího výkonu (o víc než 0,01 kg) – první
/// zápis cviku rekordem není.
int countPersonalRecords(Map<int, List<StatPoint>> oneRepMaxByExercise) {
  var count = 0;
  for (final points in oneRepMaxByExercise.values) {
    final sorted = [...points]..sort((a, b) => a.x.compareTo(b.x));
    double? best;
    for (final p in sorted) {
      final before = best;
      if (before != null && p.y > before + 0.01) count++;
      if (before == null || p.y > before) best = p.y;
    }
  }
  return count;
}

/// Nejdelší série týdnů (pondělí–neděle), ve kterých počet tréninků
/// dosáhl [goal]. Probíhající týden se započítá, jen když už je splněný
/// (stejně jako weekStreak ve stats/streak.dart).
int longestWeekStreak(
  Iterable<DateTime> sessions,
  DateTime now, {
  required int goal,
}) {
  final need = math.max(1, goal);
  final perWeek = <DateTime, int>{};
  DateTime? first;
  for (final s in sessions) {
    final w = weekStartOf(s);
    perWeek[w] = (perWeek[w] ?? 0) + 1;
    if (first == null || w.isBefore(first)) first = w;
  }
  if (first == null) return 0;
  final current = weekStartOf(now);
  var best = 0;
  var run = 0;
  for (var w = first; !w.isAfter(current); w = addDays(w, 7)) {
    if ((perWeek[w] ?? 0) >= need) {
      run++;
      if (run > best) best = run;
    } else if (w != current) {
      run = 0;
    }
  }
  return best;
}

/// Spočítá postup ke všem odznakům.
/// [weeklyGoal] = počet tréninků týdně podle plánů
/// (requiredSessionsPerWeek ve stats/streak.dart).
BadgeProgress computeBadgeProgress({
  required OverloadHistory overload,
  required Map<int, List<StatPoint>> oneRepMaxByExercise,
  required Iterable<DateTime> sessionDates,
  required int weeklyGoal,
  required DateTime now,
}) {
  final runs = <MuscleGroup, int>{};
  final mastered = <MuscleGroup>{};
  for (final MapEntry(key: group, value: results) in overload.byGroup.entries) {
    final m = masteryProgress(results);
    runs[group] = m.bestRun;
    if (m.mastered) mastered.add(group);
  }
  return BadgeProgress(
    overloadStreak: overload.longestStreak,
    masteryRuns: runs,
    masteredGroups: mastered,
    personalRecords: countPersonalRecords(oneRepMaxByExercise),
    consistencyStreak: longestWeekStreak(sessionDates, now, goal: weeklyGoal),
  );
}
