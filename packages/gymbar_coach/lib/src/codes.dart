// Kód trenéra (trainerCodes/{kód}) a pravidla statusu trenéra.
import 'dart:math';

import 'text_filter.dart';

/// Stejná abeceda jako kód přítele a posilovny (bez 0/O, 1/I/L).
const coachCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

/// Délka kódu trenéra (kód posilovny má také 6 znaků, ale jiný odkaz:
/// /coach?code=…, takže se nepletou).
const coachCodeLength = 6;

/// Status trenéra zanikne, když trenér tolik dní nemá žádného klienta
/// (Cloud Function expireTrainers, functions/src/coach.ts).
const coachInactiveDays = 60;

/// Max. délka jména trenéra a popisu (firestore.rules).
const coachNameMax = 40;
const coachBioMax = 300;

/// Max. délka komentáře trenéra k tréninku (firestore.rules).
const coachNoteMax = 500;

String generateCoachCode([Random? random]) {
  final r = random ?? Random.secure();
  return String.fromCharCodes([
    for (var i = 0; i < coachCodeLength; i++)
      coachCodeAlphabet.codeUnitAt(r.nextInt(coachCodeAlphabet.length)),
  ]);
}

String normalizeCoachCode(String input) =>
    input.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

bool isValidCoachCode(String code) =>
    code.length == coachCodeLength &&
    code.codeUnits.every(coachCodeAlphabet.codeUnits.contains);

/// Kód z naskenovaného textu: odkaz `…/coach?code=…`
/// (gymbar://coach?code=… i https://gymbar.app/coach?code=…) nebo kód.
String? parseCoachCode(String scanned) {
  final text = scanned.trim();
  final uri = Uri.tryParse(text);
  if (uri != null && uri.hasScheme) {
    final isCoach = uri.host == 'coach' ||
        (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'coach');
    final code = uri.queryParameters['code'];
    if (!isCoach || code == null) return null;
    final n = normalizeCoachCode(code);
    return isValidCoachCode(n) ? n : null;
  }
  final n = normalizeCoachCode(text);
  return isValidCoachCode(n) ? n : null;
}

/// Kdy trenér přijde o status: [coachInactiveDays] dní od chvíle, kdy
/// nemá žádného klienta ([zeroSince]). S klienty nikdy (null).
DateTime? coachStatusExpiresAt({
  required int clientCount,
  required DateTime? zeroSince,
}) {
  if (clientCount > 0 || zeroSince == null) return null;
  // Kalendářně (kvůli letnímu času); funkce na serveru počítá v ms,
  // rozdíl je nejvýš hodina.
  final z = zeroSince;
  return DateTime(z.year, z.month, z.day + coachInactiveDays, z.hour,
      z.minute, z.second);
}

/// Jméno trenéra / klienta, jak se uloží (max. [coachNameMax] znaků,
/// bez hrubých slov – jinak „?“).
String coachName(String input) {
  final t = input.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return '?';
  return publicTextOr(
      t.length > coachNameMax ? t.substring(0, coachNameMax) : t, '?');
}

/// Popis trenéra, jak se uloží (null = žádný / s hrubými slovy).
String? coachBio(String? input) {
  final t = input?.trim() ?? '';
  if (t.isEmpty) return null;
  final clipped = t.length > coachBioMax ? t.substring(0, coachBioMax) : t;
  final clean = publicTextOr(clipped, '');
  return clean.isEmpty ? null : clean;
}
