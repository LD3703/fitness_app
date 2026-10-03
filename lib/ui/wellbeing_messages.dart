import '../core/wellbeing.dart';
import '../l10n/app_localizations.dart';

/// Kde se hláška zobrazuje – každé místo má vlastní sadu textů.
enum MessagePlace { today, workout, summary, skip }

/// Povzbuzující hláška pro danou situaci a místo, nebo null,
/// pokud se v dané situaci na tomto místě nic nezobrazuje.
/// Varianta se střídá po dnech, během dne zůstává stejná.
String? wellbeingMessage(
  AppLocalizations l10n,
  WellbeingSituation situation,
  MessagePlace place,
  DateTime day,
) {
  final options = _options(l10n, situation, place);
  if (options.isEmpty) return null;
  return options[messageVariant(day, options.length, salt: place.index)];
}

List<String> _options(
  AppLocalizations l10n,
  WellbeingSituation s,
  MessagePlace place,
) {
  switch (place) {
    case MessagePlace.today:
      return switch (s) {
        WellbeingSituation.illness => [
            l10n.encTodayIllness1,
            l10n.encTodayIllness2,
            l10n.encTodayIllness3,
          ],
        WellbeingSituation.injury => [
            l10n.encTodayInjury1,
            l10n.encTodayInjury2,
          ],
        WellbeingSituation.recovery => [
            l10n.encTodayRecovery1,
            l10n.encTodayRecovery2,
            l10n.encTodayRecovery3,
          ],
        WellbeingSituation.cut => [
            l10n.encTodayCut1,
            l10n.encTodayCut2,
          ],
        WellbeingSituation.normal => const [],
      };
    case MessagePlace.workout:
      return switch (s) {
        WellbeingSituation.illness => [l10n.encWorkoutIllness],
        WellbeingSituation.injury => [l10n.encWorkoutInjury],
        WellbeingSituation.recovery => [
            l10n.encWorkoutRecovery1,
            l10n.encWorkoutRecovery2,
          ],
        WellbeingSituation.cut => [l10n.encWorkoutCut],
        WellbeingSituation.normal => const [],
      };
    case MessagePlace.summary:
      return switch (s) {
        WellbeingSituation.illness ||
        WellbeingSituation.recovery =>
          [l10n.encSummaryRecovery1, l10n.encSummaryRecovery2],
        WellbeingSituation.injury => [l10n.encSummaryInjury],
        WellbeingSituation.cut => [l10n.encSummaryCut],
        WellbeingSituation.normal => const [],
      };
    case MessagePlace.skip:
      return switch (s) {
        WellbeingSituation.illness || WellbeingSituation.injury => [
            l10n.encSkipIllness1,
            l10n.encSkipIllness2,
            l10n.encSkipIllness3,
          ],
        WellbeingSituation.recovery => [l10n.encSkipRecovery],
        WellbeingSituation.cut ||
        WellbeingSituation.normal =>
          [l10n.encSkipNormal1, l10n.encSkipNormal2],
      };
  }
}
