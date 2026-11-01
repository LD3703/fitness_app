// Předvyplnění série v tréninku: váha i opakování z minula
// (lib/features/workout/workout_service.dart, prefillSet).
import 'package:fitness_app/data/database.dart';
import 'package:fitness_app/features/workout/workout_service.dart';
import 'package:flutter_test/flutter_test.dart';

SetEntry _prev({double? kg, int? reps, int? seconds}) => SetEntry(
      id: 1,
      sessionId: 1,
      exerciseId: 1,
      position: 0,
      weightKg: kg,
      reps: reps,
      durationSeconds: seconds,
      isWarmup: false,
      isDrop: false,
    );

PlanSetDraft _target(int reps, [double? kg]) =>
    (reps: reps, weightKg: kg, isWarmup: false, isDrop: false);

void main() {
  test('bez váhy v plánu: váha i opakování z minula', () {
    final p = prefillSet(
      target: _target(10),
      previous: _prev(kg: 60, reps: 12),
      isDuration: false,
    );
    expect(p.weightKg, 60);
    expect(p.value, 12);
  });

  test('plán s vahou (progrese, trenér) má přednost i u opakování', () {
    final p = prefillSet(
      target: _target(8, 62.5),
      previous: _prev(kg: 60, reps: 12),
      isDuration: false,
    );
    expect(p.weightKg, 62.5);
    expect(p.value, 8);
  });

  test('bez historie opakování z plánu, bez plánu 10', () {
    expect(prefillSet(target: _target(15), previous: null, isDuration: false),
        (weightKg: null, value: 15));
    expect(prefillSet(target: null, previous: null, isDuration: false),
        (weightKg: null, value: 10));
  });

  test('cvik na čas: sekundy z minula', () {
    final p = prefillSet(
      target: _target(30),
      previous: _prev(seconds: 45),
      isDuration: true,
    );
    expect(p.value, 45);
  });

  test('minulá série bez opakování (neúplný záznam) – z plánu', () {
    final p = prefillSet(
      target: _target(10),
      previous: _prev(kg: 50),
      isDuration: false,
    );
    expect(p.weightKg, 50);
    expect(p.value, 10);
  });
}
