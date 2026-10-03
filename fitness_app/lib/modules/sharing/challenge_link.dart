// Odkaz s výzvou: sestavení a čtení parametrů. Čistý Dart (testovatelné).
//
// Podoba: <web>/challenge?e=<slug nebo id>&v=<odhad 1RM>&n=<jméno>&d=<rrrr-mm-dd>
// U vlastních cviků (bez slugu) se přidává x=<název cviku>, protože ID
// cviku na telefonu kamaráda nic neznamená.

import 'challenge_progress.dart';

class ChallengeLink {
  const ChallengeLink({
    required this.exercise,
    required this.value,
    this.exerciseName,
    this.fromName,
    this.deadline,
  });

  /// Slug vestavěného cviku, nebo číselné ID.
  final String exercise;

  /// Cílový odhad 1RM v kg (zaokrouhlený na 0,5).
  final double value;

  /// Název cviku (jen u vlastních cviků).
  final String? exerciseName;
  final String? fromName;

  /// Termín (den, 00:00 místního času).
  final DateTime? deadline;

  static const maxNameLength = 40;
  static const maxValueKg = 1000.0;

  /// Je [exercise] číselné ID (a ne slug)?
  int? get exerciseId => int.tryParse(exercise);

  /// Slug, pokud [exercise] není číslo.
  String? get exerciseSlug => exerciseId == null ? exercise : null;

  /// Query část odkazu (bez „?“), zakódovaná.
  String toQuery() {
    final params = <String, String>{
      'e': exercise,
      'v': formatValue(value),
      if (exerciseName != null && exerciseName!.isNotEmpty) 'x': exerciseName!,
      if (fromName != null && fromName!.isNotEmpty) 'n': fromName!,
      if (deadline != null) 'd': formatDate(deadline!),
    };
    return Uri(queryParameters: params).query;
  }

  /// Webový odkaz: <baseUrl>/challenge?...
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
    return ChallengeLink(
      exercise: e,
      value: roundToHalf(v),
      exerciseName: _clean(q['x']),
      fromName: _clean(q['n']),
      deadline: parseDate(q['d']),
    );
  }

  static String? _clean(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return null;
    return t.length > maxNameLength ? t.substring(0, maxNameLength) : t;
  }

  /// 116.0 → „116“, 116.5 → „116.5“ (tečka – kvůli odkazu, ne pro zobrazení).
  static String formatValue(double v) {
    final r = roundToHalf(v);
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
