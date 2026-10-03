// Série aktivních týdnů (streak). Čistá logika bez Flutteru.

import 'dart:math' as math;

import 'stats_math.dart';

/// Stav série: kolik týdnů v řadě je splněno a jak je na tom tento týden.
typedef StreakState = ({
  /// Počet splněných týdnů v řadě (včetně tohoto, pokud už je splněný).
  int weeks,

  /// Dokončené tréninky (plné i plán B) v tomto týdnu.
  int doneThisWeek,

  /// Kolik tréninků týdně je potřeba.
  int goal,
});

/// Kolik tréninků týdně je potřeba pro splnění týdne: počet naplánovaných
/// tréninkových dní (podle masek plánů), alespoň 1. Bez plánů 1.
int requiredSessionsPerWeek(Iterable<int> weekdayMasks) =>
    math.max(1, plannedDaysPerWeek(weekdayMasks));

/// Spočítá sérii týdnů, ve kterých počet dokončených tréninků [sessions]
/// (plných i plánu B – i 5min rutina se počítá) dosáhl [goal].
///
/// Probíhající týden sérii nepřeruší, dokud neskončí: pokud ještě není
/// splněný, série se počítá od minulého týdne.
StreakState weekStreak(
  Iterable<DateTime> sessions,
  DateTime now, {
  required int goal,
}) {
  final need = math.max(1, goal);
  final perWeek = <DateTime, int>{};
  for (final s in sessions) {
    final w = weekStartOf(s);
    perWeek[w] = (perWeek[w] ?? 0) + 1;
  }
  final current = weekStartOf(now);
  final doneThisWeek = perWeek[current] ?? 0;
  var weeks = doneThisWeek >= need ? 1 : 0;
  var week = addDays(current, -7);
  while ((perWeek[week] ?? 0) >= need) {
    weeks++;
    week = addDays(week, -7);
  }
  return (weeks: weeks, doneThisWeek: doneThisWeek, goal: need);
}
