import 'package:fitness_app/features/workout/workout_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('první výskyt cviku má pozice jako dřív (0, 1, 2…)', () {
    expect(setPositionFor(0, 0), 0);
    expect(setPositionFor(0, 2), 2);
    expect(blockSlotOf(2), 0);
    expect(blockRowOf(2), 2);
  });

  test('další výskyty stejného cviku se s prvním nesrazí', () {
    final first = {for (var i = 0; i < 10; i++) setPositionFor(0, i)};
    final second = {for (var i = 0; i < 10; i++) setPositionFor(1, i)};
    expect(first.intersection(second), isEmpty);
  });

  test('pozice jde rozložit zpět na slot a řádek', () {
    for (final slot in [0, 1, 3]) {
      for (final row in [0, 1, 7, blockPositionStride - 1]) {
        final position = setPositionFor(slot, row);
        expect(blockSlotOf(position), slot);
        expect(blockRowOf(position), row);
      }
    }
  });
}
