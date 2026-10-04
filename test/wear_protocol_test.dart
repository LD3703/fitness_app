import 'dart:io';

import 'package:fitness_app/modules/wear/wear_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phone and watch protocol files are identical', () {
    final phone = File('lib/modules/wear/wear_protocol.dart');
    final watch = File('wear/lib/wear_protocol.dart');
    expect(watch.readAsStringSync(), phone.readAsStringSync(),
        reason: 'Zkopíruj lib/modules/wear/wear_protocol.dart do wear/lib/.');
  });

  test('envelope round trip', () {
    final msg = wearEnvelope({'t': WearMsg.hello});
    expect(msg.keys, [kWearMessageKey]);
    expect(msg[kWearMessageKey], isA<String>());
    final opened = openWearEnvelope(msg)!;
    expect(opened['t'], WearMsg.hello);
    expect(opened['v'], kWearProtocolVersion);
    expect(openWearEnvelope({'other': 'x'}), isNull);
    expect(openWearEnvelope({kWearMessageKey: 'not json'}), isNull);
  });

  test('state round trip', () {
    const state = WearState(
      phase: WearPhase.active,
      sessionId: 7,
      title: 'Push',
      startedAtMs: 1000,
      unit: 'lb',
      kgPerUnit: 0.45359237,
      weightStep: 5,
      current: WearCurrentSet(
        blockIndex: 1,
        exerciseId: 42,
        name: 'Bench press',
        isDuration: false,
        weightRequired: true,
        setIndex: 2,
        setCount: 4,
        kind: WearSetKind.drop,
        weightKg: 60,
        value: 8,
        previousWeightKg: 57.5,
        previousValue: 10,
      ),
      restEndsAtMs: 5000,
      restTotalSeconds: 90,
      exercises: [
        WearExerciseItem(
            blockIndex: 0, exerciseId: 1, name: 'A', doneSets: 3, totalSets: 3),
        WearExerciseItem(
            blockIndex: 1, exerciseId: 42, name: 'B', doneSets: 2, totalSets: 4),
      ],
    );
    final opened = openWearEnvelope(
        wearEnvelope({'t': WearMsg.state, 'state': state.toJson()}))!;
    final back = WearState.fromJson(opened['state'])!;
    expect(back.phase, WearPhase.active);
    expect(back.sessionId, 7);
    expect(back.unit, 'lb');
    expect(back.weightStep, 5);
    expect(back.current!.kind, WearSetKind.drop);
    expect(back.current!.weightKg, 60);
    expect(back.current!.previousValue, 10);
    expect(back.restEndsAtMs, 5000);
    expect(back.exercises.length, 2);
    expect(back.exercises.first.isDone, isTrue);
    expect(back.doneSets, 5);
    expect(back.totalSets, 7);
  });

  test('commands round trip', () {
    const commands = <WearCommand>[
      WearCompleteSet(
          blockIndex: 1, exerciseId: 2, setIndex: 3, weightKg: 62.5, value: 8),
      WearCompleteSet(
          blockIndex: 0, exerciseId: 2, setIndex: 0, weightKg: null, value: 30),
      WearAdjustWeight(blockIndex: 1, exerciseId: 2, setIndex: 3, delta: -1),
      WearAdjustReps(blockIndex: 1, exerciseId: 2, setIndex: 3, delta: 1),
      WearSkipRest(),
      WearNextExercise(),
      WearSelectExercise(blockIndex: 4, exerciseId: 9),
      WearFinishWorkout(),
      WearOpenWorkout(),
    ];
    for (final c in commands) {
      final opened = openWearEnvelope(wearEnvelope(c.toJson(5)))!;
      expect(opened['t'], WearMsg.command);
      expect(opened['id'], 5);
      final back = WearCommand.fromJson(opened);
      expect(back, isNotNull, reason: c.name);
      expect(back!.name, c.name);
      expect(back.args, c.args);
    }
    expect(WearCommand.fromJson({'cmd': 'completeSet'}), isNull);
    expect(WearCommand.fromJson({'cmd': 'unknown'}), isNull);
  });

  test('ack round trip', () {
    final back = WearAck.fromJson(
        const WearAck(3, ok: false, reason: WearAckReason.invalid).toJson())!;
    expect(back.id, 3);
    expect(back.ok, isFalse);
    expect(back.reason, WearAckReason.invalid);
  });

  test('premium required state round trip and unknown phase fallback', () {
    const state = WearState.premiumRequired();
    final back = WearState.fromJson(state.toJson())!;
    expect(back.phase, WearPhase.premiumRequired);
    expect(back.sessionId, isNull);
    expect(back.exercises, isEmpty);
    // Neznámá fáze (novější telefon, starší hodinky) → idle.
    final unknown = WearState.fromJson({...state.toJson(), 'phase': 'future'})!;
    expect(unknown.phase, WearPhase.idle);
  });
}
