import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/fatigue.dart';
import '../../core/superset.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../modules/data/units.dart';
import '../../modules/module_hub.dart';
import '../../modules/progression/progression_plan_widgets.dart';
import '../../providers.dart';
import '../../ui/dialogs.dart';
import '../../ui/labels.dart';
import '../../ui/set_format.dart';
import '../../ui/weekdays.dart';
import '../exercises/exercise_picker.dart';
import '../fatigue/fatigue_card.dart';
import '../fatigue/fatigue_providers.dart';
import '../workout/start_workout.dart';

enum _LinkAction { linkNext, unlink }

class PlanEditorScreen extends ConsumerWidget {
  const PlanEditorScreen({super.key, required this.planId});

  final int planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final plan = ref.watch(planProvider(planId));

    return plan.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.errorGeneric)),
      ),
      data: (p) => p == null
          ? Scaffold(appBar: AppBar())
          : _PlanEditor(plan: p),
    );
  }
}

class _PlanEditor extends ConsumerWidget {
  const _PlanEditor({required this.plan});

  final WorkoutPlan plan;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = await showTextInputDialog(
      context,
      title: l10n.planRename,
      initialValue: plan.name,
    );
    if (name != null) {
      await ref.read(databaseProvider).renamePlan(plan.id, name);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.planDeleteTitle,
      message: l10n.planDeleteMessage(plan.name),
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    context.go('/plans');
    await ref.read(databaseProvider).deletePlan(plan.id);
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final current = plan.plannedTimeMinutes ?? 17 * 60;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (time != null) {
      await ref
          .read(databaseProvider)
          .setPlanTime(plan.id, time.hour * 60 + time.minute);
    }
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final exercise = await showExercisePicker(context);
    if (exercise != null) {
      await ref.read(databaseProvider).addExerciseToPlan(plan.id, exercise.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final db = ref.watch(databaseProvider);
    final items = ref.watch(planItemsProvider(plan.id)).valueOrNull ?? [];
    final dayNames = shortWeekdayNames(context);
    final groups = [for (final it in items) it.item.supersetGroup];
    final supersets = supersetLabels(groups);
    final fatigue = ref.watch(fatigueProvider).valueOrNull;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(l10n.planDays,
              style: Theme.of(context).textTheme.titleSmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < 7; i++)
                FilterChip(
                  label: Text(dayNames[i]),
                  selected: isWeekdayInMask(plan.weekdaysMask, i),
                  onSelected: (_) => db.setPlanWeekdays(
                    plan.id,
                    toggleWeekday(plan.weekdaysMask, i),
                  ),
                ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: Text(l10n.planTime),
          subtitle: Text(
            plan.plannedTimeMinutes == null
                ? l10n.planTimeNone
                : formatMinutesOfDay(context, plan.plannedTimeMinutes!),
          ),
          onTap: () => _pickTime(context, ref),
          trailing: plan.plannedTimeMinutes == null
              ? null
              : IconButton(
                  tooltip: l10n.planTimeClear,
                  icon: const Icon(Icons.clear),
                  onPressed: () => db.setPlanTime(plan.id, null),
                ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(l10n.planExercises,
              style: Theme.of(context).textTheme.titleSmall),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(l10n.planNoExercises),
          ),
      ],
    );

    final footer = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => _addExercise(context, ref),
            icon: const Icon(Icons.add),
            label: Text(l10n.planAddExercise),
          ),
          ...modulePlanEditorSections(plan.id),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name),
        actions: [
          IconButton(
            tooltip: l10n.planRename,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _rename(context, ref),
          ),
          IconButton(
            tooltip: l10n.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        header: header,
        footer: footer,
        buildDefaultDragHandles: false,
        itemCount: items.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex -= 1;
          final ids = [for (final it in items) it.item.id];
          final moved = ids.removeAt(oldIndex);
          ids.insert(newIndex, moved);
          db.reorderPlanItems(ids);
        },
        itemBuilder: (context, i) {
          final it = items[i];
          final g = it.exercise.muscleGroup;
          return _PlanItemTile(
            key: ValueKey(it.item.id),
            item: it,
            index: i,
            supersetLabel: supersets[i],
            canLinkNext: canLinkSupersetWithNext(groups, i),
            fatiguePercent: fatigue == null || fatigue.sessions == 0
                ? null
                : fatigue.percent[g],
            onTap: () => context.go('/plans/${plan.id}/item/${it.item.id}'),
            onLinkAction: (action) async {
              if (action == _LinkAction.linkNext) {
                final ok = await db.linkPlanItemWithNext(plan.id, it.item.id);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text(l10n.supersetTooLarge),
                    ));
                }
              } else {
                await db.unlinkPlanItem(plan.id, it.item.id);
              }
            },
          );
        },
      ),
      floatingActionButton: items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => startWorkout(context, ref, planId: plan.id),
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.workoutStart),
            ),
    );
  }
}

class _PlanItemTile extends ConsumerWidget {
  const _PlanItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.onTap,
    required this.onLinkAction,
    this.supersetLabel,
    this.canLinkNext = false,
    this.fatiguePercent,
  });

  final PlanItem item;
  final int index;
  final VoidCallback onTap;
  final ValueChanged<_LinkAction> onLinkAction;

  /// „A1“, „A2“… u cviku v supersérii.
  final String? supersetLabel;
  final bool canLinkNext;

  /// Současná únava hlavní partie cviku (null = bez tréninku za 7 dní).
  final double? fatiguePercent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final record =
        ref.watch(exerciseStatsProvider(item.exercise.id)).valueOrNull?.record;
    ref.watch(unitSystemProvider); // překreslit po změně kg / lb
    final setsText = describePlanSets(
      context,
      item.sets.map((s) => (
            reps: s.reps,
            weightKg: s.weightKg,
            isWarmup: s.isWarmup,
            isDrop: s.isDrop,
          )),
      isDuration: item.exercise.type == ExerciseType.duration,
    );
    final label = supersetLabel;
    final fatigue = fatiguePercent;
    final fatigueState = fatigue == null ? null : fatigueStatus(fatigue);
    final tile = ListTile(
      leading: label == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      title: Text(item.exercise.localizedName(context)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(setsText),
          Text(l10n.workoutRestLabel(item.item.restSeconds)),
          // Nepoužitý návrh automatické progrese („↑ +2,5 kg příště“).
          // Premium (autoProgression): bez předplatného se štítek skryje
          // sám (ProgressionPlanBadge).
          ProgressionPlanBadge(
            planId: item.item.planId,
            planExerciseId: item.item.id,
          ),
          if (record != null)
            Text(
              describeRecord(context, record),
              style: TextStyle(color: theme.colorScheme.tertiary),
            ),
          // Jemná nápověda: partie je ještě unavená z minulých tréninků.
          if (fatigue != null &&
              fatigueState != null &&
              fatigueState != FatigueStatus.recovered)
            Row(
              children: [
                Icon(
                  fatigueIcon(fatigueState),
                  size: 14,
                  color: fatigueColor(context, fatigueState),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    l10n.fatigueExerciseHint(
                      l10n.muscleGroup(item.exercise.muscleGroup),
                      fatigue.round(),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      isThreeLine: true,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<_LinkAction>(
            tooltip: l10n.supersetMenu,
            icon: Icon(
              Icons.link,
              color: label == null ? null : theme.colorScheme.primary,
            ),
            onSelected: onLinkAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _LinkAction.linkNext,
                enabled: canLinkNext,
                child: Text(l10n.supersetLinkNext),
              ),
              if (label != null)
                PopupMenuItem(
                  value: _LinkAction.unlink,
                  child: Text(l10n.supersetUnlink),
                ),
            ],
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
        ],
      ),
    );
    if (label == null) return tile;
    // Cviky supersérie spojuje svislá čára vlevo.
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 4),
        ),
      ),
      child: tile,
    );
  }
}
