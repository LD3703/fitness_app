import 'package:drift/drift.dart';

import '../../core/formulas.dart';
import '../../core/muscle_sets.dart';
import '../../core/readiness.dart';
import '../../core/rest_time.dart';
import '../../data/database.dart';

// ---------------------------------------------------------------------
// Stejný cvik v tréninku víckrát (sloty)
// ---------------------------------------------------------------------
//
// Série se v databázi rozlišují jen tréninkem, cvikem a pozicí. Když je
// stejný cvik v jednom tréninku víckrát (v plánu dvakrát, nebo ho
// uživatel přidá znovu tlačítkem „Přidat cvik“), dřív oba výskyty
// zapisovaly pozice 0, 1, 2… a po návratu do tréninku dostaly oba bloky
// stejné uložené série (a série se stejnou pozicí se slily do jedné).
//
// Bez změny schématu to řeší „sloty“: k-tý výskyt cviku v tréninku
// (od 0) ukládá řádek i na pozici k * [blockPositionStride] + i. Pozice
// se tak mezi výskyty nikdy nesrazí a při načtení se uložené série
// rozdělí zpět do bloků podle position ~/ [blockPositionStride]. První
// výskyt má pozice 0, 1, 2… jako dřív, takže běžné tréninky i starší
// data se nemění. Řazení podle pozice (statistiky, minulé série) dá
// nejdřív série prvního výskytu, pak druhého atd.

/// Rozestup pozic mezi výskyty (sloty) stejného cviku v jednom tréninku.
/// Víc řádků než [blockPositionStride] jeden cvik mít nemůže.
const blockPositionStride = 1000;

/// Slot (pořadí výskytu cviku v tréninku) podle uložené pozice série.
int blockSlotOf(int position) => position ~/ blockPositionStride;

/// Řádek v bloku podle uložené pozice série.
int blockRowOf(int position) => position % blockPositionStride;

/// Pozice série pro řádek [row] bloku ve slotu [slot].
int setPositionFor(int slot, int row) => slot * blockPositionStride + row;

/// Série z minula pro výskyt cviku ve slotu [slot]: série stejného
/// výskytu z minulého tréninku; když tam cvik byl jen jednou, série
/// prvního výskytu.
List<SetEntry> previousSetsForSlot(List<SetEntry> previous, int slot) {
  for (final s in {slot, 0}) {
    final list = [
      for (final e in previous)
        if (blockSlotOf(e.position) == s) e,
    ];
    if (list.isNotEmpty) return list;
  }
  return previous;
}

/// Zápisy sérií jednoho bloku (výskytu cviku) v tréninku.
extension WorkoutSetQueries on AppDatabase {
  /// Supersérie zapsaná jen k sériím [setIds] (jednomu bloku) – stejný
  /// cvik může být v tréninku víckrát a každý výskyt má vlastní skupinu
  /// (setSessionSupersetGroup by přepsal všechny výskyty najednou).
  Future<void> setSetsSupersetGroup(Iterable<int> setIds, int? group) async {
    final ids = setIds.toList();
    if (ids.isEmpty) return;
    await (update(setEntries)..where((e) => e.id.isIn(ids)))
        .write(SetEntriesCompanion(supersetGroup: Value(group)));
  }
}

/// Data jednoho cviku v tréninku, jak se načtou z databáze.
class WorkoutBlockData {
  WorkoutBlockData({
    required this.exercise,
    required this.targets,
    this.manualRestSeconds,
    required this.previous,
    required this.saved,
    required this.record,
    this.supersetGroup,
    this.slot = 0,
    this.planNote,
  });

  final Exercise exercise;

  /// Poznámka ke cviku v plánu (u plánu od trenéra od trenéra). Moje
  /// poznámka ke cviku je v [Exercise.note].
  final String? planNote;

  /// Pořadí výskytu cviku v tréninku (0 = první), viz [blockPositionStride].
  final int slot;

  /// Cílové série z plánu (opakování, váha, rozcvička, drop série).
  final List<PlanSetDraft> targets;

  /// Pauza nastavená ručně u cviku v plánu; null = automaticky podle
  /// cviku, zaměření tréninku a pohlaví (core/rest_time.dart).
  final int? manualRestSeconds;

  bool get restIsAuto => manualRestSeconds == null;

  /// Pauza po sérii tohoto cviku.
  int restSecondsFor(TrainingFocus focus, Sex? sex) =>
      manualRestSeconds ?? autoRestSeconds(exercise, focus, sex);

  /// Supersérie: z plánu, nebo z už uložených sérií (propojení během
  /// tréninku). null = samostatný cvik.
  final int? supersetGroup;

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
    required this.focus,
    this.sex,
    this.planTrainer,
  });

  /// Lehčí trénink kvůli slabší regeneraci (core/readiness.dart): méně
  /// pracovních sérií (už v [blocks]) a váhy −10 %.
  bool get light => session.light;

  final WorkoutSession session;
  final String? planName;

  /// Jméno trenéra, když je plán od trenéra (poznámky v plánu jsou jeho).
  final String? planTrainer;
  final List<WorkoutBlockData> blocks;

  /// Zaměření tréninku (síla / svaly / kondice) – určuje automatické pauzy.
  final TrainingFocus focus;

  /// Pohlaví z profilu (null = neuvedeno).
  final Sex? sex;
}

/// Lehčí trénink: o třetinu méně pracovních sérií (core/readiness.dart).
List<PlanSetDraft> _lighterIf(bool light, List<PlanSetDraft> targets) => light
    ? lighterTargets(targets, isWorking: (t) => !t.isWarmup && !t.isDrop)
    : targets;

/// Rozhodnutí před tréninkem podle plánu (kontroly modulů, např.
/// připravenost z hodinek a prstenů).
enum WorkoutStartDecision {
  /// Trénovat podle plánu.
  proceed,

  /// Lehčí trénink (WorkoutSession.light).
  light,

  /// Netrénovat teď (uživatel zvolil Plán B nebo dialog zavřel).
  cancel,
}

/// Automatická pauza po sérii cviku [exercise] (core/rest_time.dart).
int autoRestSeconds(Exercise exercise, TrainingFocus focus, Sex? sex) =>
    recommendedRestSeconds(
      restTierOf(
        slug: exercise.slug,
        group: exercise.muscleGroup,
        equipment: exercise.equipment,
        type: exercise.type,
      ),
      focus,
      sex: sex,
    );

/// Supersérie cviku podle už uložených sérií (poslední zapsaná série má
/// aktuální stav – při propojení během tréninku se přepíší všechny).
int? _savedSupersetGroup(List<SetEntry> saved) {
  if (saved.isEmpty) return null;
  return saved.reduce((a, b) => a.id > b.id ? a : b).supersetGroup;
}

/// Načte vše potřebné pro obrazovku tréninku: cviky z plánu, už zapsané
/// série a hodnoty z minula. Cviky přidané během tréninku (mimo plán)
/// jsou zařazeny na konec v pořadí, v jakém byly poprvé zapsány.
/// Uložené série se přiřazují k blokům podle cviku a slotu (viz
/// [blockPositionStride]), takže cvik zařazený víckrát dostane do každého
/// bloku jen jeho vlastní série.
Future<WorkoutSetup> loadWorkoutSetup(AppDatabase db, int sessionId) async {
  final session = await db.getSession(sessionId);
  final planId = session.planId;
  final planItems =
      planId == null ? <PlanItem>[] : await db.getPlanItems(planId);
  final plan = planId == null ? null : await db.watchPlan(planId).first;
  final planName = plan?.name;
  final planTrainer = (plan?.remoteId?.startsWith('coach:') ?? false)
      ? plan?.remoteFrom
      : null;
  final saved = await db.getSessionSets(sessionId);
  final profile = await db.watchProfile().first;

  // Uložené série podle (cvik, slot).
  final savedByBlock = <(int, int), List<SetEntry>>{};
  for (final s in saved) {
    savedByBlock
        .putIfAbsent((s.exerciseId, blockSlotOf(s.position)), () => [])
        .add(s);
  }

  // Minulé série a rekord stačí načíst jednou na cvik.
  final previousByExercise = <int, List<SetEntry>>{};
  Future<List<SetEntry>> previousOf(int exerciseId) async =>
      previousByExercise[exerciseId] ??=
          await db.previousSetsFor(exerciseId, excludeSessionId: sessionId);

  final blocks = <WorkoutBlockData>[];
  final nextSlot = <int, int>{};

  // Cviky plánu odebrané z tréninku (AppDatabase.removeSessionBlock).
  final skipped = {
    ...?session.skippedBlocks?.split(',').where((e) => e.isNotEmpty),
  };

  for (final it in planItems) {
    final exerciseId = it.exercise.id;
    final slot = nextSlot[exerciseId] ?? 0;
    nextSlot[exerciseId] = slot + 1;
    if (skipped.contains('$exerciseId:$slot')) continue;
    final saved =
        savedByBlock.remove((exerciseId, slot)) ?? const <SetEntry>[];
    blocks.add(WorkoutBlockData(
      exercise: it.exercise,
      slot: slot,
      targets: _lighterIf(session.light, [
        for (final s in it.sets)
          (
            reps: s.reps,
            weightKg: s.weightKg,
            isWarmup: s.isWarmup,
            isDrop: s.isDrop,
          ),
      ]),
      manualRestSeconds: it.item.restAuto ? null : it.item.restSeconds,
      previous: previousSetsForSlot(await previousOf(exerciseId), slot),
      saved: saved,
      record: await db.exerciseRecord(exerciseId,
          excludeSessionId: sessionId),
      supersetGroup: saved.isEmpty
          ? it.item.supersetGroup
          : _savedSupersetGroup(saved),
      planNote: it.item.note,
    ));
  }

  // Zbylé (cvik, slot) = cviky přidané během tréninku (mimo plán, nebo
  // další výskyt cviku z plánu).
  if (savedByBlock.isNotEmpty) {
    // Pořadí podle první zapsané série, aby propojené cviky zůstaly u sebe.
    int firstId((int, int) key) => savedByBlock[key]!
        .map((s) => s.id)
        .reduce((a, b) => a < b ? a : b);
    final keys = savedByBlock.keys.toList()
      ..sort((a, b) => firstId(a).compareTo(firstId(b)));
    final exercises = {
      for (final e in await db.getExercisesByIds({for (final k in keys) k.$1}))
        e.id: e,
    };
    for (final key in keys) {
      final e = exercises[key.$1];
      if (e == null) continue;
      blocks.add(await loadExtraBlock(db, sessionId, e,
          slot: key.$2, saved: savedByBlock[key]!));
    }
  }

  return WorkoutSetup(
    session: session,
    planName: planName,
    planTrainer: planTrainer,
    blocks: blocks,
    focus: session.focus ?? trainingFocusOf(profile.trainingFocus),
    sex: sexOf(profile.sex),
  );
}

/// Blok pro cvik přidaný během tréninku (mimo plán, nebo další výskyt
/// cviku, který už v tréninku je – pak má [slot] > 0).
Future<WorkoutBlockData> loadExtraBlock(
  AppDatabase db,
  int sessionId,
  Exercise exercise, {
  int slot = 0,
  List<SetEntry> saved = const [],
}) async =>
    WorkoutBlockData(
      exercise: exercise,
      slot: slot,
      targets: AppDatabase.defaultPlanSets,
      previous: previousSetsForSlot(
        await db.previousSetsFor(exercise.id, excludeSessionId: sessionId),
        slot,
      ),
      saved: saved,
      record: await db.exerciseRecord(exercise.id, excludeSessionId: sessionId),
      supersetGroup: _savedSupersetGroup(saved),
    );

/// Nový osobní rekord (nejtěžší série) dosažený v tréninku.
class PersonalRecord {
  PersonalRecord(
    this.exercise,
    this.newBest,
    this.previousBest, {
    required this.weightKg,
    required this.reps,
    required this.previousWeightKg,
    required this.previousReps,
  });

  final Exercise exercise;

  /// [recordValue] nové a předchozí rekordní série.
  final double newBest;
  final double previousBest;

  /// Nová rekordní série.
  final double weightKg;
  final int reps;

  /// Předchozí rekordní série.
  final double previousWeightKg;
  final int previousReps;
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
    this.muscles = emptyMuscleSets,
  });

  final int sessionId;
  final DateTime startedAt;
  final Duration duration;
  final int setCount;
  final double volumeKg;
  final double? estimatedKcal;
  final List<PersonalRecord> records;

  /// Procvičené partie (hlavní a vedlejší) – mapa těla v souhrnu.
  final MuscleSets muscles;
}

/// Nejdelší započítaný trénink. Zapomenutý trénink ukončený až druhý den
/// by jinak poslal do Zdraví a statistik desítky hodin a tisíce kcal.
const kMaxWorkoutDuration = Duration(hours: 4);

/// Délka tréninku k uložení: od začátku do teď, nejvýš [kMaxWorkoutDuration].
Duration workoutDuration(DateTime startedAt, DateTime now) {
  final d = now.difference(startedAt);
  if (d.isNegative) return Duration.zero;
  return d > kMaxWorkoutDuration ? kMaxWorkoutDuration : d;
}

/// Ukončí trénink: spočítá souhrn, odhad kalorií a nové osobní rekordy.
/// Rekord se hlásí jen při překonání předchozího výkonu – první zápis
/// cviku rekordem není. Drop série se počítají do objemu a počtu sérií,
/// ne do rekordů.
Future<WorkoutSummary> finishWorkout(AppDatabase db, int sessionId) async {
  final session = await db.getSession(sessionId);
  final sets = (await db.getSessionSets(sessionId))
      .where((s) => !s.isWarmup)
      .toList();
  final exercises = {
    for (final e in await db.getExercisesByIds(sets.map((s) => s.exerciseId)))
      e.id: e,
  };

  final duration = workoutDuration(session.startedAt, DateTime.now());

  var volume = 0.0;
  var metSum = 0.0;
  final bestInSession = <int, ({double value, double weightKg, int reps})>{};
  for (final s in sets) {
    metSum += exercises[s.exerciseId]?.met ?? 5.0;
    final w = s.weightKg;
    final r = s.reps;
    if (w != null && r != null) {
      volume += w * r;
      if (s.isDrop) continue;
      final value = recordValue(w, r);
      if (value != null &&
          value > (bestInSession[s.exerciseId]?.value ?? 0)) {
        bestInSession[s.exerciseId] = (value: value, weightKg: w, reps: r);
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
    final before =
        await db.exerciseRecord(entry.key, excludeSessionId: sessionId);
    final exercise = exercises[entry.key];
    final best = entry.value;
    // Těžší váha, nebo stejná váha na víc opakování (recordValue).
    if (before != null && exercise != null && best.value > before.value) {
      records.add(PersonalRecord(
        exercise,
        best.value,
        before.value,
        weightKg: best.weightKg,
        reps: best.reps,
        previousWeightKg: before.weightKg,
        previousReps: before.reps,
      ));
    }
  }

  await db.finishSession(
    sessionId,
    estimatedKcal: kcal,
    endedAt: session.startedAt.add(duration),
  );

  return WorkoutSummary(
    sessionId: sessionId,
    startedAt: session.startedAt,
    duration: duration,
    setCount: sets.length,
    volumeKg: volume,
    estimatedKcal: kcal,
    records: records,
    muscles: muscleSetsOf([
      for (final id in {for (final s in sets) s.exerciseId})
        if (exercises[id] != null) exercises[id]!,
    ]),
  );
}
