// Připomínky pití podle toho, kolik ještě chybí (lib/core/water_pace.dart).
import 'package:fitness_app/core/water_pace.dart';
import 'package:flutter_test/flutter_test.dart';

String _hm(DateTime d) =>
    '${d.hour}:${d.minute.toString().padLeft(2, '0')}';

void main() {
  test('poslední pití = večerka mínus pauza před spaním', () {
    expect(
        lastDrinkMinutes(
            startMinutes: 540, bedtimeMinutes: 1350, stopBeforeBedMinutes: 90),
        1260); // 22:30 − 1,5 h = 21:00
    // Večerka po půlnoci: 0:30 − 1,5 h = 23:00.
    expect(
        lastDrinkMinutes(
            startMinutes: 540, bedtimeMinutes: 30, stopBeforeBedMinutes: 90),
        1380);
    // Nejpozději 23:55, nejdřív začátek.
    expect(
        lastDrinkMinutes(
            startMinutes: 540, bedtimeMinutes: 120, stopBeforeBedMinutes: 0),
        1435);
    expect(
        lastDrinkMinutes(
            startMinutes: 540, bedtimeMinutes: 600, stopBeforeBedMinutes: 120),
        540);
  });

  test('17:35, vypito 1750 z 3000: 5× po 250 ml do 21:00', () {
    final now = DateTime(2026, 10, 29, 17, 35);
    final plan = planWaterReminders(
      now: now,
      day: now,
      startMinutes: 540,
      lastDrinkMinutes: 1260,
      goalMl: 3000,
      drunkMl: 1750,
      glassMl: 250,
    );
    expect(plan.map((r) => _hm(r.at)),
        ['17:55', '18:40', '19:25', '20:15', '21:00']);
    expect(plan.map((r) => r.amountMl), everyElement(250));
    expect(plan.fold<int>(0, (a, r) => a + r.amountMl),
        greaterThanOrEqualTo(1250));
  });

  test('celý den: sklenice zhruba každou hodinu od začátku', () {
    final now = DateTime(2026, 10, 29, 7);
    final plan = planWaterReminders(
      now: now,
      day: now,
      startMinutes: 540,
      lastDrinkMinutes: 1260,
      goalMl: 3000,
      drunkMl: 0,
      glassMl: 250,
    );
    expect(plan, hasLength(12));
    expect(_hm(plan.first.at), '9:00');
    expect(_hm(plan.last.at), '21:00');
  });

  test('málo času: nejvýš jednou za 30 min, víc na jednou', () {
    final now = DateTime(2026, 10, 29, 20);
    final plan = planWaterReminders(
      now: now,
      day: now,
      startMinutes: 540,
      lastDrinkMinutes: 1260,
      goalMl: 3000,
      drunkMl: 1500,
      glassMl: 250,
    );
    // 20:20–21:00 = 40 min → 2 připomínky po 750 ml.
    expect(plan.map((r) => _hm(r.at)), ['20:20', '21:00']);
    expect(plan.map((r) => r.amountMl), [750, 750]);
  });

  test('cíl splněný nebo po posledním pití – nic', () {
    final now = DateTime(2026, 10, 29, 15);
    List<WaterReminder> plan(DateTime now, int drunk) => planWaterReminders(
          now: now,
          day: now,
          startMinutes: 540,
          lastDrinkMinutes: 1260,
          goalMl: 3000,
          drunkMl: drunk,
          glassMl: 250,
        );
    expect(plan(now, 3000), isEmpty);
    expect(plan(DateTime(2026, 10, 29, 20, 50), 1000), isEmpty);
  });

  test('další den se plánuje na celý cíl bez ohledu na čas', () {
    final now = DateTime(2026, 10, 29, 22);
    final plan = planWaterReminders(
      now: now,
      day: DateTime(2026, 10, 30),
      startMinutes: 480,
      lastDrinkMinutes: 1200,
      goalMl: 2000,
      drunkMl: 0,
      glassMl: 500,
    );
    expect(plan, hasLength(4));
    expect(plan.first.at, DateTime(2026, 10, 30, 8));
    expect(plan.map((r) => r.amountMl), everyElement(500));
  });
}
