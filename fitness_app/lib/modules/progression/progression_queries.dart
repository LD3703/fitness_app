import 'package:drift/drift.dart';

import '../../core/auto_progression.dart';
import '../../data/database.dart';

/// Návrh pro jeden cvik plánu po tréninku (pro souhrn).
typedef ProgressionEntry = ({
  int eventId,
  Exercise exercise,
  ProgressionProposal proposal,
});

/// Nastavení progrese cviku z editoru plánu.
typedef ProgressionItemSettingsValue = ({
  bool auto,
  int? repRangeMin,
  int? repRangeMax,
  double? incrementKg,
});

List<TargetSet> _targetsOf(List<PlanSet> sets) => [
      for (final s in sets)
        (
          reps: s.reps,
          weightKg: s.weightKg,
          isWarmup: s.isWarmup,
          isDrop: s.isDrop,
        ),
    ];

List<PerformedSet> _performedOf(Iterable<SetEntry> sets) => [
      for (final s in sets)
        (
          weightKg: s.weightKg,
          reps: s.reps,
          durationSeconds: s.durationSeconds,
          isWarmup: s.isWarmup,
          isDrop: s.isDrop,
        ),
    ];

/// Dotazy automatické progrese (tabulka ProgressionEvents a nové sloupce
/// PlanExercises, schéma v10).
extension ProgressionQueries on AppDatabase {
  /// Spočítá návrhy pro dokončený trénink [sessionId] plánu [planId] a uloží
  /// je jako události. Starší nepoužité návrhy stejných cviků nahradí.
  /// [apply] = rovnou je zapíše do plánu (režim „použít automaticky“).
  Future<List<ProgressionEntry>> runAutoProgression(
    int sessionId,
    int planId, {
    required UnitSystem unit,
    required ProgressionBlockers blockers,
    required bool apply,
  }) async {
    final items = await getPlanItems(planId);
    final sessionSets = await getSessionSets(sessionId);
    final byExercise = <int, List<SetEntry>>{};
    for (final s in sessionSets) {
      byExercise.putIfAbsent(s.exerciseId, () => []).add(s);
    }
    for (final list in byExercise.values) {
      list.sort((a, b) => a.position.compareTo(b.position));
    }

    final now = DateTime.now();
    final result = <ProgressionEntry>[];
    final seen = <int>{};
    for (final it in items) {
      // Cvik zařazený v plánu dvakrát: série z tréninku nejdou rozlišit,
      // hodnotí se jen první výskyt.
      if (!seen.add(it.exercise.id)) continue;
      if (!it.item.autoProgression) continue;
      final performed = byExercise[it.exercise.id];
      if (performed == null || performed.isEmpty) continue;
      final previous =
          await previousSetsFor(it.exercise.id, excludeSessionId: sessionId);
      final proposal = proposeProgression(
        ProgressionInput(
          type: it.exercise.type,
          group: it.exercise.muscleGroup,
          equipment: it.exercise.equipment,
          slug: it.exercise.slug,
          targets: _targetsOf(it.sets),
          repRangeMin: it.item.repRangeMin,
          repRangeMax: it.item.repRangeMax,
          incrementKg: it.item.progressionIncrementKg,
          performed: _performedOf(performed),
          previous: _performedOf(previous),
        ),
        unit: unit,
        holdReason: blockers.reasonFor(it.exercise.muscleGroup),
      );
      if (proposal == null) continue;
      final eventId = await transaction(() async {
        await (delete(progressionEvents)
              ..where((e) =>
                  e.planExerciseId.equals(it.item.id) &
                  e.applied.equals(false)))
            .go();
        final applied = !proposal.changesPlan || apply;
        final id = await into(progressionEvents).insert(
          ProgressionEventsCompanion.insert(
            planExerciseId: it.item.id,
            sessionId: Value(sessionId),
            createdAt: now,
            kind: proposal.kind,
            oldJson: encodeProgressionState(proposal.before),
            newJson: encodeProgressionState(proposal.after, info: proposal.info),
            applied: Value(applied),
          ),
        );
        if (apply && proposal.changesPlan) {
          await _writeProgressionSnapshot(it.item.id, proposal.after);
        }
        return id;
      });
      result.add((eventId: eventId, exercise: it.exercise, proposal: proposal));
    }
    return result;
  }

  /// Zapíše stav cviku do plánu (série a rozsah opakování).
  Future<void> _writeProgressionSnapshot(
    int planExerciseId,
    ProgressionSnapshot snapshot,
  ) async {
    if (snapshot.sets.isEmpty) return;
    await (delete(planSets)
          ..where((s) => s.planExerciseId.equals(planExerciseId)))
        .go();
    for (var i = 0; i < snapshot.sets.length; i++) {
      final s = snapshot.sets[i];
      await into(planSets).insert(PlanSetsCompanion.insert(
        planExerciseId: planExerciseId,
        position: i,
        reps: s.reps,
        weightKg: Value(s.weightKg),
        isWarmup: Value(s.isWarmup),
        isDrop: Value(s.isDrop),
      ));
    }
    await (update(planExercises)..where((pe) => pe.id.equals(planExerciseId)))
        .write(PlanExercisesCompanion(
      repRangeMin: Value(snapshot.repRangeMin),
      repRangeMax: Value(snapshot.repRangeMax),
      targetSets: Value(snapshot.sets.length),
    ));
  }

  Future<ProgressionEvent?> _progressionEvent(int id) =>
      (select(progressionEvents)..where((e) => e.id.equals(id)))
          .getSingleOrNull();

  /// Platí ještě návrh? (cvik v plánu má stejné série a rozsah jako
  /// v době návrhu)
  Future<bool> _proposalStillValid(ProgressionEvent e) async {
    final before = decodeProgressionState(e.oldJson).snapshot;
    final item = await (select(planExercises)
          ..where((pe) => pe.id.equals(e.planExerciseId)))
        .getSingleOrNull();
    if (item == null ||
        item.repRangeMin != before.repRangeMin ||
        item.repRangeMax != before.repRangeMax) {
      return false;
    }
    return sameTargets(
      before.sets,
      _targetsOf(await getPlanSets(e.planExerciseId)),
    );
  }

  /// Po ruční úpravě cviku v editoru plánu zahodí návrhy, které už
  /// neodpovídají plánu.
  Future<void> dropStaleProgression(int planExerciseId) =>
      transaction(() async {
        final pending = await (select(progressionEvents)
              ..where((e) =>
                  e.planExerciseId.equals(planExerciseId) &
                  e.applied.equals(false)))
            .get();
        for (final e in pending) {
          if (!await _proposalStillValid(e)) {
            await (delete(progressionEvents)..where((x) => x.id.equals(e.id)))
                .go();
          }
        }
      });

  /// Použije návrh. Když se cvik v plánu mezitím změnil (série nebo
  /// rozsah), návrh je zastaralý: smaže se a vrátí false.
  Future<bool> applyProgressionEvent(int id) => transaction(() async {
        final e = await _progressionEvent(id);
        if (e == null) return false;
        if (e.applied) return true;
        final stale = !await _proposalStillValid(e);
        if (stale) {
          await (delete(progressionEvents)..where((x) => x.id.equals(id)))
              .go();
          return false;
        }
        await _writeProgressionSnapshot(
          e.planExerciseId,
          decodeProgressionState(e.newJson).snapshot,
        );
        await (update(progressionEvents)..where((x) => x.id.equals(id)))
            .write(const ProgressionEventsCompanion(applied: Value(true)));
        return true;
      });

  /// Vrátí použitou změnu (obnoví původní série a rozsah) a smaže ji
  /// z historie. Nepoužitý návrh jen smaže.
  Future<void> undoProgressionEvent(int id) => transaction(() async {
        final e = await _progressionEvent(id);
        if (e == null) return;
        if (e.applied && e.kind != ProgressionKind.hold) {
          await _writeProgressionSnapshot(
            e.planExerciseId,
            decodeProgressionState(e.oldJson).snapshot,
          );
        }
        await (delete(progressionEvents)..where((x) => x.id.equals(id))).go();
      });

  /// „Ponechat“: zahodí nepoužité návrhy.
  Future<void> discardProgressionEvents(Iterable<int> ids) =>
      (delete(progressionEvents)
            ..where((e) => e.id.isIn(ids) & e.applied.equals(false)))
          .go();

  /// Nepoužité návrhy cviků plánu (nejnovější pro každý cvik plánu),
  /// podle ID cviku v plánu.
  Stream<Map<int, ProgressionEvent>> watchPendingProgression(int planId) {
    final q = select(progressionEvents).join([
      innerJoin(
        planExercises,
        planExercises.id.equalsExp(progressionEvents.planExerciseId),
      ),
    ])
      ..where(planExercises.planId.equals(planId) &
          progressionEvents.applied.equals(false))
      ..orderBy([
        OrderingTerm.asc(progressionEvents.createdAt),
        OrderingTerm.asc(progressionEvents.id),
      ]);
    return q.watch().map((rows) {
      final result = <int, ProgressionEvent>{};
      for (final r in rows) {
        final e = r.readTable(progressionEvents);
        result[e.planExerciseId] = e;
      }
      return result;
    });
  }

  /// Poslední použitá změna (nebo „drží“) cviku v plánu.
  Stream<ProgressionEvent?> watchLastProgressionEvent(int planExerciseId) =>
      (select(progressionEvents)
            ..where((e) =>
                e.planExerciseId.equals(planExerciseId) &
                e.applied.equals(true))
            ..orderBy([
              (e) => OrderingTerm.desc(e.createdAt),
              (e) => OrderingTerm.desc(e.id),
            ])
            ..limit(1))
          .watchSingleOrNull();

  /// Uloží nastavení progrese cviku z editoru plánu.
  Future<void> saveProgressionSettings(
    int planExerciseId,
    ProgressionItemSettingsValue value,
  ) =>
      (update(planExercises)..where((pe) => pe.id.equals(planExerciseId)))
          .write(PlanExercisesCompanion(
        autoProgression: Value(value.auto),
        repRangeMin: Value(value.repRangeMin),
        repRangeMax: Value(value.repRangeMax),
        progressionIncrementKg: Value(value.incrementKg),
      ));
}
