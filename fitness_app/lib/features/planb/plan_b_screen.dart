import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formulas.dart';
import '../../data/database.dart';
import '../../data/seed/content_i18n.dart';
import '../../l10n/app_localizations.dart';
import '../../premium/premium.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../core/coach_tone.dart';
import '../../ui/coach_messages.dart';
import '../../ui/labels.dart';
import '../../ui/wellbeing_messages.dart';

/// Plán B: krátká domácí rutina bez vybavení (práce / pauza s časovačem),
/// když uživatel nestíhá plnohodnotný trénink.
class PlanBScreen extends ConsumerStatefulWidget {
  const PlanBScreen({super.key, this.planId});

  /// Původně naplánovaný trénink (podle něj se vybere rutina
  /// a po dokončení se nabídne jeho odložení).
  final int? planId;

  @override
  ConsumerState<PlanBScreen> createState() => _PlanBScreenState();
}

enum _StepKind { work, rest }

typedef _Step = ({Exercise exercise, _StepKind kind, int seconds});

class _PlanBScreenState extends ConsumerState<PlanBScreen> {
  List<HomeRoutineWithExercises> _routines = const [];
  HomeRoutineWithExercises? _selected;
  WorkoutPlan? _originalPlan;

  // Průběh
  List<_Step> _steps = const [];
  int _stepIndex = -1;
  DateTime? _endAt;
  Duration? _pausedRemaining;
  DateTime? _startedAt;
  Timer? _ticker;
  final _done = <({int exerciseId, int seconds})>[];

  bool get _running => _stepIndex >= 0;
  AppDatabase get _db => ref.read(databaseProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final routines = await _db.getHomeRoutines();
    WorkoutPlan? plan;
    var preferred = 'home_full';
    if (widget.planId != null) {
      plan = await _db.watchPlan(widget.planId!).first;
      final items = await _db.getPlanItems(widget.planId!);
      var upper = 0, lower = 0;
      for (final it in items) {
        switch (it.exercise.muscleGroup) {
          case MuscleGroup.legs || MuscleGroup.glutes:
            lower++;
          case MuscleGroup.chest ||
                MuscleGroup.back ||
                MuscleGroup.shoulders ||
                MuscleGroup.biceps ||
                MuscleGroup.triceps:
            upper++;
          case MuscleGroup.core || MuscleGroup.fullBody:
            break;
        }
      }
      if (upper > lower) preferred = 'home_upper';
      if (lower > upper) preferred = 'home_lower';
    }
    if (!mounted) return;
    setState(() {
      _routines = routines;
      _originalPlan = plan;
      _selected = routines.where((r) => r.routine.slug == preferred).firstOrNull ??
          routines.firstOrNull;
    });
  }

  String _routineName(BuildContext context, HomeRoutine r) {
    final slug = r.slug;
    return seedText(
      Localizations.localeOf(context).languageCode,
      en: r.nameEn,
      cs: r.nameCs,
      other: slug == null ? null : (t) => t.routineNames[slug],
    );
  }

  // -------------------------------------------------------------------
  // Časovač
  // -------------------------------------------------------------------

  Duration get _remaining {
    if (_pausedRemaining != null) return _pausedRemaining!;
    final end = _endAt;
    if (end == null) return Duration.zero;
    final left = end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  void _start() {
    final r = _selected;
    if (r == null || r.items.isEmpty) return;
    final steps = <_Step>[];
    for (var i = 0; i < r.items.length; i++) {
      final it = r.items[i];
      steps.add((exercise: it.exercise, kind: _StepKind.work, seconds: it.workSeconds));
      if (i < r.items.length - 1 && it.restSeconds > 0) {
        steps.add((exercise: r.items[i + 1].exercise, kind: _StepKind.rest, seconds: it.restSeconds));
      }
    }
    _startedAt = DateTime.now();
    _steps = steps;
    _done.clear();
    _enterStep(0);
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  void _enterStep(int index) {
    setState(() {
      _stepIndex = index;
      _pausedRemaining = null;
      _endAt = DateTime.now().add(Duration(seconds: _steps[index].seconds));
    });
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }

  void _completeStep({required bool skipped}) {
    final step = _steps[_stepIndex];
    if (step.kind == _StepKind.work) {
      final doneSeconds = step.seconds - _remaining.inSeconds;
      if (!skipped || doneSeconds >= 5) {
        _done.add((exerciseId: step.exercise.id, seconds: skipped ? doneSeconds : step.seconds));
      }
    }
    if (_stepIndex + 1 < _steps.length) {
      _enterStep(_stepIndex + 1);
    } else {
      _finish();
    }
  }

  void _tick() {
    if (!_running || _pausedRemaining != null) return;
    if (_remaining == Duration.zero) {
      _completeStep(skipped: false);
    } else {
      setState(() {});
    }
  }

  void _togglePause() {
    setState(() {
      if (_pausedRemaining == null) {
        _pausedRemaining = _remaining;
      } else {
        _endAt = DateTime.now().add(_pausedRemaining!);
        _pausedRemaining = null;
      }
    });
  }

  // -------------------------------------------------------------------
  // Dokončení
  // -------------------------------------------------------------------

  Future<void> _finish() async {
    _ticker?.cancel();
    final l10n = AppLocalizations.of(context);
    final startedAt = _startedAt ?? DateTime.now();
    setState(() => _stepIndex = -1);

    if (_done.isNotEmpty) {
      final weight = (await _db.watchLatestWeight().first)?.weightKg;
      final met = await _db.averageMet(_done.map((d) => d.exerciseId));
      final seconds = _done.fold<int>(0, (a, d) => a + d.seconds);
      await _db.savePlanBSession(
        startedAt: startedAt,
        done: _done,
        estimatedKcal: weight == null
            ? null
            : estimateKcal(
                met: met,
                bodyWeightKg: weight,
                duration: Duration(seconds: seconds),
              ),
      );
    }
    if (!mounted) return;

    // Přísný trenér jen ve zdravé situaci a bez velké únavy.
    final strict = await resolveCoachTone(ref) == CoachTone.strict;
    if (!mounted) return;
    final now = DateTime.now();

    final plan = _originalPlan;
    if (plan != null) {
      final postpone = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(l10n.planBPostponeTitle),
          content: Text(strict
              ? strictPlanBPostpone(l10n, plan.name, now)
              : l10n.planBPostponeMessage(plan.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.planBPostponeNo),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.planBPostponeYes),
            ),
          ],
        ),
      );
      if (postpone == true) {
        await _db.postponePlan(plan.id, DateTime.now());
      } else {
        await _db.skipPlan(plan.id, DateTime.now());
      }
      if (!mounted) return;
    }

    final extra = wellbeingMessage(
      l10n,
      ref.read(situationProvider),
      MessagePlace.summary,
      DateTime.now(),
    );
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.favorite_outline),
        title: Text(l10n.planBDoneTitle),
        content: Text(extra ??
            (strict ? strictPlanBDone(l10n, now) : l10n.planBDoneMessage)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    if (mounted) context.pop();
  }

  Future<bool> _confirmQuit() async {
    if (!_running) return true;
    final l10n = AppLocalizations.of(context);
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.planBQuitTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.planBQuit),
          ),
        ],
      ),
    );
    return quit ?? false;
  }

  // -------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_running,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmQuit()) {
          _ticker?.cancel();
          setState(() => _stepIndex = -1);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.todayPlanB)),
        body: _running ? _buildRunning(context) : _buildSelect(context),
      ),
    );
  }

  Widget _buildSelect(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = _selected;
    if (_routines.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    // Premium: zdarma jsou první 3 rutiny.
    final premium = ref
        .watch(premiumProvider)
        .isPremium(PremiumFeature.extraHomeRoutines);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.planBIntro),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (index, r) in _routines.indexed)
              ChoiceChip(
                avatar: isHomeRoutineLocked(index, premium: premium)
                    ? const Icon(Icons.lock_outline, size: 16)
                    : null,
                label: Text(_routineName(context, r.routine)),
                selected: identical(r, selected),
                onSelected: (_) async {
                  if (isHomeRoutineLocked(index, premium: premium) &&
                      !await requirePremium(
                          context, ref, PremiumFeature.extraHomeRoutines)) {
                    return;
                  }
                  if (mounted) setState(() => _selected = r);
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (selected != null)
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final it in selected.items)
                  ListTile(
                    title: Text(it.exercise.localizedName(context)),
                    trailing: Text(
                      '${it.workSeconds} s',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: selected == null ? null : _start,
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.planBStart),
        ),
      ],
    );
  }

  Widget _buildRunning(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final step = _steps[_stepIndex];
    final isWork = step.kind == _StepKind.work;
    final workSteps = _steps.where((s) => s.kind == _StepKind.work).toList();
    final workNumber =
        _steps.take(_stepIndex + 1).where((s) => s.kind == _StepKind.work).length;
    final progress = step.seconds == 0
        ? 0.0
        : 1 - _remaining.inMilliseconds / (step.seconds * 1000);
    final nextWork = _steps
        .skip(_stepIndex + 1)
        .where((s) => s.kind == _StepKind.work)
        .firstOrNull;
    final color = isWork ? theme.colorScheme.primary : theme.colorScheme.tertiary;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            isWork
                ? l10n.planBExerciseOf(workNumber, workSteps.length)
                : l10n.planBRestNext,
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          ),
          const SizedBox(height: 8),
          Text(
            step.exercise.localizedName(context),
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 10,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
                Center(
                  child: Text(
                    formatDuration(_remaining + const Duration(milliseconds: 999)),
                    style: theme.textTheme.displayMedium,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (isWork && nextWork != null)
            Text(l10n.planBNext(nextWork.exercise.localizedName(context))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                iconSize: 32,
                tooltip: _pausedRemaining == null ? l10n.planBPause : l10n.planBResume,
                onPressed: _togglePause,
                icon: Icon(_pausedRemaining == null ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 24),
              IconButton.filledTonal(
                iconSize: 32,
                tooltip: l10n.workoutSkipRest,
                onPressed: () => _completeStep(skipped: true),
                icon: const Icon(Icons.skip_next),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
