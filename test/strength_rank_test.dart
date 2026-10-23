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

  group('percentil', () {
    // 20 lidí: 10× 80 kg, 5× 100 kg, 5× 120 kg.
    final d = LiftDistribution.fromMap({
      'n': 20,
      'h': [80, 10, 100, 5, 120, 5],
    })!;

    test('slabší + polovina stejných', () {
      expect(d.hasData, isTrue);
      expect(d.percentBelow(100), 62.5); // (10 + 2,5) / 20
      expect(d.percentBelow(110), 75);
      expect(d.percentBelow(60), 0);
      expect(d.percentBelow(200), 100);
      expect(d.percentBelow(99.8), 62.5); // zaokrouhlení na 0,5 kg
    });

    test('popisek: dolů na celé, nejvýš 99', () {
      expect(liftPercentLabel(62.5), 62);
      expect(liftPercentLabel(100), 99);
      expect(liftPercentLabel(0), 0);
    });

    test('malá skupina nebo bez rozložení = bez percentilu', () {
      final small = LiftDistribution.fromMap({'n': 7})!;
      expect(small.hasData, isFalse);
      expect(small.percentBelow(100), isNull);
      expect(LiftDistribution.fromMap({'n': 25, 'h': []})!.hasData, isFalse);
      expect(LiftDistribution.fromMap('x'), isNull);
    });
  });

  test('skupiny z dokumentu', () {
    final g = parseLiftStatsGroups({
      'groups': {
        'all_all': {'n': 30, 'h': [100, 30]},
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
