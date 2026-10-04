/// Odhad maxima na 1 opakování (1RM) podle Epleyho vzorce:
/// 1RM = w × (1 + r / 30).
///
/// Vrací null pro neplatné vstupy. Pro 1 opakování vrací přímo váhu.
/// Nad 12 opakování je odhad výrazně nepřesný – volající může
/// takové série ze statistik vynechat.
double? estimateOneRepMax(double weightKg, int reps) {
  if (weightKg <= 0 || reps <= 0) return null;
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30);
}

/// Odhad spálených kalorií z MET hodnoty:
/// kcal = MET × hmotnost (kg) × doba (h).
/// Je to jen orientační odhad – v aplikaci ho tak vždy označuj.
double estimateKcal({
  required double met,
  required double bodyWeightKg,
  required Duration duration,
}) {
  if (met <= 0 || bodyWeightKg <= 0 || duration.isNegative) return 0;
  return met * bodyWeightKg * duration.inSeconds / 3600;
}

/// Maximální váha pro daný počet opakování z odhadu 1RM
/// (obrácený Epleyho vzorec): w = 1RM / (1 + r / 30).
double weightForReps(double oneRepMax, int reps) {
  if (oneRepMax <= 0 || reps <= 0) return 0;
  if (reps == 1) return oneRepMax;
  return oneRepMax / (1 + reps / 30);
}

/// Zaokrouhlí váhu na nejbližší násobek [step] (kotouče po 1,25 kg → 2,5 kg).
double roundToStep(double kg, {double step = 2.5}) {
  if (step <= 0) return kg;
  return (kg / step).round() * step;
}

/// Orientační návrh pracovní váhy: [intensity] z maxima pro daný počet
/// opakování (0,9 = zhruba 1–2 opakování v rezervě), zaokrouhleno.
double suggestWorkingWeight(
  double oneRepMax,
  int reps, {
  double intensity = 0.9,
  double step = 2.5,
}) =>
    roundToStep(weightForReps(oneRepMax, reps) * intensity, step: step);

/// Skupina po sobě jdoucích stejných sérií, např. 3 × 10 × 60 kg.
typedef SetGroup = ({
  int count,
  int reps,
  double? weightKg,
  bool isWarmup,
  bool isDrop,
});

/// Sloučí po sobě jdoucí stejné série do skupin pro stručný popis plánu.
/// Rozcvičky a drop série se slučují jen se sériemi stejného druhu.
List<SetGroup> groupSets(
  Iterable<({int reps, double? weightKg, bool isWarmup, bool isDrop})> sets,
) {
  final groups = <SetGroup>[];
  for (final s in sets) {
    if (groups.isNotEmpty) {
      final last = groups.last;
      if (last.reps == s.reps &&
          last.weightKg == s.weightKg &&
          last.isWarmup == s.isWarmup &&
          last.isDrop == s.isDrop) {
        groups[groups.length - 1] = (
          count: last.count + 1,
          reps: last.reps,
          weightKg: last.weightKg,
          isWarmup: last.isWarmup,
          isDrop: last.isDrop,
        );
        continue;
      }
    }
    groups.add((
      count: 1,
      reps: s.reps,
      weightKg: s.weightKg,
      isWarmup: s.isWarmup,
      isDrop: s.isDrop,
    ));
  }
  return groups;
}

/// Váha drop série: o [dropFraction] nižší než [previousKg], zaokrouhlená
/// na krok kotoučů [step] (v kg). Null, když by vyšla 0 nebo méně.
double? dropSetWeight(
  double previousKg, {
  double dropFraction = 0.2,
  double step = 2.5,
}) {
  if (previousKg <= 0) return null;
  final w = roundToStep(previousKg * (1 - dropFraction), step: step);
  if (w <= 0) return null;
  // Zaokrouhlení nahoru by mohlo vrátit stejnou váhu – drop musí být nižší.
  if (w >= previousKg) {
    final lower = w - step;
    return lower > 0 ? lower : null;
  }
  return w;
}

/// Klouzavý průměr časové řady: pro každý bod průměr hodnot za posledních
/// [windowDays] dní (včetně dne bodu). Vyhlazuje denní výkyvy váhy.
List<({DateTime x, double y})> movingAverage(
  List<({DateTime x, double y})> points, {
  int windowDays = 7,
}) {
  final sorted = [...points]..sort((a, b) => a.x.compareTo(b.x));
  final result = <({DateTime x, double y})>[];
  for (final p in sorted) {
    final from = DateTime(p.x.year, p.x.month, p.x.day - (windowDays - 1));
    final window = sorted.where((q) => !q.x.isBefore(from) && !q.x.isAfter(p.x));
    final avg = window.map((q) => q.y).reduce((a, b) => a + b) / window.length;
    result.add((x: p.x, y: avg));
  }
  return result;
}

/// Počet tréninků v jednotlivých týdnech (pondělí–neděle), od nejstaršího.
/// [weeks] týdnů končících týdnem obsahujícím [now].
List<({DateTime weekStart, int count})> weeklyCounts(
  Iterable<DateTime> dates,
  DateTime now, {
  int weeks = 12,
}) {
  final thisMonday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  final starts = [
    for (var i = weeks - 1; i >= 0; i--)
      DateTime(thisMonday.year, thisMonday.month, thisMonday.day - 7 * i),
  ];
  final counts = List<int>.filled(weeks, 0);
  for (final d in dates) {
    for (var i = 0; i < weeks; i++) {
      final end = DateTime(starts[i].year, starts[i].month, starts[i].day + 7);
      if (!d.isBefore(starts[i]) && d.isBefore(end)) {
        counts[i]++;
        break;
      }
    }
  }
  return [for (var i = 0; i < weeks; i++) (weekStart: starts[i], count: counts[i])];
}
