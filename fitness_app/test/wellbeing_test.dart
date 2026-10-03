import 'package:fitness_app/core/wellbeing.dart';
import 'package:fitness_app/data/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 10, 18, 30);

  PeriodSpan span(PeriodType t, DateTime start, [DateTime? end]) =>
      (type: t, start: start, end: end);

  test('bez období je situace normální', () {
    expect(determineSituation(const [], now), WellbeingSituation.normal);
  });

  test('probíhající nemoc', () {
    final periods = [span(PeriodType.illness, DateTime(2026, 10, 8))];
    expect(determineSituation(periods, now), WellbeingSituation.illness);
  });

  test('nemoc končící dnes je stále nemoc', () {
    final periods = [
      span(PeriodType.illness, DateTime(2026, 10, 5), DateTime(2026, 10, 10)),
    ];
    expect(determineSituation(periods, now), WellbeingSituation.illness);
  });

  test('3 dny po nemoci = zotavování', () {
    final periods = [
      span(PeriodType.illness, DateTime(2026, 10, 1), DateTime(2026, 10, 7)),
    ];
    expect(determineSituation(periods, now), WellbeingSituation.recovery);
  });

  test('8 dní po nemoci už je normální stav', () {
    final periods = [
      span(PeriodType.illness, DateTime(2026, 9, 25), DateTime(2026, 10, 2)),
    ];
    expect(determineSituation(periods, now), WellbeingSituation.normal);
  });

  test('nemoc má přednost před dietou', () {
    final periods = [
      span(PeriodType.cut, DateTime(2026, 9, 1)),
      span(PeriodType.illness, DateTime(2026, 10, 9)),
    ];
    expect(determineSituation(periods, now), WellbeingSituation.illness);
  });

  test('zotavování má přednost před dietou', () {
    final periods = [
      span(PeriodType.cut, DateTime(2026, 9, 1)),
      span(PeriodType.illness, DateTime(2026, 10, 1), DateTime(2026, 10, 8)),
    ];
    expect(determineSituation(periods, now), WellbeingSituation.recovery);
  });

  test('budoucí období se nepočítá', () {
    final periods = [span(PeriodType.injury, DateTime(2026, 10, 12))];
    expect(determineSituation(periods, now), WellbeingSituation.normal);
  });

  test('varianta hlášky je během dne stejná a střídá se', () {
    final a = messageVariant(DateTime(2026, 10, 10, 8), 3);
    final b = messageVariant(DateTime(2026, 10, 10, 22), 3);
    final c = messageVariant(DateTime(2026, 10, 11, 8), 3);
    expect(a, b);
    expect(c, isNot(a));
    expect(a, inInclusiveRange(0, 2));
  });

  test('daysBetween přes změnu času', () {
    expect(daysBetween(DateTime(2026, 10, 24), DateTime(2026, 10, 26)), 2);
  });
}
