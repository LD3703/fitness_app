// Názvy vestavěných cviků pro texty push notifikací v Cloud Functions
// (functions/src/exerciseNames.ts) ve všech 10 jazycích aplikace.
//
//   dart run tool/push_exercises.dart
//
// Po změně cviků nebo jejich překladů spusť znovu a commitni
// (test/push_exercises_test.dart hlídá, že soubor sedí).
import 'dart:convert';
import 'dart:io';

import 'package:fitness_app/data/seed/seed_data.dart';
import 'package:fitness_app/data/seed/seed_translations.dart';

const pushExercisesPath = 'functions/src/exerciseNames.ts';

/// Pořadí jazyků v řádku tabulky (stejné jako PUSH_LANGS ve functions).
const pushLangs = ['en', 'cs', 'de', 'es', 'fr', 'it', 'nl', 'pl', 'pt', 'sk'];

String pushExercisesTs() {
  final rows = [
    for (final e in seedExercises)
      '  ${jsonEncode(e.slug)}: ${jsonEncode([
            for (final l in pushLangs)
              switch (l) {
                'en' => e.nameEn,
                'cs' => e.nameCs,
                _ => seedTranslations[l]?.exerciseNames[e.slug] ?? e.nameEn,
              },
          ])},',
  ].join('\n');
  return '// Vygenerováno: dart run tool/push_exercises.dart '
      '(z lib/data/seed). Ručně neupravovat.\n'
      '// slug → název cviku v jazycích ${pushLangs.join(', ')}.\n'
      'export const EXERCISE_NAMES: Record<string, readonly string[]> = {\n'
      '$rows\n'
      '};\n';
}

void main() {
  File(pushExercisesPath).writeAsStringSync(pushExercisesTs());
  stdout.writeln('✓ $pushExercisesPath (${seedExercises.length} cviků)');
}
