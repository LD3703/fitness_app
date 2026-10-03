import 'package:drift/drift.dart';

import '../../core/date_utils.dart';
import '../../data/database.dart';

/// Trénink k zápisu do Health spolu s názvem plánu (pokud nějaký má).
typedef HealthSessionItem = ({WorkoutSession session, String? planName});

extension HealthQueries on AppDatabase {
  JoinedSelectStatement<HasResultSet, dynamic> _healthSessionQuery() =>
      select(workoutSessions).join([
        leftOuterJoin(
          workoutPlans,
          workoutPlans.id.equalsExp(workoutSessions.planId),
        ),
      ]);

  HealthSessionItem _toItem(TypedResult row) => (
        session: row.readTable(workoutSessions),
        planName: row.readTableOrNull(workoutPlans)?.name,
      );

  /// Dokončené tréninky od [since], které ještě nejsou v Health.
  Future<List<HealthSessionItem>> healthSessionsToExport(
    DateTime since,
  ) async {
    final query = _healthSessionQuery()
      ..where(workoutSessions.endedAt.isNotNull() &
          workoutSessions.healthExportedAt.isNull() &
          workoutSessions.startedAt.isBiggerOrEqualValue(since))
      ..orderBy([OrderingTerm.asc(workoutSessions.startedAt)]);
    final rows = await query.get();
    return [for (final r in rows) _toItem(r)];
  }

  /// Jeden dokončený trénink, pokud ještě není v Health.
  Future<HealthSessionItem?> healthSessionToExport(int sessionId) async {
    final query = _healthSessionQuery()
      ..where(workoutSessions.id.equals(sessionId) &
          workoutSessions.endedAt.isNotNull() &
          workoutSessions.healthExportedAt.isNull());
    final row = await query.getSingleOrNull();
    return row == null ? null : _toItem(row);
  }

  Future<void> markHealthExported(int sessionId, DateTime at) =>
      (update(workoutSessions)..where((s) => s.id.equals(sessionId)))
          .write(WorkoutSessionsCompanion(healthExportedAt: Value(at)));

  /// Záznamy váhy od daného dne (včetně).
  Future<List<BodyWeightEntry>> healthWeightsSince(DateTime from) =>
      (select(bodyWeightEntries)
            ..where((b) => b.day.isBiggerOrEqualValue(startOfDay(from)))
            ..orderBy([(b) => OrderingTerm.asc(b.day)]))
          .get();

  /// Uloží váhu pro den jen tehdy, když ten den ještě žádný záznam nemá
  /// (sloupec `day` je unikátní – stejně jako u logWeight; existující
  /// ruční záznam se nikdy nepřepíše).
  Future<void> insertWeightIfMissing(DateTime day, double kg) =>
      into(bodyWeightEntries).insert(
        BodyWeightEntriesCompanion.insert(day: startOfDay(day), weightKg: kg),
        mode: InsertMode.insertOrIgnore,
      );
}
