// Kontrola příchozích odkazů. Čistý Dart (testy: test/deep_links_test.dart).

/// Jde odkaz celý dekódovat? `Uri.parse` přijme i „%FF“ (není platné
/// UTF-8), výjimku ale vyhodí až `queryParameters` / `pathSegments` –
/// typicky v builderu obrazovky. Proto se to ověří hned při příchodu
/// odkazu (deep_links.dart; chrání všechny moduly: výzvy, přátele,
/// posilovny…).
bool isDecodableLink(Uri uri) {
  try {
    Uri.decodeComponent(uri.path);
    Uri.splitQueryString(uri.query);
    return true;
  } catch (_) {
    // FormatException (neplatné UTF-8) i ArgumentError (neplatné „%xx“).
    return false;
  }
}

/// Slug cviku z odkazu ze samolepky na stroji (`gymbar://ex?id=bench_press`,
/// `https://gymbar.app/ex?id=…&gym=…`, docs/fitka.md), jinak null. Že jde
/// o odkaz /ex, ověří volající (isAppLink). Parametr `gym` je pro budoucí
/// statistiku skenů, aplikace ho zatím nepoužívá.
String? exerciseLinkSlug(Uri uri) {
  final id = uri.queryParameters['id']?.trim().toLowerCase();
  if (id == null || !RegExp(r'^[a-z0-9_]{2,60}$').hasMatch(id)) return null;
  return id;
}
