import 'package:flutter_test/flutter_test.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

CoachSession session({
  DateTime? start,
  int weeks = 1,
  int duration = 60,
  CoachSessionStatus status = CoachSessionStatus.pending,
  String? note,
}) =>
    CoachSession(
      id: 'abc',
      startAt: start ?? DateTime(2026, 10, 20, 18),
      durationMin: duration,
      weeks: weeks,
      title: 'Nohy',
      note: note,
      trainerName: 'Tom',
      status: status,
    );

void main() {
  test('opakování po týdnu drží místní čas i přes změnu letního času', () {
    // 25. 10. 2026 končí v Evropě letní čas.
    final s = session(start: DateTime(2026, 10, 20, 18), weeks: 3);
    expect(s.occurrences, [
      DateTime(2026, 10, 20, 18),
      DateTime(2026, 10, 27, 18),
      DateTime(2026, 11, 3, 18),
    ]);
    expect(s.endOf(s.occurrences.last), DateTime(2026, 11, 3, 19));
  });

  test('nadcházející termíny a aktivní pozvánka', () {
    final s = session(weeks: 3);
    expect(s.upcoming(DateTime(2026, 10, 20, 18, 30)).length, 3);
    expect(s.upcoming(DateTime(2026, 10, 20, 19, 1)).length, 2);
    expect(s.nextOccurrence(DateTime(2026, 10, 21)), DateTime(2026, 10, 27, 18));
    expect(s.isActive(DateTime(2026, 12, 1)), isFalse);
    expect(session(status: CoachSessionStatus.cancelled).isActive(DateTime(2026)),
        isFalse);
  });

  test('JSON tam a zpět, poškozená a krajní data', () {
    final s = session(weeks: 4, note: 'Vem si švihadlo');
    final back = CoachSession.fromJson('abc', {
      ...s.toJson(),
      'status': 'accepted',
    }, updatedAtMs: 5);
    expect(back.startAt, s.startAt);
    expect((back.weeks, back.durationMin, back.title, back.note),
        (4, 60, 'Nohy', 'Vem si švihadlo'));
    expect(back.status, CoachSessionStatus.accepted);
    expect(back.updatedAtMs, 5);

    final odd = CoachSession.fromJson('x', {
      'startAtMs': 0,
      'title': 'T',
      'weeks': 999,
      'durationMin': 5,
      'status': 'nesmysl',
    });
    expect((odd.weeks, odd.durationMin, odd.status),
        (1, 60, CoachSessionStatus.pending));
    expect(() => CoachSession.fromJson('x', {'title': 'T'}),
        throwsA(isA<CoachFormatException>()));

    final clipped = session(weeks: 99, duration: 1000).toJson();
    expect((clipped['weeks'], clipped['durationMin']),
        (coachSessionMaxWeeks, coachSessionMaxMinutes));
  });

  test('.ics s opakováním a escapovaným textem', () {
    final ics = coachSessionIcs(
      session(weeks: 4),
      title: 'Fitko – Nohy; s Tomem',
      description: 'Řádek 1\nŘádek 2, konec',
      now: DateTime.utc(2026, 10, 16, 8, 30),
    );
    expect(ics, contains('DTSTART:20261020T180000\r\n'));
    expect(ics, contains('DTEND:20261020T190000\r\n'));
    expect(ics, contains('RRULE:FREQ=WEEKLY;COUNT=4\r\n'));
    expect(ics, contains(r'SUMMARY:Fitko – Nohy\; s Tomem'));
    expect(ics, contains(r'DESCRIPTION:Řádek 1\nŘádek 2\, konec'));
    expect(ics, contains('DTSTAMP:20261016T083000Z'));
    expect(ics, contains('UID:abc@gymbar.app'));
    expect(coachSessionIcs(session(), title: 'X', now: DateTime.utc(2026)),
        isNot(contains('RRULE')));
  });
}
