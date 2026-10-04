import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fatigue.dart';
import '../../data/database.dart';
import '../../data/seed/exercise_secondary_muscles.dart';
import '../../providers.dart';

/// Dotazy pro model únavy svalů.
extension FatigueQueries on AppDatabase {
  static const _sql =
      'SELECT s.id, s.ended_at, s.kind, s.feeling, e.is_warmup, e.is_drop, '
      'x.muscle_group, x.slug '
      'FROM set_entries e '
      'INNER JOIN workout_sessions s ON s.id = e.session_id '
      'INNER JOIN exercises x ON x.id = e.exercise_id '
      'WHERE s.ended_at IS NOT NULL AND s.ended_at >= ? '
      'ORDER BY s.id';

  Selectable<QueryRow> _fatigueRows(DateTime from) => customSelect(
        _sql,
        variables: [Variable.withDateTime(from)],
        readsFrom: {setEntries, workoutSessions, exercises},
      );

  /// Dokončené tréninky (se sériemi) od [from] pro výpočet únavy.
  Stream<List<FatigueSession>> watchFatigueSessions(DateTime from) =>
      _fatigueRows(from).watch().map(_toSessions);

  Future<List<FatigueSession>> fatigueSessions(DateTime from) async =>
      _toSessions(await _fatigueRows(from).get());

  static List<FatigueSession> _toSessions(List<QueryRow> rows) {
    final byId = <int, ({DateTime at, WorkoutFeeling? feeling, bool isPlanB})>{};
    final sets = <int, List<FatigueSet>>{};
    for (final r in rows) {
      final id = r.read<int>('id');
      final groupIndex = r.read<int>('muscle_group');
      if (groupIndex < 0 || groupIndex >= MuscleGroup.values.length) continue;
      final feelingIndex = r.readNullable<int>('feeling');
      final kindIndex = r.read<int>('kind');
      byId[id] ??= (
        at: r.read<DateTime>('ended_at'),
        feeling: feelingIndex != null &&
                feelingIndex >= 0 &&
                feelingIndex < WorkoutFeeling.values.length
            ? WorkoutFeeling.values[feelingIndex]
            : null,
        isPlanB: kindIndex == SessionKind.planB.index,
      );
      (sets[id] ??= []).add((
        primary: MuscleGroup.values[groupIndex],
        secondary: secondaryMusclesOf(r.readNullable<String>('slug')),
        isWarmup: r.read<bool>('is_warmup'),
        isDrop: r.read<bool>('is_drop'),
      ));
    }
    return [
      for (final e in byId.entries)
        (
          at: e.value.at,
          feeling: e.value.feeling,
          isPlanB: e.value.isPlanB,
          sets: sets[e.key] ?? const <FatigueSet>[],
        ),
    ];
  }
}

/// Aktuální únava svalů (přepočítá se po každé změně tréninků).
final fatigueProvider = StreamProvider.autoDispose<FatigueReport>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .watchFatigueSessions(DateTime.now().subtract(fatigueWindow))
      .map((sessions) => computeFatigue(sessions, DateTime.now()));
});

/// Únava pro jednorázové rozhodnutí (před spuštěním tréninku).
Future<FatigueReport> loadFatigue(AppDatabase db, DateTime now) async =>
    computeFatigue(
      await db.fatigueSessions(now.subtract(fatigueWindow)),
      now,
    );
