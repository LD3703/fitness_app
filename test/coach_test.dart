import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

void main() {
  group('kód trenéra', () {
    test('vygenerovaný kód je platný', () {
      final r = Random(1);
      for (var i = 0; i < 50; i++) {
        expect(isValidCoachCode(generateCoachCode(r)), isTrue);
      }
    });

    test('kód z odkazu i z textu', () {
      expect(parseCoachCode('https://gymbar.app/coach?code=abc234'), 'ABC234');
      expect(parseCoachCode('gymbar://coach?code=ABC234'), 'ABC234');
      expect(parseCoachCode(' abc-234 '), 'ABC234');
      expect(parseCoachCode('https://gymbar.app/gym?code=ABC234'), isNull);
      expect(parseCoachCode('ABC23'), isNull);
      // 0, O, 1, I, L v kódu nejsou.
      expect(parseCoachCode('ABC230'), isNull);
    });

    test('jméno a popis trenéra', () {
      expect(coachName('  Petr   Novák '), 'Petr Novák');
      expect(coachName('   '), '?');
      expect(coachName('x' * 60).length, coachNameMax);
      expect(coachBio('  '), isNull);
      expect(coachBio(' Silový trénink ')!, 'Silový trénink');
      expect(coachBio('y' * 400)!.length, coachBioMax);
    });

    test('status vyprší 60 dní bez klienta', () {
      final since = DateTime(2026, 10, 1);
      expect(
        coachStatusExpiresAt(clientCount: 0, zeroSince: since),
        DateTime(2026, 11, 30),
      );
      expect(coachStatusExpiresAt(clientCount: 2, zeroSince: since), isNull);
      expect(coachStatusExpiresAt(clientCount: 0, zeroSince: null), isNull);
    });
  });

  group('plán', () {
    const plan = CoachPlan(
      name: 'Push A',
      description: 'Hrudník a ramena',
      weekdaysMask: 0x15,
      exercises: [
        CoachPlanExercise(
          slug: 'bench_press',
          nameEn: 'Bench press',
          nameCs: 'Bench press',
          restSeconds: 150,
          restAuto: false,
          note: 'Lopatky u sebe, 3 s dolů',
          sets: [
            CoachPlanSet(reps: 10, kg: 40, warmup: true),
            CoachPlanSet(reps: 5, kg: 80),
            CoachPlanSet(reps: 8, kg: 60, drop: true),
          ],
        ),
        CoachPlanExercise(
          nameEn: 'Sled push',
          nameCs: 'Tlačení saní',
          muscle: 'quads',
          equipment: 'machine',
          type: 'weightReps',
          superset: 1,
          repMin: 8,
          repMax: 12,
          sets: [CoachPlanSet(reps: 12)],
        ),
      ],
    );

    test('JSON tam a zpět', () {
      final back = CoachPlan.fromJson(plan.toJson());
      expect(back.name, 'Push A');
      expect(back.description, 'Hrudník a ramena');
      expect(back.weekdaysMask, 0x15);
      expect(back.exercises.length, 2);
      final bench = back.exercises.first;
      expect(bench.slug, 'bench_press');
      expect(bench.restAuto, isFalse);
      expect(bench.restSeconds, 150);
      expect(bench.note, 'Lopatky u sebe, 3 s dolů');
      expect(bench.sets, plan.exercises.first.sets);
      final custom = back.exercises.last;
      expect(custom.slug, isNull);
      expect(custom.nameCs, 'Tlačení saní');
      expect(custom.muscle, 'quads');
      expect(custom.superset, 1);
      expect(custom.repMin, 8);
      expect(custom.repMax, 12);
      expect(custom.restAuto, isTrue);
      expect(custom.note, isNull);
      expect(custom.toJson().containsKey('note'), isFalse);
      expect(back.workingSets, 3);
    });

    test('poškozená data', () {
      expect(() => CoachPlan.fromJson('x'), throwsA(isA<CoachFormatException>()));
      expect(() => CoachPlan.fromJson({'exercises': []}),
          throwsA(isA<CoachFormatException>()));
      // Nesmyslné hodnoty se zahodí nebo nahradí výchozími.
      final p = CoachPlan.fromJson({
        'name': 'X',
        'days': 999,
        'exercises': [
          {
            'en': 'A',
            'sets': [
              {'r': -5, 'kg': 5000},
            ],
          },
        ],
      });
      expect(p.weekdaysMask, 0);
      expect(p.exercises.single.sets.single.reps, 10);
      expect(p.exercises.single.sets.single.kg, isNull);
      final long = CoachPlan.fromJson({
        'name': 'Y',
        'exercises': [
          {'en': 'B', 'note': 'x' * 1000},
        ],
      });
      expect(long.exercises.single.note!.length, coachExerciseNoteMax);
    });

    test('plán od trenéra', () {
      final a = AssignedPlan.fromJson('p1', {
        'plan': plan.toJson(),
        'version': 3,
        'trainerName': 'Petr',
      });
      expect(a.version, 3);
      expect(a.trainerName, 'Petr');
      expect(assignedPlanRemoteId(a.id), 'coach:p1');
      expect(sharedPlanRemoteId('abc'), 'shared:abc');
    });
  });

  group('tréninky a statistiky', () {
    CoachWorkout w(DateTime at, List<CoachWorkoutExercise> ex, {int id = 1}) =>
        CoachWorkout(id: coachWorkoutId(id), startedAt: at, exercises: ex);

    CoachWorkoutExercise bench(List<CoachSet> sets) => CoachWorkoutExercise(
        slug: 'bench_press', nameEn: 'Bench press', nameCs: 'Bench', sets: sets);

    test('JSON tam a zpět', () {
      final x = w(DateTime(2026, 10, 12, 18), [
        bench(const [
          CoachSet(kg: 40, reps: 10, warmup: true),
          CoachSet(kg: 80, reps: 5),
        ]),
      ], id: 42);
      final back = CoachWorkout.fromJson('s42', x.toJson());
      expect(back.id, 's42');
      expect(back.startedAt, DateTime(2026, 10, 12, 18));
      expect(back.exercises.single.sets.length, 2);
      expect(back.exercises.single.topKg, 80);
      // Objem bez rozcvičky.
      expect(back.volumeKg, 400);
      expect(back.workingSets, 1);
    });

    test('nejtěžší série bez rozcvičky a drop sérií', () {
      final e = bench(const [
        CoachSet(kg: 100, reps: 3, warmup: true),
        CoachSet(kg: 90, reps: 0),
        CoachSet(kg: 85, reps: 5),
        CoachSet(kg: 95, reps: 6, drop: true),
      ]);
      expect(e.topKg, 85);
    });

    test('týdny, souhrn a rekordy', () {
      final now = DateTime(2026, 10, 14, 12); // středa
      final list = [
        w(DateTime(2026, 10, 13), [bench(const [CoachSet(kg: 80, reps: 5)])], id: 1),
        w(DateTime(2026, 10, 12), [bench(const [CoachSet(kg: 82.5, reps: 3)])], id: 2),
        w(DateTime(2026, 10, 7), [bench(const [CoachSet(kg: 75, reps: 5)])], id: 3),
        w(DateTime(2026, 9, 1), [bench(const [CoachSet(kg: 70, reps: 5)])], id: 4),
      ];
      expect(coachWeekStart(now), DateTime(2026, 10, 12));
      final weeks = weeklyBuckets(list, now: now, weeks: 4);
      expect(weeks.length, 4);
      expect(weeks.last.start, DateTime(2026, 10, 12));
      expect(weeks.last.workouts, 2);
      expect(weeks[2].workouts, 1);
      expect(weeks.first.workouts, 0);

      final s = summarizeClient(list, now: now);
      expect(s.lastWorkout, DateTime(2026, 10, 13));
      expect(s.daysSinceLast(now), 1);
      expect(s.thisWeek, 2);
      expect(s.total, 4);
      expect(s.inactive(now), isFalse);
      expect(s.inactive(DateTime(2026, 10, 30)), isTrue);

      final series = topWeightSeries(list, 'bench_press');
      expect(series.map((p) => p.value).toList(), [70, 75, 82.5, 80]);
      final records = personalRecords(list);
      expect(records.single.kg, 82.5);
      expect(records.single.date, DateTime(2026, 10, 12));
      expect(exerciseOptions(list).single.count, 4);
    });

    test('tělesná váha', () {
      final points = [
        CoachWeightPoint(DateTime(2026, 10, 2), 80.5),
        CoachWeightPoint(DateTime(2026, 10, 1), 81),
      ];
      final back = CoachWeightPoint.listFromJson(CoachWeightPoint.listToJson(points));
      expect(back.map((p) => p.kg).toList(), [81, 80.5]);
      expect(CoachWeightPoint.listFromJson(null), isEmpty);
    });
  });
}
