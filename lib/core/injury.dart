import '../data/enums.dart';
import 'date_utils.dart';

/// Zraněné partie se v databázi ukládají jako text „shoulders,back“
/// (názvy hodnot výčtu – nezávisí na jejich pořadí).
Set<MuscleGroup> decodeMuscleGroups(String? value) {
  if (value == null || value.isEmpty) return const {};
  final byName = {for (final g in MuscleGroup.values) g.name: g};
  return {
    for (final part in value.split(','))
      if (byName[part.trim()] case final g?) g,
  };
}

String? encodeMuscleGroups(Iterable<MuscleGroup> groups) {
  if (groups.isEmpty) return null;
  final sorted = groups.toSet().toList()
    ..sort((a, b) => a.index.compareTo(b.index));
  return sorted.map((g) => g.name).join(',');
}

/// Týká se období grafu nebo cviku?
///
/// [exerciseGroup] je partie cviku v grafu, null u grafů, které se
/// k žádné partii neváží (váha, frekvence tréninků).
/// - Zranění se zadanými partiemi platí jen pro cviky na tyto partie
///   (a pro cviky na celé tělo).
/// - Zranění bez zadané partie (starší záznamy) platí všude.
/// - Ostatní období (nemoc, dieta…) platí vždy.
bool periodAppliesTo(
  PeriodType type,
  Set<MuscleGroup> injured,
  MuscleGroup? exerciseGroup,
) {
  if (type != PeriodType.injury || injured.isEmpty) return true;
  if (exerciseGroup == null) return false;
  return exerciseGroup == MuscleGroup.fullBody ||
      injured.contains(exerciseGroup);
}

/// Partie, které jsou k datu [now] zraněné (z probíhajících zranění).
Set<MuscleGroup> activeInjuredGroups(
  Iterable<({PeriodType type, DateTime start, DateTime? end, Set<MuscleGroup> groups})>
      periods,
  DateTime now,
) {
  final today = startOfDay(now);
  return {
    for (final p in periods)
      if (p.type == PeriodType.injury &&
          !startOfDay(p.start).isAfter(today) &&
          (p.end == null || !startOfDay(p.end!).isBefore(today)))
        ...p.groups,
  };
}
