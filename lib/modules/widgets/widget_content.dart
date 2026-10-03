// Čistá logika widgetu na ploše (bez Flutteru a pluginů) – kvůli testům.

import 'package:intl/intl.dart';

/// Schéma odkazů z widgetu. Záměrně jiné než kAppLinkScheme (fitnessapp),
/// aby odkaz z widgetu nezpracoval i posluchač app_links (deep_links.dart)
/// a voda se nepřičetla dvakrát.
const kWidgetUriScheme = 'homewidget';

/// Hosty odkazů: homewidget://open, homewidget://water?ml=250&n=<nonce>
const kWidgetHostOpen = 'open';
const kWidgetHostWater = 'water';

/// Plně kvalifikovaný název AppWidgetProvideru (zapisuje ho
/// tool/platform/widgets.dart vedle MainActivity.kt).
const kAndroidWidgetClass = 'cz.dedina.fitness_app.FitnessWidgetProvider';

/// Klíče dat widgetu (SharedPreferences pluginu home_widget). Všechny
/// hodnoty jsou řetězce; nativní strana je jen zobrazuje.
abstract final class WidgetKeys {
  static const title = 'fw_title';
  static const day = 'fw_day';
  static const workout = 'fw_workout';
  static const water = 'fw_water';
  static const percent = 'fw_percent';
  // Varianta na zítřek – widget ji po půlnoci ukáže sám, i když aplikace
  // mezitím neběžela (překresluje se každých 30 min).
  static const dayNext = 'fw_day_next';
  static const workoutNext = 'fw_workout_next';
  static const waterNext = 'fw_water_next';
  static const percentNext = 'fw_percent_next';
  static const waterVisible = 'fw_water_visible';
  static const glassMl = 'fw_glass_ml';
  static const addLabel = 'fw_add_label';
  static const addDescription = 'fw_add_desc';

  /// Poslední zpracovaný „nonce“ tlačítka +sklenice (viz [shouldAddWater]).
  static const lastWaterNonce = 'fw_last_water_nonce';
}

/// Den ve tvaru, který porovnává Kotlin (yyyy-MM-dd, místní čas).
String widgetDayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// 1250 → „1 250“ (cs) / „1,250“ (en).
String formatMl(int ml, String locale) =>
    NumberFormat.decimalPattern(locale).format(ml);

/// Procento splnění cíle 0–100.
int waterPercent(int current, int goal) {
  if (goal <= 0) return current > 0 ? 100 : 0;
  return (current * 100 / goal).round().clamp(0, 100);
}

/// Množství z odkazu widgetu; nesmyslné hodnoty nahradí velikostí sklenice.
int parseWidgetMl(Uri uri, int fallback) {
  final ml = int.tryParse(uri.queryParameters['ml'] ?? '');
  if (ml == null || ml <= 0 || ml > 2000) return fallback;
  return ml;
}

/// Má se voda z odkazu přičíst?
///
/// Widget do odkazu dává čas svého vykreslení (`n`). Android po obnovení
/// aplikace z posledních aplikací může znovu doručit původní intent –
/// stejný nebo starší nonce proto přeskočíme. Odkaz bez nonce se přičte.
bool shouldAddWater(int? nonce, int? lastHandled) {
  if (nonce == null) return true;
  return lastHandled == null || nonce > lastHandled;
}
