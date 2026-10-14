// Filtr hrubých slov v textech, které vidí ostatní (jméno pro přátele,
// přezdívka v žebříčku, název a město posilovny, název vlastního cviku
// ve výzvě, jméno trenéra). Čistý Dart ve sdíleném balíčku (aplikace i web
// pro trenéry) – testy: test/text_filter_test.dart.
//
// Záměrně úzký (rozhodnutí vývojáře): blokuje jen
//  - urážky skupin lidí (rasové, etnické, homofobní…),
//  - vyloženě sexuální vulgarity,
//  - nacistické výrazy.
// Hovorové nadávky („kurva“, „hovno“, „shit“, „mierda“…) projdou. Na
// zbytek je nahlášení (moderace) – filtr jen odchytí to nejhorší, jak
// chce Apple (App Review Guideline 1.2) i Google Play.
//
// Porovnává se celé slovo po normalizaci (malá písmena, bez diakritiky,
// 1→i, 0→o …, „PičaMan“ → „pica man“, víc než 2 stejná písmena za sebou
// → 2), takže „Scunthorpe“ nebo „Dick“ projdou. Několik jednoznačných
// kořenů se hledá i uvnitř slov (stems).

/// Celá slova (už normalizovaná).
const _words = <String>{
  // urážky skupin
  'nigger', 'niggers', 'nigga', 'niggas', 'niggaz', 'faggot', 'faggots',
  'fag', 'fags', 'spic', 'spics', 'chink', 'chinks', 'gook', 'gooks',
  'wetback', 'wetbacks', 'tranny', 'trannies', 'raghead', 'towelhead',
  'negr', 'negri', 'negre', 'negrum', 'negrovi', 'cigos', 'cigosi',
  'buzerant', 'buzeranti', 'buzerante', 'buzna', 'buzny', 'buzno',
  'neger', 'kanake', 'kanaken', 'schwuchtel', 'schwuchteln',
  'maricon', 'maricones', 'sudaca', 'sudacas', 'negrata',
  'bougnoule', 'bougnoules', 'youpin', 'youpins',
  'czarnuch', 'czarnuchy', 'cwel', 'cwele', 'cwelu',
  'frocio', 'froci', 'ricchione', 'ricchioni', 'negraccio',
  'viado', 'viados', 'flikker', 'flikkers',
  // sexuální vulgarity
  'cunt', 'cunts', 'blowjob', 'handjob', 'rimjob', 'dildo', 'dildos',
  'porn', 'porno', 'pornhub', 'cumshot', 'gangbang', 'rape', 'rapist',
  'pedo', 'pedos', 'pedophile', 'paedophile', 'pedofil', 'pedofilove',
  'zoofil',
  'pica', 'pice', 'picu', 'picus', 'picusi', 'kunda', 'kundy',
  'kundo', 'kundu', 'sukat', 'sukam', 'sukani', 'mrdat', 'mrdam', 'mrdka',
  'mrdky', 'jebat', 'jebu', 'jebe', 'jebac', 'jebany', 'pizda', 'pizdy',
  'fotze', 'fotzen', 'ficken', 'salope', 'salopes', 'buceta',
  // nacismus
  'nazi', 'nazis', 'neonazi', 'heil', 'auschwitz', 'kkk',
};

/// Jednoznačné kořeny, hledají se i uvnitř slov a přes mezery
/// („N i g g e r“, „HitlerFan“).
const _stems = <String>[
  'nigger', 'nigga', 'faggot', 'hitler', 'siegheil', 'kinderfick',
  'whitepower', 'sandnigger',
];

const _diacritics = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ą': 'a',
  'č': 'c', 'ć': 'c', 'ç': 'c', 'ď': 'd',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ě': 'e', 'ę': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ľ': 'l', 'ĺ': 'l', 'ł': 'l', 'ň': 'n', 'ń': 'n', 'ñ': 'n',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ő': 'o',
  'ř': 'r', 'ŕ': 'r', 'š': 's', 'ś': 's', 'ß': 'ss', 'ť': 't',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ů': 'u', 'ű': 'u',
  'ý': 'y', 'ÿ': 'y', 'ž': 'z', 'ź': 'z', 'ż': 'z',
};

const _leet = {
  '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't',
  '@': 'a', r'$': 's', '!': 'i',
};

/// Hranice „malé → velké písmeno“ (PičaMan → Piča Man).
final _camel = RegExp(r'(?<=\p{Ll})(?=\p{Lu})', unicode: true);
final _nonLetter = RegExp('[^a-z]+');
final _longRun = RegExp(r'([a-z])\1{2,}');

/// Slova textu po normalizaci (pro testy a [containsSevereProfanity]).
List<String> profanityTokens(String text) {
  final spaced = text.replaceAll(_camel, ' ').toLowerCase();
  final b = StringBuffer();
  for (final ch in spaced.split('')) {
    b.write(_diacritics[ch] ?? _leet[ch] ?? ch);
  }
  return b
      .toString()
      .split(_nonLetter)
      .where((t) => t.isNotEmpty)
      .map((t) => t.replaceAllMapped(_longRun, (m) => '${m[1]}${m[1]}'))
      .toList();
}

/// Obsahuje text vyloženě hrubé slovo? (Hovorové nadávky ne.)
bool containsSevereProfanity(String text) {
  final tokens = profanityTokens(text);
  if (tokens.any(_words.contains)) return true;
  final joined = tokens.join();
  return _stems.any(joined.contains);
}

/// Text pro zveřejnění: s hrubým slovem nahrazený [fallback] (pojistka
/// pro případ, že ho aplikace nezachytila už při psaní).
String publicTextOr(String text, String fallback) =>
    containsSevereProfanity(text) ? fallback : text;
