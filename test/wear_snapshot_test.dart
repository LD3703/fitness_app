import 'package:fitness_app/modules/wear/wear_protocol.dart';
import 'package:fitness_app/modules/wear/wear_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

WearRowInput row({
  int? savedId,
  bool warmup = false,
  bool drop = false,
  double? kg = 50,
  int? value = 10,
}) =>
    (
      isDone: savedId != null,
      isWarmup: warmup,
      isDrop: drop,
      weightKg: kg,
      value: value,
      previousWeightKg: null,
      previousValue: null,
      savedId: savedId,
    );

WearBlockInput block(int id, List<WearRowInput> rows) => (
      exerciseId: id,
      name: 'E$id',
      isDuration: false,
      weightRequired: true,
      rows: rows,
    );

void main() {
  test('fresh workout starts with the first set', () {
    final blocks = [
      block(1, [row(), row()]),
      block(2, [row()]),
    ];
    expect(pickCurrentSet(blocks), (block: 0, row: 0));
  });

  test('suggested undone set wins', () {
    final blocks = [
      block(1, [row(savedId: 1), row()]),
      block(2, [row(), row()]),
    ];
    expect(pickCurrentSet(blocks, suggested: (block: 1, row: 0)),
        (block: 1, row: 0));
    // Odškrtnutá navržená série se ignoruje.
    expect(pickCurrentSet(blocks, suggested: (block: 0, row: 0)),
        (block: 0, row: 1));
  });

  test('stays on the exercise of the last saved set', () {
    final blocks = [
      block(1, [row(), row()]),
      block(2, [row(savedId: 5), row()]),
    ];
    expect(pickCurrentSet(blocks), (block: 1, row: 1));
  });

  test('moves forward after the last set of an exercise', () {
    final blocks = [
      block(1, [row(), row()]),
      block(2, [row(savedId: 5)]),
      block(3, [row()]),
    ];
    expect(pickCurrentSet(blocks), (block: 2, row: 0));
    // Za posledním cvikem dokola od začátku.
    final wrap = [
      block(1, [row()]),
      block(2, [row(savedId: 5)]),
    ];
    expect(pickCurrentSet(wrap), (block: 0, row: 0));
  });

  test('all done returns null', () {
    final blocks = [
      block(1, [row(savedId: 1)]),
      block(2, [row(savedId: 2)]),
    ];
    expect(pickCurrentSet(blocks), isNull);
    expect(pickCurrentSet(const []), isNull);
  });

  test('next exercise skips finished ones and wraps', () {
    final blocks = [
      block(1, [row()]),
      block(2, [row(savedId: 1)]),
      block(3, [row()]),
    ];
    expect(nextExercisePosition(blocks, 0), (block: 2, row: 0));
    expect(nextExercisePosition(blocks, 2), (block: 0, row: 0));
    expect(nextExercisePosition([block(1, [row()])], 0), isNull);
    expect(firstUndoneInBlock(blocks, 1), isNull);
    expect(firstUndoneInBlock(blocks, 2), (block: 2, row: 0));
  });

  test('builds active state with current set and counts', () {
    final blocks = [
      block(1, [row(savedId: 1), row(drop: true, kg: 40, value: 8)]),
      (
        exerciseId: 2,
        name: 'Plank',
        isDuration: true,
        weightRequired: false,
        rows: [row(kg: null, value: 30)],
      ),
    ];
    final state = buildActiveWearState(
      sessionId: 3,
      title: null,
      startedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      blocks: blocks,
      restEndsAt: DateTime.fromMillisecondsSinceEpoch(9000),
      restTotalSeconds: 90,
      unit: 'kg',
      kgPerUnit: 1,
      weightStep: 2.5,
    );
    expect(state.phase, WearPhase.active);
    expect(state.current!.blockIndex, 0);
    expect(state.current!.setIndex, 1);
    expect(state.current!.kind, WearSetKind.drop);
    expect(state.current!.weightKg, 40);
    expect(state.restEndsAtMs, 9000);
    expect(state.restTotalSeconds, 90);
    expect(state.exercises.map((e) => e.doneSets), [1, 0]);
    expect(state.exercises.map((e) => e.totalSets), [2, 1]);

    final noRest = buildActiveWearState(
      sessionId: 3,
      title: 'Plan',
      startedAt: DateTime(2026),
      blocks: blocks,
      restTotalSeconds: 90,
      unit: 'kg',
      kgPerUnit: 1,
      weightStep: 2.5,
    );
    expect(noRest.restEndsAtMs, isNull);
    expect(noRest.restTotalSeconds, 0);
  });
}
