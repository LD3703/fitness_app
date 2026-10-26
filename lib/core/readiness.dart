// Připravenost k tréninku z dat hodinek a prstenů (čistý Dart, testy:
// test/readiness_test.dart). Data čte modul health z Health Connect /
// Apple Zdraví (spánek, HRV, klidový tep), postup a zdroje jsou
// v docs/readiness.md.
//
// Princip: každý člověk má jiné „normální“ hodnoty, proto se vše
// porovnává s jeho vlastním průměrem za posledních 60 dní (HRV4Training,
// Oura). Bez aspoň 14 dní dat se HRV a klidový tep nevyhodnocují
// („učím se“), spánek ano – doporučení (aspoň 7 h) je pro všechny stejné.
//
// - HRV: vyhodnocuje se 7denní průměr ln(HRV) – denní hodnota hodně
//   kolísá (Plews a kol. 2012, AIS). Potřeba jsou aspoň 3 měření
//   v posledních 7 dnech. Normál = 60denní průměr ± 0,75 SD; pod
//   normálem = organismus se nestíhá zotavovat. Prudký jednodenní pokles
//   (pod průměr − 1,5 SD) je jen varování. Vyšší HRV než normál se
//   neřeší – „normální je lepší než vyšší“ (Altini).
// - Klidový tep: o 5+ tepů nad průměrem = varování, o 10+ = výrazně
//   zvýšený, 3 dny po sobě o 5+ = možná začínající nemoc nebo přetížení
//   (praxe trenérů; nemoc často zvedne tep dřív než příznaky).
// - Spánek: dospělí potřebují aspoň 7 h (AASM/SRS 2015). Pod 6 h je
//   „nedostatek spánku“ (Craven a kol. 2022), silové výkony ve
//   vícekloubových cvicích klesají hlavně po několika kratších nocích po
//   sobě (Knowles a kol. 2018) – sleduje se proto i dluh za 3 noci.
//
// Body: HRV pod normálem 2, prudký pokles HRV 1, tep +5 1, tep +10 2,
// tep 3 dny zvýšený 2, spánek < 6 h 1, < 5 h 2, dluh ≥ 3 h za 3 noci 1.
// 0 = dobrá připravenost, 1–2 = opatrně, 3+ = slabší regenerace.

import 'dart:math' as math;

import '../data/enums.dart';

/// Data jednoho dne (ráno po noci): spánek předchozí noci, HRV a klidový
/// tep. Chybějící údaje = null.
class RecoveryDay {
  const RecoveryDay({
    required this.day,
    this.sleepMinutes,
    this.hrvMs,
    this.restingHr,
  });

  /// Den (00:00 místního času), ke kterému se noc vztahuje (den probuzení).
  final DateTime day;
  final int? sleepMinutes;

  /// HRV v ms (Android RMSSD, iOS SDNN – porovnává se jen se stejným
  /// zdrojem, proto na typu nezáleží).
  final double? hrvMs;
  final double? restingHr;

  bool get isEmpty =>
      sleepMinutes == null && hrvMs == null && restingHr == null;
}

enum ReadinessLevel { good, caution, low }

/// Co připravenost snižuje (pořadí = pořadí v kartě).
enum ReadinessFactor {
  hrvLow,
  hrvDrop,
  restingHrHigh,
  restingHrElevated,
  restingHrSustained,
  sleepVeryShort,
  sleepShort,
  sleepBelow,
  sleepDebt,
}

/// Body faktoru (viz hlavička souboru). sleepBelow je jen informace.
int readinessPoints(ReadinessFactor f) => switch (f) {
      ReadinessFactor.hrvLow => 2,
      ReadinessFactor.hrvDrop => 1,
      ReadinessFactor.restingHrHigh => 2,
      ReadinessFactor.restingHrElevated => 1,
      ReadinessFactor.restingHrSustained => 2,
      ReadinessFactor.sleepVeryShort => 2,
      ReadinessFactor.sleepShort => 1,
      ReadinessFactor.sleepBelow => 0,
      ReadinessFactor.sleepDebt => 1,
    };

/// Doporučení k tréninku.
enum ReadinessAdvice {
  /// Trénink podle plánu.
  train,

  /// Podle plánu, ale bez rekordů: 2 opakování v záloze, delší pauzy.
  trainEasy,

  /// Lehčí trénink (o třetinu méně sérií, váhy −10 %), nebo Plán B.
  lighter,

  /// Odpočinek – klidový tep je výrazně / dlouho zvýšený (možná nemoc).
  rest,
}

/// Rozsah normálních hodnot.
typedef NormalRange = ({double low, double high});

class ReadinessReport {
  const ReadinessReport({
    required this.level,
    required this.factors,
    required this.advice,
    required this.baselineDays,
    this.hrv7DayMs,
    this.hrvTodayMs,
    this.hrvNormalMs,
    this.restingHrToday,
    this.restingHrBaseline,
    this.sleepMinutes,
    this.sleepDebtMinutes = 0,
  });

  final ReadinessLevel level;
  final List<ReadinessFactor> factors;
  final ReadinessAdvice advice;

  /// Kolik dní s HRV nebo klidovým tepem je v 60denním okně (pro
  /// „učím se: X z 14 dní“).
  final int baselineDays;

  /// 7denní průměr HRV (zpět z ln, ms) a dnešní hodnota.
  final double? hrv7DayMs;
  final double? hrvTodayMs;

  /// Normální rozsah HRV v ms (null = málo dat).
  final NormalRange? hrvNormalMs;
  final double? restingHrToday;

  /// 60denní průměr klidového tepu (null = málo dat).
  final double? restingHrBaseline;

  /// Spánek poslední noci.
  final int? sleepMinutes;

  /// Spánkový dluh za poslední 3 noci (proti 7 h).
  final int sleepDebtMinutes;

  /// HRV i klidový tep mají dost dat pro porovnání s normálem.
  bool get learning => baselineDays < kReadinessMinBaselineDays;

  int get points => factors.fold(0, (sum, f) => sum + readinessPoints(f));
}

/// Délka okna pro normální hodnoty (dny před dneškem).
const kReadinessBaselineDays = 60;

/// Kolik dní dat je potřeba, než se HRV a tep porovnávají s normálem.
const kReadinessMinBaselineDays = 14;

/// Šířka normálního rozsahu HRV v násobcích SD.
const kHrvNormalSd = 0.75;

/// Spodní mez SD ln(HRV): u velmi stabilních hodnot (nebo zaokrouhlených
/// dat ze zařízení) by byl normál tak úzký, že by „mimo“ byla každá noc.
/// Běžná variabilita ln(rMSSD) mezi dny je 0,1–0,2.
const kHrvMinSd = 0.08;

/// Doporučený spánek (min) – AASM/SRS 2015: aspoň 7 h.
const kSleepTargetMinutes = 7 * 60;

DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);

double _mean(Iterable<double> v) => v.reduce((a, b) => a + b) / v.length;

double _sd(List<double> v) {
  if (v.length < 2) return 0;
  final m = _mean(v);
  final sumSq = v.fold<double>(0, (s, x) => s + (x - m) * (x - m));
  return math.sqrt(sumSq / (v.length - 1));
}

/// Vyhodnotí připravenost pro den [today] z denních dat [days] (pořadí
/// nezáleží, dny po [today] se ignorují). Null = žádná data za poslední
/// 2 dny (nic se neukazuje).
ReadinessReport? evaluateReadiness(List<RecoveryDay> days, DateTime today) {
  final t = _date(today);
  final byDay = <DateTime, RecoveryDay>{
    for (final d in days)
      if (!_date(d.day).isAfter(t)) _date(d.day): d,
  };
  final todayData = byDay[t];
  final yesterday = byDay[DateTime(t.year, t.month, t.day - 1)];
  if ((todayData == null || todayData.isEmpty) &&
      (yesterday == null || yesterday.isEmpty)) {
    return null;
  }

  RecoveryDay? at(int daysAgo) =>
      byDay[DateTime(t.year, t.month, t.day - daysAgo)];

  // 60 dní před dneškem.
  final baseline = [
    for (var i = 1; i <= kReadinessBaselineDays; i++)
      if (at(i) case final d?) d,
  ];
  final baseLnHrv = [
    for (final d in baseline)
      if (d.hrvMs case final h? when h > 0) math.log(h),
  ];
  final baseRhr = [
    for (final d in baseline)
      if (d.restingHr case final r? when r > 0) r,
  ];
  final baselineDays = baseline
      .where((d) => (d.hrvMs ?? 0) > 0 || (d.restingHr ?? 0) > 0)
      .length;

  final factors = <ReadinessFactor>{};

  // --- HRV ---
  double? hrv7;
  double? hrvToday;
  NormalRange? normal;
  final last7 = [
    for (var i = 0; i < 7; i++)
      if (at(i)?.hrvMs case final h? when h > 0) math.log(h),
  ];
  if (last7.length >= 3) hrv7 = math.exp(_mean(last7));
  if (todayData?.hrvMs case final h? when h > 0) hrvToday = h;
  if (baseLnHrv.length >= kReadinessMinBaselineDays) {
    final mean = _mean(baseLnHrv);
    final sd = math.max(_sd(baseLnHrv), kHrvMinSd);
    normal = (
      low: math.exp(mean - kHrvNormalSd * sd),
      high: math.exp(mean + kHrvNormalSd * sd),
    );
    if (last7.length >= 3 && _mean(last7) < mean - kHrvNormalSd * sd) {
      factors.add(ReadinessFactor.hrvLow);
    }
    if (hrvToday != null && math.log(hrvToday) < mean - 1.5 * sd) {
      factors.add(ReadinessFactor.hrvDrop);
    }
  }

  // --- Klidový tep ---
  final rhrToday = todayData?.restingHr;
  double? rhrBase;
  if (baseRhr.length >= kReadinessMinBaselineDays) {
    rhrBase = _mean(baseRhr);
    final base = rhrBase;
    if (rhrToday != null && rhrToday > 0) {
      final diff = rhrToday - base;
      if (diff >= 10) {
        factors.add(ReadinessFactor.restingHrHigh);
      } else if (diff >= 5) {
        factors.add(ReadinessFactor.restingHrElevated);
      }
    }
    final sustained = [0, 1, 2].every((i) {
      final r = at(i)?.restingHr;
      return r != null && r - base >= 5;
    });
    if (sustained) factors.add(ReadinessFactor.restingHrSustained);
  }

  // --- Spánek ---
  final sleep = todayData?.sleepMinutes;
  if (sleep != null) {
    if (sleep < 5 * 60) {
      factors.add(ReadinessFactor.sleepVeryShort);
    } else if (sleep < 6 * 60) {
      factors.add(ReadinessFactor.sleepShort);
    } else if (sleep < kSleepTargetMinutes) {
      factors.add(ReadinessFactor.sleepBelow);
    }
  }
  var debt = 0;
  for (var i = 0; i < 3; i++) {
    final s = at(i)?.sleepMinutes;
    if (s != null && s < kSleepTargetMinutes) debt += kSleepTargetMinutes - s;
  }
  if (debt >= 180) factors.add(ReadinessFactor.sleepDebt);

  final ordered = [
    for (final f in ReadinessFactor.values)
      if (factors.contains(f)) f,
  ];
  final points = ordered.fold(0, (sum, f) => sum + readinessPoints(f));
  final level = points >= 3
      ? ReadinessLevel.low
      : points >= 1
          ? ReadinessLevel.caution
          : ReadinessLevel.good;
  final illnessSign = factors.contains(ReadinessFactor.restingHrSustained) &&
      (factors.contains(ReadinessFactor.restingHrHigh) ||
          factors.contains(ReadinessFactor.hrvLow));
  final advice = switch (level) {
    ReadinessLevel.good => ReadinessAdvice.train,
    ReadinessLevel.caution => ReadinessAdvice.trainEasy,
    ReadinessLevel.low =>
      illnessSign ? ReadinessAdvice.rest : ReadinessAdvice.lighter,
  };

  return ReadinessReport(
    level: level,
    factors: ordered,
    advice: advice,
    baselineDays: baselineDays,
    hrv7DayMs: hrv7,
    hrvTodayMs: hrvToday,
    hrvNormalMs: normal,
    restingHrToday: rhrToday,
    restingHrBaseline: rhrBase,
    sleepMinutes: sleep,
    sleepDebtMinutes: debt,
  );
}

// ---------------------------------------------------------------------
// Denní hodnoty ze vzorků (Health Connect / Apple Zdraví)
// ---------------------------------------------------------------------

/// Úsek spánku (fáze spánku nebo celá noc) z jednoho zdroje.
typedef SleepInterval = ({DateTime start, DateTime end});

/// Noc ke dni [day]: od 18:00 předchozího dne do 14:00 dne [day].
({DateTime start, DateTime end}) nightWindow(DateTime day) {
  final d = _date(day);
  return (
    start: DateTime(d.year, d.month, d.day - 1, 18),
    end: DateTime(d.year, d.month, d.day, 14),
  );
}

/// Minuty spánku v noci ke dni [day]. Úseky se sjednotí, takže prsten
/// a hodinky zapisující stejnou noc se nesečtou dvakrát.
int? sleepMinutesForDay(List<SleepInterval> intervals, DateTime day) {
  final w = nightWindow(day);
  final clipped = <SleepInterval>[
    for (final i in intervals)
      if (i.end.isAfter(w.start) && i.start.isBefore(w.end))
        (
          start: i.start.isBefore(w.start) ? w.start : i.start,
          end: i.end.isAfter(w.end) ? w.end : i.end,
        ),
  ]..sort((a, b) => a.start.compareTo(b.start));
  if (clipped.isEmpty) return null;
  var total = Duration.zero;
  var curStart = clipped.first.start;
  var curEnd = clipped.first.end;
  for (final i in clipped.skip(1)) {
    if (i.start.isAfter(curEnd)) {
      total += curEnd.difference(curStart);
      curStart = i.start;
      curEnd = i.end;
    } else if (i.end.isAfter(curEnd)) {
      curEnd = i.end;
    }
  }
  total += curEnd.difference(curStart);
  final minutes = total.inMinutes;
  return minutes > 0 ? minutes : null;
}

/// Medián (odolný vůči ojedinělým chybným měřením).
double? median(Iterable<double> values) {
  final v = values.toList()..sort();
  if (v.isEmpty) return null;
  final mid = v.length ~/ 2;
  return v.length.isOdd ? v[mid] : (v[mid - 1] + v[mid]) / 2;
}

/// Vzorek hodnoty v čase (HRV, tep).
typedef TimedValue = ({DateTime at, double value});

/// HRV ke dni [day]: medián měření během noci (u hodinek a prstenů
/// nejspolehlivější – klid, stejná poloha).
double? hrvForDay(List<TimedValue> samples, DateTime day) {
  final w = nightWindow(day);
  return median([
    for (final s in samples)
      if (!s.at.isBefore(w.start) && s.at.isBefore(w.end) && s.value > 0)
        s.value,
  ]);
}

/// Klidový tep ke dni [day]: medián hodnot zapsaných během dne [day]
/// (Apple ho počítá z celého dne, prsteny a Health Connect ráno).
double? restingHrForDay(List<TimedValue> samples, DateTime day) {
  final d = _date(day);
  final end = DateTime(d.year, d.month, d.day + 1);
  return median([
    for (final s in samples)
      if (!s.at.isBefore(d) && s.at.isBefore(end) && s.value > 20) s.value,
  ]);
}

// ---------------------------------------------------------------------
// Tep během tréninku
// ---------------------------------------------------------------------

/// Odhad maximálního tepu podle věku: 208 − 0,7 × věk (Tanaka a kol.
/// 2001, přesnější než 220 − věk; individuálně ±10 tepů).
double estimatedMaxHr(int age) => 208 - 0.7 * age;

/// Zóny tepu podle % maximálního tepu: 1 = 50–60 %, 2 = 60–70 %,
/// 3 = 70–80 %, 4 = 80–90 %, 5 = 90+ % (pod 50 % = 0).
int heartRateZone(double bpm, double maxHr) {
  final p = bpm / maxHr;
  if (p >= 0.9) return 5;
  if (p >= 0.8) return 4;
  if (p >= 0.7) return 3;
  if (p >= 0.6) return 2;
  if (p >= 0.5) return 1;
  return 0;
}

class HeartRateSummary {
  const HeartRateSummary({
    required this.average,
    required this.max,
    required this.zoneSeconds,
  });

  final int average;
  final int max;

  /// Sekundy v zónách 0–5 (prázdné, když není známý věk).
  final List<int> zoneSeconds;

  /// Zóny jako text do databáze („0,120,600,…“).
  String get zonesText => zoneSeconds.join(',');

  static List<int> zonesFromText(String? text) => [
        for (final p in (text ?? '').split(','))
          if (int.tryParse(p) case final v?) v,
      ];
}

/// Souhrn tepu ze vzorků během tréninku. Každý vzorek platí do dalšího
/// (nejvýš 60 s – mezery v měření se nepočítají). Null = málo dat.
HeartRateSummary? summarizeHeartRate(
  List<TimedValue> samples, {
  required DateTime start,
  required DateTime end,
  int? age,
}) {
  final s = [
    for (final x in samples)
      if (!x.at.isBefore(start) &&
          !x.at.isAfter(end) &&
          x.value > 30 &&
          x.value < 240)
        x,
  ]..sort((a, b) => a.at.compareTo(b.at));
  if (s.length < 3) return null;
  var weighted = 0.0;
  var seconds = 0;
  var maxBpm = 0.0;
  final zones = List.filled(6, 0);
  final maxHr = age == null ? null : estimatedMaxHr(age);
  for (var i = 0; i < s.length; i++) {
    final next = i + 1 < s.length ? s[i + 1].at : end;
    final dt = math.min(next.difference(s[i].at).inSeconds, 60);
    final w = math.max(dt, 1);
    weighted += s[i].value * w;
    seconds += w;
    maxBpm = math.max(maxBpm, s[i].value);
    if (maxHr != null) zones[heartRateZone(s[i].value, maxHr)] += w;
  }
  return HeartRateSummary(
    average: (weighted / seconds).round(),
    max: maxBpm.round(),
    zoneSeconds: maxHr == null ? const [] : zones,
  );
}

/// Energie podle průměrného tepu (Keytel a kol. 2005, rovnice bez
/// VO2max): kJ/min, převedeno na kcal za [minutes]. Null = chybí věk,
/// váha nebo pohlaví, nebo vyjde nesmysl.
int? heartRateKcal({
  required int avgHr,
  required double minutes,
  required double? weightKg,
  required int? age,
  required Sex? sex,
}) {
  if (weightKg == null || age == null || sex == null || minutes <= 0) {
    return null;
  }
  final kjPerMin = sex == Sex.male
      ? -55.0969 + 0.6309 * avgHr + 0.1988 * weightKg + 0.2017 * age
      : -20.4022 + 0.4472 * avgHr - 0.1263 * weightKg + 0.074 * age;
  if (kjPerMin <= 0) return null;
  return (kjPerMin * minutes / 4.184).round();
}

// ---------------------------------------------------------------------
// Lehčí trénink
// ---------------------------------------------------------------------

/// Váhy v lehčím tréninku: −10 %.
const kLightWeightFactor = 0.9;

/// Cíle série v lehčím tréninku: o třetinu méně pracovních sérií
/// (zaokrouhleno dolů, aspoň 1 série zůstane), rozcvičky a drop série
/// zůstávají. Váhy cílů −10 % (zaokrouhlí obrazovka tréninku).
List<T> lighterTargets<T>(
  List<T> targets, {
  required bool Function(T) isWorking,
}) {
  final working = targets.where(isWorking).length;
  final drop = working ~/ 3;
  if (drop == 0) return targets;
  var removed = 0;
  final result = <T>[];
  // Odebírají se poslední pracovní série.
  for (final t in targets.reversed) {
    if (isWorking(t) && removed < drop) {
      removed++;
      continue;
    }
    result.add(t);
  }
  return result.reversed.toList();
}
