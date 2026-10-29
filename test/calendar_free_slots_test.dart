import 'package:fitness_app/modules/calendar/free_slots.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2026, 10, 5);
  DateTime at(int h, [int m = 0]) => DateTime(2026, 10, 5, h, m);
  CalendarEntry ev(String t, DateTime s, DateTime e, {bool allDay = false}) =>
      CalendarEntry(title: t, start: s, end: e, allDay: allDay);

  group('freeWindows', () {
    test('prázdný den = jedno okno 6–22', () {
      final w = freeWindows(day: day, entries: const []);
      expect(w, hasLength(1));
      expect(w.first.start, at(6));
      expect(w.first.end, at(22));
    });

    test('událost se rozšíří o 15 min na obě strany', () {
      final w = freeWindows(
        day: day,
        entries: [ev('Porada', at(9), at(17))],
      );
      expect(w, hasLength(2));
      expect(w[0].start, at(6));
      expect(w[0].end, at(8, 45));
      expect(w[1].start, at(17, 15));
      expect(w[1].end, at(22));
    });

    test('celodenní události se ignorují', () {
      final w = freeWindows(
        day: day,
        entries: [ev('Svátek', at(0), DateTime(2026, 10, 6), allDay: true)],
      );
      expect(w, hasLength(1));
      expect(w.first.end.difference(w.first.start).inHours, 16);
    });

    test('krátká okna se vynechají, překrývající události se sloučí', () {
      final w = freeWindows(
        day: day,
        entries: [
          ev('A', at(6), at(12)),
          ev('B', at(11), at(13)),
          // mezera 13:15–14:15 = 60 min → přesně na hraně, zůstane
          ev('C', at(14, 30), at(21)),
        ],
      );
      expect(w, hasLength(1));
      expect(w.first.start, at(13, 15));
      expect(w.first.end, at(14, 15));
    });

    test('delší trénink vyžaduje delší okno', () {
      final w = freeWindows(
        day: day,
        minMinutes: 90,
        entries: [ev('A', at(6), at(13)), ev('B', at(14, 30), at(22))],
      );
      expect(w, isEmpty);
    });

    test('události mimo rozmezí a přes půlnoc', () {
      final w = freeWindows(
        day: day,
        entries: [
          ev('Noc', DateTime(2026, 10, 4, 23), at(7)),
          ev('Pozdě', at(22, 30), at(23)),
        ],
      );
      expect(w, hasLength(1));
      expect(w.first.start, at(7, 15));
      expect(w.first.end, at(22));
    });

    test('notBefore ořízne začátek', () {
      final w = freeWindows(day: day, entries: const [], notBefore: at(20, 10));
      expect(w, hasLength(1));
      expect(w.first.start, at(20, 10));
      final none =
          freeWindows(day: day, entries: const [], notBefore: at(21, 30));
      expect(none, isEmpty);
    });

    test('celý den obsazený', () {
      final w = freeWindows(day: day, entries: [ev('Výlet', at(5), at(23))]);
      expect(w, isEmpty);
    });
  });

  group('suggestStarts', () {
    test('bez času plánu preferuje 17–19', () {
      final w = freeWindows(day: day, entries: [ev('Práce', at(8), at(16))]);
      final s = suggestStarts(day: day, windows: w);
      expect(s.first.start, at(17));
      expect(s.first.distance, 0);
    });

    test('okno začíná uprostřed preferovaného rozmezí', () {
      final w = freeWindows(day: day, entries: [ev('Práce', at(8), at(17, 5))]);
      final s = suggestStarts(day: day, windows: w);
      // 17:05 + 15 min rezerva = 17:20 → zaokrouhleno na 17:30
      expect(s.first.start, at(17, 30));
      expect(s.first.distance, 0);
    });

    test('preferovaný čas plánu', () {
      final w = freeWindows(day: day, entries: [ev('Schůzka', at(17), at(18))]);
      final range = preferredRange(17 * 60 + 30);
      final s = suggestStarts(
        day: day,
        windows: w,
        preferredFrom: range.from,
        preferredTo: range.to,
      );
      // Okna 6:00–16:45 a 18:15–22:00; nejblíž 17:30 je 18:15 (45 min)
      // proti 15:45 (105 min).
      expect(s.first.start, at(18, 15));
      expect(s.first.distance, 45);
      expect(s[1].start, at(15, 45));
    });

    test('okno kratší než trénink po zaokrouhlení se vynechá', () {
      final windows = <TimeWindow>[(start: at(10, 5), end: at(11, 5))];
      expect(suggestStarts(day: day, windows: windows), isEmpty);
    });

    // Dny změny času v Evropě (29. 3. a 25. 10. 2026) a v USA (8. 3.
    // a 1. 11. 2026). Chybu odhalí test spuštěný v časovém pásmu se
    // změnou času (např. TZ=Europe/Prague); jinde musí projít také.
    test('v den změny času navrhne čas podle hodin', () {
      for (final d in [
        DateTime(2026, 3, 29),
        DateTime(2026, 10, 25),
        DateTime(2026, 3, 8),
        DateTime(2026, 11, 1),
      ]) {
        DateTime t(int h) => DateTime(d.year, d.month, d.day, h);
        // Jediné volné okno 18:00–19:00 → trénink přesně v 18:00.
        final s = suggestStarts(
          day: d,
          windows: [(start: t(18), end: t(19))],
        );
        expect(s, hasLength(1), reason: '$d');
        expect(s.first.start, t(18), reason: '$d');
        expect(s.first.distance, 0, reason: '$d');

        // Celý volný den: preferovaných 17:00, ne 16:00 / 18:00.
        final w = freeWindows(day: d, entries: const []);
        expect(suggestStarts(day: d, windows: w).first.start, t(17),
            reason: '$d');
      }
    });

    test('konec okna o půlnoci se počítá jako 24:00', () {
      final windows = <TimeWindow>[
        (start: at(22, 30), end: DateTime(2026, 10, 6)),
      ];
      final s = suggestStarts(day: day, windows: windows);
      expect(s, hasLength(1));
      expect(s.first.start, at(22, 30));
    });
  });

  group('collisionsWith', () {
    test('najde překryv a ignoruje celodenní', () {
      final entries = [
        ev('Meeting', at(17), at(18)),
        ev('Dovolená', at(0), DateTime(2026, 10, 6), allDay: true),
        ev('Ráno', at(8), at(9)),
      ];
      final c = collisionsWith(entries, at(17, 30), at(18, 30));
      expect(c.map((e) => e.title), ['Meeting']);
    });

    test('navazující událost není kolize', () {
      final c = collisionsWith(
          [ev('A', at(16), at(17, 30))], at(17, 30), at(18, 30));
      expect(c, isEmpty);
    });
  });

  group('commonStarts', () {
    test('čas volný ve všech dnech plánu', () {
      final mon = DateTime(2026, 10, 5);
      final wed = DateTime(2026, 10, 7);
      final days = <DayWindows>[
        (
          day: mon,
          windows: freeWindows(day: mon, entries: [
            CalendarEntry(
              title: 'A',
              start: DateTime(2026, 10, 5, 8),
              end: DateTime(2026, 10, 5, 17),
            ),
          ]),
        ),
        (
          day: wed,
          windows: freeWindows(day: wed, entries: [
            CalendarEntry(
              title: 'B',
              start: DateTime(2026, 10, 7, 17),
              end: DateTime(2026, 10, 7, 18, 30),
            ),
          ]),
        ),
      ];
      // Po: volno od 17:15. St: do 16:45 a od 18:45.
      final s = commonStarts(days: days);
      expect(s, isNotEmpty);
      expect(s.first.minutes, 18 * 60 + 45);
      expect(s.first.distance, 45);
      for (final c in s) {
        expect(c.minutes >= 17 * 60 + 15, isTrue);
      }
    });

    test('žádný společný čas', () {
      final mon = DateTime(2026, 10, 5);
      final days = <DayWindows>[(day: mon, windows: const [])];
      expect(commonStarts(days: days), isEmpty);
      expect(commonStarts(days: const []), isEmpty);
    });
  });
}
