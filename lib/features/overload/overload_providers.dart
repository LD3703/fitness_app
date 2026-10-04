import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/progressive_overload.dart';
import '../../data/database.dart';
import '../../providers.dart';

/// Dotazy pro progresivní přetížení (core/progressive_overload.dart).
extension OverloadQueries on AppDatabase {
  /// Pracovní série se zátěží z dokončených tréninků (rozcvička se
  /// vynechá už tady, drop série zůstanou – počítají se do objemu).
  Selectable<OverloadSet> _overloadSets() => customSelect(
        'SELECT s.started_at, e.exercise_id, x.muscle_group, e.weight_kg, '
        'e.reps, e.is_drop '
        'FROM set_entries e '
        'INNER JOIN workout_sessions s ON s.id = e.session_id '
        'INNER JOIN exercises x ON x.id = e.exercise_id '
        'WHERE s.ended_at IS NOT NULL AND e.is_warmup = 0 '
        'AND e.weight_kg > 0 AND e.reps > 0 '
        'ORDER BY s.started_at',
        readsFrom: {setEntries, workoutSessions, exercises},
      ).map((r) {
        final index = r.read<int>('muscle_group');
        final group = index >= 0 && index < MuscleGroup.values.length
            ? MuscleGroup.values[index]
            : MuscleGroup.fullBody; // neznámá partie se nehodnotí
        return (
          date: r.read<DateTime>('started_at'),
          exerciseId: r.read<int>('exercise_id'),
          group: group,
          weightKg: r.read<double>('weight_kg'),
          reps: r.read<int>('reps'),
          isWarmup: false,
          isDrop: r.read<bool>('is_drop'),
        );
      });

  Stream<List<OverloadSet>> watchOverloadSets() => _overloadSets().watch();

  Future<List<OverloadSet>> overloadSets() => _overloadSets().get();
}

/// Období převedená pro výpočet (zranění s partiemi).
List<OverloadPeriod> overloadPeriodsOf(Iterable<Period> periods) => [
      for (final p in periods)
        (
          type: p.type,
          start: p.startDate,
          end: p.endDate,
          injuredGroups: p.injuredGroups,
        ),
    ];

/// Načte vše potřebné a spočítá historii k [now] (pro háčky a notifikace).
/// Období se berou jen, když je uživatel sleduje.
Future<OverloadHistory> loadOverloadHistory(
  AppDatabase db,
  UserProfile profile,
  DateTime now,
) async {
  final sets = await db.overloadSets();
  final periods = profile.trackPeriods
      ? await db.watchPeriods().first
      : const <Period>[];
  return computeOverloadHistory(sets, overloadPeriodsOf(periods), now);
}

final overloadSetsProvider = StreamProvider<List<OverloadSet>>(
  (ref) => ref.watch(databaseProvider).watchOverloadSets(),
);

/// Hodnocení partií po týdnech (null, dokud se data načítají).
final overloadHistoryProvider = Provider<OverloadHistory?>((ref) {
  final sets = ref.watch(overloadSetsProvider).valueOrNull;
  final profile = ref.watch(profileProvider).valueOrNull;
  if (sets == null || profile == null) return null;
  final periods = profile.trackPeriods
      ? ref.watch(periodsProvider).valueOrNull ?? const <Period>[]
      : const <Period>[];
  return computeOverloadHistory(
    sets,
    overloadPeriodsOf(periods),
    DateTime.now(),
  );
});
