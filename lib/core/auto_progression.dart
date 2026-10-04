// Automatická progrese cílů v plánu (čistý Dart, testy:
// test/auto_progression_test.dart).
//
// Po tréninku z plánu aplikace navrhne nové cíle pro příští trénink
// stejného plánu. Výchozí model je „dvojitá progrese“ po cvicích plánu:
// - každý cvik má rozsah opakování min–max (z plánu, jinak odvozený
//   z cílových opakování první pracovní série: min = cíl, max = cíl + 2
//   pro cíl ≤ 8, jinak cíl + 4),
// - hodnotí se jen pracovní série (bez rozcvičky a drop sérií), v pořadí,
//   série tréninku se párují se sériemi plánu,
// - VŠECHNY pracovní série na horní hranici rozsahu s cílovou vahou →
//   váha + přírůstek (výchozí podle partie a vybavení, viz
//   [defaultIncrementKg]) a opakování zpět na spodní hranici,
// - všechny série splnily cílová opakování, ale ne horní hranici → +1
//   opakování (nejvýš do horní hranice),
// - 2 tréninky po sobě nedosáhly spodní hranice se stejnou vahou →
//   odlehčení o 10 % (zaokrouhleno na krok kotoučů) a opakování na spodní
//   hranici,
// - jinak beze změny.
// Cviky s vlastní vahou: +1 opakování, cviky na čas: +5 s, když všechny
// pracovní série splnily cíl (bez odlehčení).
//
// Při nemoci, do 7 dní po nemoci, u zraněné partie a v dietě (cut) se nic
// nezvyšuje (ani váha, ani opakování) – návrh je „drží“ s důvodem.
// Odlehčení se povolí vždy. Únava svalů progresi neblokuje.

import 'dart:convert';

import '../data/enums.dart';
import 'date_utils.dart';
import 'formulas.dart';
import 'wellbeing.dart';

/// Identifikátor placené funkce (premium gating).
const autoProgressionFeatureId = 'autoProgression';

/// Odlehčení po opakovaném nesplnění: o 10 %.
const deloadFraction = 0.10;

/// Přírůstek u cviků na čas (sekundy na sérii).
const durationIncrementSeconds = 5;

/// Přírůstek u cviků s vlastní vahou (opakování na sérii).
const bodyweightIncrementReps = 1;

const double _kgPerLb = 0.45359237;
const double _eps = 0.01;

/// Režim z profilu (UserProfile.progressionMode):
/// 0 = vypnuto, 1 = navrhovat (výchozí), 2 = použít automaticky.
enum ProgressionMode { off, suggest, auto }

ProgressionMode progressionModeOf(int? value) => switch (value) {
      0 => ProgressionMode.off,
      2 => ProgressionMode.auto,
      _ => ProgressionMode.suggest,
    };

int progressionModeValue(ProgressionMode mode) => switch (mode) {
      ProgressionMode.off => 0,
      ProgressionMode.suggest => 1,
      ProgressionMode.auto => 2,
    };

/// Cílová série plánu (stejný tvar jako PlanSetDraft v database.dart).
typedef TargetSet = ({int reps, double? weightKg, bool isWarmup, bool isDrop});

/// Odcvičená série z tréninku.
typedef PerformedSet = ({
  double? weightKg,
  int? reps,
  int? durationSeconds,
  bool isWarmup,
  bool isDrop,
});

/// Rozsah opakování (u cviků na čas sekund) včetně obou hranic.
typedef RepRange = ({int min, int max});

bool _isWorking(TargetSet s) => !s.isWarmup && !s.isDrop;

/// Výchozí rozsah z cílových opakování: cíl až cíl + 2 (cíl ≤ 8),
/// jinak cíl až cíl + 4.
RepRange defaultRepRange(int targetReps) {
  final min = targetReps < 1 ? 1 : targetReps;
  return (min: min, max: min + (min <= 8 ? 2 : 4));
}

/// Rozsah, který se použije: z plánu ([min], [max]), chybějící hranice se
/// odvodí z cílových opakování první pracovní série.
RepRange effectiveRepRange(List<TargetSet> targets, {int? min, int? max}) {
  final TargetSet first = targets.where(_isWorking).firstOrNull ??
      targets.firstOrNull ??
      (reps: 10, weightKg: null, isWarmup: false, isDrop: false);
  if (min != null && max != null) {
    return min <= max ? (min: min, max: max) : (min: max, max: min);
  }
  if (min != null) return defaultRepRange(min);
  final d = defaultRepRange(first.reps);
  if (max != null) {
    final lo = d.min <= max ? d.min : max;
    return (min: lo < 1 ? 1 : lo, max: max);
  }
  return d;
}

bool _isLowerBody(MuscleGroup group, String? slug) =>
    group == MuscleGroup.legs ||
    group == MuscleGroup.glutes ||
    (slug?.contains('deadlift') ?? false);

/// Výchozí přírůstek váhy v kg.
/// Metricky: horní polovina těla s činkou / strojem 2,5 kg, dolní (nohy,
/// hýždě, mrtvý tah) 5 kg, jednoruční činky 2 kg, kettlebell 4 kg, kladka
/// a ostatní 2,5 kg. V librách 5 / 10 / 5 lb.
double defaultIncrementKg({
  required MuscleGroup group,
  required Equipment equipment,
  String? slug,
  required UnitSystem unit,
}) {
  final lower = _isLowerBody(group, slug);
  if (unit == UnitSystem.imperial) {
    final lb = switch (equipment) {
      Equipment.dumbbell || Equipment.kettlebell => 5.0,
      Equipment.barbell || Equipment.machine => lower ? 10.0 : 5.0,
      _ => 5.0,
    };
    return lb * _kgPerLb;
  }
  return switch (equipment) {
    Equipment.dumbbell => 2.0,
    Equipment.kettlebell => 4.0,
    Equipment.barbell || Equipment.machine => lower ? 5.0 : 2.5,
    _ => 2.5,
  };
}

/// Krok zaokrouhlení nových vah v kg: metricky činky 1 kg, kettlebell
/// 2 kg, jinak 2,5 kg; v librách 5 lb. Nikdy větší než přírůstek, aby
/// vlastní menší přírůstek (např. 1,25 kg) zůstal zachovaný.
double roundingStepKg(Equipment equipment, UnitSystem unit, double incrementKg) {
  final base = unit == UnitSystem.imperial
      ? 5 * _kgPerLb
      : switch (equipment) {
          Equipment.dumbbell => 1.0,
          Equipment.kettlebell => 2.0,
          _ => 2.5,
        };
  if (incrementKg > 0 && incrementKg < base) return incrementKg;
  return base;
}

double _round4(double v) => (v * 10000).round() / 10000;

/// Váha po zvýšení: zaokrouhlená na krok, vždy vyšší než [ref].
double increasedWeight(double ref, double incrementKg, double stepKg) {
  final step = stepKg > 0 ? stepKg : incrementKg;
  var w = roundToStep(ref + incrementKg, step: step);
  if (step <= 0) return _round4(ref + incrementKg);
  while (w <= ref + _eps) {
    w += step;
  }
  return _round4(w);
}

/// Váha po odlehčení o 10 %: zaokrouhlená na krok, vždy nižší než [ref]
/// (pokud to jde – u velmi malých vah zůstane [ref]).
double deloadedWeight(double ref, double stepKg) {
  var w = roundToStep(ref * (1 - deloadFraction), step: stepKg);
  if (w >= ref - _eps) w -= stepKg;
  if (w <= 0) return ref;
  return _round4(w);
}

// ---------------------------------------------------------------------
// Co progresi blokuje
// ---------------------------------------------------------------------

/// Proč se nezvyšuje (podle priority).
enum HoldReason { illness, recovery, injury, cut }

/// Období pro určení blokací (stejný tvar jako vstup activeInjuredGroups).
typedef ProgressionPeriod = ({
  PeriodType type,
  DateTime start,
  DateTime? end,
  Set<MuscleGroup> groups,
});

class ProgressionBlockers {
  const ProgressionBlockers({
    this.illness = false,
    this.recovery = false,
    this.cut = false,
    this.injured = const {},
    this.injuredAll = false,
  });

  static const none = ProgressionBlockers();

  final bool illness;

  /// Do 7 dní po skončení nemoci.
  final bool recovery;
  final bool cut;

  /// Zraněné partie.
  final Set<MuscleGroup> injured;

  /// Zranění bez zadané partie (starší záznamy) – platí pro všechny cviky.
  final bool injuredAll;

  /// Důvod, proč se u cviku na partii [group] nezvyšuje, nebo null.
  HoldReason? reasonFor(MuscleGroup group) {
    if (illness) return HoldReason.illness;
    if (recovery) return HoldReason.recovery;
    if (injuredAll ||
        injured.contains(group) ||
        (group == MuscleGroup.fullBody && injured.isNotEmpty)) {
      return HoldReason.injury;
    }
    if (cut) return HoldReason.cut;
    return null;
  }
}

/// Blokace k datu [now] podle zapsaných období.
ProgressionBlockers progressionBlockersFrom(
  Iterable<ProgressionPeriod> periods,
  DateTime now,
) {
  final list = periods.toList();
  final today = startOfDay(now);
  bool active(ProgressionPeriod p) =>
      !startOfDay(p.start).isAfter(today) &&
      (p.end == null || !startOfDay(p.end!).isBefore(today));
  PeriodSpan span(ProgressionPeriod p) =>
      (type: p.type, start: p.start, end: p.end);

  final illnessOnly = [
    for (final p in list)
      if (p.type == PeriodType.illness) span(p),
  ];
  final illnessSituation = determineSituation(illnessOnly, now);
  final injuries = [
    for (final p in list)
      if (p.type == PeriodType.injury && active(p)) p,
  ];
  return ProgressionBlockers(
    illness: illnessSituation == WellbeingSituation.illness,
    recovery: illnessSituation == WellbeingSituation.recovery,
    cut: list.any((p) => p.type == PeriodType.cut && active(p)),
    injured: {for (final p in injuries) ...p.groups},
    injuredAll: injuries.any((p) => p.groups.isEmpty),
  );
}

// ---------------------------------------------------------------------
// Stav plánu a návrh
// ---------------------------------------------------------------------

/// Stav cviku v plánu (série a rozsah), ukládá se jako JSON do
/// ProgressionEvents.oldJson / newJson kvůli vrácení změny a historii.
class ProgressionSnapshot {
  const ProgressionSnapshot({
    required this.sets,
    this.repRangeMin,
    this.repRangeMax,
  });

  final List<TargetSet> sets;
  final int? repRangeMin;
  final int? repRangeMax;

  Map<String, Object?> toJson() => {
        'sets': [
          for (final s in sets)
            {
              'reps': s.reps,
              'weightKg': s.weightKg,
              'isWarmup': s.isWarmup,
              'isDrop': s.isDrop,
            },
        ],
        'repRangeMin': repRangeMin,
        'repRangeMax': repRangeMax,
      };

  static ProgressionSnapshot fromJson(Map<String, Object?> json) {
    final raw = json['sets'];
    return ProgressionSnapshot(
      sets: [
        if (raw is List)
          for (final s in raw)
            if (s is Map)
              (
                reps: (s['reps'] as num?)?.toInt() ?? 10,
                weightKg: (s['weightKg'] as num?)?.toDouble(),
                isWarmup: s['isWarmup'] == true,
                isDrop: s['isDrop'] == true,
              ),
      ],
      repRangeMin: (json['repRangeMin'] as num?)?.toInt(),
      repRangeMax: (json['repRangeMax'] as num?)?.toInt(),
    );
  }
}

/// Údaje pro zobrazení změny („80 → 82,5 kg × 6“, „+1 opakování“…).
class ProgressionInfo {
  const ProgressionInfo({
    this.fromKg,
    this.toKg,
    required this.reps,
    this.delta = 0,
    this.isDuration = false,
    this.holdReason,
    this.blocked,
  });

  /// Pracovní váha první pracovní série před / po změně.
  final double? fromKg;
  final double? toKg;

  /// Cílová opakování (sekundy) první pracovní série po změně.
  final int reps;

  /// Přírůstek opakování / sekund (u ProgressionKind.reps).
  final int delta;
  final bool isDuration;

  /// U „drží“: důvod a co by se jinak stalo.
  final HoldReason? holdReason;
  final ProgressionKind? blocked;

  Map<String, Object?> toJson() => {
        'fromKg': fromKg,
        'toKg': toKg,
        'reps': reps,
        'delta': delta,
        'isDuration': isDuration,
        'holdReason': holdReason?.name,
        'blocked': blocked?.name,
      };

  static ProgressionInfo fromJson(Map<String, Object?> json) {
    T? byName<T extends Enum>(List<T> values, Object? name) =>
        values.where((v) => v.name == name).firstOrNull;
    return ProgressionInfo(
      fromKg: (json['fromKg'] as num?)?.toDouble(),
      toKg: (json['toKg'] as num?)?.toDouble(),
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      delta: (json['delta'] as num?)?.toInt() ?? 0,
      isDuration: json['isDuration'] == true,
      holdReason: byName(HoldReason.values, json['holdReason']),
      blocked: byName(ProgressionKind.values, json['blocked']),
    );
  }
}

/// Zakóduje stav (a u nového stavu i údaje pro zobrazení) do JSON.
String encodeProgressionState(ProgressionSnapshot s, {ProgressionInfo? info}) =>
    jsonEncode({
      ...s.toJson(),
      if (info != null) 'info': info.toJson(),
    });

/// Opak [encodeProgressionState]. Poškozený JSON → prázdný stav.
({ProgressionSnapshot snapshot, ProgressionInfo? info}) decodeProgressionState(
  String json,
) {
  try {
    final map = jsonDecode(json);
    if (map is! Map) throw const FormatException();
    final m = map.cast<String, Object?>();
    final info = m['info'];
    return (
      snapshot: ProgressionSnapshot.fromJson(m),
      info: info is Map
          ? ProgressionInfo.fromJson(info.cast<String, Object?>())
          : null,
    );
  } catch (_) {
    return (snapshot: const ProgressionSnapshot(sets: []), info: null);
  }
}

/// Mají dva seznamy sérií stejné cíle? (váhy s tolerancí 0,01 kg)
bool sameTargets(List<TargetSet> a, List<TargetSet> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final x = a[i];
    final y = b[i];
    if (x.reps != y.reps || x.isWarmup != y.isWarmup || x.isDrop != y.isDrop) {
      return false;
    }
    final wx = x.weightKg;
    final wy = y.weightKg;
    if ((wx == null) != (wy == null)) return false;
    if (wx != null && wy != null && (wx - wy).abs() > _eps) return false;
  }
  return true;
}

/// Vstup pro jeden cvik plánu.
class ProgressionInput {
  const ProgressionInput({
    required this.type,
    required this.group,
    required this.equipment,
    this.slug,
    required this.targets,
    this.repRangeMin,
    this.repRangeMax,
    this.incrementKg,
    required this.performed,
    this.previous = const [],
  });

  final ExerciseType type;
  final MuscleGroup group;
  final Equipment equipment;
  final String? slug;

  /// Cílové série z plánu (v pořadí).
  final List<TargetSet> targets;

  /// Rozsah z plánu (null = odvodit).
  final int? repRangeMin;
  final int? repRangeMax;

  /// Vlastní přírůstek v kg (null = výchozí).
  final double? incrementKg;

  /// Série cviku z právě dokončeného tréninku (v pořadí).
  final List<PerformedSet> performed;

  /// Série cviku z předchozího dokončeného tréninku (pro odlehčení).
  final List<PerformedSet> previous;
}

/// Navržená změna cílů jednoho cviku plánu.
class ProgressionProposal {
  const ProgressionProposal({
    required this.kind,
    required this.before,
    required this.after,
    required this.info,
  });

  final ProgressionKind kind;
  final ProgressionSnapshot before;
  final ProgressionSnapshot after;
  final ProgressionInfo info;

  /// Mění se plán? („drží“ ne).
  bool get changesPlan => kind != ProgressionKind.hold;
}

List<int> _workingIndexes(List<TargetSet> targets) => [
      for (var i = 0; i < targets.length; i++)
        if (_isWorking(targets[i])) i,
    ];

List<PerformedSet> _workingPerformed(List<PerformedSet> sets) => [
      for (final s in sets)
        if (!s.isWarmup && !s.isDrop) s,
    ];

TargetSet _withTarget(TargetSet s, {int? reps, double? weightKg}) => (
      reps: reps ?? s.reps,
      weightKg: weightKg ?? s.weightKg,
      isWarmup: s.isWarmup,
      isDrop: s.isDrop,
    );

/// Navrhne změnu cílů pro příští trénink. Null = beze změny (nebo málo
/// dat). [holdReason] (viz [ProgressionBlockers.reasonFor]) změní zvýšení
/// váhy i opakování na „drží“; odlehčení zůstává.
ProgressionProposal? proposeProgression(
  ProgressionInput input, {
  required UnitSystem unit,
  HoldReason? holdReason,
}) {
  final targets = input.targets;
  final work = _workingIndexes(targets);
  if (work.isEmpty) return null;
  final done = _workingPerformed(input.performed);
  if (done.isEmpty) return null;
  final before = ProgressionSnapshot(
    sets: targets,
    repRangeMin: input.repRangeMin,
    repRangeMax: input.repRangeMax,
  );
  return switch (input.type) {
    ExerciseType.weightReps => _weighted(input, before, work, done, unit,
        holdReason: holdReason),
    ExerciseType.bodyweightReps => _linear(input, before, work, done,
        isDuration: false, holdReason: holdReason),
    ExerciseType.duration => _linear(input, before, work, done,
        isDuration: true, holdReason: holdReason),
  };
}

ProgressionProposal _hold(
  ProgressionSnapshot before,
  ProgressionKind blocked,
  HoldReason reason, {
  double? fromKg,
  required int reps,
  bool isDuration = false,
}) =>
    ProgressionProposal(
      kind: ProgressionKind.hold,
      before: before,
      after: before,
      info: ProgressionInfo(
        fromKg: fromKg,
        toKg: fromKg,
        reps: reps,
        isDuration: isDuration,
        holdReason: reason,
        blocked: blocked,
      ),
    );

/// Vlastní váha a čas: +1 opakování / +5 s, když všechny pracovní série
/// splnily cíl. U vlastní váhy je strop horní hranice rozsahu z plánu
/// (jen když je zadaná).
ProgressionProposal? _linear(
  ProgressionInput input,
  ProgressionSnapshot before,
  List<int> work,
  List<PerformedSet> done, {
  required bool isDuration,
  HoldReason? holdReason,
}) {
  final targets = input.targets;
  for (var j = 0; j < work.length; j++) {
    if (j >= done.length) return null;
    final p = done[j];
    final value = (isDuration ? p.durationSeconds : p.reps) ?? 0;
    if (value < targets[work[j]].reps) return null;
  }
  final step = isDuration ? durationIncrementSeconds : bodyweightIncrementReps;
  final cap = isDuration ? null : input.repRangeMax;
  final next = [...targets];
  var changed = false;
  for (final k in work) {
    final t = targets[k];
    var r = t.reps + step;
    if (cap != null && r > cap) r = cap > t.reps ? cap : t.reps;
    if (r != t.reps) {
      next[k] = _withTarget(t, reps: r);
      changed = true;
    }
  }
  if (!changed) return null;
  final firstReps = next[work.first].reps;
  if (holdReason != null) {
    return _hold(before, ProgressionKind.reps, holdReason,
        reps: targets[work.first].reps, isDuration: isDuration);
  }
  return ProgressionProposal(
    kind: ProgressionKind.reps,
    before: before,
    after: ProgressionSnapshot(
      sets: next,
      repRangeMin: input.repRangeMin,
      repRangeMax: input.repRangeMax,
    ),
    info: ProgressionInfo(
      reps: firstReps,
      delta: step,
      isDuration: isDuration,
    ),
  );
}

/// Cviky s vahou: dvojitá progrese.
ProgressionProposal? _weighted(
  ProgressionInput input,
  ProgressionSnapshot before,
  List<int> work,
  List<PerformedSet> done,
  UnitSystem unit, {
  HoldReason? holdReason,
}) {
  final targets = input.targets;
  final range = effectiveRepRange(
    targets,
    min: input.repRangeMin,
    max: input.repRangeMax,
  );
  final increment = (input.incrementKg ?? 0) > 0
      ? input.incrementKg!
      : defaultIncrementKg(
          group: input.group,
          equipment: input.equipment,
          slug: input.slug,
          unit: unit,
        );
  final step = roundingStepKg(input.equipment, unit, increment);

  // Referenční váha každé pracovní série: cíl z plánu, jinak odcvičená.
  final refs = <double>[];
  var allTop = true;
  var allTarget = true;
  double? failWeight;
  for (var j = 0; j < work.length; j++) {
    final t = targets[work[j]];
    if (j >= done.length) {
      // Nedokončené série: žádné zvýšení, ale ani selhání.
      allTop = false;
      allTarget = false;
      final ref = t.weightKg ?? refs.lastOrNull;
      if (ref == null) return null;
      refs.add(ref);
      continue;
    }
    final p = done[j];
    final ref = t.weightKg ?? p.weightKg;
    if (ref == null || ref <= 0) return null; // bez vah nelze progresovat
    refs.add(ref);
    final reps = p.reps ?? 0;
    final atWeight = (p.weightKg ?? 0) >= ref - _eps;
    if (!atWeight || reps < range.max) allTop = false;
    if (!atWeight || reps < t.reps) allTarget = false;
    if (atWeight && reps < range.min) {
      failWeight = failWeight == null || ref > failWeight ? ref : failWeight;
    }
  }

  // Rozsah se při první změně uloží do plánu, aby se dál neposouval
  // spolu s cílovými opakováními.
  ProgressionSnapshot after(List<TargetSet> sets) => ProgressionSnapshot(
        sets: sets,
        repRangeMin: range.min,
        repRangeMax: range.max,
      );

  final firstRef = refs.first;

  if (allTop) {
    if (holdReason != null) {
      return _hold(before, ProgressionKind.increase, holdReason,
          fromKg: firstRef, reps: targets[work.first].reps);
    }
    final next = [...targets];
    for (var j = 0; j < work.length; j++) {
      next[work[j]] = _withTarget(
        targets[work[j]],
        reps: range.min,
        weightKg: increasedWeight(refs[j], increment, step),
      );
    }
    return ProgressionProposal(
      kind: ProgressionKind.increase,
      before: before,
      after: after(next),
      info: ProgressionInfo(
        fromKg: firstRef,
        toKg: next[work.first].weightKg,
        reps: range.min,
      ),
    );
  }

  if (allTarget) {
    final next = [...targets];
    var changed = false;
    for (final k in work) {
      final t = targets[k];
      if (t.reps >= range.max) continue;
      next[k] = _withTarget(t, reps: t.reps + 1);
      changed = true;
    }
    if (!changed) return null;
    if (holdReason != null) {
      return _hold(before, ProgressionKind.reps, holdReason,
          fromKg: firstRef, reps: targets[work.first].reps);
    }
    return ProgressionProposal(
      kind: ProgressionKind.reps,
      before: before,
      after: after(next),
      info: ProgressionInfo(
        fromKg: firstRef,
        toKg: firstRef,
        reps: next[work.first].reps,
        delta: 1,
      ),
    );
  }

  final fail = failWeight;
  if (fail != null && _failedBefore(input.previous, fail, range.min)) {
    final next = [...targets];
    for (var j = 0; j < work.length; j++) {
      next[work[j]] = _withTarget(
        targets[work[j]],
        reps: range.min,
        weightKg: deloadedWeight(refs[j], step),
      );
    }
    return ProgressionProposal(
      kind: ProgressionKind.deload,
      before: before,
      after: after(next),
      info: ProgressionInfo(
        fromKg: firstRef,
        toKg: next[work.first].weightKg,
        reps: range.min,
      ),
    );
  }
  return null;
}

/// Nedosáhl i předchozí trénink spodní hranice se stejnou (nebo vyšší)
/// vahou?
bool _failedBefore(List<PerformedSet> previous, double weightKg, int min) {
  for (final p in _workingPerformed(previous)) {
    final w = p.weightKg;
    if (w != null && w >= weightKg - _eps && (p.reps ?? 0) < min) return true;
  }
  return false;
}
