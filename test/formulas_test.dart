import 'package:fitness_app/core/date_utils.dart';
import 'package:fitness_app/core/formulas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('estimateOneRepMax', () {
    test('1 opakování vrací samotnou váhu', () {
      expect(estimateOneRepMax(100, 1), 100);
    });

    test('Epleyho vzorec: 100 kg × 10 ≈ 133,3 kg', () {
      expect(estimateOneRepMax(100, 10), closeTo(133.33, 0.01));
    });

    test('80 kg × 8 a 90 kg × 5 jdou porovnat', () {
      expect(estimateOneRepMax(80, 8), closeTo(101.33, 0.01));
      expect(estimateOneRepMax(90, 5), closeTo(105.0, 0.01));
    });

    test('neplatné vstupy vrací null', () {
      expect(estimateOneRepMax(0, 5), isNull);
      expect(estimateOneRepMax(100, 0), isNull);
      expect(estimateOneRepMax(-10, 5), isNull);
    });
  });

  group('estimateKcal', () {
    test('MET 6, 80 kg, 1 hodina = 480 kcal', () {
      expect(
        estimateKcal(met: 6, bodyWeightKg: 80, duration: const Duration(hours: 1)),
        closeTo(480, 0.001),
      );
    });

    test('nulová hmotnost vrací 0', () {
      expect(
        estimateKcal(met: 6, bodyWeightKg: 0, duration: const Duration(hours: 1)),
        0,
      );
    });
  });

  group('date utils', () {
    test('konec dne je půlnoc následujícího dne', () {
      final d = DateTime(2026, 10, 25, 15, 30);
      expect(startOfDay(d), DateTime(2026, 10, 25));
      expect(endOfDayExclusive(d), DateTime(2026, 10, 26));
    });

    test('přechod přes konec měsíce', () {
      expect(endOfDayExclusive(DateTime(2026, 1, 31)), DateTime(2026, 2, 1));
    });
  });

  group('návrh váhy', () {
    test('weightForReps je inverze estimateOneRepMax', () {
      final orm = estimateOneRepMax(80, 8)!;
      expect(weightForReps(orm, 8), closeTo(80, 0.001));
    });

    test('roundToStep zaokrouhlí na 2,5 kg', () {
      expect(roundToStep(61.2), 60);
      expect(roundToStep(61.3), 62.5);
    });

    test('suggestWorkingWeight: 1RM 100 kg, 10 opakování', () {
      // max pro 10 opak. = 75 kg, 90 % = 67,5 kg
      expect(suggestWorkingWeight(100, 10), 67.5);
    });
  });

  group('groupSets', () {
    test('sloučí stejné série, rozcvičku drží zvlášť', () {
      final groups = groupSets([
        (reps: 15, weightKg: 40, isWarmup: true),
        (reps: 10, weightKg: 60, isWarmup: false),
        (reps: 10, weightKg: 60, isWarmup: false),
        (reps: 8, weightKg: 65, isWarmup: false),
      ]);
      expect(groups.length, 3);
      expect(groups[0].isWarmup, isTrue);
      expect(groups[1].count, 2);
      expect(groups[2].reps, 8);
    });

    test('prázdný vstup', () {
      expect(groupSets(const []), isEmpty);
    });
  });
}
