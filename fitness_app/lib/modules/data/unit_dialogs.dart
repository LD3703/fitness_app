import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/number_input_dialog.dart';

/// Dialog pro zadání váhy ve zvolených jednotkách (kg / lb).
/// Rozsah [minKg]–[maxKg] se převede a zaokrouhlí na celé jednotky.
/// Vrací váhu v kg, nebo null při zrušení.
Future<double?> showWeightInputDialog(
  BuildContext context, {
  required String title,
  required double minKg,
  required double maxKg,
  double? initialKg,
}) async {
  final l10n = AppLocalizations.of(context);
  final min = kgToDisplay(minKg).floorToDouble();
  final max = kgToDisplay(maxKg).ceilToDouble();
  final value = await showNumberInputDialog(
    context,
    title: title,
    min: min,
    max: max,
    errorText: l10n.dataRangeInvalid(
      formatDecimal(context, min, maxDecimals: 0),
      formatDecimal(context, max, maxDecimals: 0),
    ),
    initialValue: initialKg == null ? null : weightForInput(initialKg),
  );
  if (value == null) return null;
  return displayToKg(value).clamp(minKg, maxKg).toDouble();
}

/// Dialog pro zadání objemu ve zvolených jednotkách (ml / oz).
/// Vrací objem v ml, nebo null při zrušení.
Future<int?> showVolumeInputDialog(
  BuildContext context, {
  required String title,
  required int minMl,
  required int maxMl,
  int? initialMl,
}) async {
  final l10n = AppLocalizations.of(context);
  final min = math.max(1.0, mlToDisplay(minMl).floorToDouble());
  final max = mlToDisplay(maxMl).ceilToDouble();
  final value = await showNumberInputDialog(
    context,
    title: title,
    min: min,
    max: max,
    errorText: l10n.dataRangeInvalid(
      formatDecimal(context, min, maxDecimals: 0),
      formatDecimal(context, max, maxDecimals: 0),
    ),
    initialValue:
        initialMl == null ? null : mlToDisplay(initialMl).roundToDouble(),
    allowDecimals: false,
  );
  if (value == null) return null;
  return displayToMl(value).clamp(minMl, maxMl).toInt();
}
