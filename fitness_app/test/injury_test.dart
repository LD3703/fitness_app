import 'package:fitness_app/core/injury.dart';
import 'package:fitness_app/data/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('uložení partií', () {
    test('tam a zpět', () {
      final text =
          encodeMuscleGroups({MuscleGroup.back, MuscleGroup.shoulders});
      expect(text, 'back,shoulders');
      expect(decodeMuscleGroups(text),
          {MuscleGroup.back, MuscleGroup.shoulders});
    });

    test('prázdné a neznámé hodnoty', () {
      expect(encodeMuscleGroups(const []), isNull);
      expect(decodeMuscleGroups(null), isEmpty);
      expect(decodeMuscleGroups(''), isEmpty);
      expect(decodeMuscleGroups('chest,xyz'), {MuscleGroup.chest});
    });
  });

  group('periodAppliesTo', () {
    const shoulder = {MuscleGroup.shoulders};

    test('zranění ramene jen u cviků na ramena a celé tělo', () {
      expect(periodAppliesTo(PeriodType.injury, shoulder, MuscleGroup.shoulders),
          isTrue);
      expect(periodAppliesTo(PeriodType.injury, shoulder, MuscleGroup.fullBody),
          isTrue);
      expect(periodAppliesTo(PeriodType.injury, shoulder, MuscleGroup.legs),
          isFalse);
    });

    test('zranění s partií se v grafu váhy neukáže', () {
      expect(periodAppliesTo(PeriodType.injury, shoulder, null), isFalse);
    });

    test('zranění bez partie a jiná období platí všude', () {
      expect(periodAppliesTo(PeriodType.injury, const {}, MuscleGroup.legs),
          isTrue);
      expect(periodAppliesTo(PeriodType.injury, const {}, null), isTrue);
      expect(periodAppliesTo(PeriodType.illness, shoulder, MuscleGroup.legs),
          isTrue);
      expect(periodAppliesTo(PeriodType.cut, const {}, null), isTrue);
    });
  });

  test('activeInjuredGroups bere jen probíhající zranění', () {
    final now = DateTime(2026, 9, 30, 12);
    final groups = activeInjuredGroups([
      (
        type: PeriodType.injury,
        start: DateTime(2026, 9, 20),
        end: null,
        groups: {MuscleGroup.shoulders},
      ),
      (
        type: PeriodType.injury,
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 20),
        groups: {MuscleGroup.legs},
      ),
      (
        type: PeriodType.illness,
        start: DateTime(2026, 9, 25),
        end: null,
        groups: const <MuscleGroup>{},
      ),
    ], now);
    expect(groups, {MuscleGroup.shoulders});
  });
}
