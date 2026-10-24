// functions/src/exerciseNames.ts musí odpovídat vestavěným cvikům
// a jejich překladům (tool/push_exercises.dart).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/push_exercises.dart';

void main() {
  test('exerciseNames.ts je aktuální (jinak: dart run tool/push_exercises.dart)',
      () {
    expect(File(pushExercisesPath).readAsStringSync(), pushExercisesTs());
  });
}
