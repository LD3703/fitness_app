// Seznam vestavěných cviků pro web (docs/web/fitka/exercises.js):
// samolepky na stroje na gymbar.app/fitka a název cviku na stránce
// gymbar.app/ex?id=<slug> (docs/fitka.md).
//
//   dart run tool/web_exercises.dart
//
// Po změně cviků v lib/data/seed/seed_data.dart spusť znovu a commitni
// (test/web_exercises_test.dart hlídá, že soubor sedí).
import 'dart:convert';
import 'dart:io';

import 'package:fitness_app/data/enums.dart';
import 'package:fitness_app/data/seed/seed_data.dart';

const webExercisesPath = 'docs/web/fitka/exercises.js';

/// Vybavení, ke kterému dává smysl samolepka (stroj, kladka, stanoviště
/// s činkou). Cviky s vlastní vahou, jednoručkami a gumou se nenabízejí.
const stickerEquipment = {Equipment.machine, Equipment.cable, Equipment.barbell};

/// Výchozí výběr samolepek (12 nejběžnějších strojů a stanovišť).
const stickerDefaults = [
  'leg_press',
  'lat_pulldown',
  'seated_cable_row',
  'chest_press_machine',
  'pec_deck',
  'shoulder_press_machine',
  'leg_extension',
  'leg_curl',
  'triceps_pushdown',
  'hack_squat',
  'bench_press',
  'back_squat',
];

String webExercisesJs() {
  final list = [
    for (final e in seedExercises)
      {
        's': e.slug,
        'cs': e.nameCs,
        'en': e.nameEn,
        'm': e.muscleGroup.name,
        if (stickerEquipment.contains(e.equipment)) 'st': 1,
      },
  ];
  final rows = list.map((m) => '  ${jsonEncode(m)}').join(',\n');
  return '// Vygenerováno: dart run tool/web_exercises.dart '
      '(z lib/data/seed/seed_data.dart). Ručně neupravovat.\n'
      '// s = slug (stabilní ID v odkazu /ex?id=), m = svalová skupina,\n'
      '// st = nabízí se jako samolepka na stroj.\n'
      'window.GYMBAR_EXERCISES = [\n$rows\n];\n'
      'window.GYMBAR_STICKER_DEFAULTS = ${jsonEncode(stickerDefaults)};\n';
}

void main() {
  final file = File(webExercisesPath)..createSync(recursive: true);
  file.writeAsStringSync(webExercisesJs());
  stdout.writeln('✓ $webExercisesPath (${seedExercises.length} cviků)');
}
