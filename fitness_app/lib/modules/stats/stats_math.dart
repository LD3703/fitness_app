// Čisté pomocné výpočty statistik (bez Flutteru, testovatelné).

import '../../core/date_utils.dart';

/// Bod časové řady (stejný tvar jako SeriesPoint v databázi).
typedef StatPoint = ({DateTime x, double y});

/// Pondělí (00:00) týdne, do kterého patří [d].
DateTime weekStartOf(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

/// [d] posunuté o [days] kalendářních dní (odolné vůči letnímu času).
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Počet různých dní v týdnu, na které má uživatel naplánovaný trénink
/// (sjednocení bitových masek plánů; bit 0 = pondělí … bit 6 = neděle).
int plannedDaysPerWeek(Iterable<int> weekdayMasks) {
  var union = 0;
  for (final m in weekdayMasks) {
    union |= m & 0x7F;
  }
  var count = 0;
  for (var i = 0; i < 7; i++) {
    if (union & (1 << i) != 0) count++;
  }
  return count;
}

/// Součet hodnot po týdnech (pondělí–neděle), od nejstaršího.
/// [weeks] týdnů končících týdnem obsahujícím [now].
List<({DateTime weekStart, double total})> weeklySums(
  Iterable<StatPoint> points,
  DateTime now, {
  int weeks = 12,
}) {
  final thisMonday = weekStartOf(now);
  final starts = [
    for (var i = weeks - 1; i >= 0; i--) addDays(thisMonday, -7 * i),
  ];
  final index = {for (var i = 0; i < weeks; i++) starts[i]: i};
  final totals = List<double>.filled(weeks, 0);
  for (final p in points) {
    final i = index[weekStartOf(p.x)];
    if (i != null) totals[i] += p.y;
  }
  return [
    for (var i = 0; i < weeks; i++) (weekStart: starts[i], total: totals[i]),
  ];
}

/// Počet záznamů v jednotlivých dnech (klíč = půlnoc dne).
Map<DateTime, int> dailyCounts(Iterable<DateTime> dates) {
  final result = <DateTime, int>{};
  for (final d in dates) {
    final day = startOfDay(d);
    result[day] = (result[day] ?? 0) + 1;
  }
  return result;
}

/// Průměr hodnot s časem v intervalu [from, toExclusive), null když žádné
/// nejsou nebo jich je méně než [minCount].
double? averageBetween(
  Iterable<StatPoint> points,
  DateTime from,
  DateTime toExclusive, {
  int minCount = 1,
}) {
  var sum = 0.0;
  var n = 0;
  for (final p in points) {
    if (!p.x.isBefore(from) && p.x.isBefore(toExclusive)) {
      sum += p.y;
      n++;
    }
  }
  if (n == 0 || n < minCount) return null;
  return sum / n;
}

/// Nejvyšší hodnota s časem v intervalu [from, toExclusive), nebo null.
double? bestBetween(
  Iterable<StatPoint> points,
  DateTime from,
  DateTime toExclusive,
) {
  double? best;
  for (final p in points) {
    if (!p.x.isBefore(from) && p.x.isBefore(toExclusive)) {
      if (best == null || p.y > best) best = p.y;
    }
  }
  return best;
}
