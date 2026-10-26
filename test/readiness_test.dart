import 'dart:math' as math;

import 'package:fitness_app/core/readiness.dart';
import 'package:fitness_app/data/enums.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = DateTime(2026, 10, 26);

DateTime _ago(int days) =>
    DateTime(_today.year, _today.month, _today.day - days);

/// 60 dní „normálu“: HRV kolem 60 ms (±5 %), tep 55, spánek 7,5 h.
List<RecoveryDay> _baseline({int days = 60}) => [
      for (var i = 1; i <= days; i++)
        RecoveryDay(
          day: _ago(i),
          hrvMs: 60 * (1 + 0.05 * math.sin(i.toDouble())),
          restingHr: 55 + (i % 3 - 1).toDouble(),
          sleepMinutes: 450,
        ),
    ];

List<RecoveryDay> _with(List<RecoveryDay> recent, {int baseDays = 60}) => [
      ..._baseline(days: baseDays)
          .where((b) => !recent.any((r) => r.day == b.day)),
      ...recent,
    ];

void main() {
  group('připravenost', () {
    test('bez dat za poslední 2 dny nic', () {
      expect(evaluateReadiness(_baseline().skip(2).toList(), _today), isNull);
    });

    test('vše v normálu = dobrá připravenost', () {
      final r = evaluateReadiness(
        _with([
          RecoveryDay(day: _today, hrvMs: 61, restingHr: 55, sleepMinutes: 470)
        ]),
        _today,
      )!;
      expect(r.level, ReadinessLevel.good);
      expect(r.factors, isEmpty);
      expect(r.advice, ReadinessAdvice.train);
      expect(r.learning, isFalse);
      expect(r.hrvNormalMs!.low, lessThan(60));
      expect(r.hrvNormalMs!.high, greaterThan(60));
      expect(r.restingHrBaseline, closeTo(55, 0.5));
    });

    test('málo dat: HRV a tep se nehodnotí, spánek ano', () {
      final r = evaluateReadiness(
        _with([
          RecoveryDay(day: _today, hrvMs: 30, restingHr: 70, sleepMinutes: 290),
        ], baseDays: 10),
        _today,
      )!;
      expect(r.learning, isTrue);
      expect(r.baselineDays, 10);
      expect(r.factors, [ReadinessFactor.sleepVeryShort]);
      expect(r.level, ReadinessLevel.caution);
    });

    test('HRV 7 dní pod normálem + zvýšený tep = slabší regenerace', () {
      final r = evaluateReadiness(
        _with([
          for (var i = 0; i < 7; i++)
            RecoveryDay(
                day: _ago(i), hrvMs: 48, restingHr: 56, sleepMinutes: 450),
          RecoveryDay(day: _today, hrvMs: 47, restingHr: 61, sleepMinutes: 450),
        ]),
        _today,
      )!;
      expect(r.factors, contains(ReadinessFactor.hrvLow));
      expect(r.factors, contains(ReadinessFactor.restingHrElevated));
      expect(r.level, ReadinessLevel.low);
      expect(r.advice, ReadinessAdvice.lighter);
    });

    test('jedna horší noc HRV = jen varování', () {
      final r = evaluateReadiness(
        _with([
          RecoveryDay(day: _today, hrvMs: 40, restingHr: 55, sleepMinutes: 450)
        ]),
        _today,
      )!;
      expect(r.factors, [ReadinessFactor.hrvDrop]);
      expect(r.level, ReadinessLevel.caution);
      expect(r.advice, ReadinessAdvice.trainEasy);
    });

    test('tep 3 dny zvýšený a dnes o 10+ = odpočinek', () {
      final r = evaluateReadiness(
        _with([
          RecoveryDay(day: _ago(2), restingHr: 61),
          RecoveryDay(day: _ago(1), restingHr: 62),
          RecoveryDay(day: _today, restingHr: 66, sleepMinutes: 450),
        ]),
        _today,
      )!;
      expect(r.factors, [
        ReadinessFactor.restingHrHigh,
        ReadinessFactor.restingHrSustained,
      ]);
      expect(r.level, ReadinessLevel.low);
      expect(r.advice, ReadinessAdvice.rest);
    });

    test('spánek: pod 7 h jen informace, dluh za 3 noci', () {
      final r = evaluateReadiness(
        _with([
          RecoveryDay(day: _ago(2), sleepMinutes: 330),
          RecoveryDay(day: _ago(1), sleepMinutes: 340),
          RecoveryDay(day: _today, sleepMinutes: 400, hrvMs: 60, restingHr: 55),
        ]),
        _today,
      )!;
      expect(
          r.factors, [ReadinessFactor.sleepBelow, ReadinessFactor.sleepDebt]);
      expect(r.sleepDebtMinutes, 90 + 80 + 20);
      expect(r.level, ReadinessLevel.caution);
    });
  });

  group('denní hodnoty ze vzorků', () {
    test('spánek z prstenu a hodinek se nesečte dvakrát', () {
      final night = DateTime(2026, 10, 25, 23);
      final minutes = sleepMinutesForDay([
        (start: night, end: night.add(const Duration(hours: 7))),
        (
          start: night.add(const Duration(minutes: 30)),
          end: night.add(const Duration(hours: 7, minutes: 30)),
        ),
        // Odpolední spánek předchozího dne se nepočítá.
        (start: DateTime(2026, 10, 25, 14), end: DateTime(2026, 10, 25, 15)),
      ], _today);
      expect(minutes, 7 * 60 + 30);
    });

    test('HRV medián v noci, klidový tep během dne', () {
      final samples = [
        (at: DateTime(2026, 10, 26, 2), value: 50.0),
        (at: DateTime(2026, 10, 26, 3), value: 70.0),
        (at: DateTime(2026, 10, 26, 4), value: 60.0),
        (at: DateTime(2026, 10, 26, 16), value: 20.0), // odpoledne ne
      ];
      expect(hrvForDay(samples, _today), 60);
      expect(
        restingHrForDay([
          (at: DateTime(2026, 10, 26, 7), value: 54.0),
          (at: DateTime(2026, 10, 25, 7), value: 70.0),
        ], _today),
        54,
      );
    });
  });

  group('tep během tréninku', () {
    test('průměr, maximum a zóny', () {
      final start = DateTime(2026, 10, 26, 18);
      final samples = [
        for (var i = 0; i <= 60; i++)
          (
            at: start.add(Duration(seconds: 30 * i)),
            value: i < 30 ? 120.0 : 160.0,
          ),
      ];
      final hr = summarizeHeartRate(samples,
          start: start, end: start.add(const Duration(minutes: 30)), age: 30)!;
      expect(hr.max, 160);
      expect(hr.average, closeTo(140, 2));
      // Max. tep 187: 120 = 64 % (zóna 2), 160 = 86 % (zóna 4).
      expect(hr.zoneSeconds[2], 900);
      expect(hr.zoneSeconds[4], greaterThan(890));
      expect(HeartRateSummary.zonesFromText(hr.zonesText), hr.zoneSeconds);
    });

    test('málo vzorků = nic', () {
      final t = DateTime(2026, 10, 26, 18);
      expect(
          summarizeHeartRate([(at: t, value: 100.0)],
              start: t, end: t.add(const Duration(minutes: 1))),
          isNull);
    });

    test('Tanaka a Keytel', () {
      expect(estimatedMaxHr(40), 180);
      final kcal = heartRateKcal(
          avgHr: 130, minutes: 60, weightKg: 80, age: 30, sex: Sex.male)!;
      // (−55,0969 + 82,017 + 15,904 + 6,051) × 60 / 4,184 ≈ 700
      expect(kcal, closeTo(700, 5));
      expect(
          heartRateKcal(
              avgHr: 130, minutes: 60, weightKg: 80, age: null, sex: Sex.male),
          isNull);
    });
  });

  test('lehčí trénink: o třetinu méně pracovních sérií', () {
    final sets = ['w', 'p', 'p', 'p', 'p', 'd'];
    expect(lighterTargets(sets, isWorking: (s) => s == 'p'),
        ['w', 'p', 'p', 'p', 'd']);
    final six = ['p', 'p', 'p', 'p', 'p', 'p'];
    expect(lighterTargets(six, isWorking: (s) => s == 'p'), hasLength(4));
    expect(lighterTargets(['p', 'p'], isWorking: (s) => s == 'p'), ['p', 'p']);
  });
}
