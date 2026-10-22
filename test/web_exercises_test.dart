// docs/web/fitka/exercises.js musí odpovídat vestavěným cvikům
// (tool/web_exercises.dart, docs/fitka.md).
import 'dart:io';

import 'package:fitness_app/data/seed/seed_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/web_exercises.dart';

void main() {
  test('exercises.js je aktuální (jinak: dart run tool/web_exercises.dart)', () {
    expect(File(webExercisesPath).readAsStringSync(), webExercisesJs());
  });

  test('výchozí samolepky jsou existující cviky se samolepkou', () {
    final bySlug = {for (final e in seedExercises) e.slug: e};
    expect(stickerDefaults, hasLength(12));
    for (final s in stickerDefaults) {
      expect(bySlug[s], isNotNull, reason: s);
      expect(stickerEquipment, contains(bySlug[s]!.equipment), reason: s);
    }
  });
}
