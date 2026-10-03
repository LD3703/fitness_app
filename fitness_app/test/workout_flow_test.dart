import 'package:fitness_app/features/workout/workout_flow.dart';
import 'package:flutter_test/flutter_test.dart';

FlowRow work({bool done = false}) =>
    (isDone: done, isWarmup: false, isDrop: false);
FlowRow warm({bool done = false}) =>
    (isDone: done, isWarmup: true, isDrop: false);
FlowRow drop({bool done = false}) =>
    (isDone: done, isWarmup: false, isDrop: true);

void main() {
  test('roundsOf: rozcvička bez kola, drop patří ke své sérii', () {
    expect(roundsOf([warm(), work(), drop(), work()]), [null, 0, 0, 1]);
  });

  test('samostatný cvik: pauza podle cviku', () {
    final blocks = <FlowBlock>[
      (group: null, rows: [work(done: true), work()], restSeconds: 90),
    ];
    final step = nextAfterSet(blocks, 0, 0);
    expect(step.restSeconds, 90);
    expect(step.block, isNull);
  });

  test('drop série navazuje bez pauzy, pauza až po poslední', () {
    final blocks = <FlowBlock>[
      (
        group: null,
        rows: [work(done: true), drop(), drop()],
        restSeconds: 90,
      ),
    ];
    final first = nextAfterSet(blocks, 0, 0);
    expect(first.restSeconds, isNull);
    expect(first.row, 1);

    final afterLast = nextAfterSet(<FlowBlock>[
      (
        group: null,
        rows: [work(done: true), drop(done: true), drop(done: true)],
        restSeconds: 90,
      ),
    ], 0, 2);
    expect(afterLast.restSeconds, 90);
  });

  test('supersérie: A1 → A2 bez pauzy, po A2 pauza a další kolo A1', () {
    final a1Done = <FlowBlock>[
      (group: 1, rows: [work(done: true), work()], restSeconds: 60),
      (group: 1, rows: [work(), work()], restSeconds: 120),
    ];
    final s1 = nextAfterSet(a1Done, 0, 0);
    expect(s1.restSeconds, isNull);
    expect(s1.block, 1);
    expect(s1.row, 0);

    final a2Done = <FlowBlock>[
      (group: 1, rows: [work(done: true), work()], restSeconds: 60),
      (group: 1, rows: [work(done: true), work()], restSeconds: 120),
    ];
    final s2 = nextAfterSet(a2Done, 1, 0);
    expect(s2.restSeconds, 120); // pauza posledního cviku supersérie
    expect(s2.block, 0);
    expect(s2.row, 1);
  });

  test('supersérie s rozcvičkou: kola se počítají jen z pracovních sérií',
      () {
    final blocks = <FlowBlock>[
      (group: 1, rows: [warm(done: true), work(done: true)], restSeconds: 60),
      (group: 1, rows: [work()], restSeconds: 60),
    ];
    final step = nextAfterSet(blocks, 0, 1);
    expect(step.block, 1);
    expect(step.row, 0);
    expect(step.restSeconds, isNull);

    // Po rozcvičce se nestřídá.
    final afterWarmup = nextAfterSet(blocks, 0, 0);
    expect(afterWarmup.restSeconds, 60);
  });

  test('supersérie: drop série A1 před přechodem na A2', () {
    final blocks = <FlowBlock>[
      (group: 2, rows: [work(done: true), drop()], restSeconds: 60),
      (group: 2, rows: [work()], restSeconds: 60),
    ];
    final s = nextAfterSet(blocks, 0, 0);
    expect(s.block, 0);
    expect(s.row, 1);
    expect(s.restSeconds, isNull);

    final afterDrop = nextAfterSet(<FlowBlock>[
      (group: 2, rows: [work(done: true), drop(done: true)], restSeconds: 60),
      (group: 2, rows: [work()], restSeconds: 60),
    ], 0, 1);
    expect(afterDrop.block, 1);
    expect(afterDrop.restSeconds, isNull);
  });

  test('různé skupiny vedle sebe se nemíchají', () {
    final blocks = <FlowBlock>[
      (group: 1, rows: [work(done: true)], restSeconds: 60),
      (group: 2, rows: [work()], restSeconds: 60),
    ];
    expect(nextAfterSet(blocks, 0, 0).restSeconds, 60);
  });
}
