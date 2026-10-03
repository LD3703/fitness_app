// Čistá logika synchronizace se zdravotními daty telefonu
// (Health Connect / Apple Zdraví) – bez závislosti na pluginu, aby šla testovat.

import '../../core/date_utils.dart';

/// Jedno měření váhy (z Health nebo z aplikace).
typedef WeightSample = ({DateTime at, double kg});

/// Rozumný rozsah tělesné váhy; jiné hodnoty z Health ignorujeme.
bool isPlausibleWeightKg(double kg) => kg >= 20 && kg <= 400;

/// Zaokrouhlení na 0,1 kg (stejná přesnost jako ruční zápis v aplikaci).
double roundWeightKg(double kg) => (kg * 10).round() / 10;

/// Váhy z Health, které chybí v aplikaci: pro každý den bez záznamu
/// v aplikaci poslední měření toho dne. Klíč = půlnoc dne.
Map<DateTime, double> weightsToImport({
  required Iterable<WeightSample> health,
  required Set<DateTime> appDays,
}) {
  final latest = <DateTime, WeightSample>{};
  for (final s in health) {
    if (!isPlausibleWeightKg(s.kg)) continue;
    final day = startOfDay(s.at);
    if (appDays.contains(day)) continue;
    final prev = latest[day];
    if (prev == null || s.at.isAfter(prev.at)) latest[day] = s;
  }
  return {
    for (final e in latest.entries) e.key: roundWeightKg(e.value.kg),
  };
}

/// Záznamy váhy z aplikace, které v Health pro daný den ještě nejsou.
/// [alreadyExported] = co už aplikace zapsala dřív (den → kg); brání
/// opakovanému zápisu, když Health nedovolí čtení (iOS to nepřizná).
List<({DateTime day, double kg})> weightsToExport({
  required Iterable<({DateTime day, double kg})> app,
  required Iterable<WeightSample> health,
  required DateTime from,
  Map<DateTime, double> alreadyExported = const {},
}) {
  final healthDays = {for (final s in health) startOfDay(s.at)};
  final start = startOfDay(from);
  return [
    for (final e in app)
      if (!startOfDay(e.day).isBefore(start) &&
          !healthDays.contains(startOfDay(e.day)) &&
          alreadyExported[startOfDay(e.day)] != e.kg)
        (day: startOfDay(e.day), kg: e.kg),
  ];
}

/// Čas, kterým se zapíše denní váha do Health: 8:00 toho dne,
/// ale nikdy ne v budoucnosti (dnešní záznam zapsaný před osmou).
DateTime weightSampleTime(DateTime day, DateTime now) {
  final d = startOfDay(day);
  final morning = DateTime(d.year, d.month, d.day, 8);
  if (morning.isBefore(now)) return morning;
  return now.isBefore(d) ? d : now;
}

/// Záznamy „už zapsáno do Health“ (den → kg) ve tvaru pro JSON.
Map<String, double> encodeExportedWeights(Map<DateTime, double> m) => {
      for (final e in m.entries)
        '${e.key.year.toString().padLeft(4, '0')}-'
            '${e.key.month.toString().padLeft(2, '0')}-'
            '${e.key.day.toString().padLeft(2, '0')}': e.value,
    };

Map<DateTime, double> decodeExportedWeights(Object? json) {
  final result = <DateTime, double>{};
  if (json is! Map) return result;
  for (final e in json.entries) {
    final key = e.key;
    final value = e.value;
    if (key is! String || value is! num) continue;
    final parts = key.split('-');
    if (parts.length != 3) continue;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) continue;
    result[DateTime(y, m, d)] = value.toDouble();
  }
  return result;
}

/// Ponechá jen záznamy od [from] (starší už nejsou potřeba).
Map<DateTime, double> pruneExportedWeights(
  Map<DateTime, double> m,
  DateTime from,
) {
  final start = startOfDay(from);
  return {
    for (final e in m.entries)
      if (!e.key.isBefore(start)) e.key: e.value,
  };
}

/// Omezení četnosti synchronizace (jen v paměti).
class SyncThrottle {
  SyncThrottle(this.interval, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final Duration interval;
  final DateTime Function() _clock;
  DateTime? _last;

  /// Vrátí true a zapamatuje si čas, pokud od posledního běhu uplynul
  /// aspoň [interval]; jinak false.
  bool tryAcquire() {
    final now = _clock();
    final last = _last;
    if (last != null && now.difference(last) < interval) return false;
    _last = now;
    return true;
  }

  void reset() => _last = null;
}
