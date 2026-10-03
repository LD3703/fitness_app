// Čistá logika žebříčku posilovny (bez Firebase a Flutteru) – testovatelná.
// Datový model: docs/social.md, sekce „Žebříček posilovny“.
import 'dart:math';

import '../social_logic.dart';

/// Kategorie žebříčku: silový cvik (odhad 1RM vestavěného cviku) nebo
/// počet tréninků v měsíci. [key] je klíč na serveru (pole `category`
/// a přípona ID záznamu `<uid>_<key>`); u cviků je to slug vestavěného
/// cviku. Instance vznikají jen tady (konstanty), takže se porovnávají
/// identitou a fungují jako klíče map i v `const` kolekcích.
class GymCategory {
  const GymCategory._(
    this.key,
    this.limit, {
    this.isLift = true,
    this.perDumbbell = false,
    this.addedWeight = false,
  });

  /// Klíč na serveru (slug cviku nebo „workouts“).
  final String key;

  /// Absolutní hranice reálnosti: kg odhadu 1RM u cviků, počet tréninků
  /// za měsíc. Stejně ve functions/src/plausibility.ts a firestore.rules.
  final double limit;

  /// Odhad 1RM v kg (ne počet tréninků).
  final bool isLift;

  /// Váha jedné jednoručky, jak se zapisuje.
  final bool perDumbbell;

  /// Jen přidaná zátěž (opasek, jednoručka), bez tělesné váhy.
  final bool addedWeight;

  /// Slug vestavěného cviku u silových kategorií, jinak null.
  String? get exerciseSlug => isLift ? key : null;

  static const benchPress = GymCategory._('bench_press', 350);
  static const backSquat = GymCategory._('back_squat', 500);
  static const deadlift = GymCategory._('deadlift', 500);
  static const overheadPress = GymCategory._('overhead_press', 250);
  static const inclineBenchPress = GymCategory._('incline_bench_press', 300);
  static const dumbbellBenchPress =
      GymCategory._('dumbbell_bench_press', 120, perDumbbell: true);
  static const dumbbellShoulderPress =
      GymCategory._('dumbbell_shoulder_press', 100, perDumbbell: true);
  static const barbellCurl = GymCategory._('barbell_curl', 150);
  static const dumbbellCurl =
      GymCategory._('dumbbell_curl', 80, perDumbbell: true);
  static const weightedPullUp =
      GymCategory._('weighted_pull_up', 150, addedWeight: true);
  static const weightedDips =
      GymCategory._('weighted_dips', 200, addedWeight: true);
  static const barbellRow = GymCategory._('barbell_row', 300);
  static const legPress = GymCategory._('leg_press', 1000);
  static const hipThrust = GymCategory._('hip_thrust', 500);
  static const frontSquat = GymCategory._('front_squat', 400);
  static const romanianDeadlift = GymCategory._('romanian_deadlift', 400);

  /// Počet tréninků v měsíci.
  static const workouts = GymCategory._('workouts', 62, isLift: false);

  /// Silové kategorie v pořadí, v jakém je ukazuje žebříček.
  static const lifts = <GymCategory>[
    benchPress,
    backSquat,
    deadlift,
    overheadPress,
    inclineBenchPress,
    dumbbellBenchPress,
    dumbbellShoulderPress,
    barbellCurl,
    dumbbellCurl,
    weightedPullUp,
    weightedDips,
    barbellRow,
    legPress,
    hipThrust,
    frontSquat,
    romanianDeadlift,
  ];

  /// Všechny kategorie (cviky a nakonec tréninky).
  static const values = <GymCategory>[...lifts, workouts];

  @override
  String toString() => 'GymCategory($key)';
}

/// Kategorie podle klíče na serveru; neznámý klíč (i zrušené kategorie
/// `bench`, `squat` z dřívějších verzí) → null.
GymCategory? gymCategoryFromKey(String? key) {
  for (final c in GymCategory.values) {
    if (c.key == key) return c;
  }
  return null;
}

/// Klíče kategorií z dřívějších verzí (před přechodem na slugy cviků).
/// Používá se jen pro čtení starých položek novinek; záznamy žebříčku se
/// zrušenými klíči aplikace maže (GymService.deleteRetiredEntries).
const gymLegacyCategoryKeys = <String, String>{
  'bench': 'bench_press',
  'squat': 'back_squat',
};

/// Jako [gymCategoryFromKey], ale rozumí i starým klíčům (novinky).
GymCategory? gymCategoryFromAnyKey(String? key) =>
    gymCategoryFromKey(gymLegacyCategoryKeys[key] ?? key);

/// Pohlaví pro filtr žebříčku (volitelné).
enum GymGender { male, female, unspecified }

GymGender gymGenderFromKey(String? key) {
  for (final g in GymGender.values) {
    if (g.name == key) return g;
  }
  return GymGender.unspecified;
}

/// Filtr žebříčku podle pohlaví.
enum GymGenderFilter { all, men, women }

bool gymGenderMatches(GymGenderFilter filter, GymGender gender) =>
    switch (filter) {
      GymGenderFilter.all => true,
      GymGenderFilter.men => gender == GymGender.male,
      GymGenderFilter.women => gender == GymGender.female,
    };

/// Věková skupina v žebříčku. Ven jde jen klíč skupiny ([key]), nikdy
/// věk ani rok narození.
enum GymAgeGroup {
  /// Do 39 let.
  under40('u40'),

  /// 40–49 let.
  from40('40'),

  /// 50–59 let.
  from50('50'),

  /// 60 a víc.
  from60('60');

  const GymAgeGroup(this.key);

  /// Hodnota pole `ageGroup` ve Firestore (stejně jako firestore.rules).
  final String key;
}

GymAgeGroup? gymAgeGroupFromKey(String? key) {
  for (final g in GymAgeGroup.values) {
    if (g.key == key) return g;
  }
  return null;
}

/// Nejstarší a nejmladší přípustný rok narození (formulář profilu).
const gymBirthYearMin = 1920;
const gymMinAgeYears = 10;
int gymBirthYearMax(int currentYear) => currentYear - gymMinAgeYears;

/// Je rok narození v rozsahu [gymBirthYearMin] … [gymBirthYearMax]?
bool isValidBirthYear(int? birthYear, int currentYear) =>
    birthYear != null &&
    birthYear >= gymBirthYearMin &&
    birthYear <= gymBirthYearMax(currentYear);

/// Věková skupina z roku narození a aktuálního roku (věk = rozdíl let,
/// den narození neznáme). Bez roku nebo s nesmyslným rokem null.
GymAgeGroup? gymAgeGroupFor(int? birthYear, int currentYear) {
  if (!isValidBirthYear(birthYear, currentYear)) return null;
  final age = currentYear - birthYear!;
  if (age >= 60) return GymAgeGroup.from60;
  if (age >= 50) return GymAgeGroup.from50;
  if (age >= 40) return GymAgeGroup.from40;
  return GymAgeGroup.under40;
}

/// Filtr žebříčku podle věku: všichni / 40+ / 50+ / 60+.
enum GymAgeFilter { all, from40, from50, from60 }

/// Spodní hranice filtru v letech (null = všichni).
extension GymAgeFilterInfo on GymAgeFilter {
  int? get minAge => switch (this) {
        GymAgeFilter.all => null,
        GymAgeFilter.from40 => 40,
        GymAgeFilter.from50 => 50,
        GymAgeFilter.from60 => 60,
      };
}

/// 40+ = skupiny 40, 50, 60; 50+ = 50, 60; 60+ = 60. Bez skupiny (bez roku
/// narození) jen ve filtru „všichni“.
bool gymAgeMatches(GymAgeFilter filter, GymAgeGroup? group) {
  if (filter == GymAgeFilter.all) return true;
  if (group == null) return false;
  return switch (filter) {
    GymAgeFilter.all => true,
    GymAgeFilter.from40 => group != GymAgeGroup.under40,
    GymAgeFilter.from50 =>
      group == GymAgeGroup.from50 || group == GymAgeGroup.from60,
    GymAgeFilter.from60 => group == GymAgeGroup.from60,
  };
}

/// Max. délka přezdívky (stejně jako ve firestore.rules).
const gymNicknameMaxLength = 24;

/// Max. délka názvu posilovny a města (firestore.rules).
const gymNameMaxLength = 60;
const gymAddressMaxLength = 120;

/// Od kolika nahlášení se záznam skryje (i bez Cloud Functions).
const gymReportHideThreshold = 5;

/// Série s víc opakováními se do žebříčku nepočítají (Epley je nad
/// 12 opakování nepřesný a nadsazuje).
const gymMaxReps = 12;

/// Kolik záznamů žebříčku se načte (filtr pohlaví a věku běží v aplikaci).
const gymBoardLimit = 300;

/// Přezdívka: oříznutá, nejvýš [gymNicknameMaxLength] znaků, nikdy prázdná.
String sanitizeGymNickname(String input) {
  final t = input.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return '?';
  return t.length > gymNicknameMaxLength
      ? t.substring(0, gymNicknameMaxLength).trim()
      : t;
}

/// Text oříznutý na [max] znaků (název, město, adresa).
String clampText(String input, int max) {
  final t = input.trim().replaceAll(RegExp(r'\s+'), ' ');
  return t.length > max ? t.substring(0, max).trim() : t;
}

// ---------------------------------------------------------------------------
// Kód posilovny
// ---------------------------------------------------------------------------

/// Kód posilovny: 6 znaků ze stejné abecedy jako kód přítele (8 znaků),
/// takže se nepletou.
const gymCodeLength = 6;

String generateGymCode([Random? random]) {
  final r = random ?? Random.secure();
  return String.fromCharCodes([
    for (var i = 0; i < gymCodeLength; i++)
      friendCodeAlphabet.codeUnitAt(r.nextInt(friendCodeAlphabet.length)),
  ]);
}

bool isValidGymCode(String code) =>
    code.length == gymCodeLength &&
    code.codeUnits.every(friendCodeAlphabet.codeUnits.contains);

/// Kód posilovny z naskenovaného textu: odkaz `…/gym?code=…`
/// (fitnessapp://gym?code=… i https://<web>/gym?code=…) nebo samotný kód.
String? parseGymCode(String scanned) {
  final text = scanned.trim();
  final uri = Uri.tryParse(text);
  if (uri != null && uri.hasScheme) {
    final isGym = uri.host == 'gym' ||
        (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'gym');
    final code = uri.queryParameters['code'];
    if (!isGym || code == null) return null;
    final n = normalizeFriendCode(code);
    return isValidGymCode(n) ? n : null;
  }
  final n = normalizeFriendCode(text);
  return isValidGymCode(n) ? n : null;
}

// ---------------------------------------------------------------------------
// Vyhledávání (prefix ve Firestore nad nameLower / cityLower)
// ---------------------------------------------------------------------------

const _diacritics = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ą': 'a',
  'č': 'c', 'ć': 'c', 'ç': 'c',
  'ď': 'd',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ě': 'e', 'ę': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ľ': 'l', 'ĺ': 'l', 'ł': 'l',
  'ň': 'n', 'ń': 'n', 'ñ': 'n',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ő': 'o',
  'ř': 'r', 'ŕ': 'r',
  'š': 's', 'ś': 's', 'ß': 'ss',
  'ť': 't',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ů': 'u', 'ű': 'u',
  'ý': 'y', 'ÿ': 'y',
  'ž': 'z', 'ź': 'z', 'ż': 'z',
};

/// Malá písmena bez diakritiky a nadbytečných mezer: „Gym Jičín “ →
/// „gym jicin“. Stejně se normalizuje uložený název i hledaný text.
String normalizeGymSearch(String input) {
  final lower = input.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    b.write(_diacritics[ch] ?? ch);
  }
  final s = b.toString();
  return s.length > gymNameMaxLength ? s.substring(0, gymNameMaxLength) : s;
}

/// Horní mez pro prefixový dotaz (`>= q` a `< q + ''`).
String gymSearchUpperBound(String normalized) => '$normalized';

// ---------------------------------------------------------------------------
// Hodnoty
// ---------------------------------------------------------------------------

/// Odhad 1RM pro žebříček: na 0,5 kg (stejně jako rekordy pro přátele).
double roundGymLift(double kg) => roundRecord(kg);

/// Nejvyšší počet tréninků v jednom měsíci (klíč „yyyy-MM“).
int bestMonthCount(Iterable<DateTime> workoutDates) {
  final counts = <String, int>{};
  for (final d in workoutDates) {
    final k = monthKey(d);
    counts[k] = (counts[k] ?? 0) + 1;
  }
  return counts.values.fold<int>(0, max);
}

/// ID záznamu v žebříčku: `<uid>_<klíč kategorie>`.
String gymEntryId(String uid, GymCategory category) => '${uid}_${category.key}';

/// remoteId lokální výzvy „Překonej mě“ – podle něj se výzva neduplikuje.
String gymChallengeRemoteId({
  required String gymId,
  required String uid,
  required GymCategory category,
  required double value,
}) {
  final v = category == GymCategory.workouts
      ? value.round().toString()
      : value.toStringAsFixed(2);
  return 'gym:$gymId:$uid:${category.key}:$v';
}

/// Je to výzva ze žebříčku posilovny (ne výzva na serveru)?
bool isGymChallengeRemoteId(String? remoteId) =>
    remoteId != null && remoteId.startsWith('gym:');
