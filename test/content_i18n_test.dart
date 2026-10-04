import 'package:fitness_app/data/seed/content_i18n.dart';
import 'package:fitness_app/data/seed/plan_templates.dart';
import 'package:fitness_app/data/seed/seed_data.dart';
import 'package:fitness_app/data/seed/seed_translations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('každý vestavěný obsah má překlad ve všech jazycích', () {
    for (final entry in seedTranslations.entries) {
      final t = entry.value;
      for (final e in seedExercises) {
        expect(t.exerciseNames[e.slug], isNotNull,
            reason: '${entry.key}: název ${e.slug}');
        expect(t.exerciseInstructions[e.slug], isNotNull,
            reason: '${entry.key}: návod ${e.slug}');
      }
      for (final r in seedHomeRoutines) {
        expect(t.routineNames[r.slug], isNotNull,
            reason: '${entry.key}: rutina ${r.slug}');
      }
      for (final p in templatePrograms) {
        expect(t.programNames[p.slug], isNotNull);
        expect(t.programDescriptions[p.slug], isNotNull);
        for (final plan in p.plans) {
          expect(t.planNames[plan.nameEn], isNotNull,
              reason: '${entry.key}: plán ${plan.nameEn}');
        }
      }
    }
  });

  test('seedText vybere jazyk a jinak angličtinu', () {
    String pick(String lang) => seedText(lang,
        en: 'Bench Press',
        cs: 'Bench press',
        other: (t) => t.exerciseNames['bench_press']);
    expect(pick('cs'), 'Bench press');
    expect(pick('en'), 'Bench Press');
    expect(pick('de'), seedTranslations['de']!.exerciseNames['bench_press']);
    // Jazyk bez překladu obsahu → angličtina.
    expect(pick('ja'), 'Bench Press');
  });

  test('hledání cviku v kterémkoli jazyce a bez diakritiky', () {
    bool find(String q) => exerciseMatchesQuery(
          slug: 'bench_press',
          nameEn: 'Bench Press',
          nameCs: 'Bench press',
          query: q,
        );
    expect(find('bench'), isTrue);
    expect(find('bankdrucken'), isTrue);
    expect(find('BANKDRÜCKEN'), isTrue);
    expect(find('developpe'), isTrue);
    expect(find('press de banca'), isTrue);
    expect(find('kreuzheben'), isFalse);
    expect(find('   '), isTrue);
  });

  test('foldForSearch odstraní diakritiku', () {
    expect(foldForSearch('Dřep s činkou'), 'drep s cinkou');
    expect(foldForSearch('Größe'), 'grosse');
  });
}
