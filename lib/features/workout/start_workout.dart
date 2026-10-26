import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/coach_tone.dart';
import '../../core/fatigue.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../modules/module_hub.dart';
import '../../modules/widgets/rest_live_activity.dart';
import '../../providers.dart';
import '../../services/notification_service.dart';
import '../../ui/coach_messages.dart';
import '../../ui/labels.dart';
import '../fatigue/fatigue_providers.dart';
import 'workout_service.dart' show WorkoutStartDecision;

enum _ActiveChoice { resume, discardAndStart }

enum _FatigueChoice { trainAnyway, planB, postpone }

/// Právě běží [startWorkout] – dvojité klepnutí na „Začít“ by jinak
/// vytvořilo dva tréninky.
bool _starting = false;

/// Spustí nový trénink (volitelně podle plánu) a otevře jeho obrazovku.
/// Pokud už nějaký trénink probíhá, nabídne pokračování nebo jeho zahození.
/// [light] = lehčí trénink kvůli slabší regeneraci (z karty
/// Připravenost); kontrola připravenosti se pak už neptá.
Future<void> startWorkout(
  BuildContext context,
  WidgetRef ref, {
  int? planId,
  bool light = false,
}) async {
  if (_starting) return;
  _starting = true;
  try {
    await _startWorkout(context, ref, planId: planId, light: light);
  } finally {
    _starting = false;
  }
}

Future<void> _startWorkout(
  BuildContext context,
  WidgetRef ref, {
  int? planId,
  bool light = false,
}) async {
  final db = ref.read(databaseProvider);
  final l10n = AppLocalizations.of(context);
  final active = await db.getActiveSession();
  if (!context.mounted) return;

  if (active != null) {
    final choice = await showDialog<_ActiveChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workoutInProgressTitle),
        content: Text(l10n.workoutInProgressMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_ActiveChoice.discardAndStart),
            child: Text(l10n.workoutDiscardAndStart),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_ActiveChoice.resume),
            child: Text(l10n.workoutResume),
          ),
        ],
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == _ActiveChoice.resume) {
      context.push('/workout/${active.id}');
      return;
    }
  }

  // Únava se ověří ještě před zahozením rozpracovaného tréninku – když
  // uživatel zvolí plán B nebo odklad, starý trénink zůstane.
  if (planId != null) {
    final proceed = await _checkFatigue(context, ref, planId);
    if (!proceed || !context.mounted) return;
    // Kontroly modulů (připravenost z hodinek a prstenů): lehčí trénink,
    // nebo netrénovat.
    if (!light) {
      for (final check in moduleWorkoutStartChecks()) {
        final decision = await check(context, ref, planId);
        if (!context.mounted || decision == WorkoutStartDecision.cancel) {
          return;
        }
        if (decision == WorkoutStartDecision.light) light = true;
      }
    }
  }

  if (active != null) {
    await db.discardSession(active.id);
    // Upozornění na konec pauzy zahozeného tréninku (pauza běží dál i po
    // odchodu z jeho obrazovky) by v novém tréninku jen mátlo.
    unawaited(NotificationService.instance.cancelRestEnd());
    unawaited(RestLiveActivity.instance.end());
    if (!context.mounted) return;
  }

  // Zaměření (síla / svaly / výdrž) podle plánu, jinak cíl z profilu;
  // dá se změnit nahoře na obrazovce tréninku (jen pro tento trénink).
  final id = await db.startSession(
    planId: planId,
    focus: await db.focusForNewSession(planId),
    light: light,
  );
  if (!context.mounted) return;
  context.push('/workout/$id');
}

/// Před tréninkem podle plánu: když je některá partie plánu ještě hodně
/// unavená (≥ 80 %), jemně se zeptá, jestli trénovat, dát plán B nebo
/// trénink odložit. Vrací true, když se má trénink spustit.
/// Zraněné partie se přeskočí – na ty upozorňuje trénink zvlášť.
Future<bool> _checkFatigue(
  BuildContext context,
  WidgetRef ref,
  int planId,
) async {
  final db = ref.read(databaseProvider);
  final injured = ref.read(injuredGroupsProvider);
  final now = DateTime.now();
  MapEntry<MuscleGroup, double>? found;
  try {
    final items = await db.getPlanItems(planId);
    final groups = {
      for (final it in items)
        if (it.exercise.muscleGroup != MuscleGroup.fullBody &&
            !injured.any((g) => g.overlaps(it.exercise.muscleGroup)))
          it.exercise.muscleGroup,
    };
    if (groups.isEmpty) return true;
    found = mostFatiguedOf(await loadFatigue(db, now), groups);
  } catch (e) {
    // Odhad únavy nesmí zablokovat trénink.
    debugPrint('Fatigue check failed: $e');
    return true;
  }
  final worst = found;
  if (worst == null || !context.mounted) return true;

  final l10n = AppLocalizations.of(context);
  // Přísný trenér i tady drží zdraví na prvním místě: jeho varianta je
  // drsnější, ale doporučuje odpočinek (k tréninku netlačí). Při nemoci,
  // zranění a zotavování zůstává přátelský text.
  final strict = effectiveCoachTone(
        chosenCoachTone(ref),
        ref.read(situationProvider),
      ) ==
      CoachTone.strict;
  final groupName = l10n.muscleGroup(worst.key);
  final percent = worst.value.round();
  final choice = await showDialog<_FatigueChoice>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.battery_alert),
      title: Text(l10n.fatigueWarningTitle),
      content: Text(strict
          ? strictFatigueWarning(l10n, groupName, percent, now)
          : l10n.fatigueWarningMessage(groupName, percent)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_FatigueChoice.postpone),
          child: Text(l10n.fatiguePostpone),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_FatigueChoice.planB),
          child: Text(l10n.fatiguePlanB),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_FatigueChoice.trainAnyway),
          child: Text(l10n.fatigueTrainAnyway),
        ),
      ],
    ),
  );
  if (!context.mounted) return false;
  switch (choice) {
    case _FatigueChoice.trainAnyway:
      return true;
    case _FatigueChoice.planB:
      context.push('/planb?planId=$planId');
      return false;
    case _FatigueChoice.postpone:
      await db.postponePlan(planId, now);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.planPostponedToTomorrow)),
          );
      }
      return false;
    case null:
      return false;
  }
}
