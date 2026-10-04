import 'package:fitness_app/core/coach_tone.dart';
import 'package:fitness_app/core/wellbeing.dart';
import 'package:fitness_app/data/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hodnota z profilu', () {
    expect(coachToneOf(0), CoachTone.friendly);
    expect(coachToneOf(null), CoachTone.friendly);
    expect(coachToneOf(1), CoachTone.strict);
    expect(coachToneOf(7), CoachTone.friendly);
  });

  test('přísný tón jen ve zdravé situaci', () {
    for (final s in WellbeingSituation.values) {
      final allowed = s == WellbeingSituation.normal ||
          s == WellbeingSituation.cut;
      expect(strictToneAllowed(s), allowed, reason: s.name);
      expect(
        effectiveCoachTone(CoachTone.strict, s),
        allowed ? CoachTone.strict : CoachTone.friendly,
        reason: s.name,
      );
    }
  });

  test('únava ≥ 80 % vrací přátelský tón', () {
    const s = WellbeingSituation.normal;
    expect(effectiveCoachTone(CoachTone.strict, s, maxFatigue: 79.9),
        CoachTone.strict);
    expect(effectiveCoachTone(CoachTone.strict, s, maxFatigue: 80),
        CoachTone.friendly);
    expect(effectiveCoachTone(CoachTone.strict, s, maxFatigue: 95),
        CoachTone.friendly);
  });

  test('přátelský tón zůstává přátelský', () {
    expect(
      effectiveCoachTone(CoachTone.friendly, WellbeingSituation.normal,
          maxFatigue: 0),
      CoachTone.friendly,
    );
  });

  test('nejvyšší únava', () {
    expect(maxFatiguePercent((percent: const {}, sessions: 0)), 0);
    expect(
      maxFatiguePercent((
        percent: {MuscleGroup.chest: 40, MuscleGroup.legs: 85.5},
        sessions: 2,
      )),
      85.5,
    );
  });
}
