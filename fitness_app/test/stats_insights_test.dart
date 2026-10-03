import 'package:fitness_app/data/enums.dart';
import 'package:fitness_app/modules/stats/insights.dart';
import 'package:fitness_app/modules/stats/stats_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Středa 30. 9. 2026.
  final now = DateTime(2026, 9, 30, 12);

  StatPoint p(int month, int day, double y) =>
      (x: DateTime(2026, month, day, 18), y: y);

  StatPoint w(int month, int day, double kg) =>
      (x: DateTime(2026, month, day), y: kg);

  List<T> only<T>(List<Insight> list) => list.whereType<T>().toList();

  group('návrat po nemoci', () {
    final illness = (
      type: PeriodType.illness,
      start: DateTime(2026, 8, 25),
      end: DateTime(2026, 9, 1),
    );

    test('počet dní do návratu na 97 % formy', () {
      final insights = computeInsights(InsightInput(
        now: now,
        periods: [illness],
        oneRepMaxByExercise: {
          1: [
            p(8, 1, 100),
            p(8, 10, 98),
            p(8, 20, 100),
            p(9, 3, 90),
            p(9, 8, 95),
            p(9, 12, 98),
          ],
        },
      ));
      final r = only<IllnessRecoveryInsight>(insights).single;
      expect(r.lifts.single.exerciseId, 1);
      expect(r.lifts.single.daysToRecover, 11);
      expect(r.lifts.single.percentBelow, isNull);
      expect(r.allRecovered, isTrue);
    });

    test('ještě pod formou: o kolik %', () {
      final insights = computeInsights(InsightInput(
        now: now,
        periods: [illness],
        oneRepMaxByExercise: {
          1: [p(8, 1, 100), p(8, 20, 100), p(9, 5, 85), p(9, 20, 90)],
        },
      ));
      final r = only<IllnessRecoveryInsight>(insights).single;
      expect(r.lifts.single.daysToRecover, isNull);
      expect(r.lifts.single.percentBelow, closeTo(10, 0.001));
      expect(r.allRecovered, isFalse);
    });

    test('během nemoci se návrat nehlásí', () {
      final insights = computeInsights(InsightInput(
        now: now,
        periods: [
          illness,
          (type: PeriodType.illness, start: DateTime(2026, 9, 28), end: null),
        ],
        oneRepMaxByExercise: {
          1: [p(8, 1, 100), p(8, 20, 100), p(9, 5, 85)],
        },
      ));
      expect(only<IllnessRecoveryInsight>(insights), isEmpty);
    });

    test('bez sledování období nic', () {
      final insights = computeInsights(InsightInput(
        now: now,
        trackPeriods: false,
        periods: [illness],
        oneRepMaxByExercise: {
          1: [p(8, 1, 100), p(8, 20, 100), p(9, 5, 85)],
        },
      ));
      expect(only<IllnessRecoveryInsight>(insights), isEmpty);
    });
  });

  group('dieta a nabírání', () {
    final lift = [p(7, 10, 100), p(8, 15, 97), p(9, 20, 95)];
    final weights = [
      w(8, 1, 90),
      w(8, 2, 90),
      w(8, 3, 90),
      w(9, 28, 86),
      w(9, 29, 86),
    ];

    test('probíhající cut: změna váhy a udržená síla', () {
      final insights = computeInsights(InsightInput(
        now: now,
        periods: [
          (type: PeriodType.cut, start: DateTime(2026, 8, 1), end: null),
        ],
        weights: weights,
        oneRepMaxByExercise: {1: lift},
      ));
      final cut = only<CutSummaryInsight>(insights).single;
      expect(cut.ongoing, isTrue);
      expect(cut.weightChangeKg, closeTo(-4, 0.001));
      expect(cut.strengthKeptPercent, closeTo(95, 0.001));
    });

    test('bez sledování váhy jen síla', () {
      final insights = computeInsights(InsightInput(
        now: now,
        trackWeight: false,
        periods: [
          (type: PeriodType.cut, start: DateTime(2026, 8, 1), end: null),
        ],
        weights: weights,
        oneRepMaxByExercise: {1: lift},
      ));
      final cut = only<CutSummaryInsight>(insights).single;
      expect(cut.weightChangeKg, isNull);
      expect(cut.strengthKeptPercent, isNotNull);
    });

    test('skončený bulk: přírůstek váhy a síly', () {
      final insights = computeInsights(InsightInput(
        now: now,
        periods: [
          (
            type: PeriodType.bulk,
            start: DateTime(2026, 7, 1),
            end: DateTime(2026, 9, 20),
          ),
        ],
        weights: [
          w(7, 1, 80),
          w(7, 2, 80),
          w(9, 18, 83),
          w(9, 19, 83),
        ],
        oneRepMaxByExercise: {
          1: [p(6, 10, 100), p(8, 1, 105), p(9, 15, 110)],
        },
      ));
      final bulk = only<BulkSummaryInsight>(insights).single;
      expect(bulk.ongoing, isFalse);
      expect(bulk.weightChangeKg, closeTo(3, 0.001));
      expect(bulk.strengthChangePercent, closeTo(10, 0.001));
    });

    test('krátká dieta (< 14 dní) se nevyhodnocuje', () {
      final insights = computeInsights(InsightInput(
        now: now,
        periods: [
          (type: PeriodType.cut, start: DateTime(2026, 9, 25), end: null),
        ],
        weights: weights,
        oneRepMaxByExercise: {1: lift},
      ));
      expect(only<CutSummaryInsight>(insights), isEmpty);
    });
  });

  group('rekordy tento měsíc', () {
    test('počet a největší zlepšení', () {
      final insights = computeInsights(InsightInput(
        now: now,
        oneRepMaxByExercise: {
          1: [p(8, 10, 100), p(9, 15, 105)],
          2: [p(8, 10, 50), p(9, 16, 60)],
          3: [p(8, 10, 80), p(9, 16, 79)],
          // První trénink vůbec není rekord.
          4: [p(9, 10, 40)],
        },
      ));
      final r = only<MonthRecordsInsight>(insights).single;
      expect(r.count, 2);
      expect(r.bestExerciseId, 2);
      expect(r.bestOneRepMax, 60);
      expect(r.bestGainPercent, closeTo(20, 0.001));
    });
  });

  group('pravidelnost', () {
    test('průměr za 4 týdny vs. plán', () {
      final insights = computeInsights(InsightInput(
        now: now,
        sessionDates: [
          DateTime(2026, 1, 5),
          for (var d = 0; d < 8; d++) DateTime(2026, 9, 3 + d * 3),
        ],
        weekdayMasks: [0x15], // po, st, pá
      ));
      final c = only<ConsistencyInsight>(insights).single;
      expect(c.averagePerWeek, closeTo(2, 0.001));
      expect(c.plannedPerWeek, 3);
      expect(c.onTrack, isFalse);
    });

    test('nový uživatel: průměr jen od prvního tréninku', () {
      final insights = computeInsights(InsightInput(
        now: now,
        sessionDates: [DateTime(2026, 9, 17), DateTime(2026, 9, 24)],
      ));
      final c = only<ConsistencyInsight>(insights).single;
      // 14 dní = 2 týdny
      expect(c.averagePerWeek, closeTo(1, 0.001));
      expect(c.onTrack, isTrue);
    });
  });

  group('zanedbaná partie', () {
    final sessions = <GroupSession>[
      (day: DateTime(2026, 8, 1), group: MuscleGroup.legs),
      (day: DateTime(2026, 8, 8), group: MuscleGroup.legs),
      (day: DateTime(2026, 8, 15), group: MuscleGroup.legs),
      (day: DateTime(2026, 8, 1), group: MuscleGroup.chest),
      (day: DateTime(2026, 8, 8), group: MuscleGroup.chest),
      (day: DateTime(2026, 8, 15), group: MuscleGroup.chest),
      (day: DateTime(2026, 9, 25), group: MuscleGroup.chest),
    ];
    final dates = [
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 8),
      DateTime(2026, 8, 15),
      DateTime(2026, 9, 25),
    ];

    test('partie bez tréninku 14 dní', () {
      final insights = computeInsights(InsightInput(
        now: now,
        groupSessions: sessions,
        sessionDates: dates,
      ));
      final n = only<NeglectedGroupInsight>(insights).single;
      expect(n.group, MuscleGroup.legs);
      expect(n.daysSince, 46);
    });

    test('zraněná partie se nehlásí', () {
      final insights = computeInsights(InsightInput(
        now: now,
        groupSessions: sessions,
        sessionDates: dates,
        injuredGroups: {MuscleGroup.legs},
      ));
      expect(only<NeglectedGroupInsight>(insights), isEmpty);
    });

    test('bez jakéhokoli tréninku za 14 dní se nehlásí', () {
      final insights = computeInsights(InsightInput(
        now: now,
        groupSessions: sessions.take(6).toList(),
        sessionDates: dates.take(3).toList(),
      ));
      expect(only<NeglectedGroupInsight>(insights), isEmpty);
    });
  });

  group('rychlé hubnutí', () {
    final fast = [
      w(9, 10, 80),
      w(9, 12, 80),
      w(9, 25, 78),
      w(9, 28, 78),
    ];

    test('úbytek nad 1 % týdně', () {
      expect(weeklyWeightLossPercent(fast, now), closeTo(1.25, 0.001));
      final insights = computeInsights(InsightInput(now: now, weights: fast));
      final d = only<WeightDropInsight>(insights).single;
      expect(d.percentPerWeek, closeTo(1.25, 0.001));
      // Varování je nejdůležitější.
      expect(insights.first, isA<WeightDropInsight>());
    });

    test('pomalé hubnutí je v pořádku', () {
      final slow = [w(9, 10, 80), w(9, 12, 80), w(9, 25, 79.5), w(9, 28, 79.5)];
      final insights = computeInsights(InsightInput(now: now, weights: slow));
      expect(only<WeightDropInsight>(insights), isEmpty);
    });

    test('bez sledování váhy nic', () {
      final insights = computeInsights(
        InsightInput(now: now, weights: fast, trackWeight: false),
      );
      expect(only<WeightDropInsight>(insights), isEmpty);
    });

    test('málo vážení = bez odhadu', () {
      expect(weeklyWeightLossPercent([w(9, 10, 80), w(9, 28, 78)], now), isNull);
    });
  });

  test('nejvýš 5 postřehů seřazených podle důležitosti', () {
    final insights = computeInsights(InsightInput(
      now: now,
      periods: [
        (type: PeriodType.cut, start: DateTime(2026, 8, 1), end: null),
      ],
      weights: [
        w(8, 1, 90),
        w(8, 2, 90),
        w(9, 10, 88),
        w(9, 12, 88),
        w(9, 25, 85),
        w(9, 28, 85),
      ],
      oneRepMaxByExercise: {
        1: [p(7, 10, 100), p(8, 15, 97), p(9, 20, 101)],
      },
      groupSessions: [
        (day: DateTime(2026, 8, 1), group: MuscleGroup.legs),
        (day: DateTime(2026, 8, 8), group: MuscleGroup.legs),
        (day: DateTime(2026, 8, 15), group: MuscleGroup.legs),
        (day: DateTime(2026, 8, 1), group: MuscleGroup.back),
        (day: DateTime(2026, 8, 8), group: MuscleGroup.back),
        (day: DateTime(2026, 8, 15), group: MuscleGroup.back),
      ],
      sessionDates: [DateTime(2026, 8, 1), DateTime(2026, 9, 25)],
      weekdayMasks: [0x15],
    ));
    expect(insights.length, 5);
    for (var i = 1; i < insights.length; i++) {
      expect(insights[i - 1].priority >= insights[i].priority, isTrue);
    }
    expect(insights.first, isA<WeightDropInsight>());
  });

  test('mainLifts: nejčastější cviky s aspoň 3 tréninky', () {
    final lifts = mainLifts({
      1: [p(9, 1, 1), p(9, 2, 1), p(9, 3, 1)],
      2: [p(9, 1, 1), p(9, 2, 1), p(9, 3, 1), p(9, 4, 1)],
      3: [p(9, 1, 1), p(9, 2, 1)],
      4: [(x: DateTime(2025, 1, 1), y: 1.0), (x: DateTime(2025, 1, 2), y: 1.0),
          (x: DateTime(2025, 1, 3), y: 1.0)],
    }, now);
    expect(lifts, [2, 1]);
  });
}
