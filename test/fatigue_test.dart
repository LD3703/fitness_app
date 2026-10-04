import 'package:fitness_app/core/fatigue.dart';
import 'package:fitness_app/data/enums.dart';
import 'package:fitness_app/data/seed/exercise_secondary_muscles.dart';
import 'package:fitness_app/data/seed/seed_data.dart';
import 'package:flutter_test/flutter_test.dart';

FatigueSet workSet(
  MuscleGroup primary, {
  Set<MuscleGroup> secondary = const {},
  bool warmup = false,
  bool drop = false,
}) =>
    (primary: primary, secondary: secondary, isWarmup: warmup, isDrop: drop);

FatigueSession session(
  DateTime at,
  List<FatigueSet> sets, {
  WorkoutFeeling? feeling,
  bool planB = false,
}) =>
    (at: at, feeling: feeling, isPlanB: planB, sets: sets);

void main() {
  final now = DateTime(2026, 10, 2, 18);

  test('12 čerstvých sérií = 100 %', () {
    final r = computeFatigue([
      session(now, List.filled(12, workSet(MuscleGroup.chest))),
    ], now);
    expect(r.percent[MuscleGroup.chest], closeTo(100, 0.001));
    expect(r.percent[MuscleGroup.back], 0);
    expect(r.sessions, 1);
  });

  test('strop 100 %', () {
    final r = computeFatigue([
      session(now, List.filled(30, workSet(MuscleGroup.legs))),
    ], now);
    expect(r.percent[MuscleGroup.legs], 100);
  });

  test('vedlejší partie 0,5, rozcvička 0, drop 0,7', () {
    final r = computeFatigue([
      session(now, [
        workSet(MuscleGroup.chest, secondary: {MuscleGroup.triceps}),
        workSet(MuscleGroup.chest, warmup: true),
        workSet(MuscleGroup.chest, drop: true),
      ]),
    ], now);
    expect(r.percent[MuscleGroup.chest], closeTo(1.7 / 12 * 100, 0.001));
    expect(r.percent[MuscleGroup.triceps], closeTo(0.5 / 12 * 100, 0.001));
  });

  test('celé tělo přidá 0,3 každé partii', () {
    final r = computeFatigue([
      session(now, [workSet(MuscleGroup.fullBody)]),
    ], now);
    for (final g in fatigueGroups) {
      expect(r.percent[g], closeTo(0.3 / 12 * 100, 0.001));
    }
    expect(r.percent.containsKey(MuscleGroup.fullBody), isFalse);
  });

  test('poločas: velké partie 36 h, malé 24 h', () {
    final r = computeFatigue([
      session(now.subtract(const Duration(hours: 36)),
          List.filled(12, workSet(MuscleGroup.back))),
      session(now.subtract(const Duration(hours: 24)),
          List.filled(12, workSet(MuscleGroup.biceps))),
    ], now);
    expect(r.percent[MuscleGroup.back], closeTo(50, 0.01));
    expect(r.percent[MuscleGroup.biceps], closeTo(50, 0.01));
  });

  test('pocit po tréninku a plán B násobí zátěž', () {
    final sets = List.filled(4, workSet(MuscleGroup.shoulders));
    double p(WorkoutFeeling? f, {bool planB = false}) =>
        computeFatigue([session(now, sets, feeling: f, planB: planB)], now)
            .percent[MuscleGroup.shoulders]!;
    final base = p(null);
    expect(p(WorkoutFeeling.ok), closeTo(base, 0.001));
    expect(p(WorkoutFeeling.easy), closeTo(base * 0.8, 0.001));
    expect(p(WorkoutFeeling.hard), closeTo(base * 1.25, 0.001));
    expect(p(null, planB: true), closeTo(base * 0.5, 0.001));
  });

  test('tréninky starší než 7 dní se nepočítají', () {
    final r = computeFatigue([
      session(now.subtract(const Duration(days: 8)),
          List.filled(12, workSet(MuscleGroup.chest))),
    ], now);
    expect(r.sessions, 0);
    expect(r.percent[MuscleGroup.chest], 0);
  });

  test('stavy a řazení', () {
    expect(fatigueStatus(10), FatigueStatus.recovered);
    expect(fatigueStatus(30), FatigueStatus.recovering);
    expect(fatigueStatus(70), FatigueStatus.fatigued);

    final r = computeFatigue([
      session(now, [
        ...List.filled(3, workSet(MuscleGroup.legs)),
        ...List.filled(10, workSet(MuscleGroup.chest)),
      ]),
    ], now);
    expect(sortedByFatigue(r).first.key, MuscleGroup.chest);
    expect(mostFatiguedOf(r, [MuscleGroup.legs, MuscleGroup.chest])?.key,
        MuscleGroup.chest);
    expect(mostFatiguedOf(r, [MuscleGroup.legs]), isNull);
  });

  test('každý vestavěný cvik má vedlejší partie a nejsou mezi nimi hlavní',
      () {
    for (final e in seedExercises) {
      expect(exerciseSecondaryMuscles.containsKey(e.slug), isTrue,
          reason: e.slug);
      expect(exerciseSecondaryMuscles[e.slug]!.contains(e.muscleGroup),
          isFalse,
          reason: e.slug);
      expect(exerciseSecondaryMuscles[e.slug]!.contains(MuscleGroup.fullBody),
          isFalse,
          reason: e.slug);
    }
  });
}
