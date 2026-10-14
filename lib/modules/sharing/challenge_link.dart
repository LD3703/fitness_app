// Odkaz s výzvou: sestavení a čtení parametrů. Čistý Dart (testovatelné).
//
// Podoba: <web>/challenge?e=<slug nebo id>&v=<kg>&r=<opakování>&n=<jméno>&d=<rrrr-mm-dd>
// v + r = nejtěžší série vyzývajícího; překonat ji = zvednout víc, nebo
// stejnou váhu na víc opakování ([target], recordValue).
// U vlastních cviků (bez slugu) se přidává x=<název cviku>, protože ID
// cviku na telefonu kamaráda nic neznamená.

import '../../core/formulas.dart';

class ChallengeLink {
  const ChallengeLink({
    required this.exercise,
    required this.value,
    this.reps,
    this.exerciseName,
    this.fromName,
    this.deadline,
  });

  /// Slug vestavěného cviku, nebo číselné ID.
  final String exercise;

  /// Váha rekordní série vyzývajícího v kg (na setiny).
  final double value;

  /// Opakování rekordní série (null = jen váha).
  final int? reps;

  /// Název cviku (jen u vlastních cviků).
  final String? exerciseName;
  final String? fromName;

  /// Termín (den, 00:00 místního času).
  final DateTime? deadline;

  /// Nejdelší jméno vyzývajícího ([fromName]).
  static const maxNameLength = 40;

  /// Nejdelší název vlastního cviku ([exerciseName]) – víc, než dovolí
  /// editor cviku (60), aby se název nikdy nezkrátil. Stejný limit
  /// (i pro [maxNameLength]) používá webová stránka docs/web/challenge.html.
  static const maxExerciseNameLength = 64;
  static const maxValueKg = 1000.0;
  static const maxReps = 999;

  /// Cíl výzvy jako [recordValue]: kamarád ho překoná těžší vahou, nebo
  /// stejnou vahou na víc opakování.
  double get target =>
      reps == null ? value : (recordValue(value, reps) ?? value);

  /// Je [exercise] číselné ID (a ne slug)?
  int? get exerciseId => int.tryParse(exercise);

  /// Slug, pokud [exercise] není číslo.
  String? get exerciseSlug => exerciseId == null ? exercise : null;

  /// Query část odkazu (bez „?“), zakódovaná.
  /// Názvy se zkrátí na stejné limity, jaké platí při čtení ([fromQuery]).
  String toQuery() {
    final x = _clean(exerciseName, maxExerciseNameLength);
    final n = _clean(fromName, maxNameLength);
    final params = <String, String>{
      'e': exercise,
      'v': formatValue(value),
      if (reps != null) 'r': '$reps',
      if (x != null) 'x': x,
      if (n != null) 'n': n,
      if (deadline != null) 'd': formatDate(deadline!),
    };
    return Uri(queryParameters: params).query;
  }

  /// Webový odkaz: `<baseUrl>/challenge?...`
  String toWebUrl(String baseUrl) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return '$base/challenge?${toQuery()}';
  }

  /// Přečte parametry z odkazu. Vrací null, když odkaz není platný.
  static ChallengeLink? fromQuery(Map<String, String> q) {
    final e = q['e']?.trim() ?? '';
    if (e.isEmpty || e.length > 64) return null;
    final v = double.tryParse((q['v'] ?? '').replaceAll(',', '.'));
    if (v == null || v.isNaN || v <= 0 || v > maxValueKg) return null;
    final r = int.tryParse(q['r']?.trim() ?? '');
    return ChallengeLink(
      exercise: e,
      value: roundKg(v),
      reps: r == null || r < 1 || r > maxReps ? null : r,
      exerciseName: _clean(q['x'], maxExerciseNameLength),
      fromName: _clean(q['n'], maxNameLength),
      deadline: parseDate(q['d']),
    );
  }

  /// Ořízne mezery a zkrátí na [max] jednotek UTF-16 (jako `slice` na
  /// webu); rozpůlený pár náhradních znaků (emoji) na konci zahodí.
  static String? _clean(String? s, int max) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return null;
    if (t.length <= max) return t;
    var cut = t.substring(0, max);
    final last = cut.codeUnitAt(cut.length - 1);
    if (last >= 0xD800 && last <= 0xDBFF) {
      cut = cut.substring(0, cut.length - 1);
    }
    final result = cut.trimRight();
    return result.isEmpty ? null : result;
  }

  /// Váha na setiny kg (z liber vychází např. 102,06 kg).
  static double roundKg(double v) => (v * 100).round() / 100;

  /// 116.0 → „116“, 102.06 → „102.06“ (tečka – kvůli odkazu, ne pro zobrazení).
  static String formatValue(double v) {
    final r = roundKg(v);
    return r == r.roundToDouble() ? r.toInt().toString() : r.toString();
  }

  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// „2026-10-30“ → DateTime(2026, 10, 30). Neplatné datum → null.
  static DateTime? parseDate(String? s) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s?.trim() ?? '');
    if (m == null) return null;
    final y = int.parse(m.group(1)!);
    final mo = int.parse(m.group(2)!);
    final d = int.parse(m.group(3)!);
    final date = DateTime(y, mo, d);
    if (date.year != y || date.month != mo || date.day != d) return null;
    return date;
  }
}
