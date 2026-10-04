import 'package:fitness_app/core/progressive_overload.dart';
import 'package:fitness_app/data/enums.dart';
import 'package:flutter_test/flutter_test.dart';

OverloadSet _set(
  DateTime date,
  double weightKg,
  int reps, {
  int exerciseId = 1,
  MuscleGroup group = MuscleGroup.chest,
  bool isWarmup = false,
  bool isDrop = false,
}) =>
    (
      date: date,
      exerciseId: exerciseId,
      group: group,
      weightKg: weightKg,
      reps: reps,
      isWarmup: isWarmup,
      isDrop: isDrop,
    );

OverloadPeriod _period(
  PeriodType type,
  DateTime start, [
  DateTime? end,
  Set<MuscleGroup> injured = const {},
]) =>
    (type: type, start: start, end: end, injuredGroups: injured);

GroupOverload _chest(List<OverloadSet> sets,
    {List<OverloadPeriod> periods = const [], DateTime? now}) {
  final h = computeOverloadHistory(sets, periods, now ?? _now);
  return currentOverload(h).firstWhere((g) => g.group == MuscleGroup.chest);
}

// Středa 30. 9. 2026 (týden od 28. 9.). Dokončené týdny: …, 31. 8., 7. 9.
// (předchozí okno), 14. 9., 21. 9. (poslední okno).
final _now = DateTime(2026, 9, 30, 18);
final _w0 = DateTime(2026, 8, 31, 18); // úterý atd. – jen den v týdnu
final _w1 = DateTime(2026, 9, 8, 18);
final _w2 = DateTime(2026, 9, 15, 18);
final _w3 = DateTime(2026, 9, 22, 18);

void main() {
  group('stav partie', () {
    test('objem +8 % → progres (důvod objem)', () {
      final r = _chest([
        _set(_w0, 100, 10),
        _set(_w1, 100, 10),
        _set(_w2, 100, 10),
        _set(_w2, 10, 8),
        _set(_w3, 100, 10),
        _set(_w3, 10, 8),
      ]);
      expect(r.status, OverloadStatus.progressing);
      expect(r.reasons, hasLength(1));
      expect(r.reasons.single.kind, OverloadReasonKind.volume);
      expect(r.reasons.single.percent, closeTo(8, 0.01));
    });

    test('1RM cviku +4 % při stejném objemu → progres (důvod 1RM)', () {
      final r = _chest([
        for (final d in [_w0, _w1]) ...[_set(d, 100, 10), _set(d, 100, 10)],
        for (final d in [_w2, _w3]) ...[_set(d, 104, 10), _set(d, 96, 10)],
      ]);
      expect(r.status, OverloadStatus.progressing);
      expect(r.reasons, hasLength(1));
      expect(r.reasons.single.kind, OverloadReasonKind.oneRepMax);
      expect(r.reasons.single.exerciseId, 1);
      expect(r.reasons.single.percent, closeTo(4, 0.01));
      expect(r.volumeChangePercent, closeTo(0, 0.001));
    });

    test('nový cvik s vyšším 1RM se nepočítá jako zlepšení (skladba cviků)',
        () {
      final r = _chest([
        for (final d in [_w0, _w1]) ...[_set(d, 100, 10), _set(d, 100, 10)],
        for (final d in [_w2, _w3]) ...[
          _set(d, 100, 10),
          _set(d, 200, 5, exerciseId: 2),
        ],
      ]);
      expect(r.status, OverloadStatus.stagnating);
      expect(r.stagnantWeeks, 1);
      expect(r.tip, isNull);
    });

    test('objem −20 % bez zlepšení 1RM → pokles', () {
      final r = _chest([
        for (final d in [_w0, _w1]) ...[_set(d, 100, 10), _set(d, 100, 10)],
        for (final d in [_w2, _w3]) ...[_set(d, 100, 10), _set(d, 60, 10)],
      ]);
      expect(r.status, OverloadStatus.declining);
      expect(r.reasons.single.kind, OverloadReasonKind.volume);
      expect(r.reasons.single.percent, closeTo(-20, 0.01));
    });

    test('dieta pokles omlouvá → drží', () {
      final r = _chest(
        [
          for (final d in [_w0, _w1]) ...[_set(d, 100, 10), _set(d, 100, 10)],
          for (final d in [_w2, _w3]) ...[_set(d, 100, 10), _set(d, 60, 10)],
        ],
        periods: [_period(PeriodType.cut, DateTime(2026, 9, 14))],
      );
      expect(r.status, OverloadStatus.holding);
      expect(r.inCut, isTrue);
    });

    test('partie trénovaná jen v posledním okně → málo dat', () {
      final r = _chest([_set(_w2, 100, 10), _set(_w3, 100, 10)]);
      expect(r.status, OverloadStatus.insufficientData);
      expect(r.excused, isFalse);
    });

    test('rozcvička se nepočítá, drop série jen do objemu', () {
      final r = _chest([
        _set(_w0, 100, 10),
        _set(_w1, 100, 10),
        for (final d in [_w2, _w3]) ...[
          _set(d, 50, 10, isWarmup: true),
          _set(d, 100, 10),
          _set(d, 120, 10, isDrop: true),
        ],
      ]);
      expect(r.status, OverloadStatus.progressing);
      expect(r.reasons, hasLength(1));
      expect(r.reasons.single.kind, OverloadReasonKind.volume);
      expect(r.reasons.single.percent, closeTo(120, 0.01));
    });

    test('vedlejší partie ani celé tělo se nehodnotí', () {
      final h = computeOverloadHistory([
        for (final d in [_w0, _w1, _w2, _w3])
          _set(d, 24, 15, group: MuscleGroup.fullBody),
      ], const [], _now);
      expect(h.byGroup, isEmpty);
      expect(currentOverload(h), isEmpty);
    });
  });

  group('omluvené týdny', () {
    final sets = [
      _set(DateTime(2026, 8, 25), 100, 10),
      _set(_w0, 100, 10),
      _set(_w1, 110, 10),
      _set(_w3, 110, 10),
    ];

    test('nemoc: týden se z oken vynechá', () {
      final periods = [
        _period(PeriodType.illness, DateTime(2026, 9, 15), DateTime(2026, 9, 16)),
      ];
      final h = computeOverloadHistory(sets, periods, _now);
      final r = currentOverload(h).single;
      // Okna: 21. 9. + 7. 9. vs. 31. 8. + 24. 8. → +10 %.
      expect(r.status, OverloadStatus.progressing);
      expect(r.volumeChangePercent, closeTo(10, 0.01));
      // Samotný týden nemoci je omluvený.
      final ill = h.weeks.indexOf(DateTime(2026, 9, 14));
      expect(h.pausedWeeks[ill], isTrue);
      expect(h.byGroup[MuscleGroup.chest]![ill].excused, isTrue);
      expect(h.outcomeAt(ill), OverloadWeekOutcome.excused);
    });

    test('bez nemoci by šlo o pokles', () {
      final r = _chest(sets);
      expect(r.status, OverloadStatus.declining);
    });

    test('zranění jiné partie týden nevynechá', () {
      final r = _chest(sets, periods: [
        _period(PeriodType.injury, DateTime(2026, 9, 15), DateTime(2026, 9, 17),
            {MuscleGroup.shoulders}),
      ]);
      expect(r.status, OverloadStatus.declining);
    });

    test('zranění této partie týden vynechá', () {
      final r = _chest(sets, periods: [
        _period(PeriodType.injury, DateTime(2026, 9, 15), DateTime(2026, 9, 17),
            {MuscleGroup.chest}),
      ]);
      expect(r.status, OverloadStatus.progressing);
    });
  });

  group('stagnace a tipy', () {
    List<OverloadSet> constant(int weeks, DateTime lastMonday) => [
          for (var i = 0; i < weeks; i++)
            _set(
              DateTime(lastMonday.year, lastMonday.month,
                  lastMonday.day - 7 * i + 1, 18),
              100,
              10,
            ),
        ];

    test('3 týdny stagnace → přidat opakování', () {
      final r = _chest(constant(6, DateTime(2026, 9, 21)));
      expect(r.status, OverloadStatus.stagnating);
      expect(r.stagnantWeeks, 3);
      expect(r.tip, OverloadTip.addReps);
    });

    test('4 týdny → přidat sérii, 5 týdnů → přidat váhu', () {
      final four = _chest(constant(7, DateTime(2026, 9, 28)),
          now: DateTime(2026, 10, 7));
      expect(four.stagnantWeeks, 4);
      expect(four.tip, OverloadTip.addSet);
      final five = _chest(constant(8, DateTime(2026, 10, 5)),
          now: DateTime(2026, 10, 14));
      expect(five.stagnantWeeks, 5);
      expect(five.tip, OverloadTip.addWeight);
    });

    test('v dietě se tip nedává', () {
      final r = _chest(constant(6, DateTime(2026, 9, 21)), periods: [
        _period(PeriodType.cut, DateTime(2026, 9, 1)),
      ]);
      expect(r.status, OverloadStatus.stagnating);
      expect(r.tip, isNull);
    });

    test('overloadTipFor', () {
      expect(overloadTipFor(2), isNull);
      expect(overloadTipFor(3), OverloadTip.addReps);
      expect(overloadTipFor(6), OverloadTip.addReps);
    });
  });

  group('série týdnů a mistrovství', () {
    GroupOverload g(OverloadStatus s,
            {MuscleGroup group = MuscleGroup.chest, bool excused = false}) =>
        GroupOverload(
          group: group,
          week: DateTime(2026),
          status: excused ? OverloadStatus.insufficientData : s,
          excused: excused,
        );
    List<DateTime> weeks(int n) =>
        [for (var i = 0; i < n; i++) DateTime(2026, 1, 5 + 7 * i)];

    test('omluvený týden sérii nepřeruší ani neprodlouží', () {
      const p = OverloadStatus.progressing;
      final h = OverloadHistory(
        weeks: weeks(6),
        byGroup: {
          MuscleGroup.chest: [
            g(p),
            g(p),
            g(p),
            g(p),
            g(OverloadStatus.stagnating),
            g(p),
          ],
        },
        pausedWeeks: [false, false, true, false, false, false],
      );
      expect(h.longestStreak, 3);
      expect(h.currentStreak, 1);
    });

    test('pokles jakékoli partie sérii přeruší', () {
      final h = OverloadHistory(
        weeks: weeks(2),
        byGroup: {
          MuscleGroup.chest: [
            g(OverloadStatus.progressing),
            g(OverloadStatus.progressing),
          ],
          MuscleGroup.back: [
            g(OverloadStatus.stagnating, group: MuscleGroup.back),
            g(OverloadStatus.declining, group: MuscleGroup.back),
          ],
        },
        pausedWeeks: [false, false],
      );
      expect(h.outcomeAt(0), OverloadWeekOutcome.extend);
      expect(h.outcomeAt(1), OverloadWeekOutcome.breaks);
      expect(h.longestStreak, 1);
    });

    test('zraněná partie se ignoruje, když jsou zraněné všechny → omluveno',
        () {
      final h = OverloadHistory(
        weeks: weeks(2),
        byGroup: {
          MuscleGroup.chest: [
            g(OverloadStatus.progressing),
            g(OverloadStatus.progressing, excused: true),
          ],
          MuscleGroup.back: [
            g(OverloadStatus.declining, group: MuscleGroup.back, excused: true),
            g(OverloadStatus.declining, group: MuscleGroup.back, excused: true),
          ],
        },
        pausedWeeks: [false, false],
      );
      expect(h.outcomeAt(0), OverloadWeekOutcome.extend);
      expect(h.outcomeAt(1), OverloadWeekOutcome.excused);
    });

    test('mistrovství: 8 týdnů progres/drží, z toho 4 progres', () {
      const p = OverloadStatus.progressing;
      const hold = OverloadStatus.holding;
      final ok = masteryProgress([
        g(p), g(hold), g(p), g(OverloadStatus.progressing, excused: true),
        g(hold), g(p), g(hold), g(p), g(hold),
      ]);
      expect(ok.mastered, isTrue);
      expect(ok.bestRun, masteryWeeks);

      final few = masteryProgress([
        g(p), g(hold), g(hold), g(hold), g(hold), g(p), g(hold), g(p),
      ]);
      expect(few.mastered, isFalse);

      final broken = masteryProgress([
        g(p), g(p), g(p), g(OverloadStatus.stagnating), g(p), g(p), g(p),
        g(p), g(p),
      ]);
      expect(broken.mastered, isFalse);
      expect(broken.bestRun, 5);
    });
  });
}
