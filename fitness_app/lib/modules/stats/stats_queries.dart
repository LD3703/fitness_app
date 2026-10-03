import 'package:drift/drift.dart';

import '../../core/formulas.dart';
import '../../data/database.dart';

/// Nejlepší série cviku v jednom dokončeném tréninku.
typedef SessionBest = ({
  int exerciseId,
  int sessionId,
  DateTime date,
  double weightKg,
  int reps,
  double oneRepMax,
});

/// Objem a počet tréninků jedné partie za období.
typedef GroupStat = ({MuscleGroup group, double volumeKg, int sessions});

/// Série cviku v jednom tréninku (pro detail cviku).
typedef ExerciseSessionSets = ({
  int sessionId,
  DateTime date,
  List<SetEntry> sets,
});

MuscleGroup? _group(int index) =>
    index >= 0 && index < MuscleGroup.values.length
        ? MuscleGroup.values[index]
        : null;

/// Dotazy modulu statistik.
extension StatsQueries on AppDatabase {
  /// Pro každý cvik a dokončený trénink série s nejvyšším odhadem 1RM
  /// (Epley, bez rozcvičky a bez drop sérií). SQLite u MAX() vrací ostatní sloupce z řádku
  /// s maximem; samotný odhad se pak počítá v Dartu přes estimateOneRepMax.
  Stream<List<SessionBest>> watchSessionBests() {
    return customSelect(
      'SELECT e.exercise_id, s.id AS session_id, s.started_at, '
      'e.weight_kg, e.reps, '
      'MAX(CASE WHEN e.reps = 1 THEN e.weight_kg '
      'ELSE e.weight_kg * (1 + e.reps / 30.0) END) AS e1rm '
      'FROM set_entries e '
      'INNER JOIN workout_sessions s ON s.id = e.session_id '
      'WHERE s.ended_at IS NOT NULL AND e.is_warmup = 0 AND e.is_drop = 0 '
      'AND e.weight_kg > 0 AND e.reps > 0 '
      'GROUP BY e.exercise_id, s.id '
      'ORDER BY s.started_at',
      readsFrom: {setEntries, workoutSessions},
    ).watch().map((rows) {
      final result = <SessionBest>[];
      for (final r in rows) {
        final weight = r.read<double>('weight_kg');
        final reps = r.read<int>('reps');
        final e1rm = estimateOneRepMax(weight, reps);
        if (e1rm == null) continue;
        result.add((
          exerciseId: r.read<int>('exercise_id'),
          sessionId: r.read<int>('session_id'),
          date: r.read<DateTime>('started_at'),
          weightKg: weight,
          reps: reps,
          oneRepMax: e1rm,
        ));
      }
      return result;
    });
  }

  /// Objem (kg × opakování, bez rozcvičky, drop série ano) každého
  /// dokončeného tréninku
  /// od [from]. Tréninky bez série s vahou se vynechají.
  Stream<List<({DateTime x, double y})>> watchSessionVolumesSince(
    DateTime from,
  ) {
    return customSelect(
      'SELECT s.started_at, SUM(e.weight_kg * e.reps) AS volume '
      'FROM workout_sessions s '
      'INNER JOIN set_entries e ON e.session_id = s.id '
      'WHERE s.ended_at IS NOT NULL AND s.started_at >= ? '
      'AND e.is_warmup = 0 AND e.weight_kg IS NOT NULL AND e.reps IS NOT NULL '
      'GROUP BY s.id',
      variables: [Variable.withDateTime(from)],
      readsFrom: {setEntries, workoutSessions},
    ).watch().map((rows) => [
          for (final r in rows)
            (
              x: r.read<DateTime>('started_at'),
              y: r.readNullable<double>('volume') ?? 0.0,
            ),
        ]);
  }

  /// Objem a počet tréninků po partiích od [from]. Do počtu tréninků se
  /// počítá každý dokončený trénink se sérií cviku na partii (i plán B).
  Stream<List<GroupStat>> watchGroupStatsSince(DateTime from) {
    return customSelect(
      'SELECT x.muscle_group, '
      'COALESCE(SUM(CASE WHEN e.is_warmup = 0 '
      'THEN e.weight_kg * e.reps END), 0.0) AS volume, '
      'COUNT(DISTINCT s.id) AS sessions '
      'FROM set_entries e '
      'INNER JOIN workout_sessions s ON s.id = e.session_id '
      'INNER JOIN exercises x ON x.id = e.exercise_id '
      'WHERE s.ended_at IS NOT NULL AND s.started_at >= ? '
      'GROUP BY x.muscle_group',
      variables: [Variable.withDateTime(from)],
      readsFrom: {setEntries, workoutSessions, exercises},
    ).watch().map((rows) {
      final result = <GroupStat>[];
      for (final r in rows) {
        final g = _group(r.read<int>('muscle_group'));
        if (g == null) continue;
        result.add((
          group: g,
          volumeKg: r.read<double>('volume'),
          sessions: r.read<int>('sessions'),
        ));
      }
      return result;
    });
  }

  /// Dokončené tréninky od [from] rozložené po partiích (jeden řádek na
  /// trénink a partii).
  Stream<List<({DateTime day, MuscleGroup group})>> watchGroupSessionsSince(
    DateTime from,
  ) {
    return customSelect(
      'SELECT DISTINCT s.id, s.started_at, x.muscle_group '
      'FROM set_entries e '
      'INNER JOIN workout_sessions s ON s.id = e.session_id '
      'INNER JOIN exercises x ON x.id = e.exercise_id '
      'WHERE s.ended_at IS NOT NULL AND s.started_at >= ?',
      variables: [Variable.withDateTime(from)],
      readsFrom: {setEntries, workoutSessions, exercises},
    ).watch().map((rows) {
      final result = <({DateTime day, MuscleGroup group})>[];
      for (final r in rows) {
        final g = _group(r.read<int>('muscle_group'));
        if (g == null) continue;
        result.add((day: r.read<DateTime>('started_at'), group: g));
      }
      return result;
    });
  }

  /// Všechny cviky podle ID (pro názvy v rekordech a postřezích).
  Stream<Map<int, Exercise>> watchExerciseMap() =>
      select(exercises).watch().map((list) => {for (final e in list) e.id: e});

  /// Posledních [limit] dokončených tréninků s cvikem a jejich série
  /// (nejnovější první, série v pořadí).
  Stream<List<ExerciseSessionSets>> watchRecentExerciseSessions(
    int exerciseId, {
    int limit = 5,
  }) {
    return customSelect(
      'SELECT s.id, s.started_at FROM workout_sessions s '
      'WHERE s.ended_at IS NOT NULL AND EXISTS ('
      'SELECT 1 FROM set_entries e '
      'WHERE e.session_id = s.id AND e.exercise_id = ?) '
      'ORDER BY s.started_at DESC LIMIT ?',
      variables: [Variable.withInt(exerciseId), Variable.withInt(limit)],
      readsFrom: {setEntries, workoutSessions},
    ).watch().asyncMap((rows) async {
      if (rows.isEmpty) return const <ExerciseSessionSets>[];
      final ids = [for (final r in rows) r.read<int>('id')];
      final sets = await (select(setEntries)
            ..where((e) => e.exerciseId.equals(exerciseId) & e.sessionId.isIn(ids))
            ..orderBy([(e) => OrderingTerm.asc(e.position)]))
          .get();
      final bySession = <int, List<SetEntry>>{};
      for (final s in sets) {
        (bySession[s.sessionId] ??= []).add(s);
      }
      return [
        for (final r in rows)
          (
            sessionId: r.read<int>('id'),
            date: r.read<DateTime>('started_at'),
            sets: bySession[r.read<int>('id')] ?? const <SetEntry>[],
          ),
      ];
    });
  }
}
