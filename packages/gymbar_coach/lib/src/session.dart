// Pozvánka od trenéra na společný trénink (coachLinks/{klient}/sessions/{id},
// docs/coach.md). Jednorázový termín nebo každý týden ve stejný den a čas.
// Čas se ukládá jako ms od epochy, opakování se počítá přes kalendářní den
// (při přechodu na letní čas zůstane stejná hodina).
import 'json.dart';

const coachSessionTitleMax = 60;
const coachSessionNoteMax = 300;
const coachSessionMinMinutes = 15;
const coachSessionMaxMinutes = 480;

/// Nejvíc týdnů opakování (půl roku).
const coachSessionMaxWeeks = 26;

enum CoachSessionStatus { pending, accepted, declined, cancelled }

CoachSessionStatus _status(Object? v) {
  for (final s in CoachSessionStatus.values) {
    if (s.name == v) return s;
  }
  return CoachSessionStatus.pending;
}

/// Termín [index] (od 0) opakování po týdnu od [first] – stejný den v týdnu
/// a stejný místní čas.
DateTime coachSessionOccurrence(DateTime first, int index) => DateTime(
      first.year,
      first.month,
      first.day + 7 * index,
      first.hour,
      first.minute,
    );

class CoachSession {
  const CoachSession({
    required this.id,
    required this.startAt,
    required this.durationMin,
    this.weeks = 1,
    required this.title,
    this.note,
    this.planId,
    required this.trainerName,
    this.status = CoachSessionStatus.pending,
    this.updatedAtMs,
  });

  /// [json] = dokument Firestore. updatedAt (Timestamp) převede volající
  /// na [updatedAtMs] – balíček Firestore nezná.
  factory CoachSession.fromJson(String id, Object? json, {int? updatedAtMs}) {
    final m = asMap(json, 'session');
    final start = optInt(m['startAtMs'], max: maxTimeMs) ??
        (throw CoachFormatException('session start missing'));
    return CoachSession(
      id: id,
      startAt: DateTime.fromMillisecondsSinceEpoch(start),
      durationMin: optInt(m['durationMin'],
              min: coachSessionMinMinutes, max: coachSessionMaxMinutes) ??
          60,
      weeks: optInt(m['weeks'], min: 1, max: coachSessionMaxWeeks) ?? 1,
      title: reqString(m['title'], 'session title', max: coachSessionTitleMax),
      note: optString(m['note'], max: coachSessionNoteMax),
      planId: optString(m['planId'], max: 40),
      trainerName: optString(m['trainerName'], max: 40) ?? '?',
      status: _status(m['status']),
      updatedAtMs: updatedAtMs,
    );
  }

  final String id;

  /// První termín (místní čas).
  final DateTime startAt;
  final int durationMin;

  /// Počet termínů po týdnu (1 = jednorázově).
  final int weeks;
  final String title;
  final String? note;

  /// Plán od trenéra (coachLinks/{klient}/plans/{planId}), null = bez plánu.
  final String? planId;
  final String trainerName;
  final CoachSessionStatus status;

  /// Poslední změna – podle ní aplikace pozná upravený termín.
  final int? updatedAtMs;

  bool get repeats => weeks > 1;

  /// Všechny termíny (začátky).
  List<DateTime> get occurrences => [
        for (var i = 0; i < weeks; i++) coachSessionOccurrence(startAt, i),
      ];

  DateTime endOf(DateTime start) => DateTime(start.year, start.month,
      start.day, start.hour, start.minute + durationMin);

  /// Termíny, které ještě neskončily.
  List<DateTime> upcoming(DateTime now) =>
      [for (final o in occurrences) if (endOf(o).isAfter(now)) o];

  /// Nejbližší termín, který ještě neskončil (null = vše proběhlo).
  DateTime? nextOccurrence(DateTime now) {
    final u = upcoming(now);
    return u.isEmpty ? null : u.first;
  }

  /// Má smysl ji ukazovat / mít v kalendáři (nezrušená a neproběhlá).
  bool isActive(DateTime now) =>
      status != CoachSessionStatus.cancelled && nextOccurrence(now) != null;

  /// Pole dokumentu, která zapisuje trenér (bez stavu a časových razítek).
  Map<String, Object?> toJson() => {
        'startAtMs': startAt.millisecondsSinceEpoch,
        'durationMin': durationMin
            .clamp(coachSessionMinMinutes, coachSessionMaxMinutes)
            .toInt(),
        'weeks': weeks.clamp(1, coachSessionMaxWeeks).toInt(),
        'title': clip(title, coachSessionTitleMax),
        if (note != null && note!.trim().isNotEmpty)
          'note': clip(note!, coachSessionNoteMax),
        if (planId != null) 'planId': planId,
        'trainerName': clip(trainerName, 40),
      };
}

String _two(int n) => n.toString().padLeft(2, '0');

/// Místní čas bez časového pásma („plovoucí“ – v kalendáři zůstane stejná
/// hodina i po změně letního času).
String _icsLocal(DateTime d) =>
    '${d.year}${_two(d.month)}${_two(d.day)}T${_two(d.hour)}${_two(d.minute)}00';

String _icsUtc(DateTime d) {
  final u = d.toUtc();
  return '${u.year}${_two(u.month)}${_two(u.day)}T${_two(u.hour)}${_two(u.minute)}${_two(u.second)}Z';
}

String _icsText(String s) => s
    .replaceAll(r'\', r'\\')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,')
    .replaceAll('\r\n', r'\n')
    .replaceAll('\n', r'\n');

/// Délka znaku (Unicode code point) v UTF-8 v bajtech.
int _utf8Length(int rune) => rune < 0x80
    ? 1
    : rune < 0x800
        ? 2
        : rune < 0x10000
            ? 3
            : 4;

/// Řádek .ics zalomený po nejvýš 75 oktetech UTF-8 (RFC 5545, pokračování
/// začíná mezerou, která se do 75 počítá). Nikdy nerozdělí znak (diakritika,
/// emoji).
String _icsFold(String line) {
  final parts = <String>[];
  final buf = StringBuffer();
  var bytes = 0;
  var limit = 75;
  for (final rune in line.runes) {
    final len = _utf8Length(rune);
    if (bytes + len > limit) {
      parts.add(buf.toString());
      buf.clear();
      bytes = 0;
      limit = 74; // + úvodní mezera
    }
    buf.writeCharCode(rune);
    bytes += len;
  }
  parts.add(buf.toString());
  return parts.join('\r\n ');
}

/// Soubor .ics s termínem (opakování po týdnu přes RRULE) – pro import do
/// kalendáře na webu. [now] = DTSTAMP.
String coachSessionIcs(
  CoachSession s, {
  required String title,
  String? description,
  required DateTime now,
}) {
  final lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//GymBar//Trener//CS',
    'CALSCALE:GREGORIAN',
    'BEGIN:VEVENT',
    'UID:${s.id}@gymbar.app',
    'DTSTAMP:${_icsUtc(now)}',
    'DTSTART:${_icsLocal(s.startAt)}',
    'DTEND:${_icsLocal(s.endOf(s.startAt))}',
    if (s.repeats) 'RRULE:FREQ=WEEKLY;COUNT=${s.weeks}',
    'SUMMARY:${_icsText(title)}',
    if (description != null && description.trim().isNotEmpty)
      'DESCRIPTION:${_icsText(description.trim())}',
    'END:VEVENT',
    'END:VCALENDAR',
  ];
  return '${lines.map(_icsFold).join('\r\n')}\r\n';
}
