import 'package:drift/drift.dart';

import '../../data/database.dart';

/// Dotazy modulu sdílení (výzvy, cviky podle slugu, metriky pro průběh).
extension SharingQueries on AppDatabase {
  /// Stream, který se ozve při každé změně výzev, sérií, tréninků nebo vody
  /// (průběh výzev závisí na všem z toho).
  Stream<void> watchChallengeInputs() => customSelect(
        'SELECT COUNT(*) AS c FROM challenges',
        readsFrom: {challenges, setEntries, workoutSessions, waterEntries},
      ).watch().map((_) {});

  Future<List<Challenge>> allChallenges() => (select(challenges)
        ..orderBy([
          (c) => OrderingTerm.asc(c.deadline),
          (c) => OrderingTerm.asc(c.createdAt),
        ]))
      .get();

  /// Výzvy splněné od [since] (pro souhrn po tréninku).
  Stream<List<Challenge>> watchChallengesCompletedSince(DateTime since) =>
      (select(challenges)
            ..where((c) => c.completedAt.isBiggerOrEqualValue(since))
            ..orderBy([(c) => OrderingTerm.asc(c.completedAt)]))
          .watch();

  /// Nesplněné a neskryté výzvy (bez ohledu na termín).
  Future<List<Challenge>> openChallenges() => (select(challenges)
        ..where((c) => c.completedAt.isNull() & c.dismissedAt.isNull()))
      .get();

  Future<int> insertChallenge(ChallengesCompanion row) =>
      into(challenges).insert(row);

  Future<void> markChallengeCompleted(int id, DateTime at) =>
      (update(challenges)..where((c) => c.id.equals(id) & c.completedAt.isNull()))
          .write(ChallengesCompanion(completedAt: Value(at)));

  Future<void> dismissChallenge(int id, DateTime at) =>
      (update(challenges)..where((c) => c.id.equals(id)))
          .write(ChallengesCompanion(dismissedAt: Value(at)));

  /// Existuje už stejná nesplněná výzva na rekord (dvojí přijetí odkazu)?
  Future<bool> hasOpenRecordChallenge({
    int? exerciseId,
    String? exerciseSlug,
    required double targetValue,
    String? fromName,
  }) async {
    final rows = await (select(challenges)
          ..where((c) =>
              c.kind.equalsValue(ChallengeKind.beatRecord) &
              c.completedAt.isNull() &
              c.dismissedAt.isNull()))
        .get();
    return rows.any((c) =>
        (c.targetValue - targetValue).abs() < 0.01 &&
        c.fromName == fromName &&
        ((exerciseId != null && c.exerciseId == exerciseId) ||
            (exerciseSlug != null && c.exerciseSlug == exerciseSlug)));
  }

  Future<Exercise?> exerciseBySlug(String slug) =>
      (select(exercises)..where((e) => e.slug.equals(slug)))
          .getSingleOrNull();

  Future<Exercise?> exerciseById(int id) =>
      (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  /// Vlastní cvik podle názvu (bez ohledu na velikost písmen).
  Future<Exercise?> customExerciseByName(String name) async {
    final wanted = name.trim().toLowerCase();
    final list = await (select(exercises)
          ..where((e) => e.isCustom.equals(true)))
        .get();
    for (final e in list) {
      if (e.nameEn.trim().toLowerCase() == wanted ||
          e.nameCs.trim().toLowerCase() == wanted) {
        return e;
      }
    }
    return null;
  }

  /// Počet dokončených tréninků, které začaly v intervalu [from, to).
  Future<int> finishedSessionCount(DateTime from, DateTime to) async {
    final count = workoutSessions.id.count();
    final q = selectOnly(workoutSessions)
      ..addColumns([count])
      ..where(workoutSessions.endedAt.isNotNull() &
          workoutSessions.startedAt.isBiggerOrEqualValue(from) &
          workoutSessions.startedAt.isSmallerThanValue(to));
    return await q.map((r) => r.read(count) ?? 0).getSingle();
  }

  /// Součet vypité vody (ml) v intervalu [from, to).
  Future<int> waterTotalBetween(DateTime from, DateTime to) async {
    final total = waterEntries.amountMl.sum();
    final q = selectOnly(waterEntries)
      ..addColumns([total])
      ..where(waterEntries.loggedAt.isBiggerOrEqualValue(from) &
          waterEntries.loggedAt.isSmallerThanValue(to));
    return await q.map((r) => r.read(total) ?? 0).getSingle();
  }

  /// Cviky zapsané v tréninku (pro kartu tréninku), v pořadí zápisu.
  Future<List<Exercise>> sessionExercises(int sessionId) async {
    final sets = await (select(setEntries)
          ..where((s) => s.sessionId.equals(sessionId))
          ..orderBy([(s) => OrderingTerm.asc(s.id)]))
        .get();
    final order = <int>[];
    for (final s in sets) {
      if (!order.contains(s.exerciseId)) order.add(s.exerciseId);
    }
    final byId = {
      for (final e in await getExercisesByIds(order)) e.id: e,
    };
    return [
      for (final id in order)
        if (byId[id] != null) byId[id]!,
    ];
  }
}
