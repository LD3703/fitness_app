import 'package:fitness_app/core/auto_progression.dart';
import 'package:fitness_app/data/enums.dart';
import 'package:flutter_test/flutter_test.dart';

const _kgPerLb = 0.45359237;

TargetSet _t(int reps, [double? kg]) =>
    (reps: reps, weightKg: kg, isWarmup: false, isDrop: false);

TargetSet _warmup(int reps, double kg) =>
    (reps: reps, weightKg: kg, isWarmup: true, isDrop: false);

TargetSet _drop(int reps, double kg) =>
    (reps: reps, weightKg: kg, isWarmup: false, isDrop: true);

PerformedSet _p(int reps, [double? kg]) => (
      weightKg: kg,
      reps: reps,
      durationSeconds: null,
      isWarmup: false,
      isDrop: false,
    );

PerformedSet _sec(int seconds) => (
      weightKg: null,
      reps: null,
      durationSeconds: seconds,
      isWarmup: false,
      isDrop: false,
    );

ProgressionInput _bench(
  List<TargetSet> targets,
  List<PerformedSet> performed, {
  List<PerformedSet> previous = const [],
  int? min,
  int? max,
  double? increment,
  MuscleGroup group = MuscleGroup.chest,
  Equipment equipment = Equipment.barbell,
  ExerciseType type = ExerciseType.weightReps,
  String? slug = 'bench_press',
}) =>
    ProgressionInput(
      type: type,
      group: group,
      equipment: equipment,
      slug: slug,
      targets: targets,
      repRangeMin: min,
      repRangeMax: max,
      incrementKg: increment,
      performed: performed,
      previous: previous,
    );

ProgressionProposal? _propose(ProgressionInput input, {HoldReason? hold}) =>
    proposeProgression(input, unit: UnitSystem.metric, holdReason: hold);

List<double?> _weights(ProgressionProposal p) => [
      for (final s in p.after.sets)
        if (!s.isWarmup && !s.isDrop) s.weightKg,
    ];

List<int> _reps(ProgressionProposal p) => [
      for (final s in p.after.sets)
        if (!s.isWarmup && !s.isDrop) s.reps,
    ];

void main() {
  group('rozsah opakování', () {
    test('výchozí: +2 do 8 opakování, jinak +4', () {
      expect(defaultRepRange(6), (min: 6, max: 8));
      expect(defaultRepRange(8), (min: 8, max: 10));
      expect(defaultRepRange(10), (min: 10, max: 14));
      expect(defaultRepRange(0), (min: 1, max: 3));
    });

    test('z plánu má přednost, chybějící hranice se dopočítá', () {
      final targets = [_t(10, 50)];
      expect(effectiveRepRange(targets), (min: 10, max: 14));
      expect(effectiveRepRange(targets, min: 6, max: 8), (min: 6, max: 8));
      expect(effectiveRepRange(targets, min: 5), (min: 5, max: 7));
      expect(effectiveRepRange(targets, max: 12), (min: 10, max: 12));
      expect(effectiveRepRange(targets, max: 6), (min: 6, max: 6));
      expect(effectiveRepRange(targets, min: 9, max: 7), (min: 7, max: 9));
    });

    test('rozcvička se pro výchozí rozsah nepočítá', () {
      expect(effectiveRepRange([_warmup(15, 40), _t(6, 80)]), (min: 6, max: 8));
    });
  });

  group('přírůstek', () {
    test('metricky podle partie a vybavení', () {
      double inc(MuscleGroup g, Equipment e, [String? slug]) =>
          defaultIncrementKg(
              group: g, equipment: e, slug: slug, unit: UnitSystem.metric);
      expect(inc(MuscleGroup.chest, Equipment.barbell), 2.5);
      expect(inc(MuscleGroup.shoulders, Equipment.machine), 2.5);
      expect(inc(MuscleGroup.legs, Equipment.barbell), 5);
      expect(inc(MuscleGroup.glutes, Equipment.barbell), 5);
      expect(inc(MuscleGroup.back, Equipment.barbell, 'deadlift'), 5);
      expect(inc(MuscleGroup.back, Equipment.barbell, 'barbell_row'), 2.5);
      expect(inc(MuscleGroup.chest, Equipment.dumbbell), 2);
      expect(inc(MuscleGroup.legs, Equipment.dumbbell), 2);
    });

    test('v librách 5 / 10 / 5 lb', () {
      double lb(MuscleGroup g, Equipment e) =>
          defaultIncrementKg(group: g, equipment: e, unit: UnitSystem.imperial) /
          _kgPerLb;
      expect(lb(MuscleGroup.chest, Equipment.barbell), closeTo(5, 1e-9));
      expect(lb(MuscleGroup.legs, Equipment.barbell), closeTo(10, 1e-9));
      expect(lb(MuscleGroup.chest, Equipment.dumbbell), closeTo(5, 1e-9));
    });

    test('zvýšená váha je vždy vyšší a zaokrouhlená', () {
      expect(increasedWeight(80, 2.5, 2.5), 82.5);
      expect(increasedWeight(81, 2.5, 2.5), 82.5);
      expect(increasedWeight(20, 2, 1), 22);
      expect(increasedWeight(80, 1.25, 1.25), 81.25);
    });

    test('odlehčení o 10 % na krok kotoučů', () {
      expect(deloadedWeight(80, 2.5), 72.5);
      expect(deloadedWeight(100, 2.5), 90);
      expect(deloadedWeight(2, 1), 1);
      expect(deloadedWeight(1, 1), 1); // menší už to nejde
    });
  });

  group('dvojitá progrese', () {
    test('všechny série na horní hranici → vyšší váha, opakování od spodní',
        () {
      final p = _propose(_bench(
        [_t(8, 80), _t(8, 80), _t(8, 80)],
        [_p(8, 80), _p(8, 80), _p(9, 80)],
        min: 6,
        max: 8,
      ))!;
      expect(p.kind, ProgressionKind.increase);
      expect(_weights(p), [82.5, 82.5, 82.5]);
      expect(_reps(p), [6, 6, 6]);
      expect(p.info.fromKg, 80);
      expect(p.info.toKg, 82.5);
      expect(p.info.reps, 6);
      expect(p.changesPlan, isTrue);
    });

    test('dřep +5 kg, jednoruční činky +2 kg, vlastní přírůstek', () {
      final squat = _propose(_bench(
        [_t(5, 100)],
        [_p(7, 100)],
        min: 5,
        max: 7,
        group: MuscleGroup.legs,
        slug: 'squat',
      ))!;
      expect(_weights(squat), [105]);

      final db = _propose(_bench(
        [_t(12, 20)],
        [_p(12, 20)],
        min: 8,
        max: 12,
        equipment: Equipment.dumbbell,
        slug: 'dumbbell_press',
      ))!;
      expect(_weights(db), [22]);

      final custom = _propose(_bench(
        [_t(8, 80)],
        [_p(8, 80)],
        min: 6,
        max: 8,
        increment: 1.25,
      ))!;
      expect(_weights(custom), [81.25]);
    });

    test('splněný cíl, ale ne horní hranice → +1 opakování', () {
      final p = _propose(_bench(
        [_t(6, 80), _t(6, 80), _t(6, 80)],
        [_p(7, 80), _p(6, 80), _p(6, 80)],
        min: 6,
        max: 8,
      ))!;
      expect(p.kind, ProgressionKind.reps);
      expect(_reps(p), [7, 7, 7]);
      expect(_weights(p), [80, 80, 80]);
      expect(p.info.reps, 7);
      expect(p.info.delta, 1);
    });

    test('+1 opakování nepřekročí horní hranici', () {
      final p = _propose(_bench(
        [_t(8, 80), _t(7, 80)],
        [_p(8, 80), _p(7, 80)],
        min: 6,
        max: 8,
      ))!;
      expect(p.kind, ProgressionKind.reps);
      expect(_reps(p), [8, 8]);
    });

    test('odvozený rozsah se uloží spolu se změnou', () {
      final p = _propose(_bench(
        [_t(10, 50), _t(10, 50)],
        [_p(10, 50), _p(11, 50)],
      ))!;
      expect(p.kind, ProgressionKind.reps);
      expect(p.before.repRangeMin, isNull);
      expect(p.after.repRangeMin, 10);
      expect(p.after.repRangeMax, 14);
      expect(_reps(p), [11, 11]);
    });

    test('nesplněný cíl jednou → beze změny', () {
      expect(
        _propose(_bench(
          [_t(6, 100), _t(6, 100)],
          [_p(6, 100), _p(4, 100)],
          min: 6,
          max: 8,
        )),
        isNull,
      );
    });

    test('2 tréninky po sobě pod spodní hranicí se stejnou vahou → odlehčení',
        () {
      final p = _propose(_bench(
        [_t(6, 80), _t(6, 80), _t(6, 80)],
        [_p(6, 80), _p(5, 80), _p(4, 80)],
        previous: [_p(6, 80), _p(5, 80), _p(5, 80)],
        min: 6,
        max: 8,
      ))!;
      expect(p.kind, ProgressionKind.deload);
      expect(_weights(p), [72.5, 72.5, 72.5]);
      expect(_reps(p), [6, 6, 6]);
      expect(p.info.toKg, 72.5);
    });

    test('minule selhání s jinou (nižší) vahou → bez odlehčení', () {
      expect(
        _propose(_bench(
          [_t(6, 80)],
          [_p(5, 80)],
          previous: [_p(5, 77.5)],
          min: 6,
          max: 8,
        )),
        isNull,
      );
    });

    test('lehčí váha než cíl → žádné zvýšení', () {
      expect(
        _propose(_bench(
          [_t(8, 80), _t(8, 80)],
          [_p(8, 75), _p(8, 75)],
          min: 6,
          max: 8,
        )),
        isNull,
      );
    });

    test('nedokončené série → žádné zvýšení ani odlehčení', () {
      expect(
        _propose(_bench(
          [_t(8, 80), _t(8, 80), _t(8, 80)],
          [_p(8, 80), _p(8, 80)],
          min: 6,
          max: 8,
        )),
        isNull,
      );
    });

    test('rozcvička a drop série se nehodnotí ani nemění', () {
      final p = _propose(_bench(
        [_warmup(15, 40), _t(8, 80), _t(8, 80), _drop(8, 60)],
        [
          (weightKg: 40, reps: 5, durationSeconds: null, isWarmup: true,
              isDrop: false),
          _p(8, 80),
          _p(8, 80),
          (weightKg: 60, reps: 3, durationSeconds: null, isWarmup: false,
              isDrop: true),
        ],
        min: 6,
        max: 8,
      ))!;
      expect(p.kind, ProgressionKind.increase);
      expect(p.after.sets.first, _warmup(15, 40));
      expect(p.after.sets.last, _drop(8, 60));
      expect(_weights(p), [82.5, 82.5]);
    });

    test('cíl bez váhy → zvýšení z odcvičené váhy', () {
      final p = _propose(_bench(
        [_t(8), _t(8)],
        [_p(8, 60), _p(8, 60)],
        min: 6,
        max: 8,
      ))!;
      expect(p.kind, ProgressionKind.increase);
      expect(_weights(p), [62.5, 62.5]);
    });

    test('bez jakékoli váhy → beze změny', () {
      expect(_propose(_bench([_t(8)], [_p(8)], min: 6, max: 8)), isNull);
    });

    test('v librách: 135 lb → 140 lb', () {
      final p = proposeProgression(
        _bench(
          [_t(8, 135 * _kgPerLb)],
          [_p(8, 135 * _kgPerLb)],
          min: 6,
          max: 8,
        ),
        unit: UnitSystem.imperial,
      )!;
      expect(p.info.toKg! / _kgPerLb, closeTo(140, 0.01));
    });
  });

  group('vlastní váha a čas', () {
    test('kliky: všechny série splněné → +1 opakování', () {
      final p = _propose(_bench(
        [_t(10), _t(10)],
        [_p(10), _p(12)],
        type: ExerciseType.bodyweightReps,
        equipment: Equipment.bodyweight,
        slug: 'push_up',
      ))!;
      expect(p.kind, ProgressionKind.reps);
      expect(_reps(p), [11, 11]);
      expect(p.info.isDuration, isFalse);
    });

    test('kliky: horní hranice z plánu je strop', () {
      expect(
        _propose(_bench(
          [_t(15)],
          [_p(15)],
          max: 15,
          type: ExerciseType.bodyweightReps,
          equipment: Equipment.bodyweight,
        )),
        isNull,
      );
    });

    test('kliky: nesplněno → beze změny (bez odlehčení)', () {
      expect(
        _propose(_bench(
          [_t(10), _t(10)],
          [_p(10), _p(8)],
          previous: [_p(7)],
          type: ExerciseType.bodyweightReps,
          equipment: Equipment.bodyweight,
        )),
        isNull,
      );
    });

    test('plank: +5 s', () {
      final p = _propose(_bench(
        [_t(30), _t(30)],
        [_sec(30), _sec(40)],
        type: ExerciseType.duration,
        equipment: Equipment.bodyweight,
        slug: 'plank',
      ))!;
      expect(p.kind, ProgressionKind.reps);
      expect(_reps(p), [35, 35]);
      expect(p.info.isDuration, isTrue);
      expect(p.info.delta, durationIncrementSeconds);
    });
  });

  group('blokace', () {
    final now = DateTime(2026, 10, 3, 12);
    ProgressionPeriod period(
      PeriodType type,
      DateTime start, [
      DateTime? end,
      Set<MuscleGroup> groups = const {},
    ]) =>
        (type: type, start: start, end: end, groups: groups);

    test('zranění partie: jen ta partie (a celé tělo)', () {
      final b = progressionBlockersFrom(
        [period(PeriodType.injury, DateTime(2026, 9, 20), null,
            {MuscleGroup.chest})],
        now,
      );
      expect(b.reasonFor(MuscleGroup.chest), HoldReason.injury);
      expect(b.reasonFor(MuscleGroup.fullBody), HoldReason.injury);
      expect(b.reasonFor(MuscleGroup.legs), isNull);
    });

    test('zranění bez partie platí pro všechny cviky', () {
      final b = progressionBlockersFrom(
        [period(PeriodType.injury, DateTime(2026, 9, 20))],
        now,
      );
      expect(b.reasonFor(MuscleGroup.legs), HoldReason.injury);
    });

    test('nemoc, zotavování, dieta; skončená období neplatí', () {
      expect(
        progressionBlockersFrom(
          [period(PeriodType.illness, DateTime(2026, 10, 1))],
          now,
        ).reasonFor(MuscleGroup.back),
        HoldReason.illness,
      );
      expect(
        progressionBlockersFrom(
          [period(PeriodType.illness, DateTime(2026, 9, 25),
              DateTime(2026, 9, 30))],
          now,
        ).reasonFor(MuscleGroup.back),
        HoldReason.recovery,
      );
      expect(
        progressionBlockersFrom(
          [period(PeriodType.illness, DateTime(2026, 8, 1),
              DateTime(2026, 8, 10))],
          now,
        ).reasonFor(MuscleGroup.back),
        isNull,
      );
      expect(
        progressionBlockersFrom(
          [period(PeriodType.cut, DateTime(2026, 9, 1))],
          now,
        ).reasonFor(MuscleGroup.back),
        HoldReason.cut,
      );
      expect(
        progressionBlockersFrom(
          [period(PeriodType.cut, DateTime(2026, 6, 1), DateTime(2026, 8, 1))],
          now,
        ).reasonFor(MuscleGroup.back),
        isNull,
      );
      expect(ProgressionBlockers.none.reasonFor(MuscleGroup.chest), isNull);
    });

    test('zvýšení váhy i opakování se změní na „drží“', () {
      final inc = _propose(
        _bench([_t(8, 80)], [_p(8, 80)], min: 6, max: 8),
        hold: HoldReason.cut,
      )!;
      expect(inc.kind, ProgressionKind.hold);
      expect(inc.changesPlan, isFalse);
      expect(inc.info.blocked, ProgressionKind.increase);
      expect(inc.info.holdReason, HoldReason.cut);
      expect(sameTargets(inc.after.sets, inc.before.sets), isTrue);

      final reps = _propose(
        _bench([_t(6, 80)], [_p(6, 80)], min: 6, max: 8),
        hold: HoldReason.injury,
      )!;
      expect(reps.kind, ProgressionKind.hold);
      expect(reps.info.blocked, ProgressionKind.reps);
    });

    test('odlehčení se v dietě povolí', () {
      final p = _propose(
        _bench(
          [_t(6, 80)],
          [_p(4, 80)],
          previous: [_p(5, 80)],
          min: 6,
          max: 8,
        ),
        hold: HoldReason.cut,
      )!;
      expect(p.kind, ProgressionKind.deload);
    });
  });

  group('uložení', () {
    test('JSON tam a zpět', () {
      final p = _propose(_bench(
        [_warmup(12, 40), _t(8, 80), _drop(8, 60)],
        [_p(8, 80)],
        min: 6,
        max: 8,
      ))!;
      final decodedBefore =
          decodeProgressionState(encodeProgressionState(p.before));
      expect(decodedBefore.info, isNull);
      expect(sameTargets(decodedBefore.snapshot.sets, p.before.sets), isTrue);
      expect(decodedBefore.snapshot.repRangeMin, 6);

      final decoded =
          decodeProgressionState(encodeProgressionState(p.after, info: p.info));
      expect(sameTargets(decoded.snapshot.sets, p.after.sets), isTrue);
      expect(decoded.snapshot.repRangeMax, 8);
      expect(decoded.info!.fromKg, 80);
      expect(decoded.info!.toKg, 82.5);
      expect(decoded.info!.reps, 6);
    });

    test('poškozený JSON → prázdný stav', () {
      final d = decodeProgressionState('{nope');
      expect(d.snapshot.sets, isEmpty);
      expect(d.info, isNull);
    });

    test('„drží“ uloží důvod', () {
      final p = _propose(
        _bench([_t(8, 80)], [_p(8, 80)], min: 6, max: 8),
        hold: HoldReason.illness,
      )!;
      final info = decodeProgressionState(
        encodeProgressionState(p.after, info: p.info),
      ).info!;
      expect(info.holdReason, HoldReason.illness);
      expect(info.blocked, ProgressionKind.increase);
    });

    test('režim z profilu', () {
      expect(progressionModeOf(0), ProgressionMode.off);
      expect(progressionModeOf(1), ProgressionMode.suggest);
      expect(progressionModeOf(null), ProgressionMode.suggest);
      expect(progressionModeOf(2), ProgressionMode.auto);
      for (final m in ProgressionMode.values) {
        expect(progressionModeOf(progressionModeValue(m)), m);
      }
    });
  });
}
