import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/coach_tone.dart';
import '../core/wellbeing.dart';
import '../features/fatigue/fatigue_providers.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';

// Přísné varianty textů („přísný trenér“, UserProfile.coachTone = 1).
// Volající si nejdřív zjistí skutečný tón (effectiveCoachTone /
// resolveCoachTone) – při nemoci, zranění, zotavování nebo únavě ≥ 80 %
// je vždy přátelský. Varianty se střídají po dnech (messageVariant).

String _pick(List<String> options, DateTime day, int salt) =>
    options[messageVariant(day, options.length, salt: salt)];

/// Hláška po vynechání / odložení tréninku.
String strictSkipMessage(AppLocalizations l10n, DateTime day) => _pick(
      [
        l10n.coachSkip1,
        l10n.coachSkip2,
        l10n.coachSkip3,
        l10n.coachSkip4,
        l10n.coachSkip5,
      ],
      day,
      11,
    );

/// Text ranní připomínky ([plans] = názvy plánů).
String strictMorningBody(AppLocalizations l10n, String plans, DateTime day) =>
    _pick(
      [
        l10n.coachMorning1(plans),
        l10n.coachMorning2(plans),
        l10n.coachMorning3(plans),
        l10n.coachMorning4(plans),
        l10n.coachMorning5(plans),
      ],
      day,
      12,
    );

/// Text připomínky pití; [slot] = pořadí připomínky ve dni (střídání).
String strictWaterBody(
  AppLocalizations l10n,
  String goal,
  DateTime day,
  int slot,
) =>
    _pick(
      [
        l10n.coachWater1(goal),
        l10n.coachWater2(goal),
        l10n.coachWater3(goal),
        l10n.coachWater4(goal),
        l10n.coachWater5(goal),
      ],
      day,
      13 + slot,
    );

/// Nabídka přesunu tréninku po plánu B.
String strictPlanBPostpone(
  AppLocalizations l10n,
  String plan,
  DateTime day,
) =>
    _pick(
      [
        l10n.coachPlanBPostpone1(plan),
        l10n.coachPlanBPostpone2(plan),
        l10n.coachPlanBPostpone3(plan),
      ],
      day,
      14,
    );

/// Hláška po dokončení plánu B.
String strictPlanBDone(AppLocalizations l10n, DateTime day) =>
    _pick(
      [l10n.coachPlanBDone1, l10n.coachPlanBDone2, l10n.coachPlanBDone3],
      day,
      15,
    );

/// Pochvala v souhrnu po dokončeném tréninku. Volající ji použije jen
/// tehdy, když pro souhrn neplatí žádná wellbeing hláška (normální
/// situace) – při nemoci, zranění, zotavování i rýsování zůstává
/// podpůrný text z wellbeingMessage.
String strictDoneMessage(AppLocalizations l10n, DateTime day) => _pick(
      [
        l10n.coachDone1,
        l10n.coachDone2,
        l10n.coachDone3,
        l10n.coachDone4,
        l10n.coachDone5,
      ],
      day,
      17,
    );

/// Dialog „partie je ještě unavená“ (≥ 80 %). Přísný, ale k tréninku
/// netlačí – drsně doporučuje odpočinek (zdraví má přednost).
String strictFatigueWarning(
  AppLocalizations l10n,
  String group,
  int percent,
  DateTime day,
) =>
    _pick(
      [
        l10n.coachFatigueWarning1(group, percent),
        l10n.coachFatigueWarning2(group, percent),
      ],
      day,
      16,
    );

/// Zvolený tón z profilu (bez ohledu na situaci).
CoachTone chosenCoachTone(WidgetRef ref) =>
    coachToneOf(ref.read(profileProvider).valueOrNull?.coachTone);

/// Skutečný tón pro zprávu, která může tlačit do tréninku: přísný jen
/// když je zvolený, uživatel není nemocný / zraněný / po nemoci a žádná
/// partie není unavená ≥ 80 %. Při chybě odhadu únavy přátelský.
Future<CoachTone> resolveCoachTone(WidgetRef ref) async {
  final chosen = chosenCoachTone(ref);
  if (chosen == CoachTone.friendly) return chosen;
  final situation = ref.read(situationProvider);
  if (!strictToneAllowed(situation)) return CoachTone.friendly;
  try {
    final report = await loadFatigue(ref.read(databaseProvider), DateTime.now());
    return effectiveCoachTone(
      chosen,
      situation,
      maxFatigue: maxFatiguePercent(report),
    );
  } catch (e) {
    debugPrint('Coach tone fatigue check failed: $e');
    return CoachTone.friendly;
  }
}
