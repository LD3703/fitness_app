import 'package:drift/drift.dart';

import '../../../core/formulas.dart';
import '../../../data/database.dart';
import '../social_queries.dart';
import 'gym_logic.dart';

/// Dotazy do lokální databáze pro žebříček posilovny.
extension GymQueries on AppDatabase {
  /// Nejlepší odhad 1RM (Epley, [estimateOneRepMax]) vestavěného cviku
  /// z dokončených tréninků – bez rozcvičky, drop sérií a sérií nad [gymMaxReps]
  /// opakování. S [from] / [to] jen tréninky začaté v intervalu [from, to).
  Future<double?> gymBestOneRepMax(
    String slug, {
    DateTime? from,
    DateTime? to,
  }) async {
    final exercise = await socialExerciseBySlug(slug);
    if (exercise == null) return null;
    Expression<bool> cond = setEntries.exerciseId.equals(exercise.id) &
        setEntries.isWarmup.equals(false) &
        setEntries.isDrop.equals(false) &
        setEntries.weightKg.isNotNull() &
        setEntries.reps.isNotNull() &
        workoutSessions.endedAt.isNotNull();
    if (from != null) {
      cond = cond & workoutSessions.startedAt.isBiggerOrEqualValue(from);
    }
    if (to != null) {
      cond = cond & workoutSessions.startedAt.isSmallerThanValue(to);
    }
    final rows = await (select(setEntries).join([
      innerJoin(
        workoutSessions,
        workoutSessions.id.equalsExp(setEntries.sessionId),
      ),
    ])
          ..where(cond))
        .get();
    double? best;
    for (final r in rows) {
      final s = r.readTable(setEntries);
      final reps = s.reps!;
      if (reps > gymMaxReps) continue;
      final e1rm = estimateOneRepMax(s.weightKg!, reps);
      if (e1rm != null && (best == null || e1rm > best)) best = e1rm;
    }
    return best;
  }

  /// Nejvíc dokončených tréninků v jednom kalendářním měsíci.
  Future<int> gymBestMonthWorkouts() async =>
      bestMonthCount(await socialWorkoutDates(DateTime(2000)));
}
