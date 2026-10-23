// Délka tréninku (lib/features/workout/workout_service.dart): zapomenutý
// trénink se nezapočítá jako desítky hodin.
import 'package:fitness_app/features/workout/workout_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 10, 20, 18);

  test('běžný trénink: od začátku do konce', () {
    expect(workoutDuration(start, start.add(const Duration(minutes: 75))),
        const Duration(minutes: 75));
  });

  test('zapomenutý trénink: nejvýš 4 hodiny', () {
    expect(workoutDuration(start, start.add(const Duration(hours: 15))),
        kMaxWorkoutDuration);
  });

  test('posunuté hodiny: nikdy záporná délka', () {
    expect(workoutDuration(start, start.subtract(const Duration(minutes: 5))),
        Duration.zero);
  });
}
