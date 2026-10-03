import 'package:fitness_app/core/formulas.dart';
import 'package:fitness_app/data/enums.dart';
import 'package:fitness_app/ui/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => unitSystemNotifier.value = UnitSystem.metric);

  test('kg ↔ lb', () {
    expect(kgToUnit(100, UnitSystem.metric), 100);
    expect(kgToUnit(100, UnitSystem.imperial), closeTo(220.462, 0.001));
    expect(unitToKg(1, UnitSystem.imperial), 0.45359237);
    expect(unitToKg(135, UnitSystem.imperial), closeTo(61.235, 0.001));
  });

  test('ml ↔ oz', () {
    expect(mlToUnit(250, UnitSystem.metric), 250);
    expect(mlToUnit(29.5735, UnitSystem.imperial), closeTo(1, 1e-9));
    expect(unitToMl(8, UnitSystem.imperial), 237);
    expect(unitToMl(250, UnitSystem.metric), 250);
  });

  test('input text round-trips in pounds', () {
    unitSystemNotifier.value = UnitSystem.imperial;
    expect(weightUnit, 'lb');
    expect(volumeUnit, 'oz');
    final kg = parseWeightInput('135')!;
    expect(weightInputText(kg), '135');
    expect(weightInputText(60), '132.28');
    expect(weightInputText(null), '');
  });

  test('metric input is unchanged', () {
    expect(weightUnit, 'kg');
    expect(weightInputText(82.5), '82.5');
    expect(weightInputText(80), '80');
    expect(parseWeightInput('82,5'), 82.5);
  });

  test('suggestion step is 5 lb in imperial', () {
    unitSystemNotifier.value = UnitSystem.imperial;
    final kg = roundToStep(61, step: weightStepKg); // 134.5 lb → 135 lb
    expect(kgToDisplay(kg), closeTo(135, 1e-9));
    expect(roundToStep(67, step: weightDisplayStep), 65);
  });

  test('roundDecimals', () {
    expect(roundDecimals(132.2773, 2), 132.28);
    expect(roundDecimals(1.25, 0), 1);
  });
}
