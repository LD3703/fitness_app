// Čistá logika hledání volných oken v kalendáři (bez Flutteru a pluginů,
// aby šla testovat).

/// Událost z kalendáře telefonu (jen to, co potřebujeme).
class CalendarEntry {
  const CalendarEntry({
    required this.title,
    required this.start,
    required this.end,
    this.allDay = false,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final bool allDay;

  @override
  String toString() => 'CalendarEntry($title, $start – $end, allDay: $allDay)';
}

/// Volné okno [start, end).
typedef TimeWindow = ({DateTime start, DateTime end});

/// Navržený začátek tréninku; [distance] = o kolik minut se liší od
/// preferovaného času (0 = přesně v preferovaném rozmezí).
typedef SlotSuggestion = ({DateTime start, int distance});

/// Výchozí hodnoty hledání.
const kFreeDayStartMinutes = 6 * 60;
const kFreeDayEndMinutes = 22 * 60;
const kDefaultWorkoutMinutes = 60;
const kEventBufferMinutes = 15;

/// Preferované rozmezí začátku, když plán nemá vlastní čas:
/// trénink mezi 17:00 a 19:00 → začátek 17:00–18:00.
const kPreferredFromMinutes = 17 * 60;
const kPreferredToMinutes = 18 * 60;

DateTime _at(DateTime day, int minutes) =>
    DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);

int _minutesOf(DateTime day, DateTime t) {
  final midnight = DateTime(day.year, day.month, day.day);
  return t.difference(midnight).inMinutes;
}

/// Události, které trénink [start, end) překrývají (celodenní se ignorují).
List<CalendarEntry> collisionsWith(
  Iterable<CalendarEntry> entries,
  DateTime start,
  DateTime end,
) {
  final result = [
    for (final e in entries)
      if (!e.allDay && e.start.isBefore(end) && e.end.isAfter(start)) e,
  ]..sort((a, b) => a.start.compareTo(b.start));
  return result;
}

/// Volná okna dne [day] mezi [dayStartMinutes] a [dayEndMinutes].
///
/// Každá událost se rozšíří o [bufferMinutes] na obě strany (cesta,
/// převlečení). Celodenní události se ignorují. Vrací jen okna dlouhá
/// aspoň [minMinutes]. [notBefore] ořízne začátek (např. „teď“ u dneška).
List<TimeWindow> freeWindows({
  required DateTime day,
  required Iterable<CalendarEntry> entries,
  int dayStartMinutes = kFreeDayStartMinutes,
  int dayEndMinutes = kFreeDayEndMinutes,
  int minMinutes = kDefaultWorkoutMinutes,
  int bufferMinutes = kEventBufferMinutes,
  DateTime? notBefore,
}) {
  var windowStart = _at(day, dayStartMinutes);
  final windowEnd = _at(day, dayEndMinutes);
  if (notBefore != null && notBefore.isAfter(windowStart)) {
    windowStart = notBefore;
  }
  if (!windowEnd.isAfter(windowStart)) return const [];

  final buffer = Duration(minutes: bufferMinutes);
  final busy = <TimeWindow>[
    for (final e in entries)
      if (!e.allDay && e.end.isAfter(e.start))
        (start: e.start.subtract(buffer), end: e.end.add(buffer)),
  ]
    // Jen to, co zasahuje do sledovaného rozmezí.
    ..removeWhere(
        (b) => !b.end.isAfter(windowStart) || !b.start.isBefore(windowEnd))
    ..sort((a, b) => a.start.compareTo(b.start));

  final free = <TimeWindow>[];
  var cursor = windowStart;
  for (final b in busy) {
    if (b.start.isAfter(cursor)) {
      free.add((start: cursor, end: b.start));
    }
    if (b.end.isAfter(cursor)) cursor = b.end;
  }
  if (windowEnd.isAfter(cursor)) free.add((start: cursor, end: windowEnd));

  final min = Duration(minutes: minMinutes);
  return [
    for (final w in free)
      if (w.end.difference(w.start) >= min)
        (
          start: w.start.isBefore(windowStart) ? windowStart : w.start,
          end: w.end.isAfter(windowEnd) ? windowEnd : w.end,
        ),
  ];
}

/// Pro každé volné okno navrhne nejlepší začátek tréninku dlouhého
/// [durationMinutes] co nejblíž preferovanému rozmezí začátku
/// [preferredFrom]–[preferredTo] (minuty od půlnoci). Začátky se
/// zaokrouhlují na čtvrthodiny. Výsledek je seřazený od nejlepšího.
List<SlotSuggestion> suggestStarts({
  required DateTime day,
  required Iterable<TimeWindow> windows,
  int durationMinutes = kDefaultWorkoutMinutes,
  int preferredFrom = kPreferredFromMinutes,
  int preferredTo = kPreferredToMinutes,
}) {
  final result = <SlotSuggestion>[];
  for (final w in windows) {
    final lo = _roundUp(_minutesOf(day, w.start), 15);
    final hi = _roundDown(_minutesOf(day, w.end) - durationMinutes, 15);
    if (hi < lo) continue;
    final int start;
    final int distance;
    if (hi < preferredFrom) {
      start = hi;
      distance = preferredFrom - hi;
    } else if (lo > preferredTo) {
      start = lo;
      distance = lo - preferredTo;
    } else {
      start = lo > preferredFrom ? lo : _roundUp(preferredFrom, 15);
      distance = start > preferredTo ? start - preferredTo : 0;
    }
    result.add((start: _at(day, start), distance: distance));
  }
  result.sort((a, b) {
    final c = a.distance.compareTo(b.distance);
    return c != 0 ? c : a.start.compareTo(b.start);
  });
  return result;
}

/// Preferované rozmezí začátku: čas plánu, jinak 17:00–18:00.
({int from, int to}) preferredRange(int? planMinutes) => planMinutes == null
    ? (from: kPreferredFromMinutes, to: kPreferredToMinutes)
    : (from: planMinutes, to: planMinutes);

int _roundUp(int minutes, int step) =>
    minutes % step == 0 ? minutes : minutes + step - minutes % step;

int _roundDown(int minutes, int step) => minutes - minutes % step;

/// Časy připomínek pití v jednom dni: od [startMinutes] po [intervalMinutes]
/// až do [endMinutes] (včetně). Nejvýš [maxCount] připomínek.
List<int> waterReminderMinutes({
  required int startMinutes,
  required int endMinutes,
  required int intervalMinutes,
  int maxCount = 24,
}) {
  if (intervalMinutes <= 0 || endMinutes < startMinutes) return const [];
  return [
    for (var m = startMinutes;
        m <= endMinutes && m < 24 * 60;
        m += intervalMinutes)
      m,
  ].take(maxCount).toList();
}

/// Volná okna jednoho dne.
typedef DayWindows = ({DateTime day, List<TimeWindow> windows});

/// Čas začátku (minuty od půlnoci), který je volný ve všech dnech [days].
typedef CommonStart = ({int minutes, int distance});

/// Najde začátky tréninku (po čtvrthodinách), kdy je volno ve všech dnech
/// [days] – plán má jeden čas pro všechny své dny. Seřazeno podle
/// vzdálenosti od preferovaného rozmezí, navržené časy jsou od sebe
/// aspoň [minGapMinutes], nejvýš [limit] návrhů.
List<CommonStart> commonStarts({
  required List<DayWindows> days,
  int durationMinutes = kDefaultWorkoutMinutes,
  int preferredFrom = kPreferredFromMinutes,
  int preferredTo = kPreferredToMinutes,
  int limit = 3,
  int minGapMinutes = 60,
}) {
  if (days.isEmpty) return const [];
  final duration = Duration(minutes: durationMinutes);
  bool fits(DayWindows d, int m) {
    final start = _at(d.day, m);
    final end = start.add(duration);
    return d.windows
        .any((w) => !w.start.isAfter(start) && !w.end.isBefore(end));
  }

  final candidates = <CommonStart>[
    for (var m = 0; m + durationMinutes <= 24 * 60; m += 15)
      if (days.every((d) => fits(d, m)))
        (
          minutes: m,
          distance: m < preferredFrom
              ? preferredFrom - m
              : (m > preferredTo ? m - preferredTo : 0),
        ),
  ]..sort((a, b) {
      final c = a.distance.compareTo(b.distance);
      return c != 0 ? c : a.minutes.compareTo(b.minutes);
    });

  final picked = <CommonStart>[];
  for (final c in candidates) {
    if (picked.length >= limit) break;
    if (picked.every((p) => (p.minutes - c.minutes).abs() >= minGapMinutes)) {
      picked.add(c);
    }
  }
  return picked;
}
