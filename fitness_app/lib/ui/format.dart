import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../data/enums.dart';

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toString();

// ---------------------------------------------------------------------
// Jednotky (kg/lb, ml/oz)
// ---------------------------------------------------------------------
//
// Data se ukládají vždy v kg a ml. Převádí se jen při zobrazení a zadávání.
// Aktuální volbu uživatele drží [unitSystemNotifier]; nastavuje ji modul
// „data“ podle profilu (viz lib/modules/data/units.dart).

/// Jednotky zvolené uživatelem (výchozí metrické).
final unitSystemNotifier = ValueNotifier<UnitSystem>(UnitSystem.metric);

/// 1 lb = 0,45359237 kg (přesně).
const double kgPerLb = 0.45359237;

/// 1 US fl oz = 29,5735 ml.
const double mlPerFlOz = 29.5735;

bool get isImperial => unitSystemNotifier.value == UnitSystem.imperial;

/// Převod z kg do jednotek [unit].
double kgToUnit(double kg, UnitSystem unit) =>
    unit == UnitSystem.imperial ? kg / kgPerLb : kg;

/// Převod z jednotek [unit] na kg.
double unitToKg(double value, UnitSystem unit) =>
    unit == UnitSystem.imperial ? value * kgPerLb : value;

/// Převod z ml do jednotek [unit].
double mlToUnit(num ml, UnitSystem unit) =>
    unit == UnitSystem.imperial ? ml / mlPerFlOz : ml.toDouble();

/// Převod z jednotek [unit] na celé ml.
int unitToMl(double value, UnitSystem unit) =>
    (unit == UnitSystem.imperial ? value * mlPerFlOz : value).round();

/// Zaokrouhlí [value] na [decimals] desetinných míst.
double roundDecimals(double value, int decimals) {
  var f = 1.0;
  for (var i = 0; i < decimals; i++) {
    f *= 10;
  }
  return (value * f).round() / f;
}

/// Zkratka jednotky váhy: „kg“ / „lb“.
String get weightUnit => isImperial ? 'lb' : 'kg';

/// Zkratka jednotky objemu: „ml“ / „oz“.
String get volumeUnit => isImperial ? 'oz' : 'ml';

/// kg → zobrazované jednotky (kg nebo lb).
double kgToDisplay(double kg) => kgToUnit(kg, unitSystemNotifier.value);

/// Zobrazované jednotky → kg.
double displayToKg(double value) => unitToKg(value, unitSystemNotifier.value);

/// ml → zobrazované jednotky (ml nebo oz).
double mlToDisplay(num ml) => mlToUnit(ml, unitSystemNotifier.value);

/// Zobrazované jednotky → ml.
int displayToMl(double value) => unitToMl(value, unitSystemNotifier.value);

/// Krok pro návrhy vah v zobrazovaných jednotkách (kotouče): 2,5 kg / 5 lb.
double get weightDisplayStep => isImperial ? 5 : 2.5;

/// Stejný krok vyjádřený v kg (pro `roundToStep` nad hodnotami v kg).
double get weightStepKg => displayToKg(weightDisplayStep);

/// Váha pro předvyplnění vstupu v zobrazovaných jednotkách (2 desetinná místa).
double weightForInput(double kg) => roundDecimals(kgToDisplay(kg), 2);

/// Text do textového pole pro váhu: 80 → „80“, 82.5 → „82.5“,
/// v librách 60 kg → „132.28“; null → „“.
String weightInputText(double? kg) {
  if (kg == null) return '';
  return plainNumber(weightForInput(kg));
}

/// Váha zadaná uživatelem (v zobrazovaných jednotkách) převedená na kg.
double? parseWeightInput(String text) {
  final v = parseDecimal(text);
  return v == null ? null : displayToKg(v);
}

/// 80.0 → „80“, 82.5 → „82.5“ (bez oddělovačů, pro textová pole).
String plainNumber(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

// ---------------------------------------------------------------------
// Formátování
// ---------------------------------------------------------------------

String _decimalPattern(int maxDecimals) =>
    maxDecimals <= 0 ? '0' : '0.${'#' * maxDecimals}';

/// Číslo s nejvýše [maxDecimals] desetinnými místy podle jazyka.
String formatDecimal(BuildContext context, num value, {int maxDecimals = 2}) =>
    NumberFormat(_decimalPattern(maxDecimals), _locale(context)).format(value);

/// Váha v zobrazovaných jednotkách bez jednotky: 80 → „80“,
/// 82.5 → „82,5“ (v češtině); v librách převedená.
String formatWeight(BuildContext context, double kg, {int maxDecimals = 2}) =>
    formatDecimal(context, kgToDisplay(kg), maxDecimals: maxDecimals);

/// Váha s jednotkou: „82,5 kg“ / „181,88 lb“.
/// [rounded] zaokrouhlí na 0,5 kg / 1 lb (odhady 1RM).
String formatWeightWithUnit(
  BuildContext context,
  double kg, {
  int maxDecimals = 2,
  bool rounded = false,
}) {
  var v = kgToDisplay(kg);
  if (rounded) {
    final step = isImperial ? 1.0 : 0.5;
    v = (v / step).round() * step;
  }
  return '${formatDecimal(context, v, maxDecimals: maxDecimals)} $weightUnit';
}

/// Tělesná váha s jedním desetinným místem: „80,0 kg“ / „176,4 lb“.
String formatBodyWeight(BuildContext context, double kg) =>
    '${NumberFormat('0.0', _locale(context)).format(kgToDisplay(kg))} '
    '$weightUnit';

/// Celkový objem tréninku: „12 500 kg“ / „27 558 lb“.
String formatWeightTotal(BuildContext context, double kg) =>
    '${formatInt(context, kgToDisplay(kg))} $weightUnit';

/// Objem vody jen jako číslo: 250 → „250“ (ml) / „8,5“ (oz).
/// [unit] přebije aktuální volbu (např. podle profilu mimo widgety).
String formatVolumeNumberFor(String locale, num ml, {UnitSystem? unit}) {
  final u = unit ?? unitSystemNotifier.value;
  return u == UnitSystem.imperial
      ? NumberFormat('0.#', locale).format(mlToUnit(ml, u))
      : NumberFormat.decimalPattern(locale).format(ml.round());
}

/// Objem vody s jednotkou pro použití mimo widgety (notifikace).
String formatVolumeFor(String locale, num ml, {UnitSystem? unit}) {
  final u = unit ?? unitSystemNotifier.value;
  return '${formatVolumeNumberFor(locale, ml, unit: u)} '
      '${u == UnitSystem.imperial ? 'oz' : 'ml'}';
}

/// Objem vody jen jako číslo podle jazyka aplikace.
String formatVolumeNumber(BuildContext context, num ml) =>
    formatVolumeNumberFor(_locale(context), ml);

/// Objem vody s jednotkou: „250 ml“ / „8,5 oz“.
String formatVolume(BuildContext context, num ml) =>
    formatVolumeFor(_locale(context), ml);

/// Celé číslo s oddělovačem tisíců: 12500 → „12 500“.
String formatInt(BuildContext context, num value) =>
    NumberFormat.decimalPattern(_locale(context)).format(value.round());

/// 75 s → „1:15“, 3725 s → „1:02:05“.
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// Parsuje číslo zadané uživatelem, přijímá čárku i tečku.
double? parseDecimal(String text) {
  final t = text.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}
