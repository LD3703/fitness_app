// Progresivní přetížení po partiích (čistý Dart, testy:
// test/progressive_overload_test.dart).
//
// Týdny jsou ISO týdny (pondělí–neděle, místní čas). Pro každou partii
// (jen HLAVNÍ partie cviku, vedlejší se tu nepočítají; celé tělo se
// nehodnotí) se po týdnech spočítá:
// - objem = Σ váha × opakování pracovních sérií (rozcvička ne, drop série
//   ano – celým objemem),
// - nejlepší odhad 1RM každého cviku (bez rozcvičky a drop sérií).
//
// Hodnocení „k týdnu W“ (W = poslední dokončený týden) porovná poslední
// 2 týdny (W a předchozí) s 2 týdny před nimi:
// - progres: objem +≥ 2,5 % NEBO odhad 1RM některého cviku partie +≥ 1 %
//   (porovnává se cvik po cviku, aby výsledek nezkreslila jiná skladba
//   cviků),
// - pokles: objem −≥ 10 % a žádné zlepšení 1RM,
// - jinak stagnace,
// - málo dat: partie nebyla trénovaná (se zátěží) v obou oknech.
// Týdny, které zasáhla nemoc, pauza nebo zranění TÉTO partie, se z oken
// vynechají (okno se posune dál do minulosti, nejvýš o
// [overloadLookbackWeeks]). Dieta (cut) pokles omlouvá – místo poklesu je
// stav „drží“ (holding) a tipy na přidání zátěže se v dietě nedávají.
//
// Stagnace 3 a více hodnocených týdnů v řadě → tip (přidat 1–2 opakování,
// sérii, nebo váhu – střídají se).

import '../data/enums.dart';
import 'formulas.dart';
import 'injury.dart';

/// Jedna série pro výpočet. [date] = začátek tréninku.
typedef OverloadSet = ({
  DateTime date,
  int exerciseId,
  MuscleGroup group,
  double weightKg,
  int reps,
  bool isWarmup,
  bool isDrop,
});

/// Období (nemoc, zranění, dieta…). [end] = poslední den (včetně), null =
/// stále probíhá. [injuredGroups] u zranění (prázdné = celé tělo).
typedef OverloadPeriod = ({
  PeriodType type,
  DateTime start,
  DateTime? end,
  Set<MuscleGroup> injuredGroups,
});

enum OverloadStatus { progressing, holding, stagnating, declining, insufficientData }

enum OverloadReasonKind { oneRepMax, volume }

/// Důvod stavu: změna odhadu 1RM cviku [exerciseId] nebo změna objemu
/// partie, v procentech (záporné = pokles).
typedef OverloadReason = ({
  OverloadReasonKind kind,
  double percent,
  int? exerciseId,
});

enum OverloadTip { addReps, addSet, addWeight }

/// Výsledek týdne celkově (pro odznak „série progresu“).
enum OverloadWeekOutcome {
  /// Aspoň jedna partie v progresu a žádná v poklesu.
  extend,

  /// Žádný progres nebo nějaký pokles.
  breaks,

  /// Nemoc / pauza (nebo zranění všech hodnocených partií) – týden sérii
  /// nepřeruší ani neprodlouží.
  excused,
}

const overloadVolumeProgressPercent = 2.5;
const overloadOneRepMaxProgressPercent = 1.0;
const overloadVolumeDeclinePercent = 10.0;

/// Počet týdnů v jednom okně (poslední 2 týdny vs. 2 týdny před nimi).
const overloadWindowWeeks = 2;

/// Jak daleko do minulosti se hledají týdny pro okna, když se některé
/// vynechávají (nemoc, pauza, zranění).
const overloadLookbackWeeks = 12;

/// Od kolika týdnů stagnace v řadě se ukáže tip.
const overloadTipAfterWeeks = 3;

/// Hodnocené partie (cviky na celé tělo se nehodnotí).
const overloadGroups = <MuscleGroup>[
  MuscleGroup.chest,
  MuscleGroup.back,
  MuscleGroup.shoulders,
  MuscleGroup.biceps,
  MuscleGroup.triceps,
  MuscleGroup.legs,
  MuscleGroup.glutes,
  MuscleGroup.core,
];

const _eps = 1e-9;

/// Pondělí (00:00) týdne, do kterého patří [d].
DateTime overloadWeekStart(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

DateTime _addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Hodnocení jedné partie k jednomu týdnu.
class GroupOverload {
  const GroupOverload({
    required this.group,
    required this.week,
    required this.status,
    this.excused = false,
    this.inCut = false,
    this.volumeChangePercent,
    this.reasons = const [],
    this.stagnantWeeks = 0,
    this.tip,
  });

  final MuscleGroup group;

  /// Pondělí hodnoceného (posledního dokončeného) týdne.
  final DateTime week;
  final OverloadStatus status;

  /// Týden [week] partii zasáhla nemoc, pauza nebo zranění – nehodnotí se
  /// (stav je pak [OverloadStatus.insufficientData]).
  final bool excused;

  /// Poslední okno zasahuje do diety (cut).
  final bool inCut;

  /// Změna objemu posledních 2 týdnů proti 2 předchozím (%).
  final double? volumeChangePercent;

  /// Důvody stavu (nejlepší zlepšení 1RM a/nebo změna objemu).
  final List<OverloadReason> reasons;

  /// Kolik hodnocených týdnů v řadě (včetně tohoto) partie stagnuje.
  final int stagnantWeeks;

  /// Tip při stagnaci [overloadTipAfterWeeks]+ týdnů (ne v dietě).
  final OverloadTip? tip;
}

/// Hodnocení všech partií po týdnech (od prvního týdne s daty po poslední
/// dokončený týden).
class OverloadHistory {
  const OverloadHistory({
    required this.weeks,
    required this.byGroup,
    required this.pausedWeeks,
  });

  static const empty = OverloadHistory(weeks: [], byGroup: {}, pausedWeeks: []);

  /// Pondělí dokončených týdnů od nejstaršího.
  final List<DateTime> weeks;

  /// Hodnocení partií ve stejném pořadí jako [weeks]. Jen partie, které
  /// mají aspoň jednu sérii se zátěží.
  final Map<MuscleGroup, List<GroupOverload>> byGroup;

  /// Týden zasáhla nemoc nebo pauza (platí pro všechny partie).
  final List<bool> pausedWeeks;

  bool get isEmpty => weeks.isEmpty || byGroup.isEmpty;

  /// Výsledek týdne s indexem [i] pro sérii progresu.
  OverloadWeekOutcome outcomeAt(int i) {
    if (pausedWeeks[i]) return OverloadWeekOutcome.excused;
    var anyExcused = false;
    var anyRated = false;
    var anyProgress = false;
    for (final list in byGroup.values) {
      final r = list[i];
      if (r.excused) {
        anyExcused = true;
        continue;
      }
      switch (r.status) {
        case OverloadStatus.declining:
          return OverloadWeekOutcome.breaks;
        case OverloadStatus.progressing:
          anyProgress = true;
          anyRated = true;
        case OverloadStatus.holding:
        case OverloadStatus.stagnating:
          anyRated = true;
        case OverloadStatus.insufficientData:
          break;
      }
    }
    if (anyProgress) return OverloadWeekOutcome.extend;
    if (!anyRated && anyExcused) return OverloadWeekOutcome.excused;
    return OverloadWeekOutcome.breaks;
  }

  /// Nejdelší série týdnů s progresem (aspoň jedna partie v progresu,
  /// žádná v poklesu; omluvené týdny sérii nepřeruší ani neprodlouží).
  int get longestStreak {
    var best = 0;
    var run = 0;
    for (var i = 0; i < weeks.length; i++) {
      switch (outcomeAt(i)) {
        case OverloadWeekOutcome.extend:
          run++;
          if (run > best) best = run;
        case OverloadWeekOutcome.breaks:
          run = 0;
        case OverloadWeekOutcome.excused:
          break;
      }
    }
    return best;
  }

  /// Aktuální série (končící posledním dokončeným týdnem).
  int get currentStreak {
    var run = 0;
    for (var i = weeks.length - 1; i >= 0; i--) {
      switch (outcomeAt(i)) {
        case OverloadWeekOutcome.extend:
          run++;
        case OverloadWeekOutcome.breaks:
          return run;
        case OverloadWeekOutcome.excused:
          break;
      }
    }
    return run;
  }
}

/// Mistrovství partie: [masteryWeeks] hodnocených týdnů v řadě v progresu
/// nebo „drží“, z toho aspoň [masteryProgressingWeeks] v progresu.
const masteryWeeks = 8;
const masteryProgressingWeeks = 4;

/// Nejlepší postup k mistrovství partie: nejdelší řada týdnů v progresu
/// nebo „drží“ (max. [masteryWeeks]) a zda už bylo mistrovství splněno.
({int bestRun, bool mastered}) masteryProgress(List<GroupOverload> results) {
  final run = <OverloadStatus>[];
  var best = 0;
  var mastered = false;
  for (final r in results) {
    if (r.excused) continue;
    if (r.status == OverloadStatus.progressing ||
        r.status == OverloadStatus.holding) {
      run.add(r.status);
      if (run.length > best) best = run.length;
      if (run.length >= masteryWeeks) {
        final last = run.sublist(run.length - masteryWeeks);
        final progressing =
            last.where((s) => s == OverloadStatus.progressing).length;
        if (progressing >= masteryProgressingWeeks) mastered = true;
      }
    } else {
      run.clear();
    }
  }
  return (bestRun: best > masteryWeeks ? masteryWeeks : best, mastered: mastered);
}

/// Souhrn týdne jedné partie.
class _WeekAgg {
  double volume = 0;
  final best = <int, double>{};
}

enum _WeekKind { normal, cut, skipped }

/// Spočítá hodnocení všech partií po týdnech až do posledního týdne před
/// týdnem obsahujícím [now].
OverloadHistory computeOverloadHistory(
  Iterable<OverloadSet> sets,
  Iterable<OverloadPeriod> periods,
  DateTime now,
) {
  final data = <MuscleGroup, Map<DateTime, _WeekAgg>>{};
  DateTime? firstWeek;
  for (final s in sets) {
    if (s.isWarmup || s.weightKg <= 0 || s.reps <= 0) continue;
    if (!overloadGroups.contains(s.group)) continue;
    final w = overloadWeekStart(s.date);
    final agg = (data[s.group] ??= {})[w] ??= _WeekAgg();
    agg.volume += s.weightKg * s.reps;
    if (!s.isDrop) {
      final e1rm = estimateOneRepMax(s.weightKg, s.reps);
      if (e1rm != null && e1rm > (agg.best[s.exerciseId] ?? 0)) {
        agg.best[s.exerciseId] = e1rm;
      }
    }
    if (firstWeek == null || w.isBefore(firstWeek)) firstWeek = w;
  }
  final lastWeek = _addDays(overloadWeekStart(now), -7);
  if (firstWeek == null || lastWeek.isBefore(firstWeek)) {
    return OverloadHistory.empty;
  }

  final weeks = <DateTime>[];
  for (var w = firstWeek; !w.isAfter(lastWeek); w = _addDays(w, 7)) {
    weeks.add(w);
  }

  final periodList = periods.toList();
  bool overlaps(OverloadPeriod p, DateTime weekStart) {
    final weekEnd = _addDays(weekStart, 7);
    final start = DateTime(p.start.year, p.start.month, p.start.day);
    if (!start.isBefore(weekEnd)) return false;
    final end = p.end;
    if (end == null) return true;
    return !DateTime(end.year, end.month, end.day).isBefore(weekStart);
  }

  bool paused(DateTime w) => periodList.any((p) =>
      (p.type == PeriodType.illness || p.type == PeriodType.pause) &&
      overlaps(p, w));

  final kindCache = <(MuscleGroup, DateTime), _WeekKind>{};
  _WeekKind kindOf(MuscleGroup g, DateTime w) =>
      kindCache[(g, w)] ??= () {
        if (paused(w)) return _WeekKind.skipped;
        final injured = periodList.any((p) =>
            p.type == PeriodType.injury &&
            periodAppliesTo(p.type, p.injuredGroups, g) &&
            overlaps(p, w));
        if (injured) return _WeekKind.skipped;
        if (periodList.any((p) => p.type == PeriodType.cut && overlaps(p, w))) {
          return _WeekKind.cut;
        }
        return _WeekKind.normal;
      }();

  final byGroup = <MuscleGroup, List<GroupOverload>>{};
  for (final g in overloadGroups) {
    final weeksData = data[g];
    if (weeksData == null) continue;
    final results = <GroupOverload>[];
    var stagnant = 0;
    for (final w in weeks) {
      final r = _evaluate(g, w, weeksData, kindOf, stagnant);
      if (!r.excused) {
        stagnant = r.status == OverloadStatus.stagnating ? r.stagnantWeeks : 0;
      }
      results.add(r);
    }
    byGroup[g] = results;
  }

  return OverloadHistory(
    weeks: weeks,
    byGroup: byGroup,
    pausedWeeks: [for (final w in weeks) paused(w)],
  );
}

GroupOverload _evaluate(
  MuscleGroup g,
  DateTime week,
  Map<DateTime, _WeekAgg> weeksData,
  _WeekKind Function(MuscleGroup, DateTime) kindOf,
  int stagnantBefore,
) {
  if (kindOf(g, week) == _WeekKind.skipped) {
    return GroupOverload(
      group: g,
      week: week,
      status: OverloadStatus.insufficientData,
      excused: true,
      stagnantWeeks: stagnantBefore,
    );
  }

  // Týdny pro obě okna (od nejnovějšího), bez vynechaných.
  final picked = <DateTime>[];
  var cursor = week;
  for (var i = 0;
      i < overloadLookbackWeeks && picked.length < 2 * overloadWindowWeeks;
      i++) {
    if (kindOf(g, cursor) != _WeekKind.skipped) picked.add(cursor);
    cursor = _addDays(cursor, -7);
  }
  GroupOverload insufficient() => GroupOverload(
        group: g,
        week: week,
        status: OverloadStatus.insufficientData,
      );
  if (picked.length < 2 * overloadWindowWeeks) return insufficient();

  final recent = picked.take(overloadWindowWeeks).toList();
  final previous = picked.skip(overloadWindowWeeks).toList();

  ({double volume, Map<int, double> best}) sum(List<DateTime> ws) {
    var volume = 0.0;
    final best = <int, double>{};
    for (final w in ws) {
      final agg = weeksData[w];
      if (agg == null) continue;
      volume += agg.volume;
      for (final e in agg.best.entries) {
        if (e.value > (best[e.key] ?? 0)) best[e.key] = e.value;
      }
    }
    return (volume: volume, best: best);
  }

  final current = sum(recent);
  final before = sum(previous);
  if (current.volume <= 0 || before.volume <= 0) return insufficient();

  final volumeChange = (current.volume / before.volume - 1) * 100;

  // Nejlepší zlepšení 1RM cviku, který je v obou oknech.
  int? bestExercise;
  double? bestChange;
  for (final e in current.best.entries) {
    final prev = before.best[e.key];
    if (prev == null || prev <= 0) continue;
    final change = (e.value / prev - 1) * 100;
    if (bestChange == null || change > bestChange) {
      bestChange = change;
      bestExercise = e.key;
    }
  }
  final e1rmImproved = bestChange != null &&
      bestChange >= overloadOneRepMaxProgressPercent - _eps;
  final volumeUp = volumeChange >= overloadVolumeProgressPercent - _eps;
  final volumeDown = volumeChange <= -overloadVolumeDeclinePercent + _eps;
  final inCut = recent.any((w) => kindOf(g, w) == _WeekKind.cut);

  final OverloadReason volumeReason = (
    kind: OverloadReasonKind.volume,
    percent: volumeChange,
    exerciseId: null,
  );

  if (e1rmImproved || volumeUp) {
    return GroupOverload(
      group: g,
      week: week,
      status: OverloadStatus.progressing,
      inCut: inCut,
      volumeChangePercent: volumeChange,
      reasons: [
        if (e1rmImproved)
          (
            kind: OverloadReasonKind.oneRepMax,
            percent: bestChange!,
            exerciseId: bestExercise,
          ),
        if (volumeUp) volumeReason,
      ],
    );
  }
  if (volumeDown) {
    return GroupOverload(
      group: g,
      week: week,
      status: inCut ? OverloadStatus.holding : OverloadStatus.declining,
      inCut: inCut,
      volumeChangePercent: volumeChange,
      reasons: [volumeReason],
    );
  }
  final stagnant = stagnantBefore + 1;
  return GroupOverload(
    group: g,
    week: week,
    status: OverloadStatus.stagnating,
    inCut: inCut,
    volumeChangePercent: volumeChange,
    reasons: [volumeReason],
    stagnantWeeks: stagnant,
    tip: inCut ? null : overloadTipFor(stagnant),
  );
}

/// Tip podle délky stagnace (od [overloadTipAfterWeeks] týdnů; střídají se
/// opakování → série → váha).
OverloadTip? overloadTipFor(int stagnantWeeks) {
  if (stagnantWeeks < overloadTipAfterWeeks) return null;
  const order = [OverloadTip.addReps, OverloadTip.addSet, OverloadTip.addWeight];
  return order[(stagnantWeeks - overloadTipAfterWeeks) % order.length];
}

/// Aktuální hodnocení partií (k poslednímu dokončenému týdnu), jen partie
/// s daty.
List<GroupOverload> currentOverload(OverloadHistory history) => [
      for (final g in overloadGroups)
        if (history.byGroup[g] case final list? when list.isNotEmpty) list.last,
    ];
