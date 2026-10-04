import 'package:fitness_app/modules/social/gym/gym_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('gymAgeGroupFor – věková skupina z roku narození', () {
    const year = 2026;

    test('hranice skupin (věk = rozdíl let)', () {
      expect(gymAgeGroupFor(1987, year), GymAgeGroup.under40); // 39
      expect(gymAgeGroupFor(1986, year), GymAgeGroup.from40); // 40
      expect(gymAgeGroupFor(1977, year), GymAgeGroup.from40); // 49
      expect(gymAgeGroupFor(1976, year), GymAgeGroup.from50); // 50
      expect(gymAgeGroupFor(1967, year), GymAgeGroup.from50); // 59
      expect(gymAgeGroupFor(1966, year), GymAgeGroup.from60); // 60
      expect(gymAgeGroupFor(1930, year), GymAgeGroup.from60); // 96
      expect(gymAgeGroupFor(2000, year), GymAgeGroup.under40);
    });

    test('skupina se mění s novým rokem', () {
      expect(gymAgeGroupFor(1986, 2025), GymAgeGroup.under40);
      expect(gymAgeGroupFor(1986, 2026), GymAgeGroup.from40);
    });

    test('bez roku nebo s nesmyslným rokem null', () {
      expect(gymAgeGroupFor(null, year), isNull);
      expect(gymAgeGroupFor(1919, year), isNull);
      expect(gymAgeGroupFor(2017, year), isNull); // mladší než 10 let
      expect(gymAgeGroupFor(2030, year), isNull); // v budoucnosti
    });

    test('rozsah roku narození 1920 … aktuální rok − 10', () {
      expect(gymBirthYearMax(year), 2016);
      expect(isValidBirthYear(1920, year), isTrue);
      expect(isValidBirthYear(2016, year), isTrue);
      expect(isValidBirthYear(1919, year), isFalse);
      expect(isValidBirthYear(2017, year), isFalse);
      expect(isValidBirthYear(null, year), isFalse);
    });

    test('klíče skupin pro Firestore', () {
      expect(GymAgeGroup.values.map((g) => g.key), ['u40', '40', '50', '60']);
      for (final g in GymAgeGroup.values) {
        expect(gymAgeGroupFromKey(g.key), g);
      }
      expect(gymAgeGroupFromKey(null), isNull);
      expect(gymAgeGroupFromKey('45'), isNull);
      expect(gymAgeGroupFromKey('from40'), isNull);
    });
  });

  group('gymAgeMatches – filtr 40+ / 50+ / 60+', () {
    Set<GymAgeGroup?> shown(GymAgeFilter f) => {
          for (final g in <GymAgeGroup?>[null, ...GymAgeGroup.values])
            if (gymAgeMatches(f, g)) g,
        };

    test('všichni = i bez věkové skupiny', () {
      expect(shown(GymAgeFilter.all),
          {null, ...GymAgeGroup.values});
    });

    test('40+ = 40, 50, 60', () {
      expect(shown(GymAgeFilter.from40),
          {GymAgeGroup.from40, GymAgeGroup.from50, GymAgeGroup.from60});
    });

    test('50+ = 50, 60', () {
      expect(shown(GymAgeFilter.from50),
          {GymAgeGroup.from50, GymAgeGroup.from60});
    });

    test('60+ = 60', () {
      expect(shown(GymAgeFilter.from60), {GymAgeGroup.from60});
    });

    test('spodní hranice filtrů', () {
      expect(GymAgeFilter.values.map((f) => f.minAge), [null, 40, 50, 60]);
    });

    test('kombinace s filtrem pohlaví', () {
      bool matches(
        GymGenderFilter gf,
        GymAgeFilter af,
        GymGender gender,
        GymAgeGroup? group,
      ) =>
          gymGenderMatches(gf, gender) && gymAgeMatches(af, group);

      expect(
        matches(GymGenderFilter.women, GymAgeFilter.from50, GymGender.female,
            GymAgeGroup.from60),
        isTrue,
      );
      expect(
        matches(GymGenderFilter.women, GymAgeFilter.from50, GymGender.male,
            GymAgeGroup.from60),
        isFalse,
      );
      expect(
        matches(GymGenderFilter.men, GymAgeFilter.from40, GymGender.male,
            GymAgeGroup.under40),
        isFalse,
      );
      expect(
        matches(GymGenderFilter.all, GymAgeFilter.from60, GymGender.unspecified,
            null),
        isFalse,
      );
      expect(
        matches(GymGenderFilter.all, GymAgeFilter.all, GymGender.unspecified,
            null),
        isTrue,
      );
    });
  });
}
