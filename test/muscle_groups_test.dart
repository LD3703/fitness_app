import 'package:fitness_app/core/injury.dart';
import 'package:fitness_app/data/enums.dart';
import 'package:fitness_app/data/seed/seed_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pořadí pro výběr obsahuje každou partii právě jednou', () {
    expect(muscleGroupsUiOrder.toSet(), MuscleGroup.values.toSet());
    expect(muscleGroupsUiOrder.length, MuscleGroup.values.length);
  });

  test('indexy starých partií se nezměnily (databáze)', () {
    expect(MuscleGroup.legs.index, 5);
    expect(MuscleGroup.fullBody.index, 8);
    expect(MuscleGroup.quads.index, 9);
    expect(MuscleGroup.lowerBack.index, 14);
  });

  test('nohy jsou souhrnem stehen, hamstringů a lýtek', () {
    expect(MuscleGroup.quads.parent, MuscleGroup.legs);
    expect(MuscleGroup.chest.parent, isNull);
    expect(MuscleGroup.legs.specific, legMuscleGroups);
    expect(MuscleGroup.chest.specific, {MuscleGroup.chest});
    expect(MuscleGroup.legs.overlaps(MuscleGroup.calves), isTrue);
    expect(MuscleGroup.calves.overlaps(MuscleGroup.legs), isTrue);
    expect(MuscleGroup.quads.overlaps(MuscleGroup.hamstrings), isFalse);
    expect(MuscleGroup.hamstrings.isLowerBody, isTrue);
    expect(MuscleGroup.forearms.isLowerBody, isFalse);
  });

  test('zranění nohou platí i pro stehna a naopak', () {
    expect(
      periodAppliesTo(
          PeriodType.injury, {MuscleGroup.legs}, MuscleGroup.quads),
      isTrue,
    );
    expect(
      periodAppliesTo(
          PeriodType.injury, {MuscleGroup.calves}, MuscleGroup.legs),
      isTrue,
    );
    expect(
      periodAppliesTo(
          PeriodType.injury, {MuscleGroup.calves}, MuscleGroup.quads),
      isFalse,
    );
  });

  test('nové partie se ukládají jménem', () {
    final text = encodeMuscleGroups({MuscleGroup.lowerBack, MuscleGroup.chest});
    expect(text, 'chest,lowerBack');
    expect(decodeMuscleGroups(text), {MuscleGroup.chest, MuscleGroup.lowerBack});
  });

  test('každá přesná partie má aspoň jeden vestavěný cvik', () {
    final primary = {for (final e in seedExercises) e.muscleGroup};
    for (final g in MuscleGroup.values) {
      if (g == MuscleGroup.legs) continue; // souhrn – cviky má v podpartiích
      expect(primary, contains(g), reason: g.name);
    }
  });

  test('slugy vestavěných cviků jsou jedinečné', () {
    final slugs = [for (final e in seedExercises) e.slug];
    expect(slugs.toSet().length, slugs.length);
  });
}
