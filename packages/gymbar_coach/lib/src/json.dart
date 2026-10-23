// Bezpečné čtení JSON z Firestore (data můžou být poškozená nebo od
// starší / novější verze aplikace).

/// Data plánu / tréninku nejdou přečíst.
class CoachFormatException implements Exception {
  CoachFormatException(this.message);

  final String message;

  @override
  String toString() => 'CoachFormatException: $message';
}

Map<String, Object?> asMap(Object? v, String what) {
  if (v is Map) return v.map((k, value) => MapEntry('$k', value));
  throw CoachFormatException('$what is not an object');
}

List<Object?> asList(Object? v, String what) {
  if (v is List) return v;
  throw CoachFormatException('$what is not a list');
}

String? optString(Object? v, {int max = 200}) {
  if (v is! String) return null;
  final t = v.trim();
  if (t.isEmpty) return null;
  return t.length > max ? t.substring(0, max) : t;
}

String reqString(Object? v, String what, {int max = 200}) =>
    optString(v, max: max) ?? (throw CoachFormatException('$what missing'));

/// Největší přípustné číslo (i na webu, kde je int jen double).
const maxSafeInt = 9007199254740991;

/// Největší čas v ms, který zvládne DateTime.
const maxTimeMs = 8640000000000000;

int? optInt(Object? v, {int min = 0, int max = maxSafeInt}) {
  // NaN a ±Infinity by v round() hodily výjimku – data od jiného
  // uživatele (plán, trénink) nesmí shodit načítání.
  final n = v is int ? v : (v is num && v.isFinite ? v.round() : null);
  if (n == null || n < min || n > max) return null;
  return n;
}

double? optDouble(Object? v, {double min = 0, double max = 10000}) {
  final n = v is num ? v.toDouble() : null;
  if (n == null || !n.isFinite || n < min || n > max) return null;
  return n;
}

bool optBool(Object? v) => v == true;

/// Zkrátí text na [max] znaků (při zápisu).
String clip(String s, int max) {
  final t = s.trim();
  return t.length > max ? t.substring(0, max) : t;
}
