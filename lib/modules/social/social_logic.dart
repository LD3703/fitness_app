// Čistá logika sociálních funkcí (bez Firebase a Flutteru) – testovatelná.
import 'dart:math';

// ---------------------------------------------------------------------------
// Týdny a měsíce
// ---------------------------------------------------------------------------

/// Pondělí (00:00 místního času) týdne, do kterého patří [d].
DateTime isoWeekStart(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

/// Klíč ISO týdne, např. „2026-W40“. Týden patří do roku, ve kterém
/// leží jeho čtvrtek.
String isoWeekKey(DateTime d) {
  final date = DateTime.utc(d.year, d.month, d.day);
  final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
  final firstJan = DateTime.utc(thursday.year, 1, 1);
  final week = thursday.difference(firstJan).inDays ~/ 7 + 1;
  return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
}

/// Klíč měsíce, např. „2026-09“.
String monthKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

/// Klíče posledních [count] týdnů od aktuálního (index 0 = tento týden).
List<String> recentWeekKeys(DateTime now, int count) {
  final start = isoWeekStart(now);
  return [
    for (var i = 0; i < count; i++)
      isoWeekKey(DateTime(start.year, start.month, start.day - 7 * i)),
  ];
}

/// Počet týdnů, které publikujeme pro společné série.
const publishedWeeks = 12;

// ---------------------------------------------------------------------------
// Plán splněn / společná série
// ---------------------------------------------------------------------------

/// Týden je splněný, když počet tréninků dosáhl počtu naplánovaných dnů
/// (bez plánu stačí jeden trénink).
bool isPlanMet({required int workouts, required int plannedPerWeek}) =>
    workouts >= max(1, plannedPerWeek);

/// Počet naplánovaných tréninků za týden podle masek dnů plánů.
int plannedPerWeek(Iterable<int> weekdayMasks) {
  var total = 0;
  for (final mask in weekdayMasks) {
    for (var i = 0; i < 7; i++) {
      if (mask & (1 << i) != 0) total++;
    }
  }
  return total;
}

/// Společná série: kolik týdnů za sebou oba splnili plán.
///
/// Aktuální (rozběhnutý) týden se započítá, jen když ho už oba splnili;
/// jinak série končí minulým týdnem a teprve se rozhoduje.
int pairStreak(
  Map<String, bool> mine,
  Map<String, bool> theirs,
  DateTime now, {
  int maxWeeks = publishedWeeks,
}) {
  final keys = recentWeekKeys(now, maxWeeks);
  bool both(String k) => (mine[k] ?? false) && (theirs[k] ?? false);
  var streak = 0;
  for (var i = 0; i < keys.length; i++) {
    if (both(keys[i])) {
      streak++;
    } else if (i == 0) {
      continue; // tento týden ještě běží
    } else {
      break;
    }
  }
  return streak;
}

/// Ponechá jen posledních [keep] týdnů (starší klíče zahodí).
Map<String, bool> trimWeeks(Map<String, bool> weeks, DateTime now,
    {int keep = publishedWeeks}) {
  final allowed = recentWeekKeys(now, keep).toSet();
  return {
    for (final e in weeks.entries)
      if (allowed.contains(e.key)) e.key: e.value,
  };
}

// ---------------------------------------------------------------------------
// Kód přítele a odkazy
// ---------------------------------------------------------------------------

/// Bez znaků, které se pletou (0/O, 1/I/L).
const friendCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const friendCodeLength = 8;

String generateFriendCode([Random? random]) {
  final r = random ?? Random.secure();
  return String.fromCharCodes([
    for (var i = 0; i < friendCodeLength; i++)
      friendCodeAlphabet.codeUnitAt(r.nextInt(friendCodeAlphabet.length)),
  ]);
}

/// Velká písmena, bez mezer a pomlček.
String normalizeFriendCode(String input) =>
    input.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

bool isValidFriendCode(String code) =>
    code.length == friendCodeLength &&
    code.codeUnits.every(friendCodeAlphabet.codeUnits.contains);

/// Kód přítele z naskenovaného textu: odkaz s ?code=… nebo samotný kód.
String? parseFriendCode(String scanned) {
  final text = scanned.trim();
  final uri = Uri.tryParse(text);
  if (uri != null && uri.hasScheme) {
    final code = uri.queryParameters['code'];
    if (code == null) return null;
    final n = normalizeFriendCode(code);
    return isValidFriendCode(n) ? n : null;
  }
  final n = normalizeFriendCode(text);
  return isValidFriendCode(n) ? n : null;
}

// ---------------------------------------------------------------------------
// Žebříčky
// ---------------------------------------------------------------------------

typedef RankedEntry<T> = ({int rank, T item, double value});

/// Seřadí sestupně; stejné hodnoty mají stejné pořadí (1, 2, 2, 4).
/// Položky bez hodnoty (null) vynechá.
List<RankedEntry<T>> rankBy<T>(Iterable<T> items, double? Function(T) value) {
  final list = [
    for (final i in items)
      if (value(i) case final v?) (item: i, value: v),
  ]..sort((a, b) => b.value.compareTo(a.value));
  final result = <RankedEntry<T>>[];
  for (var i = 0; i < list.length; i++) {
    final rank = i > 0 && list[i].value == list[i - 1].value
        ? result[i - 1].rank
        : i + 1;
    result.add((rank: rank, item: list[i].item, value: list[i].value));
  }
  return result;
}

// ---------------------------------------------------------------------------
// Výzvy
// ---------------------------------------------------------------------------

/// Konec měsíce (první okamžik dalšího měsíce minus 1 s).
DateTime endOfMonth(DateTime d) =>
    DateTime(d.year, d.month + 1).subtract(const Duration(seconds: 1));

/// Podíl splnění v procentech 0–100 (pro pitný režim se sdílí jen tohle).
int completionPercent(double current, double target) {
  if (target <= 0) return 0;
  return (current / target * 100).clamp(0, 100).floor();
}

/// Zaokrouhlení rekordu na 0,5 kg pro zobrazení přátelům.
double roundRecord(double kg) => (kg * 2).round() / 2;
