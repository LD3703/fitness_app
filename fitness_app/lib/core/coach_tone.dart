// Tón zpráv: přátelský, nebo „přísný trenér“ (čistý Dart, testy:
// test/coach_tone_test.dart).
//
// Přísný tón je hravě sarkastický („Gauč tě určitě vytrénuje sám.“),
// nikdy neuráží postavu, vzhled ani identitu a nepoužívá vulgarismy.
// Zdraví má přednost: při nemoci, zranění, do 7 dní po nemoci a při
// únavě partie ≥ 80 % se nikdy netlačí do tréninku – použije se
// přátelský / podpůrný text. Přehled textů: docs/coach_tone.md.

import 'fatigue.dart';
import 'wellbeing.dart';

enum CoachTone { friendly, strict }

/// Hodnota z profilu (UserProfile.coachTone): 0 = přátelský, 1 = přísný.
CoachTone coachToneOf(int? value) =>
    value == 1 ? CoachTone.strict : CoachTone.friendly;

/// Nejvyšší únava ze všech partií (0, když není žádná).
double maxFatiguePercent(FatigueReport report) {
  var max = 0.0;
  for (final p in report.percent.values) {
    if (p > max) max = p;
  }
  return max;
}

/// Smí se v této situaci použít přísný tón? Ne při nemoci, zranění,
/// zotavování po nemoci ani při únavě ≥ [fatigueWarningPercent].
/// [maxFatigue] null = únava se neověřuje (zprávy, které k tréninku
/// netlačí, např. pití).
bool strictToneAllowed(
  WellbeingSituation situation, {
  double? maxFatigue,
}) {
  final healthy = switch (situation) {
    WellbeingSituation.illness ||
    WellbeingSituation.injury ||
    WellbeingSituation.recovery =>
      false,
    WellbeingSituation.cut || WellbeingSituation.normal => true,
  };
  if (!healthy) return false;
  return maxFatigue == null || maxFatigue < fatigueWarningPercent;
}

/// Tón, který se opravdu použije (přísný jen když je zvolený a dovolený).
CoachTone effectiveCoachTone(
  CoachTone chosen,
  WellbeingSituation situation, {
  double? maxFatigue,
}) =>
    chosen == CoachTone.strict &&
            strictToneAllowed(situation, maxFatigue: maxFatigue)
        ? CoachTone.strict
        : CoachTone.friendly;

