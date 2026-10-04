import 'package:fitness_app/modules/social/gym/gym_logic.dart';
import 'package:fitness_app/modules/social/gym/plausibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 2, 18);

  group('checkGymValue – absolutní hranice', () {
    test('běžné hodnoty projdou', () {
      expect(checkGymValue(category: GymCategory.benchPress, value: 120), isNull);
      expect(checkGymValue(category: GymCategory.backSquat, value: 180), isNull);
      expect(checkGymValue(category: GymCategory.deadlift, value: 220), isNull);
      expect(checkGymValue(category: GymCategory.workouts, value: 20), isNull);
    });

    test('přesně na hranici ještě projde', () {
      expect(checkGymValue(category: GymCategory.benchPress, value: 350), isNull);
      expect(checkGymValue(category: GymCategory.backSquat, value: 500), isNull);
      expect(checkGymValue(category: GymCategory.deadlift, value: 500), isNull);
      expect(checkGymValue(category: GymCategory.workouts, value: 62), isNull);
    });

    test('hranice všech cviků (kg odhadu 1RM)', () {
      const limits = {
        'bench_press': 350.0,
        'back_squat': 500.0,
        'deadlift': 500.0,
        'overhead_press': 250.0,
        'incline_bench_press': 300.0,
        'dumbbell_bench_press': 120.0,
        'dumbbell_shoulder_press': 100.0,
        'barbell_curl': 150.0,
        'dumbbell_curl': 80.0,
        'weighted_pull_up': 150.0,
        'weighted_dips': 200.0,
        'barbell_row': 300.0,
        'leg_press': 1000.0,
        'hip_thrust': 500.0,
        'front_squat': 400.0,
        'romanian_deadlift': 400.0,
      };
      expect(GymCategory.lifts.map((c) => c.key).toList(), limits.keys.toList());
      for (final c in GymCategory.lifts) {
        final limit = limits[c.key]!;
        expect(gymAbsoluteLimit(c), limit, reason: c.key);
        expect(checkGymValue(category: c, value: limit), isNull, reason: c.key);
        expect(checkGymValue(category: c, value: limit + 0.5),
            ImplausibleReason.absolute,
            reason: c.key);
      }
      expect(gymAbsoluteLimit(GymCategory.workouts), 62);
    });

    test('skok 15 % platí pro všechny cviky', () {
      for (final c in GymCategory.lifts) {
        expect(
          checkGymValue(
            category: c,
            value: 58,
            previousValue: 50,
            previousAt: now.subtract(const Duration(days: 1)),
            now: now,
          ),
          ImplausibleReason.jump,
          reason: c.key,
        );
      }
    });

    test('nad hranicí neprojde', () {
      expect(checkGymValue(category: GymCategory.benchPress, value: 350.5),
          ImplausibleReason.absolute);
      expect(checkGymValue(category: GymCategory.backSquat, value: 501),
          ImplausibleReason.absolute);
      expect(checkGymValue(category: GymCategory.deadlift, value: 600),
          ImplausibleReason.absolute);
      expect(checkGymValue(category: GymCategory.workouts, value: 63),
          ImplausibleReason.absolute);
    });

    test('záporné a neplatné hodnoty neprojdou', () {
      expect(checkGymValue(category: GymCategory.benchPress, value: -1),
          ImplausibleReason.absolute);
      expect(checkGymValue(category: GymCategory.benchPress, value: double.nan),
          ImplausibleReason.absolute);
      expect(
          checkGymValue(category: GymCategory.benchPress, value: double.infinity),
          ImplausibleReason.absolute);
    });
  });

  group('checkGymValue – skok', () {
    final recent = now.subtract(const Duration(days: 3));
    final old = now.subtract(const Duration(days: 15));

    test('skok přes 15 % proti nedávnému maximu neprojde', () {
      expect(
        checkGymValue(
          category: GymCategory.benchPress,
          value: 116,
          previousValue: 100,
          previousAt: recent,
          now: now,
        ),
        ImplausibleReason.jump,
      );
    });

    test('přesně 15 % projde', () {
      expect(
        checkGymValue(
          category: GymCategory.benchPress,
          value: 115,
          previousValue: 100,
          previousAt: recent,
          now: now,
        ),
        isNull,
      );
    });

    test('po 14 dnech se skok nehlídá', () {
      expect(
        checkGymValue(
          category: GymCategory.deadlift,
          value: 200,
          previousValue: 100,
          previousAt: old,
          now: now,
        ),
        isNull,
      );
      expect(
        checkGymValue(
          category: GymCategory.deadlift,
          value: 200,
          previousValue: 100,
          previousAt: now.subtract(gymJumpWindow),
          now: now,
        ),
        isNull,
      );
    });

    test('předchozí maximum s časem v budoucnosti se bere jako nedávné', () {
      expect(
        checkGymValue(
          category: GymCategory.backSquat,
          value: 150,
          previousValue: 100,
          previousAt: now.add(const Duration(hours: 2)),
          now: now,
        ),
        ImplausibleReason.jump,
      );
    });

    test('bez předchozí hodnoty nebo času se skok nehlídá', () {
      expect(
        checkGymValue(category: GymCategory.benchPress, value: 200, now: now),
        isNull,
      );
      expect(
        checkGymValue(
          category: GymCategory.benchPress,
          value: 200,
          previousValue: 100,
          now: now,
        ),
        isNull,
      );
    });

    test('pokles nebo stejná hodnota projde', () {
      expect(
        checkGymValue(
          category: GymCategory.benchPress,
          value: 90,
          previousValue: 100,
          previousAt: recent,
          now: now,
        ),
        isNull,
      );
    });

    test('u počtu tréninků se skok nehlídá', () {
      expect(
        checkGymValue(
          category: GymCategory.workouts,
          value: 20,
          previousValue: 2,
          previousAt: recent,
          now: now,
        ),
        isNull,
      );
    });

    test('absolutní hranice má přednost', () {
      expect(
        checkGymValue(
          category: GymCategory.benchPress,
          value: 400,
          previousValue: 100,
          previousAt: recent,
          now: now,
        ),
        ImplausibleReason.absolute,
      );
    });
  });

  group('gym_logic', () {
    test('1RM se zaokrouhlí na 0,5 kg', () {
      expect(roundGymLift(102.3), 102.5);
    });

    test('kategorie: cviky podle slugu a tréninky', () {
      expect(GymCategory.values.length, 17);
      expect(GymCategory.values.last, GymCategory.workouts);
      expect(GymCategory.workouts.isLift, isFalse);
      expect(GymCategory.workouts.exerciseSlug, isNull);
      for (final c in GymCategory.lifts) {
        expect(c.isLift, isTrue);
        expect(c.exerciseSlug, c.key);
        expect(gymCategoryFromKey(c.key), same(c));
      }
      expect(GymCategory.values.map((c) => c.key).toSet().length, 17);
      expect(gymCategoryFromKey('bench_press'), GymCategory.benchPress);
      expect(gymCategoryFromKey('workouts'), GymCategory.workouts);
      // Zrušené kategorie z dřívějších verzí se nenačtou (záznamy se smažou).
      expect(gymCategoryFromKey('relStrength'), isNull);
      expect(gymCategoryFromKey('bench'), isNull);
      expect(gymCategoryFromKey('squat'), isNull);
      expect(gymCategoryFromKey(null), isNull);
      // Staré novinky ale ano.
      expect(gymCategoryFromAnyKey('bench'), GymCategory.benchPress);
      expect(gymCategoryFromAnyKey('squat'), GymCategory.backSquat);
      expect(gymCategoryFromAnyKey('deadlift'), GymCategory.deadlift);
      expect(gymCategoryFromAnyKey('relStrength'), isNull);
    });

    test('poznámky: jednoručky a přidaná zátěž', () {
      expect(
        [for (final c in GymCategory.values) if (c.perDumbbell) c.key],
        ['dumbbell_bench_press', 'dumbbell_shoulder_press', 'dumbbell_curl'],
      );
      expect(
        [for (final c in GymCategory.values) if (c.addedWeight) c.key],
        ['weighted_pull_up', 'weighted_dips'],
      );
    });

    test('ID záznamu', () {
      expect(gymEntryId('u1', GymCategory.benchPress), 'u1_bench_press');
      expect(gymEntryId('u1', GymCategory.workouts), 'u1_workouts');
    });

    test('parseGymCode', () {
      expect(parseGymCode('fitnessapp://gym?code=abc234'), 'ABC234');
      expect(parseGymCode('https://example.com/gym?code=ABC234'), 'ABC234');
      expect(parseGymCode(' abc-234 '), 'ABC234');
      // Kód přítele (8 znaků) ani odkaz na přítele nejsou kód posilovny.
      expect(parseGymCode('fitnessapp://friend?code=ABC234'), isNull);
      expect(parseGymCode('ABCD2345'), isNull);
      expect(parseGymCode('ABC10O'), isNull);
    });

    test('generateGymCode vytváří platné kódy', () {
      for (var i = 0; i < 50; i++) {
        expect(isValidGymCode(generateGymCode()), isTrue);
      }
    });

    test('normalizeGymSearch odstraní diakritiku a mezery', () {
      expect(normalizeGymSearch('  Fitness  Jičín '), 'fitness jicin');
      expect(normalizeGymSearch('Łódź Siłownia'), 'lodz silownia');
      expect(normalizeGymSearch('Straße'), 'strasse');
    });

    test('nejlepší měsíc podle počtu tréninků', () {
      expect(bestMonthCount([]), 0);
      expect(
        bestMonthCount([
          DateTime(2026, 9, 1),
          DateTime(2026, 9, 3),
          DateTime(2026, 10, 1),
        ]),
        2,
      );
    });

    test('remoteId výzvy', () {
      expect(
        gymChallengeRemoteId(
          gymId: 'g1',
          uid: 'u1',
          category: GymCategory.benchPress,
          value: 120,
        ),
        'gym:g1:u1:bench_press:120.00',
      );
      expect(
        gymChallengeRemoteId(
          gymId: 'g1',
          uid: 'u1',
          category: GymCategory.workouts,
          value: 14,
        ),
        'gym:g1:u1:workouts:14',
      );
      expect(isGymChallengeRemoteId('gym:g1:u1:bench_press:120.00'), isTrue);
      expect(isGymChallengeRemoteId('abc'), isFalse);
    });

    test('přezdívka se ořízne', () {
      expect(sanitizeGymNickname('  '), '?');
      expect(sanitizeGymNickname('a' * 30).length, gymNicknameMaxLength);
    });
  });
}
