import 'dart:math';

import 'package:fitness_app/modules/social/social_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isoWeekKey', () {
    test('běžný týden', () {
      expect(isoWeekKey(DateTime(2026, 9, 30)), '2026-W40');
    });

    test('1. 1. 2027 (pátek) patří do 53. týdne 2026', () {
      expect(isoWeekKey(DateTime(2027, 1, 1)), '2026-W53');
    });

    test('29. 12. 2025 (pondělí) je 1. týden 2026', () {
      expect(isoWeekKey(DateTime(2025, 12, 29)), '2026-W01');
    });

    test('pondělí i neděle stejného týdne mají stejný klíč', () {
      expect(isoWeekKey(DateTime(2026, 9, 28)), isoWeekKey(DateTime(2026, 10, 4)));
    });
  });

  test('isoWeekStart vrací pondělí', () {
    expect(isoWeekStart(DateTime(2026, 10, 4, 18)), DateTime(2026, 9, 28));
  });

  test('monthKey', () {
    expect(monthKey(DateTime(2026, 3, 9)), '2026-03');
  });

  test('recentWeekKeys jde od tohoto týdne dozadu', () {
    final keys = recentWeekKeys(DateTime(2026, 1, 7), 3);
    expect(keys, ['2026-W02', '2026-W01', '2025-W52']);
  });

  group('plán a série', () {
    test('plannedPerWeek sčítá dny všech plánů', () {
      expect(plannedPerWeek([0x05, 0x10]), 3); // po+st, pá
    });

    test('bez plánu stačí jeden trénink', () {
      expect(isPlanMet(workouts: 1, plannedPerWeek: 0), isTrue);
      expect(isPlanMet(workouts: 0, plannedPerWeek: 0), isFalse);
      expect(isPlanMet(workouts: 2, plannedPerWeek: 3), isFalse);
      expect(isPlanMet(workouts: 3, plannedPerWeek: 3), isTrue);
    });

    final now = DateTime(2026, 9, 30); // týden W40
    test('rozběhnutý týden sérii nepřeruší', () {
      final mine = {'2026-W39': true, '2026-W38': true, '2026-W37': false};
      final theirs = {'2026-W39': true, '2026-W38': true, '2026-W37': true};
      expect(pairStreak(mine, theirs, now), 2);
    });

    test('splněný aktuální týden se započítá', () {
      final both = {'2026-W40': true, '2026-W39': true};
      expect(pairStreak(both, both, now), 2);
    });

    test('stačí, aby jeden nesplnil', () {
      expect(
        pairStreak({'2026-W39': true}, {'2026-W39': false}, now),
        0,
      );
    });

    test('trimWeeks zahodí staré týdny', () {
      final t = trimWeeks({'2026-W40': true, '2020-W01': true}, now);
      expect(t.keys, ['2026-W40']);
    });
  });

  group('relativeStrength', () {
    test('poměr zaokrouhlený na 0,05', () {
      expect(relativeStrength(120, 80), 1.5);
      expect(relativeStrength(101, 80), closeTo(1.25, 1e-9));
    });

    test('bez váhy nebo nesmyslná data → null', () {
      expect(relativeStrength(100, null), isNull);
      expect(relativeStrength(null, 80), isNull);
      expect(relativeStrength(100, 10), isNull);
      expect(relativeStrength(1000, 50), isNull);
    });
  });

  group('kód přítele', () {
    test('generuje platný kód', () {
      final code = generateFriendCode(Random(1));
      expect(code.length, friendCodeLength);
      expect(isValidFriendCode(code), isTrue);
    });

    test('normalizace a matoucí znaky', () {
      expect(normalizeFriendCode(' abcd-2345 '), 'ABCD2345');
      expect(isValidFriendCode('ABCD0345'), isFalse); // 0 není v abecedě
      expect(isValidFriendCode('ABC'), isFalse);
    });

    test('parseFriendCode z odkazu i z textu', () {
      expect(parseFriendCode('fitnessapp://friend?code=abcd2345'), 'ABCD2345');
      expect(parseFriendCode('https://example.com/friend?code=ABCD2345'),
          'ABCD2345');
      expect(parseFriendCode('ABCD 2345'), 'ABCD2345');
      expect(parseFriendCode('https://example.com/other'), isNull);
      expect(parseFriendCode('nonsense'), isNull);
    });
  });

  group('rankBy', () {
    test('stejné hodnoty mají stejné pořadí, null se vynechá', () {
      final r = rankBy<String>(
        ['a', 'b', 'c', 'd', 'e'],
        (s) => {'a': 5.0, 'b': 8.0, 'c': 5.0, 'd': null, 'e': 1.0}[s],
      );
      expect([for (final x in r) x.item], ['b', 'a', 'c', 'e']);
      expect([for (final x in r) x.rank], [1, 2, 2, 4]);
    });
  });

  test('completionPercent je 0–100', () {
    expect(completionPercent(500, 1000), 50);
    expect(completionPercent(5000, 1000), 100);
    expect(completionPercent(10, 0), 0);
  });

  test('endOfMonth', () {
    expect(endOfMonth(DateTime(2026, 2, 10)), DateTime(2026, 2, 28, 23, 59, 59));
    expect(endOfMonth(DateTime(2026, 12, 1)), DateTime(2026, 12, 31, 23, 59, 59));
  });

  test('roundRecord na 0,5 kg', () {
    expect(roundRecord(101.33), 101.5);
    expect(roundRecord(99.7), 99.5);
  });
}
