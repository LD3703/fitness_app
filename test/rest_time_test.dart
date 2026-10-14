import 'package:fitness_app/core/rest_time.dart';
import 'package:fitness_app/data/enums.dart';
import 'package:fitness_app/data/seed/seed_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('každý vestavěný cvik má náročnost pro pauzu', () {
    for (final e in seedExercises) {
      expect(exerciseRestTiers.containsKey(e.slug), isTrue, reason: e.slug);
    }
  });

  test('po dřepu je delší pauza než po sklapovačkách', () {
    for (final focus in TrainingFocus.values) {
      final squat = recommendedRestSeconds(
          exerciseRestTiers['back_squat']!, focus);
      final crunch =
          recommendedRestSeconds(exerciseRestTiers['crunch']!, focus);
      expect(squat, greaterThan(crunch), reason: focus.name);
    }
  });

  test('síla > svaly > kondice u každé náročnosti', () {
    for (final tier in RestTier.values) {
      final s = recommendedRestSeconds(tier, TrainingFocus.strength);
      final m = recommendedRestSeconds(tier, TrainingFocus.muscle);
      final c = recommendedRestSeconds(tier, TrainingFocus.conditioning);
      expect(s, greaterThan(m), reason: tier.name);
      expect(m, greaterThan(c), reason: tier.name);
    }
  });

  test('ženy mají kratší pauzu, zaokrouhlenou na 5 s', () {
    expect(recommendedRestSeconds(RestTier.heavy, TrainingFocus.strength), 180);
    expect(
        recommendedRestSeconds(RestTier.heavy, TrainingFocus.strength,
            sex: Sex.female),
        155);
    expect(
        recommendedRestSeconds(RestTier.heavy, TrainingFocus.strength,
            sex: Sex.male),
        180);
    for (final tier in RestTier.values) {
      for (final focus in TrainingFocus.values) {
        final f = recommendedRestSeconds(tier, focus, sex: Sex.female);
        expect(f % 5, 0);
        expect(f, greaterThanOrEqualTo(10));
        expect(f, lessThanOrEqualTo(recommendedRestSeconds(tier, focus)));
      }
    }
  });

  test('odhad náročnosti vlastního cviku', () {
    RestTier tier(MuscleGroup g, Equipment e,
            [ExerciseType t = ExerciseType.weightReps]) =>
        restTierOf(group: g, equipment: e, type: t);
    expect(tier(MuscleGroup.quads, Equipment.barbell), RestTier.heavy);
    expect(tier(MuscleGroup.back, Equipment.cable), RestTier.compound);
    expect(tier(MuscleGroup.biceps, Equipment.barbell), RestTier.isolation);
    expect(tier(MuscleGroup.shoulders, Equipment.cable), RestTier.isolation);
    expect(tier(MuscleGroup.core, Equipment.bodyweight), RestTier.core);
    expect(
        tier(MuscleGroup.fullBody, Equipment.bodyweight, ExerciseType.duration),
        RestTier.conditioning);
    // Vestavěný cvik podle slugu, i když by odhad vyšel jinak.
    expect(
        restTierOf(
            slug: 'barbell_curl',
            group: MuscleGroup.biceps,
            equipment: Equipment.barbell,
            type: ExerciseType.weightReps),
        RestTier.isolation);
  });

  test('hodnoty z databáze', () {
    expect(trainingFocusOf(null), TrainingFocus.muscle);
    expect(trainingFocusOf(0), TrainingFocus.strength);
    expect(trainingFocusOf(2), TrainingFocus.conditioning);
    expect(trainingFocusOf(9), TrainingFocus.muscle);
    expect(sexOf(null), isNull);
    expect(sexOf(1), Sex.female);
    expect(sexOf(5), isNull);
  });
}
