import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../modules/data/unit_dialogs.dart';
import '../../modules/data/units.dart';
import '../../modules/module_hub.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/labels.dart';
import '../../ui/weekdays.dart';
import '../../ui/wellbeing_messages.dart';
import '../periods/periods_screen.dart';
import '../workout/start_workout.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider).valueOrNull;
    final trackPeriods = profile?.trackPeriods ?? true;
    final name = profile?.name;
    return Scaffold(
      appBar: AppBar(
        title: Text(name == null || name.isEmpty
            ? l10n.tabToday
            : l10n.todayGreeting(name)),
        actions: [
          if (trackPeriods)
            IconButton(
              tooltip: l10n.periodsTitle,
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => context.push('/periods'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (trackPeriods) const _WellbeingCard(),
          const _WorkoutCard(),
          if (profile?.trackWater ?? true) const _WaterCard(),
          if (profile?.trackWeight ?? true) const _WeightCard(),
          ...moduleTodayCards(),
        ],
      ),
    );
  }
}


enum _PlanAction { postpone, skip }

class _WorkoutCard extends ConsumerWidget {
  const _WorkoutCard();

  Future<void> _changePlan(
    BuildContext context,
    WidgetRef ref,
    WorkoutPlan plan,
    _PlanAction action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    if (action == _PlanAction.postpone) {
      await db.postponePlan(plan.id, now);
    } else {
      await db.skipPlan(plan.id, now);
    }
    if (!context.mounted) return;
    final situation = ref.read(situationProvider);
    await showEncouragementDialog(
      context,
      title: action == _PlanAction.postpone
          ? l10n.planPostponedTitle
          : l10n.planSkippedTitle,
      message: wellbeingMessage(l10n, situation, MessagePlace.skip, now)!,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final active = ref.watch(activeSessionProvider).valueOrNull;
    final plans = ref.watch(plansProvider).valueOrNull ?? const <WorkoutPlan>[];
    final scheduled =
        ref.watch(scheduledTodayProvider).valueOrNull ?? const <ScheduledWorkout>[];
    final finished =
        ref.watch(finishedPlanIdsTodayProvider).valueOrNull ?? const <int>{};
    final now = DateTime.now();
    final todayIndex = dayIndexOf(now);

    // Dnešní plány = podle dnů v týdnu + odložené na dnešek,
    // minus odložené na zítra a vynechané.
    final postponedHere = {
      for (final s in scheduled)
        if (s.status == ScheduleStatus.planned) s.planId,
    };
    final removed = {
      for (final s in scheduled)
        if (s.status == ScheduleStatus.moved ||
            s.status == ScheduleStatus.skipped)
          s.planId: s.status,
    };
    final todayPlans = [
      for (final p in plans)
        if ((isWeekdayInMask(p.weekdaysMask, todayIndex) ||
                postponedHere.contains(p.id)) &&
            !removed.containsKey(p.id))
          p,
    ]..sort((a, b) => (a.plannedTimeMinutes ?? 24 * 60)
        .compareTo(b.plannedTimeMinutes ?? 24 * 60));
    final removedPlans = [
      for (final p in plans)
        if (removed.containsKey(p.id)) p,
    ];

    final children = <Widget>[
      Text(l10n.todayWorkoutTitle, style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
    ];

    if (active != null) {
      children.addAll([
        Text(l10n.todayWorkoutInProgress(
          formatMinutesOfDay(
            context,
            active.startedAt.hour * 60 + active.startedAt.minute,
          ),
        )),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.push('/workout/${active.id}'),
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.workoutResume),
        ),
      ]);
    } else {
      if (todayPlans.isEmpty) {
        children.add(Text(l10n.todayNoWorkout));
      } else {
        for (final plan in todayPlans) {
          final done = finished.contains(plan.id);
          final details = [
            if (plan.plannedTimeMinutes != null)
              formatMinutesOfDay(context, plan.plannedTimeMinutes!),
            if (postponedHere.contains(plan.id) &&
                !isWeekdayInMask(plan.weekdaysMask, todayIndex))
              l10n.planPostponedLabel,
          ];
          children.add(ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(plan.name),
            subtitle: details.isEmpty ? null : Text(details.join(' · ')),
            trailing: done
                ? Chip(
                    avatar: const Icon(Icons.check, size: 18),
                    label: Text(l10n.planDoneToday),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.icon(
                        onPressed: () =>
                            startWorkout(context, ref, planId: plan.id),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.workoutStart),
                      ),
                      PopupMenuButton<_PlanAction>(
                        tooltip: l10n.planMoreActions,
                        onSelected: (a) => _changePlan(context, ref, plan, a),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: _PlanAction.postpone,
                            child: Text(l10n.planPostpone),
                          ),
                          PopupMenuItem(
                            value: _PlanAction.skip,
                            child: Text(l10n.planSkipToday),
                          ),
                        ],
                      ),
                    ],
                  ),
          ));
        }
      }
      for (final plan in removedPlans) {
        children.add(ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: false,
          title: Text(plan.name),
          subtitle: Text(removed[plan.id] == ScheduleStatus.moved
              ? l10n.planPostponedToTomorrow
              : l10n.planSkippedLabel),
          trailing: TextButton(
            onPressed: () =>
                ref.read(databaseProvider).undoPlanChange(plan.id, now),
            child: Text(l10n.undo),
          ),
        ));
      }
      children.addAll([
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => startWorkout(context, ref),
              icon: const Icon(Icons.fitness_center),
              label: Text(l10n.workoutFreeStart),
            ),
            OutlinedButton.icon(
              onPressed: () {
                final pending =
                    todayPlans.where((p) => !finished.contains(p.id)).firstOrNull;
                context.push(pending == null
                    ? '/planb'
                    : '/planb?planId=${pending.id}');
              },
              icon: const Icon(Icons.home_outlined),
              label: Text(todayPlans.isEmpty ? l10n.planBQuick : l10n.todayPlanB),
            ),
          ],
        ),
      ]);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _WaterCard extends ConsumerWidget {
  const _WaterCard();

  static const _trainingBonusMl = 500;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final db = ref.watch(databaseProvider);
    final water = ref.watch(waterTodayProvider).valueOrNull ?? 0;
    final profile = ref.watch(profileProvider).valueOrNull;
    final baseGoal = profile?.waterGoalMl ?? 2500;
    // Rychlé tlačítka: vlastní sklenice a láhev z profilu (bez duplicit).
    final quickAmounts = {profile?.glassMl ?? 250, profile?.bottleMl ?? 500};
    // Ve dny tréninku je potřeba pít víc – cíl navýšíme o 500 ml.
    final trained = ref.watch(workoutDoneTodayProvider).valueOrNull ?? false;
    final goal = baseGoal + (trained ? _trainingBonusMl : 0);
    final progress = goal <= 0 ? 0.0 : (water / goal).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.waterTitle, style: theme.textTheme.titleMedium),
                const Spacer(),
                Text('${formatVolumeNumber(context, water)} / '
                    '${formatVolume(context, goal)}'),
              ],
            ),
            if (trained)
              Text(
                l10n.dataWaterTrainingBonus(
                  formatVolume(context, _trainingBonusMl),
                ),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, minHeight: 8),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final ml in quickAmounts)
                  FilledButton.tonal(
                    onPressed: () => db.addWater(ml),
                    child: Text('+${formatVolume(context, ml)}'),
                  ),
                OutlinedButton(
                  onPressed: () async {
                    final ml = await showVolumeInputDialog(
                      context,
                      title: l10n.dataWaterCustomDialog(volumeUnit),
                      minMl: 10,
                      maxMl: 2000,
                    );
                    if (ml != null) await db.addWater(ml);
                  },
                  child: Text(l10n.dataWaterCustom),
                ),
                TextButton(
                  onPressed: water > 0 ? db.undoLastWater : null,
                  child: Text(l10n.waterUndo),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightCard extends ConsumerWidget {
  const _WeightCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final latest = ref.watch(latestWeightProvider).valueOrNull;
    ref.watch(unitSystemProvider); // překreslit po změně kg / lb
    final valueText = latest == null
        ? l10n.weightNone
        : formatBodyWeight(context, latest.weightKg);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.monitor_weight_outlined,
            color: theme.colorScheme.primary),
        title: Text(l10n.weightTitle),
        subtitle: Text(valueText),
        trailing: FilledButton.tonal(
          onPressed: () async {
            final kg = await showWeightInputDialog(
              context,
              title: l10n.dataWeightDialogTitle(weightUnit),
              minKg: 20,
              maxKg: 400,
              initialKg: latest?.weightKg,
            );
            if (kg != null) {
              await ref.read(databaseProvider).logWeight(DateTime.now(), kg);
            }
          },
          child: Text(l10n.weightLog),
        ),
      ),
    );
  }
}

/// Karta s aktuálním obdobím (nemoc, zranění, dieta…) a povzbuzující
/// hláškou. Po nemoci ukazuje hlášku o návratu i bez aktivního období.
class _WellbeingCard extends ConsumerWidget {
  const _WellbeingCard();

  static const _priority = [
    PeriodType.illness,
    PeriodType.injury,
    PeriodType.cut,
    PeriodType.bulk,
    PeriodType.maintenance,
    PeriodType.pause,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final periods = ref.watch(periodsProvider).valueOrNull ?? const <Period>[];
    final situation = ref.watch(situationProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final activePeriods = [
      for (final p in periods)
        if (!p.startDate.isAfter(today) &&
            (p.endDate == null || !p.endDate!.isBefore(today)))
          p,
    ]..sort((a, b) =>
        _priority.indexOf(a.type).compareTo(_priority.indexOf(b.type)));
    final main = activePeriods.firstOrNull;
    final message =
        wellbeingMessage(l10n, situation, MessagePlace.today, now);

    if (main == null && message == null) return const SizedBox.shrink();

    final title = main != null
        ? '${l10n.periodType(main.type)} · '
            '${l10n.periodOngoingSince(formatDay(context, main.startDate))}'
        : l10n.recoveryTitle;

    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(main != null ? periodIcon(main.type) : Icons.favorite_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(message),
              ),
            ],
            if (main != null && main.endDate == null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => ref
                      .read(databaseProvider)
                      .endPeriod(main.id, DateTime.now()),
                  child: Text(main.type == PeriodType.illness
                      ? l10n.periodEndIllness
                      : l10n.periodEndToday),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dialog s povzbuzující hláškou (po odložení nebo vynechání tréninku).
Future<void> showEncouragementDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.favorite_outline),
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.ok),
        ),
      ],
    ),
  );
}
