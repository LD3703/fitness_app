/// Připomínky pití podle toho, kolik ještě chybí (čistý Dart, testy:
/// test/water_pace_test.dart).
///
/// Zbytek do cíle se rozloží rovnoměrně do času, kdy se ještě pije: od
/// začátku připomínek (nebo od teď) do posledního pití = večerka mínus
/// pauza před spaním (výchozí 22:30 − 1,5 h = 21:00, ať se v noci nechodí
/// na záchod). Připomínek je tolik, kolik je potřeba sklenic (velikost
/// sklenice z profilu), nejvýš jedna za 30 minut – když je času málo,
/// každá doporučí víc. Po každém zápisu vody se zbytek dne přepočítá
/// (NotificationService.reschedule), takže kdo pije napřed, dostane
/// připomínek méně, kdo zaostává, víc.
library;

/// Jedna připomínka: kdy a kolik vypít (ml).
typedef WaterReminder = ({DateTime at, int amountMl});

/// Ve dny tréninku se cíl pití navýší (karta Dnes, připomínky).
const kTrainingWaterBonusMl = 500;

/// Nejkratší rozestup připomínek.
const kWaterMinGapMinutes = 30;

/// První připomínka nejdřív tolik minut od teď (po zápisu nebo otevření).
const kWaterFirstDelayMinutes = 20;

/// Nejvýš připomínek za den.
const kWaterMaxPerDay = 16;

/// Možnosti „před spaním nepiju“ (minuty).
const kWaterStopBeforeBedOptions = [0, 30, 60, 90, 120];

/// Poslední pití v minutách od půlnoci: večerka mínus pauza před spaním.
/// Večerka po půlnoci (0:30) se bere jako konec dne; výsledek je nejdřív
/// [startMinutes] a nejpozději 23:55.
int lastDrinkMinutes({
  required int startMinutes,
  required int bedtimeMinutes,
  required int stopBeforeBedMinutes,
}) {
  var bed = bedtimeMinutes;
  if (bed <= startMinutes) bed += 24 * 60;
  return (bed - stopBeforeBedMinutes).clamp(startMinutes, 23 * 60 + 55);
}

int _roundTo5(int minutes) => (minutes / 5).round() * 5;

/// Připomínky na den [day] (od [now], když je to dnes). [drunkMl] = kolik
/// už dnes vypil. Prázdný seznam = cíl splněný nebo už se nepije.
List<WaterReminder> planWaterReminders({
  required DateTime now,
  required DateTime day,
  required int startMinutes,
  required int lastDrinkMinutes,
  required int goalMl,
  required int drunkMl,
  required int glassMl,
}) {
  final remaining = goalMl - drunkMl;
  if (remaining <= 0 || glassMl <= 0) return const [];
  final dayStart = DateTime(day.year, day.month, day.day);
  DateTime at(int minutes) => DateTime(
      dayStart.year, dayStart.month, dayStart.day, minutes ~/ 60, minutes % 60);

  final isToday = dayStart == DateTime(now.year, now.month, now.day);
  var from = startMinutes;
  if (isToday) {
    final soon = now.hour * 60 + now.minute + kWaterFirstDelayMinutes;
    if (soon > from) from = _roundTo5(soon + 2);
  }
  final until = lastDrinkMinutes;
  if (from > until) return const [];

  final window = until - from;
  final glasses = (remaining / glassMl).ceil();
  final count = glasses.clamp(1, window ~/ kWaterMinGapMinutes + 1)
      .clamp(1, kWaterMaxPerDay);
  // Po 50 ml nahoru, ať součet pokryje zbytek.
  final perDrink = ((remaining / count) / 50).ceil() * 50;
  return [
    for (var i = 0; i < count; i++)
      (
        at: at(count == 1 ? from : _roundTo5(from + window * i ~/ (count - 1))),
        amountMl: perDrink,
      ),
  ];
}
