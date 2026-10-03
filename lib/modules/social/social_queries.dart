import 'package:drift/drift.dart';

import '../../core/date_utils.dart';
import '../../data/database.dart';

/// Dotazy do lokální databáze pro sociální funkce.
extension SocialQueries on AppDatabase {
  /// Počet dokončených tréninků se začátkem v intervalu [from, to).
  Future<int> socialWorkoutCount(DateTime from, DateTime to) async {
    final rows = await (select(workoutSessions)
          ..where((s) =>
              s.endedAt.isNotNull() &
              s.startedAt.isBiggerOrEqualValue(from) &
              s.startedAt.isSmallerThanValue(to)))
        .get();
    return rows.length;
  }

  /// Objem (kg × opakování, bez rozcvičky) tréninků v intervalu [from, to).
  Future<double> socialVolume(DateTime from, DateTime to) async {
    final row = await customSelect(
      'SELECT COALESCE(SUM(e.weight_kg * e.reps), 0.0) AS volume '
      'FROM set_entries e '
      'INNER JOIN workout_sessions s ON s.id = e.session_id '
      'WHERE s.ended_at IS NOT NULL AND e.is_warmup = 0 '
      'AND s.started_at >= ? AND s.started_at < ?',
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {setEntries, workoutSessions},
    ).getSingle();
    return (row.data['volume'] as num?)?.toDouble() ?? 0;
  }

  /// Začátky dokončených tréninků od [from].
  Future<List<DateTime>> socialWorkoutDates(DateTime from) async {
    final rows = await (select(workoutSessions)
          ..where((s) =>
              s.endedAt.isNotNull() &
              s.startedAt.isBiggerOrEqualValue(startOfDay(from))))
        .get();
    return [for (final r in rows) r.startedAt];
  }

  Future<List<int>> socialPlanWeekdayMasks() async =>
      [for (final p in await select(workoutPlans).get()) p.weekdaysMask];

  Future<Exercise?> socialExerciseBySlug(String slug) =>
      (select(exercises)..where((e) => e.slug.equals(slug))).getSingleOrNull();

  /// Nejlepší odhad 1RM vestavěného cviku podle slugu.
  Future<double?> socialBestOneRepMax(String slug) async {
    final e = await socialExerciseBySlug(slug);
    if (e == null) return null;
    return (await exerciseRecord(e.id))?.oneRepMax;
  }

  Future<double?> socialLatestBodyWeight() async =>
      (await watchLatestWeight().first)?.weightKg;

  /// Vypitá voda (ml) v intervalu [from, to) – nikdy neopouští telefon.
  Future<int> socialWaterBetween(DateTime from, DateTime to) async {
    final rows = await (select(waterEntries)
          ..where((w) =>
              w.loggedAt.isBiggerOrEqualValue(from) &
              w.loggedAt.isSmallerThanValue(to)))
        .get();
    return rows.fold<int>(0, (a, w) => a + w.amountMl);
  }

  /// Výzvy od přátel (s ID na serveru).
  Future<List<Challenge>> socialRemoteChallenges() =>
      (select(challenges)..where((c) => c.remoteId.isNotNull())).get();

  Stream<List<Challenge>> socialWatchRemoteChallenges() =>
      (select(challenges)..where((c) => c.remoteId.isNotNull())).watch();

  Future<Challenge?> socialChallengeByRemoteId(String remoteId) =>
      (select(challenges)..where((c) => c.remoteId.equals(remoteId)))
          .getSingleOrNull();

  /// Uloží výzvu od přítele; když už existuje (stejné remoteId), nic nedělá.
  Future<void> socialInsertChallenge({
    required String remoteId,
    required ChallengeKind kind,
    required double targetValue,
    required String fromName,
    required DateTime deadline,
    String? exerciseSlug,
    int? exerciseId,
  }) async {
    await into(challenges).insert(
      ChallengesCompanion.insert(
        kind: kind,
        targetValue: targetValue,
        createdAt: DateTime.now(),
        exerciseSlug: Value(exerciseSlug),
        exerciseId: Value(exerciseId),
        fromName: Value(fromName),
        deadline: Value(deadline),
        remoteId: Value(remoteId),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Po smazání účtu přátel: výzvy ze serveru už nemají kam hlásit.
  Future<void> socialForgetRemoteIds() =>
      (update(challenges)..where((c) => c.remoteId.isNotNull()))
          .write(const ChallengesCompanion(remoteId: Value(null)));
}
