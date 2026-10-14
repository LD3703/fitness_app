// Přehledy pro trenéra (aplikace i web): poslední trénink, tréninky po
// týdnech, objem, vývoj nejtěžší váhy u cviku, osobní rekordy.
import 'workout.dart';

/// Začátek týdne (pondělí 00:00) pro [d].
/// (Přes kalendářní den, ne Duration – jinak by přechod na letní čas
/// posunul čas na 23:00 předchozího dne.)
DateTime coachWeekStart(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));

/// Jeden týden v grafu.
class WeekBucket {
  const WeekBucket(this.start, this.workouts, this.volumeKg);

  final DateTime start;
  final int workouts;
  final double volumeKg;
}

/// Posledních [weeks] týdnů (nejstarší první, poslední = aktuální týden).
List<WeekBucket> weeklyBuckets(
  Iterable<CoachWorkout> workouts, {
  required DateTime now,
  int weeks = 12,
}) {
  final current = coachWeekStart(now);
  final starts = [
    for (var i = weeks - 1; i >= 0; i--)
      DateTime(current.year, current.month, current.day - 7 * i),
  ];
  final counts = List<int>.filled(weeks, 0);
  final volumes = List<double>.filled(weeks, 0);
  for (final w in workouts) {
    final ws = coachWeekStart(w.startedAt);
    final i = starts.indexOf(ws);
    if (i < 0) continue;
    counts[i]++;
    volumes[i] += w.volumeKg;
  }
  return [
    for (var i = 0; i < weeks; i++) WeekBucket(starts[i], counts[i], volumes[i]),
  ];
}

/// Cvik, který klient dělal (pro výběr grafu).
class ExerciseOption {
  const ExerciseOption(this.key, this.nameEn, this.nameCs, this.count);

  final String key;
  final String nameEn;
  final String nameCs;

  /// V kolika trénincích byl.
  final int count;

  String nameFor(String lang) => lang == 'cs' ? nameCs : nameEn;
}

/// Cviky s váhou seřazené podle četnosti (nejčastější první).
List<ExerciseOption> exerciseOptions(Iterable<CoachWorkout> workouts) {
  final byKey = <String, ExerciseOption>{};
  for (final w in workouts) {
    for (final e in w.exercises) {
      if (e.topKg == null) continue;
      final prev = byKey[e.key];
      byKey[e.key] = ExerciseOption(
          e.key, e.nameEn, e.nameCs, (prev?.count ?? 0) + 1);
    }
  }
  final list = byKey.values.toList()
    ..sort((a, b) {
      final c = b.count.compareTo(a.count);
      return c != 0 ? c : a.nameEn.compareTo(b.nameEn);
    });
  return list;
}

/// Bod grafu.
class CoachPoint {
  const CoachPoint(this.date, this.value);

  final DateTime date;
  final double value;
}

/// Nejtěžší pracovní série cviku [key] v každém tréninku (od nejstaršího).
List<CoachPoint> topWeightSeries(
  Iterable<CoachWorkout> workouts,
  String key,
) {
  final points = <CoachPoint>[];
  for (final w in workouts) {
    double? best;
    for (final e in w.exercises) {
      if (e.key != key) continue;
      final kg = e.topKg;
      if (kg != null && (best == null || kg > best)) best = kg;
    }
    if (best != null) points.add(CoachPoint(w.startedAt, best));
  }
  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
}

/// Osobní rekord cviku (nejtěžší pracovní série).
class CoachRecord {
  const CoachRecord(this.option, this.kg, this.date);

  final ExerciseOption option;
  final double kg;
  final DateTime date;
}

/// Rekordy všech cviků s váhou (nejčastější cviky první).
List<CoachRecord> personalRecords(Iterable<CoachWorkout> workouts) {
  final list = workouts.toList();
  final records = <CoachRecord>[];
  for (final o in exerciseOptions(list)) {
    final series = topWeightSeries(list, o.key);
    CoachPoint? best;
    for (final p in series) {
      if (best == null || p.value > best.value) best = p;
    }
    if (best != null) records.add(CoachRecord(o, best.value, best.date));
  }
  return records;
}

/// Souhrn klienta pro seznam klientů.
class ClientSummary {
  const ClientSummary({
    required this.lastWorkout,
    required this.thisWeek,
    required this.avgPerWeek,
    required this.total,
  });

  /// Poslední trénink (null = zatím žádný).
  final DateTime? lastWorkout;

  /// Tréninky v aktuálním týdnu.
  final int thisWeek;

  /// Průměr tréninků za týden za posledních 4 celé týdny.
  final double avgPerWeek;
  final int total;

  /// Dní od posledního tréninku (null = žádný).
  int? daysSinceLast(DateTime now) {
    final last = lastWorkout;
    if (last == null) return null;
    // Přes UTC kalendářní dny – jinak by den s přechodem na letní čas
    // (23 h) ubral den.
    final a = DateTime.utc(last.year, last.month, last.day);
    final b = DateTime.utc(now.year, now.month, now.day);
    return b.difference(a).inDays;
  }

  /// Upozornit trenéra: klient netrénuje [days] dní a víc (nebo vůbec).
  bool inactive(DateTime now, {int days = 10}) =>
      (daysSinceLast(now) ?? days) >= days;
}

ClientSummary summarizeClient(
  Iterable<CoachWorkout> workouts, {
  required DateTime now,
}) {
  final list = workouts.toList();
  DateTime? last;
  for (final w in list) {
    if (last == null || w.startedAt.isAfter(last)) last = w.startedAt;
  }
  final buckets = weeklyBuckets(list, now: now, weeks: 5);
  final fullWeeks = buckets.take(4);
  final avg = fullWeeks.fold<int>(0, (n, b) => n + b.workouts) / 4;
  return ClientSummary(
    lastWorkout: last,
    thisWeek: buckets.last.workouts,
    avgPerWeek: avg,
    total: list.length,
  );
}
