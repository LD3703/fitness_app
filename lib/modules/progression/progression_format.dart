import 'package:flutter/widgets.dart';

import '../../core/auto_progression.dart';
import '../../core/coach_tone.dart';
import '../../core/wellbeing.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/format.dart';

/// Text změny: „80 → 82,5 kg × 6“, „+1 opakování (cíl 9)“,
/// „Odlehčení na 72,5 kg × 8“, „Zůstává stejné – …“.
String progressionChangeText(
  BuildContext context,
  ProgressionKind kind,
  ProgressionInfo info,
) {
  final l10n = AppLocalizations.of(context);
  final from = info.fromKg;
  final to = info.toKg;
  switch (kind) {
    case ProgressionKind.increase:
      if (from == null || to == null) return l10n.progressionRepsLine(info.reps);
      return l10n.progressionIncreaseLine(
        formatWeight(context, from),
        formatWeightWithUnit(context, to),
        info.reps,
      );
    case ProgressionKind.reps:
      return info.isDuration
          ? l10n.progressionSecondsLine(info.delta, info.reps)
          : l10n.progressionRepsLine(info.reps);
    case ProgressionKind.deload:
      if (to == null) return l10n.progressionRepsLine(info.reps);
      return l10n.progressionDeloadLine(
        formatWeightWithUnit(context, to),
        info.reps,
      );
    case ProgressionKind.hold:
      return progressionHoldText(l10n, info.holdReason);
  }
}

String progressionHoldText(AppLocalizations l10n, HoldReason? reason) =>
    switch (reason) {
      HoldReason.illness => l10n.progressionHoldIllness,
      HoldReason.recovery => l10n.progressionHoldRecovery,
      HoldReason.injury => l10n.progressionHoldInjury,
      HoldReason.cut || null => l10n.progressionHoldCut,
    };

/// Text uložené události (historie v editoru cviku).
String progressionEventText(BuildContext context, ProgressionEvent event) {
  final info = decodeProgressionState(event.newJson).info ??
      const ProgressionInfo(reps: 0);
  return progressionChangeText(context, event.kind, info);
}

/// Štítek nepoužitého návrhu v editoru plánu („↑ +2,5 kg příště“).
/// Null u „drží“.
String? progressionBadgeText(BuildContext context, ProgressionEvent event) {
  final l10n = AppLocalizations.of(context);
  final info = decodeProgressionState(event.newJson).info;
  if (info == null) return null;
  final from = info.fromKg;
  final to = info.toKg;
  return switch (event.kind) {
    ProgressionKind.increase when from != null && to != null =>
      l10n.progressionBadgeIncrease(formatWeightWithUnit(context, to - from)),
    ProgressionKind.increase => null,
    ProgressionKind.reps => info.isDuration
        ? l10n.progressionBadgeSeconds(info.delta)
        : l10n.progressionBadgeReps,
    ProgressionKind.deload when to != null =>
      l10n.progressionBadgeDeload(formatWeightWithUnit(context, to)),
    ProgressionKind.deload => null,
    ProgressionKind.hold => null,
  };
}

/// Hláška k vyšší váze v souhrnu: přísná jen v přísném tónu (a jen když
/// ho situace dovoluje), jinak přátelská. Varianty se střídají po dnech.
String progressionIncreaseMessage(
  AppLocalizations l10n,
  CoachTone tone,
  DateTime day,
) {
  final options = tone == CoachTone.strict
      ? [
          l10n.progressionStrictIncrease1,
          l10n.progressionStrictIncrease2,
          l10n.progressionStrictIncrease3,
        ]
      : [
          l10n.progressionFriendlyIncrease1,
          l10n.progressionFriendlyIncrease2,
          l10n.progressionFriendlyIncrease3,
        ];
  return options[messageVariant(day, options.length, salt: 21)];
}
