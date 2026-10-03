import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dny v týdnu jsou v masce uloženy jako bity: 0 = pondělí ... 6 = neděle.
bool isWeekdayInMask(int mask, int dayIndex) => mask & (1 << dayIndex) != 0;

int toggleWeekday(int mask, int dayIndex) => mask ^ (1 << dayIndex);

/// Index dne (0 = pondělí) z DateTime.weekday (1 = pondělí ... 7 = neděle).
int dayIndexOf(DateTime date) => date.weekday - 1;

/// Krátké názvy dnů od pondělí v jazyce aplikace („po“, „út“ … / „Mon“ …).
List<String> shortWeekdayNames(BuildContext context) {
  final format = DateFormat.E(Localizations.localeOf(context).toString());
  // 1. 1. 2024 bylo pondělí.
  return [for (var i = 0; i < 7; i++) format.format(DateTime(2024, 1, 1 + i))];
}

/// „po, st, pá“ – popis dnů v masce.
String describeWeekdays(BuildContext context, int mask) {
  final names = shortWeekdayNames(context);
  return [
    for (var i = 0; i < 7; i++)
      if (isWeekdayInMask(mask, i)) names[i],
  ].join(', ');
}

/// Minuty od půlnoci → čas podle nastavení zařízení („17:30“).
String formatMinutesOfDay(BuildContext context, int minutes) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
