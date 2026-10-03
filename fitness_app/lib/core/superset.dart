// Supersérie: 2–3 po sobě jdoucí cviky, které se cvičí střídavě
// (A1, A2, A1, A2… a pauza až po posledním cviku kola).
//
// Seskupení se ukládá jako číslo skupiny u každého cviku (stejné číslo =
// stejná supersérie, null = samostatný cvik). Funkce tady pracují se
// seznamem čísel skupin v pořadí cviků a jsou čisté (testy:
// test/superset_test.dart).

/// Nejvíc cviků v jedné supersérii.
const maxSupersetSize = 3;

/// Uvede skupiny do platného stavu:
/// - skupina musí mít aspoň 2 cviky jdoucí hned po sobě, jinak se zruší,
/// - když se stejné číslo objeví ve dvou oddělených úsecích (např. po
///   přesunutí cviku), druhý úsek dostane nové číslo.
List<int?> normalizeSupersetGroups(List<int?> groups) {
  final result = List<int?>.filled(groups.length, null);
  final used = <int>{};
  var nextId = groups.whereType<int>().fold<int>(0, (a, b) => a > b ? a : b) + 1;
  var i = 0;
  while (i < groups.length) {
    final g = groups[i];
    var j = i + 1;
    if (g != null) {
      while (j < groups.length && groups[j] == g) {
        j++;
      }
    }
    if (g != null && j - i >= 2) {
      var id = g;
      if (used.contains(id)) id = nextId++;
      used.add(id);
      for (var k = i; k < j; k++) {
        result[k] = id;
      }
    }
    i = j;
  }
  return result;
}

/// Rozsah [start, end) supersérie, do které patří cvik [index]
/// (u samostatného cviku jen on sám). Předpokládá normalizované skupiny.
({int start, int end}) supersetRange(List<int?> groups, int index) {
  final g = groups[index];
  if (g == null) return (start: index, end: index + 1);
  var start = index;
  while (start > 0 && groups[start - 1] == g) {
    start--;
  }
  var end = index + 1;
  while (end < groups.length && groups[end] == g) {
    end++;
  }
  return (start: start, end: end);
}

/// Propojí cvik [index] s následujícím do supersérie (případně připojí
/// k už existující supersérii). Vrací nové skupiny, nebo null, když to
/// nejde (poslední cvik, už propojené, víc než [maxSupersetSize] cviků).
List<int?>? linkSupersetWithNext(List<int?> groups, int index) {
  final normalized = normalizeSupersetGroups(groups);
  if (index < 0 || index + 1 >= normalized.length) return null;
  final a = normalized[index];
  final b = normalized[index + 1];
  if (a != null && a == b) return null;
  final ra = supersetRange(normalized, index);
  final rb = supersetRange(normalized, index + 1);
  if ((ra.end - ra.start) + (rb.end - rb.start) > maxSupersetSize) {
    return null;
  }
  final id = a ??
      b ??
      normalized.whereType<int>().fold<int>(0, (x, y) => x > y ? x : y) + 1;
  final result = [...normalized];
  for (var k = ra.start; k < rb.end; k++) {
    result[k] = id;
  }
  return normalizeSupersetGroups(result);
}

/// Jde cvik [index] propojit s následujícím?
bool canLinkSupersetWithNext(List<int?> groups, int index) =>
    linkSupersetWithNext(groups, index) != null;

/// Vyjme cvik [index] ze supersérie. Zbylé cviky zůstanou propojené, jen
/// když jich jsou aspoň 2 a jdou po sobě.
List<int?> unlinkSuperset(List<int?> groups, int index) {
  final result = [...groups];
  if (index >= 0 && index < result.length) result[index] = null;
  return normalizeSupersetGroups(result);
}

/// Popisky cviků: „A1“, „A2“, „B1“… (písmeno podle pořadí supersérie,
/// číslo podle pořadí v ní), u samostatných cviků null.
List<String?> supersetLabels(List<int?> groups) {
  final normalized = normalizeSupersetGroups(groups);
  final labels = List<String?>.filled(normalized.length, null);
  var letterIndex = -1;
  int? current;
  var position = 0;
  for (var i = 0; i < normalized.length; i++) {
    final g = normalized[i];
    if (g == null) {
      current = null;
      continue;
    }
    if (g != current) {
      current = g;
      letterIndex++;
      position = 0;
    }
    position++;
    labels[i] = '${supersetLetter(letterIndex)}$position';
  }
  return labels;
}

/// 0 → „A“, 25 → „Z“, 26 → „AA“…
String supersetLetter(int index) {
  var n = index;
  var s = '';
  do {
    s = String.fromCharCode(65 + n % 26) + s;
    n = n ~/ 26 - 1;
  } while (n >= 0);
  return s;
}
