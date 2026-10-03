import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../data/database.dart';
import '../../providers.dart';
import '../../services/calendar_service.dart';
import 'free_slots.dart';

/// Je zapnuté čtení kalendáře (hledání volných oken)?
final calendarReadEnabledProvider = Provider<bool>(
  (ref) => ref.watch(
    profileProvider.select((p) => p.valueOrNull?.calendarReadEnabled ?? false),
  ),
);

/// Kolize dnešního tréninku s událostí v kalendáři.
typedef TodayConflict = ({
  WorkoutPlan plan,
  CalendarEntry event,
  // Nejbližší volný začátek dnes (null = celý den obsazený).
  DateTime? freeAt,
});

/// Dnešní tréninky, které se kryjí s událostí v kalendáři.
final calendarTodayConflictsProvider =
    FutureProvider.autoDispose<List<TodayConflict>>((ref) async {
  if (!ref.watch(calendarReadEnabledProvider)) return const [];
  // Přepočítat při změně plánů nebo odložení.
  ref.watch(plansProvider);
  ref.watch(scheduledTodayProvider);
  final finished =
      ref.watch(finishedPlanIdsTodayProvider).valueOrNull ?? const <int>{};
  final active = ref.watch(activeSessionProvider).valueOrNull;
  if (active != null) return const [];

  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final today = startOfDay(now);
  final planned = await db.plannedWorkouts(today, 1);
  final plans = [
    for (final w in planned)
      if (!finished.contains(w.plan.id) && w.plan.plannedTimeMinutes != null)
        w.plan,
  ];
  if (plans.isEmpty) return const [];

  final entries = await CalendarService.instance
      .readEntries(db, today, endOfDayExclusive(today));
  if (entries.isEmpty) return const [];

  const duration = Duration(minutes: kDefaultWorkoutMinutes);
  final result = <TodayConflict>[];
  for (final plan in plans) {
    final t = plan.plannedTimeMinutes!;
    final start = DateTime(today.year, today.month, today.day, t ~/ 60, t % 60);
    if (!start.add(duration).isAfter(now)) continue; // už je pozdě
    final hits = collisionsWith(entries, start, start.add(duration));
    if (hits.isEmpty) continue;
    final windows = freeWindows(day: today, entries: entries, notBefore: now);
    final suggestions = suggestStarts(
      day: today,
      windows: windows,
      preferredFrom: t,
      preferredTo: t,
    );
    result.add((
      plan: plan,
      event: hits.first,
      freeAt: suggestions.isEmpty ? null : suggestions.first.start,
    ));
  }
  return result;
});

/// Návrhy času pro plán na příštích 7 dní.
typedef PlanTimeSuggestions = ({  // Časy volné ve všech dnech plánu.
  List<CommonStart> common,
  // Nejlepší volné začátky po jednotlivých dnech.
  List<({DateTime day, List<SlotSuggestion> slots})> perDay,
});

final planTimeSuggestionsProvider = FutureProvider.autoDispose
    .family<PlanTimeSuggestions, int>((ref, planId) async {
  final db = ref.watch(databaseProvider);
  final plan = await db.watchPlan(planId).first;
  if (plan == null || plan.weekdaysMask == 0) {
    return (
      common: const <CommonStart>[],
      perDay: const <({DateTime day, List<SlotSuggestion> slots})>[],
    );
  }
  final now = DateTime.now();
  final today = startOfDay(now);
  final end = DateTime(today.year, today.month, today.day + 7);
  final entries = await CalendarService.instance.readEntries(db, today, end);
  final range = preferredRange(plan.plannedTimeMinutes);

  final days = <DayWindows>[];
  final perDay = <({DateTime day, List<SlotSuggestion> slots})>[];
  for (var d = 0; d < 7; d++) {
    final day = DateTime(today.year, today.month, today.day + d);
    if (plan.weekdaysMask & (1 << (day.weekday - 1)) == 0) continue;
    final dayEntries = [
      for (final e in entries)
        if (e.start.isBefore(endOfDayExclusive(day)) && e.end.isAfter(day)) e,
    ];
    days.add((day: day, windows: freeWindows(day: day, entries: dayEntries)));
    final slots = suggestStarts(
      day: day,
      windows: freeWindows(
        day: day,
        entries: dayEntries,
        notBefore: d == 0 ? now : null,
      ),
      preferredFrom: range.from,
      preferredTo: range.to,
    );
    perDay.add((day: day, slots: slots.take(3).toList()));
  }
  return (
    common: commonStarts(
      days: days,
      preferredFrom: range.from,
      preferredTo: range.to,
    ),
    perDay: perDay,
  );
});
