// Srovnání „Jak si vedu“ (lib/modules/social/gym/strength_rank.dart).
import 'package:fitness_app/modules/social/gym/gym_logic.dart';
import 'package:fitness_app/modules/social/gym/strength_rank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ID dokumentu a klíč skupiny jako na serveru', () {
    expect(liftStatsDocId('CZ', GymCategory.benchPress), 'CZ_bench_press');
    expect(liftStatsDocId(kLiftStatsWorld, GymCategory.deadlift), 'world_deadlift');
    expect(liftStatsGroupKey(), 'all_all');
    expect(liftStatsGroupKey(gender: GymGender.male, age: GymAgeGroup.under40), 'male_u40');
    expect(liftStatsGroupKey(gender: GymGender.unspecified, age: GymAgeGroup.from50), 'all_50');
  });

  group('percentil z kvantilů', () {
    // q = 5., 10., … 95. percentil: 60, 62,5, … 105 kg (po 2,5 kg).
    final q = [for (var i = 0; i < 19; i++) 60 + 2.5 * i];
    final d = LiftDistribution.fromMap({'n': 40, 'q': q})!;

    test('mezi kvantily lineárně, na kvantilu jeho percentil', () {
      expect(d.hasData, isTrue);
      expect(d.percentBelow(60), 5);
      expect(d.percentBelow(61.25), 7.5);
      expect(d.percentBelow(105), 95);
      expect(d.percentBelow(40), 2.5);
      expect(d.percentBelow(200), 97.5);
    });

    test('stejné kvantily = jejich střed', () {
      final flat = LiftDistribution.fromMap({'n': 25, 'q': List.filled(19, 100)})!;
      expect(flat.percentBelow(100), 50);
      expect(flat.percentBelow(90), 2.5);
    });

    test('popisek: dolů na celé, nejvýš 99', () {
      expect(liftPercentLabel(62.5), 62);
      expect(liftPercentLabel(100), 99);
      expect(liftPercentLabel(0), 0);
    });

    test('malá skupina, chybné nebo neúplné kvantily = bez percentilu', () {
      final small = LiftDistribution.fromMap({'n': 7})!;
      expect(small.hasData, isFalse);
      expect(small.percentBelow(100), isNull);
      expect(LiftDistribution.fromMap({'n': 25, 'q': [1, 2]})!.hasData, isFalse);
      expect(LiftDistribution.fromMap({'n': 25, 'q': [...List.filled(18, 1), double.nan]})!.hasData, isFalse);
      expect(LiftDistribution.fromMap('x'), isNull);
    });
  });

  test('skupiny z dokumentu', () {
    final g = parseLiftStatsGroups({
      'groups': {
        'all_all': {'n': 30, 'q': List.filled(19, 100)},
        'male_40': {'n': 3},
        'bad': 'x',
      },
    });
    expect(g.keys, unorderedEquals(['all_all', 'male_40']));
    expect(parseLiftStatsGroups(null), isEmpty);
  });

  test('země: posilovna, pak jazyk telefonu', () {
    expect(liftStatsCountry(gymCountry: 'cz', localeCountry: 'SK'), 'CZ');
    expect(liftStatsCountry(gymCountry: null, localeCountry: 'SK'), 'SK');
    expect(liftStatsCountry(gymCountry: 'CZE', localeCountry: null), isNull);
    expect(countryFlag('CZ'), '🇨🇿');
  });
}
