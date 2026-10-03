import '../../core/formulas.dart';
import '../../data/database.dart';

/// Data jednoho cviku v tréninku, jak se načtou z databáze.
class WorkoutBlockData {
  WorkoutBlockData({
    required this.exercise,
    required this.targets,
    required this.restSeconds,
    required this.previous,
    required this.saved,
    required this.record,
  });

  final Exercise exercise;

  /// Cílové série z plánu (opakování, váha, rozcvička).
  final List<PlanSetDraft> targets;
  final int restSeconds;

  /// Osobní rekord cviku z předchozích tréninků.
  final ExerciseRecord? record;

  /// Série z posledního dokončeného tréninku (pro předvyplnění a „minule“).
  final List<SetEntry> previous;

  /// Série už zapsané v tomto tréninku (při pokračování).
  final List<SetEntry> saved;
}

class WorkoutSetup {
  WorkoutSetup({
    required this.session,
    required this.planName,
    required this.blocks,
  });

  final WorkoutSession session;
  final String? planName;
  final List<WorkoutBlockData> blocks;
}

const defaultRestSeconds = 90;

/// Načte vše potřebné pro obrazovku tréninku: cviky z plánu, už zapsané
/// série a hodnoty z minula. Cviky přidané během tréninku (mimo plán)
/// jsou zařazeny na konec.
Future<WorkoutSetup> loadWorkoutSetup(AppDatabase db, int sessionId) async {
  final session = await db.getSession(sessionId);
  final planId = session.planId;
  final planItems =
      planId == null ? <PlanItem>[] : await db.getPlanItems(planId);
  final planName =
      planId == null ? null : (await db.watchPlan(planId).first)?.name;
  final saved = await db.getSessionSets(sessionId);

  final savedByExercise = <int, List<SetEntry>>{};
  for (final s in saved) {
    savedByExercise.putIfAbsent(s.exerciseId, () => []).add(s);
  }

  final blocks = <WorkoutBlockData>[];
  final usedIds = <int>{};

  for (final it in planItems) {
    usedIds.add(it.exercise.id);
    blocks.add(WorkoutBlockData(
      exercise: it.exercise,
      targets: [
        for (final s in it.sets)
          (reps: s.reps, weightKg: s.weightKg, isWarmup: s.isWarmup),
      ],
      restSeconds: it.item.restSeconds,
      previous: await db.previousSetsFor(it.exercise.id,
          excludeSessionId: sessionId),
      saved: savedByExercise[it.exercise.id] ?? const [],
      record: await db.exerciseRecord(it.exercise.id,
          excludeSessionId: sessionId),
    ));
  }

  final extraIds = [
    for (final id in savedByExercise.keys)
      if (!usedIds.contains(id)) id,
  ];
  if (extraIds.isNotEmpty) {
    final extras = await db.getExercisesByIds(extraIds);
    for (final e in extras) {
      blocks.add(await loadExtraBlock(db, sessionId, e,
          saved: savedByExercise[e.id] ?? const []));
    }
  }

  return WorkoutSetup(session: session, planName: planName, blocks: blocks);
}

/// Blok pro cvik přidaný během tréninku (mimo plán).
Future<WorkoutBlockData> loadExtraBlock(
  AppDatabase db,
  int sessionId,
  Exercise exercise, {
  List<SetEntry> saved = const [],
}) async =>
    WorkoutBlockData(
      exercise: exercise,
      targets: AppDatabase.defaultPlanSets,
      restSeconds: defaultRestSeconds,
      previous:
          await db.previousSetsFor(exercise.id, excludeSessionId: sessionId),
      saved: saved,
      record: await db.exerciseRecord(exercise.id, excludeSessionId: sessionId),
    );

/// Nový osobní rekord (odhad 1RM) dosažený v tréninku.
class PersonalRecord {
  PersonalRecord(this.exercise, this.newOneRepMax, this.previousOneRepMax);

  final Exercise exercise;
  final double newOneRepMax;
  final double previousOneRepMax;
}

class WorkoutSummary {
  WorkoutSummary({
    required this.sessionId,
    required this.startedAt,
    required this.duration,
    required this.setCount,
    required this.volumeKg,
    required this.estimatedKcal,
    required this.records,
  });

  final int sessionId;
  final DateTime startedAt;
  final Duration duration;
  final int setCount;
  final double volumeKg;
  final double? estimatedKcal;
  final List<PersonalRecord> records;
}

/// Ukončí trénink: spočítá souhrn, odhad kalorií a nové osobní rekordy.
/// Rekord se hlásí jen při překonání předchozího výkonu – první zápis
/// cviku rekordem není.
Future<WorkoutSummary> finishWorkout(AppDatabase db, int sessionId) async {
  final session = await db.getSession(sessionId);
  final sets = (await db.getSessionSets(sessionId))
      .where((s) => !s.isWarmup)
      .toList();
  final exercises = {
    for (final e in await db.getExercisesByIds(sets.map((s) => s.exerciseId)))
      e.id: e,
  };

  final duration = DateTime.now().difference(session.startedAt);

  var volume = 0.0;
  var metSum = 0.0;
  final bestInSession = <int, double>{};
  for (final s in sets) {
    metSum += exercises[s.exerciseId]?.met ?? 5.0;
    final w = s.weightKg;
    final r = s.reps;
    if (w != null && r != null) {
      volume += w * r;
      final e1rm = estimateOneRepMax(w, r);
      if (e1rm != null && e1rm > (bestInSession[s.exerciseId] ?? 0)) {
        bestInSession[s.exerciseId] = e1rm;
      }
    }
  }

  final bodyWeight = (await db.watchLatestWeight().first)?.weightKg;
  final kcal = (bodyWeight == null || sets.isEmpty)
      ? null
      : estimateKcal(
          met: metSum / sets.length,
          bodyWeightKg: bodyWeight,
          duration: duration,
        );

  final records = <PersonalRecord>[];
  for (final entry in bestInSession.entries) {
    final before = (await db.exerciseRecord(entry.key,
            excludeSessionId: sessionId))
        ?.oneRepMax;
    final exercise = exercises[entry.key];
    if (before != null && exercise != null && entry.value > before + 0.01) {
      records.add(PersonalRecord(exercise, entry.value, before));
    }
  }

  await db.finishSession(sessionId, estimatedKcal: kcal);

  return WorkoutSummary(
    sessionId: sessionId,
    startedAt: session.startedAt,
    duration: duration,
    setCount: sets.length,
    volumeKg: volume,
    estimatedKcal: kcal,
    records: records,
  );
}
