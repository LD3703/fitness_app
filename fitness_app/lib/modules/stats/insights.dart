// Automatické postřehy: čistá logika bez Flutteru.
//
// Postřehy vrací jen strukturovaná data (typ + čísla). Texty skládá
// widget z lokalizovaných klíčů (viz insights_card.dart).

import 'dart:math' as math;

import '../../core/date_utils.dart';
import '../../core/wellbeing.dart' show daysBetween;
import '../../data/enums.dart';
import 'stats_math.dart';

/// Období (nemoc, dieta…) potřebné pro postřehy.
typedef PeriodRange = ({PeriodType type, DateTime start, DateTime? end});

/// Jeden dokončený trénink, který zasáhl danou partii.
typedef GroupSession = ({DateTime day, MuscleGroup group});

/// Hranice „příliš rychlého“ hubnutí v % tělesné váhy za týden.
const fastWeightLossPercentPerWeek = 1.0;

/// Po nemoci je síla „zpátky“, když odhad 1RM dosáhne 97 % formy před ní.
const recoveredRatio = 0.97;

/// Vstupní data pro výpočet postřehů.
class InsightInput {
  const InsightInput({
    required this.now,
    this.trackWeight = true,
    this.trackPeriods = true,
    this.periods = const [],
    this.weights = const [],
    this.oneRepMaxByExercise = const {},
    this.groupSessions = const [],
    this.sessionDates = const [],
    this.weekdayMasks = const [],
    this.injuredGroups = const {},
  });

  final DateTime now;

  /// Uživatel sleduje tělesnou váhu (jinak žádné postřehy o váze).
  final bool trackWeight;

  /// Uživatel sleduje období (jinak žádné postřehy k nemoci a dietě).
  final bool trackPeriods;
  final List<PeriodRange> periods;

  /// Tělesná váha po dnech (kg).
  final List<StatPoint> weights;

  /// Nejlepší odhad 1RM cviku v každém tréninku, podle ID cviku.
  final Map<int, List<StatPoint>> oneRepMaxByExercise;

  /// Tréninky podle partií (jeden záznam na trénink a partii).
  final List<GroupSession> groupSessions;

  /// Začátky všech dokončených tréninků (plných i plánu B).
  final List<DateTime> sessionDates;

  /// Masky dnů v týdnu všech plánů.
  final List<int> weekdayMasks;

  /// Právě zraněné partie (ty se jako „zanedbané“ nehlásí).
  final Set<MuscleGroup> injuredGroups;
}

/// Postřeh. [priority] určuje pořadí (vyšší = důležitější).
sealed class Insight {
  const Insight();

  int get priority;
}

/// Váha klesá rychleji než ~1 % týdně (průměr za poslední 2 týdny).
final class WeightDropInsight extends Insight {
  const WeightDropInsight(this.percentPerWeek);

  final double percentPerWeek;

  @override
  int get priority => 100;
}

/// Návrat síly hlavních cviků po nemoci.
typedef LiftRecovery = ({
  int exerciseId,

  /// Za kolik dní po konci nemoci se 1RM vrátil na ≥ 97 % (null = ještě ne).
  int? daysToRecover,

  /// O kolik % je nejlepší výkon po nemoci pod formou před ní (když ještě
  /// není zpátky).
  double? percentBelow,
});

final class IllnessRecoveryInsight extends Insight {
  const IllnessRecoveryInsight({required this.illnessEnd, required this.lifts});

  final DateTime illnessEnd;
  final List<LiftRecovery> lifts;

  bool get allRecovered => lifts.every((l) => l.daysToRecover != null);

  @override
  int get priority => allRecovered ? 60 : 90;
}

/// Shrnutí diety (cut): změna váhy a kolik síly zůstalo.
final class CutSummaryInsight extends Insight {
  const CutSummaryInsight({
    required this.ongoing,
    this.weightChangeKg,
    this.strengthKeptPercent,
  });

  final bool ongoing;

  /// Změna 7denního průměru váhy (záporná = úbytek), null bez dat.
  final double? weightChangeKg;

  /// Nejlepší 1RM za poslední 2 týdny vůči formě před dietou (100 = beze
  /// ztráty), průměr přes hlavní cviky.
  final double? strengthKeptPercent;

  @override
  int get priority => 85;
}

/// Shrnutí nabírání (bulk): přírůstek váhy a síly.
final class BulkSummaryInsight extends Insight {
  const BulkSummaryInsight({
    required this.ongoing,
    this.weightChangeKg,
    this.strengthChangePercent,
  });

  final bool ongoing;
  final double? weightChangeKg;

  /// Změna síly v % (kladná = silnější).
  final double? strengthChangePercent;

  @override
  int get priority => 84;
}

/// Nové osobní rekordy v tomto měsíci.
final class MonthRecordsInsight extends Insight {
  const MonthRecordsInsight({
    required this.count,
    required this.bestExerciseId,
    required this.bestOneRepMax,
    required this.bestGainPercent,
  });

  /// Počet cviků s novým rekordem.
  final int count;
  final int bestExerciseId;
  final double bestOneRepMax;

  /// O kolik % byl předchozí rekord překonán.
  final double bestGainPercent;

  @override
  int get priority => 80;
}

/// Partie trénovaná pravidelně, ale posledních 14 dní ne.
final class NeglectedGroupInsight extends Insight {
  const NeglectedGroupInsight(this.group, this.daysSince);

  final MuscleGroup group;
  final int daysSince;

  @override
  int get priority => 70;
}

/// Průměr tréninků za týden (poslední 4 týdny) vs. plán.
final class ConsistencyInsight extends Insight {
  const ConsistencyInsight({
    required this.averagePerWeek,
    required this.plannedPerWeek,
  });

  final double averagePerWeek;

  /// Naplánované tréninkové dny v týdnu (0 = bez plánu).
  final int plannedPerWeek;

  bool get onTrack =>
      plannedPerWeek == 0 || averagePerWeek + 0.001 >= plannedPerWeek;

  @override
  int get priority => onTrack ? 50 : 65;
}

/// Úbytek váhy v % za týden podle 7denních průměrů: posledních 7 dní vs.
/// 7 dní o dva týdny dřív. Kladné číslo = váha klesá. Null bez dat
/// (každé okno potřebuje aspoň 2 vážení).
double? weeklyWeightLossPercent(List<StatPoint> weights, DateTime now) {
  final today = startOfDay(now);
  final recent =
      averageBetween(weights, addDays(today, -6), addDays(today, 1), minCount: 2);
  final earlier = averageBetween(
      weights, addDays(today, -20), addDays(today, -13),
      minCount: 2);
  if (recent == null || earlier == null || earlier <= 0) return null;
  return (earlier - recent) / earlier * 100 / 2;
}

/// Hlavní cviky: nejčastěji trénované za posledních 180 dní (aspoň 3
/// tréninky celkem), nejvýš [max].
List<int> mainLifts(
  Map<int, List<StatPoint>> series,
  DateTime now, {
  int max = 3,
}) {
  final from = addDays(startOfDay(now), -180);
  final candidates = <({int id, int recent, int total})>[
    for (final e in series.entries)
      if (e.value.length >= 3)
        (
          id: e.key,
          recent: e.value.where((p) => !p.x.isBefore(from)).length,
          total: e.value.length,
        ),
  ]..removeWhere((c) => c.recent == 0);
  candidates.sort((a, b) {
    final r = b.recent.compareTo(a.recent);
    if (r != 0) return r;
    final t = b.total.compareTo(a.total);
    return t != 0 ? t : a.id.compareTo(b.id);
  });
  return [for (final c in candidates.take(max)) c.id];
}

/// Spočítá postřehy a vrátí nejvýš [max] nejdůležitějších.
List<Insight> computeInsights(InsightInput input, {int max = 5}) {
  final result = <Insight>[
    ...?_weightDrop(input),
    ...?_illnessRecovery(input),
    ...?_dietSummary(input, PeriodType.cut),
    ...?_dietSummary(input, PeriodType.bulk),
    ...?_monthRecords(input),
    ..._neglectedGroups(input),
    ...?_consistency(input),
  ];
  result.sort((a, b) => b.priority.compareTo(a.priority));
  return result.take(max).toList();
}

List<Insight>? _weightDrop(InsightInput input) {
  if (!input.trackWeight) return null;
  final rate = weeklyWeightLossPercent(input.weights, input.now);
  if (rate == null || rate <= fastWeightLossPercentPerWeek) return null;
  return [WeightDropInsight(rate)];
}

List<Insight>? _illnessRecovery(InsightInput input) {
  if (!input.trackPeriods) return null;
  final today = startOfDay(input.now);
  final illnesses =
      input.periods.where((p) => p.type == PeriodType.illness).toList();
  // Během nemoci „návrat“ nehlásíme.
  final ill = illnesses.any((p) =>
      !startOfDay(p.start).isAfter(today) &&
      (p.end == null || !startOfDay(p.end!).isBefore(today)));
  if (ill) return null;
  PeriodRange? last;
  for (final p in illnesses) {
    final end = p.end;
    if (end == null || !startOfDay(end).isBefore(today)) continue;
    if (last == null || end.isAfter(last.end!)) last = p;
  }
  if (last == null) return null;
  final end = startOfDay(last.end!);
  if (daysBetween(end, today) > 60) return null;
  final start = startOfDay(last.start);

  final lifts = <LiftRecovery>[];
  for (final id in mainLifts(input.oneRepMaxByExercise, input.now)) {
    final pts = input.oneRepMaxByExercise[id]!;
    final before = bestBetween(pts, addDays(start, -60), start);
    if (before == null || before <= 0) continue;
    final after = [
      for (final p in pts)
        if (!p.x.isBefore(addDays(end, 1))) p,
    ]..sort((a, b) => a.x.compareTo(b.x));
    if (after.isEmpty) continue;
    final back = after.where((p) => p.y >= before * recoveredRatio).firstOrNull;
    if (back != null) {
      lifts.add((
        exerciseId: id,
        daysToRecover: daysBetween(end, back.x),
        percentBelow: null,
      ));
    } else {
      final bestAfter = after.map((p) => p.y).reduce(math.max);
      lifts.add((
        exerciseId: id,
        daysToRecover: null,
        percentBelow: (1 - bestAfter / before) * 100,
      ));
    }
  }
  if (lifts.isEmpty) return null;
  return [IllnessRecoveryInsight(illnessEnd: end, lifts: lifts)];
}

List<Insight>? _dietSummary(InsightInput input, PeriodType type) {
  if (!input.trackPeriods) return null;
  final today = startOfDay(input.now);
  PeriodRange? period;
  for (final p in input.periods) {
    if (p.type != type || startOfDay(p.start).isAfter(today)) continue;
    final end = p.end;
    // Probíhající, nebo skončené nejvýš před 30 dny.
    if (end != null && daysBetween(startOfDay(end), today) > 30) continue;
    if (period == null || p.start.isAfter(period.start)) period = p;
  }
  if (period == null) return null;
  final start = startOfDay(period.start);
  final end = period.end == null || !startOfDay(period.end!).isBefore(today)
      ? today
      : startOfDay(period.end!);
  final ongoing = end == today;
  // Kratší období nemá smysl vyhodnocovat.
  if (daysBetween(start, end) < 14) return null;

  double? weightChange;
  if (input.trackWeight) {
    final startAvg = averageBetween(input.weights, start, addDays(start, 7)) ??
        averageBetween(input.weights, addDays(start, -7), start);
    final endAvg =
        averageBetween(input.weights, addDays(end, -6), addDays(end, 1));
    if (startAvg != null && endAvg != null) weightChange = endAvg - startAvg;
  }

  final ratios = <double>[];
  for (final id in mainLifts(input.oneRepMaxByExercise, input.now)) {
    final pts = input.oneRepMaxByExercise[id]!;
    final before = bestBetween(pts, addDays(start, -56), start);
    final recent = bestBetween(pts, addDays(end, -13), addDays(end, 1));
    if (before == null || before <= 0 || recent == null) continue;
    ratios.add(recent / before);
  }
  final strength = ratios.isEmpty
      ? null
      : ratios.reduce((a, b) => a + b) / ratios.length * 100;

  if (weightChange == null && strength == null) return null;
  return [
    if (type == PeriodType.cut)
      CutSummaryInsight(
        ongoing: ongoing,
        weightChangeKg: weightChange,
        strengthKeptPercent: strength,
      )
    else
      BulkSummaryInsight(
        ongoing: ongoing,
        weightChangeKg: weightChange,
        strengthChangePercent: strength == null ? null : strength - 100,
      ),
  ];
}

List<Insight>? _monthRecords(InsightInput input) {
  final monthStart = DateTime(input.now.year, input.now.month);
  var count = 0;
  int? bestId;
  var bestValue = 0.0;
  var bestGain = 0.0;
  final tomorrow = addDays(startOfDay(input.now), 1);
  for (final MapEntry(key: id, value: pts)
      in input.oneRepMaxByExercise.entries) {
    final before = bestBetween(pts, DateTime(1970), monthStart);
    final thisMonth = bestBetween(pts, monthStart, tomorrow);
    if (before == null || before <= 0 || thisMonth == null) continue;
    if (thisMonth <= before) continue;
    count++;
    final gain = (thisMonth / before - 1) * 100;
    if (bestId == null || gain > bestGain) {
      bestId = id;
      bestGain = gain;
      bestValue = thisMonth;
    }
  }
  final id = bestId;
  if (count == 0 || id == null) return null;
  return [
    MonthRecordsInsight(
      count: count,
      bestExerciseId: id,
      bestOneRepMax: bestValue,
      bestGainPercent: bestGain,
    ),
  ];
}

List<Insight> _neglectedGroups(InsightInput input) {
  final today = startOfDay(input.now);
  if (input.trackPeriods) {
    // Při nemoci nebo pauze je vynechání partií v pořádku.
    final resting = input.periods.any((p) =>
        (p.type == PeriodType.illness || p.type == PeriodType.pause) &&
        !startOfDay(p.start).isAfter(today) &&
        (p.end == null || !startOfDay(p.end!).isBefore(today)));
    if (resting) return const [];
  }
  final recentFrom = addDays(today, -13);
  final earlierFrom = addDays(today, -70);
  // Když uživatel posledních 14 dní netrénoval vůbec, nejde o jednu partii.
  final trainedRecently = input.sessionDates.any((d) => !d.isBefore(recentFrom));
  if (!trainedRecently) return const [];

  final earlierCount = <MuscleGroup, int>{};
  final lastDay = <MuscleGroup, DateTime>{};
  final recentGroups = <MuscleGroup>{};
  for (final s in input.groupSessions) {
    if (s.day.isBefore(earlierFrom)) continue;
    if (!s.day.isBefore(recentFrom)) {
      recentGroups.add(s.group);
    } else {
      earlierCount[s.group] = (earlierCount[s.group] ?? 0) + 1;
    }
    final last = lastDay[s.group];
    if (last == null || s.day.isAfter(last)) lastDay[s.group] = s.day;
  }
  final neglected = [
    for (final e in earlierCount.entries)
      if (e.value >= 3 &&
          e.key != MuscleGroup.fullBody &&
          !recentGroups.contains(e.key) &&
          !input.injuredGroups.contains(e.key))
        e,
  ]..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final e in neglected.take(2))
      NeglectedGroupInsight(e.key, daysBetween(lastDay[e.key]!, today)),
  ];
}

List<Insight>? _consistency(InsightInput input) {
  final today = startOfDay(input.now);
  final from = addDays(today, -27);
  final inWindow = input.sessionDates
      .where((d) => !d.isBefore(from) && d.isBefore(addDays(today, 1)))
      .length;
  if (inWindow == 0) return null;
  // Nový uživatel: průměr jen za dobu od prvního tréninku (min. 1 týden).
  final first = input.sessionDates.reduce((a, b) => a.isBefore(b) ? a : b);
  final spanDays = math.min(28, daysBetween(first, today) + 1);
  final weeks = math.max(1.0, spanDays / 7);
  return [
    ConsistencyInsight(
      averagePerWeek: inWindow / weeks,
      plannedPerWeek: plannedDaysPerWeek(input.weekdayMasks),
    ),
  ];
}
