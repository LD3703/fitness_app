// Srovnání „Jak si vedu“ (docs/social.md, „Srovnání se zemí a světem“).
// Cloud Function updateLiftStats jednou denně spočítá ze žebříčků
// posiloven anonymní rozložení nejtěžších vah (liftStats/{rozsah}_{cvik},
// functions/src/liftStats.ts). Aplikace si stáhne rozložení pro svou
// zemi a svět a spočítá percentil své vlastní maximálky – ta nikam
// neodchází. Čistý Dart (testy: test/strength_rank_test.dart).
import 'gym_logic.dart';

/// Nejmenší skupina, pro kterou server zveřejní rozložení (zrcadlo
/// LIFT_STATS_MIN_N v functions/src/liftStats.ts).
const kLiftStatsMinN = 20;

/// Rozsah „svět“ v ID dokumentu (země jsou ISO 3166-1, např. CZ).
const kLiftStatsWorld = 'world';

/// ID dokumentu liftStats: „{rozsah}_{kategorie}“, např. „CZ_bench_press“.
String liftStatsDocId(String scope, GymCategory category) =>
    '${scope}_${category.key}';

/// Klíč skupiny v dokumentu: „{pohlaví}_{věk}“ – „all_all“ = všichni,
/// jinak např. „male_u40“, „female_50“. Neuvedené = všichni.
String liftStatsGroupKey({GymGender? gender, GymAgeGroup? age}) {
  final g = switch (gender) {
    GymGender.male => 'male',
    GymGender.female => 'female',
    _ => 'all',
  };
  return '${g}_${age?.key ?? 'all'}';
}

/// Rozložení vah jedné skupiny.
class LiftDistribution {
  const LiftDistribution({required this.n, this.buckets = const []});

  /// `{n: 230, h: [80, 3, 82.5, 1, …]}` z Firestore; nesmysl → null.
  static LiftDistribution? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final n = raw['n'];
    if (n is! num || n < 0) return null;
    final h = raw['h'];
    final buckets = <(double, int)>[];
    if (h is List) {
      for (var i = 0; i + 1 < h.length; i += 2) {
        final v = h[i];
        final c = h[i + 1];
        if (v is num && c is num && c > 0) buckets.add((v.toDouble(), c.toInt()));
      }
    }
    return LiftDistribution(n: n.toInt(), buckets: buckets);
  }

  /// Počet lidí ve skupině.
  final int n;

  /// (váha, počet) vzestupně; prázdné u malé skupiny.
  final List<(double, int)> buckets;

  /// Dost dat na percentil.
  bool get hasData => n >= kLiftStatsMinN && buckets.isNotEmpty;

  /// Kolik procent lidí má slabší výkon než [kg] (stejný výkon se počítá
  /// napůl), 0–100; null bez dost dat. Váha se zaokrouhlí na 0,5 kg jako
  /// na serveru.
  double? percentBelow(double kg) {
    if (!hasData) return null;
    final x = (kg * 2).round() / 2;
    var total = 0;
    var below = 0;
    var equal = 0;
    for (final (v, c) in buckets) {
      total += c;
      if (v < x) {
        below += c;
      } else if (v == x) {
        equal += c;
      }
    }
    if (total == 0) return null;
    return ((below + equal / 2) / total * 100).clamp(0, 100).toDouble();
  }
}

/// Skupiny z dokumentu liftStats (pole `groups`).
Map<String, LiftDistribution> parseLiftStatsGroups(Map<String, Object?>? data) {
  final groups = data?['groups'];
  if (groups is! Map) return const {};
  final out = <String, LiftDistribution>{};
  for (final e in groups.entries) {
    final d = LiftDistribution.fromMap(e.value);
    if (e.key is String && d != null) out[e.key as String] = d;
  }
  return out;
}

/// Procento k zobrazení („lepší než 78 %“): dolů na celé, nejvýš 99.
int liftPercentLabel(double percent) => percent.floor().clamp(0, 99);

/// Země uživatele: země posilovny, jinak region z jazyka telefonu
/// („cs_CZ“ → CZ). Null = neznámá (jen svět).
String? liftStatsCountry({String? gymCountry, String? localeCountry}) {
  for (final c in [gymCountry, localeCountry]) {
    final up = c?.trim().toUpperCase();
    if (up != null && RegExp(r'^[A-Z]{2}$').hasMatch(up)) return up;
  }
  return null;
}

/// Vlajka země jako emoji (regionální indikátory), např. CZ → 🇨🇿.
String countryFlag(String code) => String.fromCharCodes(
      code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41),
    );
