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

/// Počet kvantilů v dokumentu (5. až 95. percentil po 5).
const kLiftStatsQuantiles = 19;

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

/// Rozložení vah jedné skupiny: jen kvantily (5., 10., … 95. percentil,
/// na 2,5 kg) – server přesné rozložení nezveřejňuje (soukromí).
class LiftDistribution {
  const LiftDistribution({required this.n, this.quantiles = const []});

  /// `{n: 230, q: [60, 65, …]}` z Firestore; nesmysl → null.
  static LiftDistribution? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final n = raw['n'];
    if (n is! num || n < 0) return null;
    final q = raw['q'];
    final quantiles = <double>[];
    if (q is List && q.length == kLiftStatsQuantiles) {
      for (final v in q) {
        if (v is! num || !v.isFinite) return LiftDistribution(n: n.toInt());
        quantiles.add(v.toDouble());
      }
    }
    return LiftDistribution(n: n.toInt(), quantiles: quantiles);
  }

  /// Počet lidí ve skupině.
  final int n;

  /// q[i] = (5·(i+1)). percentil; prázdné u malé skupiny.
  final List<double> quantiles;

  /// Dost dat na percentil.
  bool get hasData =>
      n >= kLiftStatsMinN && quantiles.length == kLiftStatsQuantiles;

  /// Kolik procent lidí má zhruba slabší výkon než [kg] (0–100), null bez
  /// dost dat. Mezi kvantily lineárně; pod 5. percentilem 2,5 %, nad 95.
  /// 97,5 %; když [kg] padne na několik stejných kvantilů, jejich střed.
  double? percentBelow(double kg) {
    if (!hasData) return null;
    final q = quantiles;
    var below = 0;
    var equal = 0;
    for (final v in q) {
      if (v < kg) {
        below++;
      } else if (v == kg) {
        equal++;
      }
    }
    if (equal > 0) return 5.0 * below + 2.5 * (equal + 1);
    if (below == 0) return 2.5;
    if (below == q.length) return 97.5;
    final lo = q[below - 1];
    final hi = q[below];
    return 5.0 * below + 5.0 * (kg - lo) / (hi - lo);
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
