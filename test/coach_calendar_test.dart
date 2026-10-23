import 'package:fitness_app/modules/coach/coach_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

final now = DateTime(2026, 10, 16, 12);

CoachCalendarItem item(
  String id, {
  CoachSessionStatus status = CoachSessionStatus.accepted,
  int version = 1,
  DateTime? start,
  int weeks = 1,
}) =>
    (
      key: clientSessionKey(id),
      withName: 'Tom',
      session: CoachSession(
        id: id,
        startAt: start ?? DateTime(2026, 10, 20, 18),
        durationMin: 60,
        weeks: weeks,
        title: 'Nohy',
        trainerName: 'Tom',
        status: status,
        updatedAtMs: version,
      ),
    );

void main() {
  test('přijatá pozvánka se přidá, nevyřízená a odmítnutá ne', () {
    final plan = planCoachCalendar([
      item('a'),
      item('b', status: CoachSessionStatus.pending),
      item('c', status: CoachSessionStatus.declined),
    ], {}, now);
    expect(plan.add.map((i) => i.key), ['c:a']);
    expect(plan.remove, isEmpty);
  });

  test('beze změny nic, nová verze se vytvoří znovu', () {
    final same = planCoachCalendar([item('a')], {'c:a': 1}, now);
    expect(same.remove, isEmpty);
    expect(same.add, isEmpty);
    final changed = planCoachCalendar([item('a', version: 2)], {'c:a': 1}, now);
    expect(changed.remove, ['c:a']);
    expect(changed.add.map((i) => i.key), ['c:a']);
  });

  test('zrušená, odmítnutá nebo zmizelá pozvánka se smaže', () {
    final plan = planCoachCalendar([
      item('a', status: CoachSessionStatus.cancelled),
      item('b', status: CoachSessionStatus.declined),
    ], {'c:a': 1, 'c:b': 1, 'c:zmizela': 1}, now);
    expect(plan.remove.toSet(), {'c:a', 'c:b', 'c:zmizela'});
    expect(plan.add, isEmpty);
  });

  test('proběhlá přijatá pozvánka v kalendáři zůstane, znovu se nevytvoří', () {
    final past = item('c', start: DateTime(2026, 10, 1, 18));
    final same = planCoachCalendar([past], {'c:c': 1}, now);
    expect(same.remove, isEmpty);
    expect(same.add, isEmpty);
    // Bez dřívějších událostí se proběhlá pozvánka nepřidá.
    expect(planCoachCalendar([past], {}, now).add, isEmpty);
    // Změněná proběhlá pozvánka: smazat (jen budoucí termíny), nic nepřidat.
    final changed = planCoachCalendar([item('c', start: DateTime(2026, 10, 1, 18), version: 2)], {'c:c': 1}, now);
    expect(changed.remove, ['c:c']);
    expect(changed.add, isEmpty);
  });

  test('opakovaná pozvánka zůstane, dokud má budoucí termín', () {
    final weekly = item('a', start: DateTime(2026, 10, 1, 18), weeks: 4);
    expect(planCoachCalendar([weekly], {}, now).add, hasLength(1));
    // 1., 8. a 15. 10. už proběhly, zbývá 22. 10.
    expect(weekly.session.upcoming(now), [DateTime(2026, 10, 22, 18)]);
  });

  test('klíče klienta a trenéra se neplete', () {
    expect(clientSessionKey('x'), 'c:x');
    expect(trainerSessionKey('u1', 'x'), 't:u1/x');
  });
}
