// Katalog vestavěných cviků pro web trenérů (trainer_web/assets/
// exercises.json) z lib/data/seed/seed_data.dart.
//
// Spusť z kořene projektu po změně vestavěných cviků:
//   dart run tool/trainer_catalog.dart
import 'dart:convert';
import 'dart:io';

import 'package:fitness_app/data/seed/seed_data.dart';

void main() {
  final lines = [
    for (final e in seedExercises)
      jsonEncode({
        'slug': e.slug,
        'en': e.nameEn,
        'cs': e.nameCs,
        'muscle': e.muscleGroup.name,
        'equipment': e.equipment.name,
        'type': e.type.name,
      }),
  ];
  final file = File('trainer_web/assets/exercises.json');
  file.writeAsStringSync('[\n${lines.join(',\n')}\n]\n');
  stdout.writeln('${lines.length} cviků → ${file.path}');
}
