import 'package:fitness_app/modules/stats/stats_math.dart';
import 'package:fitness_app/modules/stats/streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Středa 30. 9. 2026; týden začíná pondělím 28. 9.
  final now = DateTime(2026, 9, 30, 18);

  group('plannedDaysPerWeek / requiredSessionsPerWeek', () {
    test('sjednocení dnů více plánů', () {
      // Po+St a St+Pá => Po, St, Pá = 3 dny
      expect(plannedDaysPerWeek([0x05, 0x14]), 3);
    });

    test('bez plánů je potřeba 1 trénink týdně', () {
      expect(requiredSessionsPerWeek(const []), 1);
      expect(requiredSessionsPerWeek([0]), 1);
    });

    test('ignoruje bity nad nedělí', () {
      expect(plannedDaysPerWeek([0xFF]), 7);
    });
  });

  group('weekStreak', () {
    test('bez tréninků je série 0', () {
      final s = weekStreak(const [], now, goal: 1);
      expect(s.weeks, 0);
      expect(s.doneThisWeek, 0);
      expect(s.goal, 1);
    });

    test('nesplněný probíhající týden sérii nepřeruší', () {
      final s = weekStreak([
        DateTime(2026, 9, 22), // minulý týden
        DateTime(2026, 9, 15), // předminulý
      ], now, goal: 1);
      expect(s.weeks, 2);
      expect(s.doneThisWeek, 0);
    });

    test('splněný probíhající týden se započítá', () {
      final s = weekStreak([
        DateTime(2026, 9, 29),
        DateTime(2026, 9, 22),
      ], now, goal: 1);
      expect(s.weeks, 2);
      expect(s.doneThisWeek, 1);
    });

    test('týden pod plánem sérii přeruší', () {
      final s = weekStreak([
        DateTime(2026, 9, 21), DateTime(2026, 9, 23), // 2 z 2
        DateTime(2026, 9, 16), // jen 1 z 2 – přerušení
        DateTime(2026, 9, 7), DateTime(2026, 9, 9),
      ], now, goal: 2);
      expect(s.weeks, 1);
    });

    test('mezera jednoho týdne sérii ukončí', () {
      final s = weekStreak([
        DateTime(2026, 9, 22),
        DateTime(2026, 9, 8),
        DateTime(2026, 9, 1),
      ], now, goal: 1);
      expect(s.weeks, 1);
    });

    test('počítají se i krátké rutiny (každý záznam je trénink)', () {
      final s = weekStreak([
        DateTime(2026, 9, 21, 7), // plán B ráno
        DateTime(2026, 9, 21, 18), // plný trénink večer
        DateTime(2026, 9, 24),
      ], now, goal: 3);
      expect(s.weeks, 1);
    });

    test('neděle patří do týdne od pondělí', () {
      final s = weekStreak([DateTime(2026, 9, 27, 23)], now, goal: 1);
      expect(s.weeks, 1);
      expect(s.doneThisWeek, 0);
    });
  });

  group('weeklySums', () {
    test('sčítá hodnoty po týdnech a zahodí starší', () {
      final weeks = weeklySums([
        (x: DateTime(2026, 9, 29), y: 1000.0),
        (x: DateTime(2026, 9, 30), y: 500.0),
        (x: DateTime(2026, 9, 21), y: 200.0),
        (x: DateTime(2025, 1, 1), y: 999.0),
      ], now, weeks: 3);
      expect(weeks.length, 3);
      expect(weeks.last.weekStart, DateTime(2026, 9, 28));
      expect(weeks.last.total, 1500);
      expect(weeks[1].total, 200);
      expect(weeks.first.total, 0);
    });
  });

  group('dailyCounts', () {
    test('počítá tréninky po dnech', () {
      final c = dailyCounts([
        DateTime(2026, 9, 29, 7),
        DateTime(2026, 9, 29, 19),
        DateTime(2026, 9, 30, 8),
      ]);
      expect(c[DateTime(2026, 9, 29)], 2);
      expect(c[DateTime(2026, 9, 30)], 1);
      expect(c[DateTime(2026, 9, 28)], isNull);
    });
  });
}
