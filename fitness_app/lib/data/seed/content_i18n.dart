import 'seed_translations.dart';

/// Vybere text vestavěného obsahu pro jazyk [lang].
///
/// Čeština a angličtina jsou přímo v datech ([cs], [en]); ostatní jazyky
/// se hledají v [seedTranslations] přes [other]. Chybí-li překlad,
/// použije se angličtina.
String seedText(
  String lang, {
  required String en,
  required String cs,
  String? Function(SeedTranslation t)? other,
}) {
  if (lang == 'cs') return cs;
  if (lang == 'en') return en;
  final t = seedTranslations[lang];
  if (t == null || other == null) return en;
  return other(t) ?? en;
}

/// Názvy vestavěného cviku ve všech dalších jazycích (pro hledání).
Iterable<String> translatedExerciseNames(String slug) sync* {
  for (final t in seedTranslations.values) {
    final name = t.exerciseNames[slug];
    if (name != null) yield name;
  }
}

const _fold = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'č': 'c', 'ć': 'c', 'ç': 'c', 'ď': 'd',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ě': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ľ': 'l', 'ĺ': 'l', 'ň': 'n', 'ñ': 'n',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ř': 'r', 'ŕ': 'r', 'š': 's', 'ś': 's', 'ß': 'ss', 'ť': 't',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ů': 'u',
  'ý': 'y', 'ÿ': 'y', 'ž': 'z', 'ź': 'z', 'ż': 'z',
};

/// Malá písmena bez diakritiky – „Bankdrücken“ najde i „bankdrucken“.
String foldForSearch(String text) {
  final lower = text.toLowerCase();
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    buf.write(_fold[ch] ?? ch);
  }
  return buf.toString();
}

/// Odpovídá cvik hledanému textu v jakémkoli jazyce?
bool exerciseMatchesQuery({
  required String? slug,
  required String nameEn,
  required String nameCs,
  required String query,
}) {
  final q = foldForSearch(query.trim());
  if (q.isEmpty) return true;
  bool hit(String name) => foldForSearch(name).contains(q);
  if (hit(nameEn) || hit(nameCs)) return true;
  return slug != null && translatedExerciseNames(slug).any(hit);
}
