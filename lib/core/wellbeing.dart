import '../data/enums.dart';
import 'date_utils.dart';

/// V jaké situaci uživatel je – podle ní volíme povzbuzující hlášky.
enum WellbeingSituation {
  normal,

  /// Probíhá období nemoci.
  illness,

  /// Probíhá období zranění.
  injury,

  /// Do [recoveryDays] dní po skončení nemoci.
  recovery,

  /// Probíhá dieta (cut) – síla může stagnovat.
  cut,
}

/// Kolik dní po skončení nemoci ještě počítáme s nižší výkonností.
const recoveryDays = 7;

/// Minimální údaje o období potřebné pro určení situace.
typedef PeriodSpan = ({PeriodType type, DateTime start, DateTime? end});

/// Určí situaci k datu [now]. Priorita: nemoc > zranění > po nemoci > dieta.
WellbeingSituation determineSituation(
  Iterable<PeriodSpan> periods,
  DateTime now,
) {
  final today = startOfDay(now);
  bool activeOf(PeriodType t) => periods.any((p) =>
      p.type == t &&
      !startOfDay(p.start).isAfter(today) &&
      (p.end == null || !startOfDay(p.end!).isBefore(today)));

  if (activeOf(PeriodType.illness)) return WellbeingSituation.illness;
  if (activeOf(PeriodType.injury)) return WellbeingSituation.injury;

  final recentlyRecovered = periods.any((p) {
    if (p.type != PeriodType.illness || p.end == null) return false;
    final days = daysBetween(startOfDay(p.end!), today);
    return days >= 1 && days <= recoveryDays;
  });
  if (recentlyRecovered) return WellbeingSituation.recovery;

  if (activeOf(PeriodType.cut)) return WellbeingSituation.cut;
  return WellbeingSituation.normal;
}

/// Počet kalendářních dní mezi dvěma daty (nezávisle na letním čase).
int daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

/// Vybere variantu hlášky pro daný den, aby se texty střídaly,
/// ale během jednoho dne zůstaly stejné. [salt] odliší různá místa.
int messageVariant(DateTime day, int count, {int salt = 0}) {
  if (count <= 0) return 0;
  final n = daysBetween(DateTime(2020), day) + salt;
  return n % count;
}
