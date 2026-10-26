// Doporučení hotových programů podle počtu tréninků týdně a délky
// (lib/data/seed/program_fit.dart).
import 'package:drift/native.dart';
import 'package:fitness_app/data/database.dart';
import 'package:fitness_app/data/seed/plan_templates.dart';
import 'package:fitness_app/data/seed/program_fit.dart';
import 'package:flutter_test/flutter_test.dart';

TemplateProgram _program(String slug) =>
    templatePrograms.firstWhere((p) => p.slug == slug);

int _working(PlannedItem p) => p.sets.where((s) => !s.isWarmup).length;

void main() {
  test('počet tréninků týdně z dnů plánů', () {
    expect(programDaysPerWeek(_program('full_body')), 3);
    expect(programDaysPerWeek(_program('full_body_2x')), 2);
    expect(programDaysPerWeek(_program('upper_lower')), 4);
    expect(programDaysPerWeek(_program('ppl_6x')), 6);
  });

  test('odhad délky je u všech programů realistický (25–75 min)', () {
    for (final p in templatePrograms) {
      for (final goal in TrainingFocus.values) {
        expect(programMinutes(p, goal, level: p.level), inInclusiveRange(25, 75),
            reason: '${p.slug} ${goal.name}');
      }
    }
    // Síla má delší pauzy než výdrž.
    final fb = _program('full_body');
    expect(programMinutes(fb, TrainingFocus.strength),
        greaterThan(programMinutes(fb, TrainingFocus.conditioning)));
  });

  test('zkrácení: nejdřív doplňky, hlavní cviky zůstanou', () {
    final fb = _program('full_body');
    const focus = TrainingFocus.strength;
    final items = plannedItems(fb.plans.first, focus,
        program: fb, level: ExperienceLevel.advanced);
    expect(estimateSeconds(items, focus), greaterThan(60 * 60));

    final cut45 = fitToMinutes(items, focus, 45);
    expect(estimateSeconds(cut45, focus), lessThanOrEqualTo(45 * 60));
    expect(cut45.first.item.slug, 'back_squat');
    expect(cut45.every((p) => _working(p) >= 2), isTrue);

    final cut30 = fitToMinutes(items, focus, 30);
    expect(cut30.length, greaterThanOrEqualTo(3));
    expect(cut30.map((p) => p.item.slug),
        containsAll(['back_squat', 'bench_press', 'barbell_row']));

    // Krátký trénink se nemění.
    expect(fitToMinutes(items, focus, 120), items);
  });

  test('doporučení podle úrovně, dnů a cíle', () {
    List<String> rec(ExperienceLevel level, int days,
            {TrainingFocus goal = TrainingFocus.muscle, int minutes = 60}) =>
        [
          for (final f in recommendPrograms(
              level: level,
              goal: goal,
              daysPerWeek: days,
              sessionMinutes: minutes))
            f.program.slug,
        ];
    expect(rec(ExperienceLevel.beginner, 3).first, 'full_body');
    expect(rec(ExperienceLevel.beginner, 2).first, 'full_body_2x');
    // Začátečník na 4 dny dostane Horní / dolní z vyšší úrovně.
    expect(rec(ExperienceLevel.beginner, 4).first, 'upper_lower');
    expect(rec(ExperienceLevel.intermediate, 3).first, 'ppl');
    expect(rec(ExperienceLevel.intermediate, 3, goal: TrainingFocus.strength)
        .first, 'strength_dup');
    expect(rec(ExperienceLevel.advanced, 6).first, 'ppl_6x');
    expect(rec(ExperienceLevel.advanced, 4, goal: TrainingFocus.strength).first,
        'strength_advanced');
    // Programy vlastní úrovně jsou vždy v nabídce.
    expect(rec(ExperienceLevel.advanced, 2),
        containsAll(['phul', 'strength_advanced', 'ppl_6x']));
  });

  test('přidání programu zkrátí tréninky na délku z profilu', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.addProgram(_program('upper_lower'),
        languageCode: 'cs',
        goal: TrainingFocus.strength,
        level: ExperienceLevel.advanced,
        maxMinutes: 45);
    final plans = await db.select(db.workoutPlans).get();
    final full = plannedItems(
        _program('upper_lower').plans.first, TrainingFocus.strength,
        program: _program('upper_lower'), level: ExperienceLevel.advanced);
    final items = await db.getPlanItems(plans.first.id);
    final sets = items.fold<int>(0, (a, i) => a + i.sets.length);
    final fullSets = full.fold<int>(0, (a, p) => a + p.sets.length);
    expect(sets, lessThan(fullSets));
    expect(items.first.exercise.slug, 'bench_press');
  });
}
