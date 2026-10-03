import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../modules/module_hub.dart';
import '../../providers.dart';
import '../../services/notification_service.dart';
import '../../ui/dialogs.dart';
import '../../ui/format.dart';
import '../../ui/exercise_media_view.dart';
import '../../ui/labels.dart';
import '../../ui/set_format.dart';
import '../../ui/wellbeing_messages.dart';
import '../exercises/exercise_picker.dart';
import 'rest_timer.dart';
import 'workout_service.dart';

/// Obrazovka probíhajícího tréninku.
///
/// Série se ukládají do databáze hned po odškrtnutí, takže trénink přežije
/// zavření aplikace a dá se v něm pokračovat z obrazovky Dnes.
enum _MenuAction { discard }

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  final _timer = RestTimer();
  final _blocks = <_Block>[];
  WorkoutSetup? _setup;
  Object? _loadError;
  bool _busy = false;

  late final AppLifecycleListener _lifecycle;

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _onHide, onShow: _onShow);
    _load();
  }

  /// Když uživatel během pauzy odejde z aplikace (nebo zamkne telefon),
  /// naplánujeme notifikaci na konec pauzy.
  void _onHide() {
    if (_timer.isRunning) {
      NotificationService.instance
          .scheduleRestEnd(_timer.remaining, AppLocalizations.of(context));
    }
  }

  void _onShow() => NotificationService.instance.cancelRestEnd();

  @override
  void dispose() {
    _lifecycle.dispose();
    NotificationService.instance.cancelRestEnd();
    _timer.dispose();
    for (final b in _blocks) {
      b.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final setup = await loadWorkoutSetup(_db, widget.sessionId);
      if (!mounted) return;
      setState(() {
        _setup = setup;
        _blocks.addAll(setup.blocks.map(_Block.fromData));
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/today');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // -------------------------------------------------------------------
  // Série
  // -------------------------------------------------------------------

  Future<void> _toggleSet(_Block block, int index) async {
    final row = block.rows[index];
    final savedId = row.savedId;

    if (savedId != null) {
      await _db.deleteSet(savedId);
      if (mounted) setState(() => row.savedId = null);
      return;
    }

    final values = block.parse(row);
    if (values == null) {
      _showMessage(AppLocalizations.of(context).workoutSetInvalid);
      return;
    }
    final id = await _db.insertSet(
      sessionId: widget.sessionId,
      exerciseId: block.data.exercise.id,
      position: index,
      weightKg: values.weightKg,
      reps: block.isDuration ? null : values.value,
      durationSeconds: block.isDuration ? values.value : null,
      isWarmup: row.isWarmup,
    );
    if (!mounted) return;
    setState(() => row.savedId = id);
    HapticFeedback.lightImpact();
    _timer.start(block.data.restSeconds);
  }

  /// Úprava už uložené série se hned propíše do databáze.
  void _onRowEdited(_Block block, _SetRow row) {
    final savedId = row.savedId;
    if (savedId == null) return;
    final values = block.parse(row);
    if (values == null) return;
    _db.updateSet(
      savedId,
      weightKg: values.weightKg,
      reps: block.isDuration ? null : values.value,
      durationSeconds: block.isDuration ? values.value : null,
    );
  }

  void _toggleWarmup(_Block block, int index) {
    final row = block.rows[index];
    if (row.isDone) return;
    setState(() => row.isWarmup = !row.isWarmup);
  }

  void _addSet(_Block block) =>
      setState(() => block.rows.add(block.copyLastRow()));

  void _removeLastSet(_Block block) {
    if (block.rows.length <= 1 || block.rows.last.isDone) return;
    setState(() => block.rows.removeLast().dispose());
  }

  Future<void> _addExercise() async {
    final exercise = await showExercisePicker(context);
    if (exercise == null) return;
    final data = await loadExtraBlock(_db, widget.sessionId, exercise);
    if (mounted) setState(() => _blocks.add(_Block.fromData(data)));
  }

  // -------------------------------------------------------------------
  // Ukončení
  // -------------------------------------------------------------------

  Future<void> _discard() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.workoutDiscardTitle,
      message: l10n.workoutDiscardMessage,
      confirmLabel: l10n.workoutDiscard,
      destructive: true,
    );
    if (!ok) return;
    _timer.skip();
    await _db.discardSession(widget.sessionId);
    if (mounted) _close();
  }

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context);
    final anyDone = _blocks.any((b) => b.rows.any((r) => r.isDone));
    if (!anyDone) {
      final discard = await showConfirmDialog(
        context,
        title: l10n.workoutNoSetsTitle,
        message: l10n.workoutNoSetsMessage,
        confirmLabel: l10n.workoutDiscard,
        destructive: true,
      );
      if (discard) {
        await _db.discardSession(widget.sessionId);
        if (mounted) _close();
      }
      return;
    }

    final anyPending = _blocks.any((b) => b.rows.any((r) => !r.isDone));
    final ok = await showConfirmDialog(
      context,
      title: l10n.workoutFinishTitle,
      message: anyPending ? l10n.workoutFinishPendingMessage : null,
      confirmLabel: l10n.workoutFinish,
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    _timer.skip();
    try {
      final summary = await finishWorkout(_db, widget.sessionId);
      await runWorkoutFinishedHooks(ref, summary);
      if (!mounted) return;
      await showWorkoutSummaryDialog(
        context,
        summary,
        encouragement: wellbeingMessage(
          l10n,
          ref.read(situationProvider),
          MessagePlace.summary,
          DateTime.now(),
        ),
        showCalories:
            ref.read(profileProvider).valueOrNull?.showCalories ?? true,
      );
      if (mounted) _close();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _showMessage(l10n.errorGeneric);
      }
    }
  }

  // -------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final setup = _setup;

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.errorGeneric)),
      );
    }
    if (setup == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (setup.session.endedAt != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.workoutAlreadyFinished)),
      );
    }

    final wellbeing = wellbeingMessage(
      l10n,
      ref.watch(situationProvider),
      MessagePlace.workout,
      DateTime.now(),
    );
    final injured = ref.watch(injuredGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(setup.planName ?? l10n.workoutFree),
            _ElapsedText(since: setup.session.startedAt),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : _finish,
            child: Text(l10n.workoutFinish),
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: (action) {
              if (action == _MenuAction.discard) _discard();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _MenuAction.discard,
                child: Text(l10n.workoutDiscard),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          if (wellbeing != null)
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: Text(wellbeing),
              ),
            ),
          for (final block in _blocks)
            _BlockCard(
              block: block,
              injured: injured.isNotEmpty &&
                  (injured.contains(block.data.exercise.muscleGroup) ||
                      block.data.exercise.muscleGroup == MuscleGroup.fullBody),
              onToggle: (i) => _toggleSet(block, i),
              onEdited: (row) => _onRowEdited(block, row),
              onAddSet: () => _addSet(block),
              onRemoveSet: () => _removeLastSet(block),
              onToggleWarmup: (i) => _toggleWarmup(block, i),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: Text(l10n.planAddExercise),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _timer,
        builder: (context, _) => _timer.isRunning
            ? _RestBar(timer: _timer)
            : const SizedBox.shrink(),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Stav bloků a řádků
// ---------------------------------------------------------------------

typedef _SetValues = ({double? weightKg, int value});

class _SetRow {
  _SetRow({
    required String weight,
    required String value,
    this.savedId,
    this.isWarmup = false,
  })  : weight = TextEditingController(text: weight),
        value = TextEditingController(text: value);

  /// Rozcvičková série: nepočítá se do objemu ani rekordů.
  bool isWarmup;

  final TextEditingController weight;

  /// Opakování, u cviků na čas sekundy.
  final TextEditingController value;
  int? savedId;

  bool get isDone => savedId != null;

  void dispose() {
    weight.dispose();
    value.dispose();
  }
}

class _Block {
  _Block(this.data, this.rows);

  factory _Block.fromData(WorkoutBlockData data) {
    final isDuration = data.exercise.type == ExerciseType.duration;
    // Uložené série se řadí podle pozice, takže po návratu do tréninku
    // zůstanou na svých řádcích, i když byla některá série přeskočena.
    final savedByPosition = {for (final s in data.saved) s.position: s};
    final maxPosition = savedByPosition.keys.fold(-1, math.max);
    final count = math.max(data.targets.length, maxPosition + 1);
    final rows = <_SetRow>[];
    for (var i = 0; i < count; i++) {
      final s = savedByPosition[i];
      if (s != null) {
        rows.add(_SetRow(
          weight: weightInputText(s.weightKg),
          value: '${(isDuration ? s.durationSeconds : s.reps) ?? ''}',
          savedId: s.id,
          isWarmup: s.isWarmup,
        ));
      } else {
        // Cíl z plánu má přednost; chybějící váhu doplníme z minula.
        final target = _targetFor(data, i);
        final prev = _previousFor(data, i);
        rows.add(_SetRow(
          weight: weightInputText(target?.weightKg ?? prev?.weightKg),
          value: '${target?.reps ?? (isDuration ? prev?.durationSeconds : prev?.reps) ?? 10}',
          isWarmup: target?.isWarmup ?? false,
        ));
      }
    }
    return _Block(data, rows);
  }

  final WorkoutBlockData data;
  final List<_SetRow> rows;

  bool get isDuration => data.exercise.type == ExerciseType.duration;

  /// U cviků s vlastní vahou je váha volitelná (přidaná zátěž).
  bool get weightRequired =>
      data.exercise.type == ExerciseType.weightReps &&
      data.exercise.equipment != Equipment.bodyweight;

  static PlanSetDraft? _targetFor(WorkoutBlockData data, int index) {
    if (data.targets.isEmpty) return null;
    return index < data.targets.length ? data.targets[index] : data.targets.last;
  }

  static SetEntry? _previousFor(WorkoutBlockData data, int index) {
    if (data.previous.isEmpty) return null;
    return index < data.previous.length
        ? data.previous[index]
        : data.previous.last;
  }

  SetEntry? previousAt(int index) =>
      index < data.previous.length ? data.previous[index] : null;

  /// Nová série = kopie poslední pracovní série.
  _SetRow copyLastRow() {
    final last = rows.where((r) => !r.isWarmup).lastOrNull ?? rows.lastOrNull;
    return _SetRow(
      weight: last?.weight.text ?? '',
      value: last?.value.text ?? '10',
    );
  }

  /// Popisky řádků: rozcvička „R“, pracovní série číslované od 1.
  List<String> rowLabels(String warmupLabel) {
    var n = 0;
    return [for (final r in rows) r.isWarmup ? warmupLabel : '${++n}'];
  }

  /// Vrátí hodnoty řádku, nebo null, pokud nejsou platné.
  _SetValues? parse(_SetRow row) {
    final value = int.tryParse(row.value.text.trim());
    if (value == null || value <= 0 || value > 3600) return null;
    if (isDuration) return (weightKg: null, value: value);

    final weight = parseWeightInput(row.weight.text);
    if (weight == null) {
      return weightRequired ? null : (weightKg: null, value: value);
    }
    if (weight < 0 || weight > 1000) return null;
    if (weight == 0) {
      return weightRequired ? null : (weightKg: null, value: value);
    }
    return (weightKg: weight, value: value);
  }

  void dispose() {
    for (final r in rows) {
      r.dispose();
    }
  }
}

// ---------------------------------------------------------------------
// Widgety
// ---------------------------------------------------------------------

class _BlockCard extends StatelessWidget {
  const _BlockCard({
    required this.block,
    this.injured = false,
    required this.onToggle,
    required this.onEdited,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onToggleWarmup,
  });

  final _Block block;

  /// Cvik zatěžuje partii, kterou má uživatel právě zraněnou.
  final bool injured;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onToggleWarmup;
  final ValueChanged<_SetRow> onEdited;
  final VoidCallback onAddSet;
  final VoidCallback onRemoveSet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelSmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final canRemove = block.rows.length > 1 && !block.rows.last.isDone;
    final labels = block.rowLabels(l10n.setWarmupShort);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        showExerciseMediaSheet(context, block.data.exercise),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            block.data.exercise.localizedName(context),
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          semanticLabel: l10n.mediaShowExercise,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  l10n.workoutRestLabel(block.data.restSeconds),
                  style: muted,
                ),
              ],
            ),
            if (injured)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Icon(Icons.healing_outlined,
                        size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.workoutInjuredPart,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            if (block.data.record != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  describeRecord(context, block.data.record!),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.tertiary),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(width: 28, child: Text(l10n.workoutColSet, style: muted)),
                Expanded(child: Text(l10n.workoutColPrevious, style: muted)),
                if (!block.isDuration) ...[
                  SizedBox(
                    width: 72,
                    child: Text(weightUnit, style: muted, textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 20),
                ],
                SizedBox(
                  width: 60,
                  child: Text(
                    block.isDuration ? 's' : l10n.workoutColReps,
                    style: muted,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            for (var i = 0; i < block.rows.length; i++)
              _SetRowView(
                label: labels[i],
                row: block.rows[i],
                isDuration: block.isDuration,
                previous: block.previousAt(i),
                onToggle: () => onToggle(i),
                onEdited: () => onEdited(block.rows[i]),
                onToggleWarmup: () => onToggleWarmup(i),
              ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onAddSet,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.workoutAddSet),
                ),
                if (canRemove)
                  IconButton(
                    tooltip: l10n.workoutRemoveSet,
                    onPressed: onRemoveSet,
                    icon: const Icon(Icons.remove),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRowView extends StatelessWidget {
  const _SetRowView({
    required this.label,
    required this.row,
    required this.isDuration,
    required this.previous,
    required this.onToggle,
    required this.onEdited,
    required this.onToggleWarmup,
  });

  final String label;
  final _SetRow row;
  final bool isDuration;
  final SetEntry? previous;
  final VoidCallback onToggle;
  final VoidCallback onEdited;
  final VoidCallback onToggleWarmup;

  String _previousText(BuildContext context) {
    final p = previous;
    if (p == null) return '–';
    if (isDuration) return '${p.durationSeconds ?? '–'} s';
    final w = p.weightKg;
    return w == null ? '${p.reps ?? '–'}×' : '${formatWeight(context, w)} × ${p.reps ?? '–'}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = row.isDone;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: done ? scheme.primaryContainer.withValues(alpha: 0.5) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Klepnutím na číslo série ji označíš jako rozcvičku (a zpět).
          InkWell(
            onTap: done ? null : onToggleWarmup,
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 28,
              height: 40,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: row.isWarmup ? scheme.tertiary : null,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              _previousText(context),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          if (!isDuration) ...[
            SizedBox(
              width: 72,
              child: _NumberField(
                controller: row.weight,
                decimal: true,
                onChanged: onEdited,
              ),
            ),
            const SizedBox(width: 20, child: Text('×', textAlign: TextAlign.center)),
          ],
          SizedBox(
            width: 60,
            child: _NumberField(
              controller: row.value,
              decimal: false,
              onChanged: onEdited,
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: onToggle,
              icon: Icon(
                done ? Icons.check_circle : Icons.check_circle_outline,
                color: done ? scheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.decimal,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool decimal;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(decimal ? r'[0-9.,]' : r'[0-9]'),
          ),
        ],
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

class _RestBar extends StatelessWidget {
  const _RestBar({required this.timer});

  final RestTimer timer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: timer.progress),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined),
                  const SizedBox(width: 8),
                  Text(l10n.workoutRest, style: theme.textTheme.titleSmall),
                  const SizedBox(width: 8),
                  Text(
                    formatDuration(timer.remaining + const Duration(milliseconds: 999)),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => timer.adjust(-15),
                    child: const Text('−15'),
                  ),
                  TextButton(
                    onPressed: () => timer.adjust(15),
                    child: const Text('+15'),
                  ),
                  TextButton(
                    onPressed: timer.skip,
                    child: Text(l10n.workoutSkipRest),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uplynulý čas od začátku tréninku, obnovovaný každou sekundu.
class _ElapsedText extends StatefulWidget {
  const _ElapsedText({required this.since});

  final DateTime since;

  @override
  State<_ElapsedText> createState() => _ElapsedTextState();
}

class _ElapsedTextState extends State<_ElapsedText> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker =
        Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatDuration(DateTime.now().difference(widget.since)),
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}

// ---------------------------------------------------------------------
// Souhrn po tréninku
// ---------------------------------------------------------------------

Future<void> showWorkoutSummaryDialog(
  BuildContext context,
  WorkoutSummary summary, {
  String? encouragement,
  bool showCalories = true,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final theme = Theme.of(context);
      Widget line(String label, String value) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(label)),
                Text(value, style: theme.textTheme.titleSmall),
              ],
            ),
          );
      return AlertDialog(
        title: Text(l10n.workoutSummaryTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (encouragement != null) ...[
                Text(encouragement),
                const SizedBox(height: 12),
              ],
              line(l10n.workoutSummaryDuration,
                  formatDuration(summary.duration)),
              line(l10n.workoutSummarySets, '${summary.setCount}'),
              line(l10n.workoutSummaryVolume,
                  formatWeightTotal(context, summary.volumeKg)),
              if (showCalories && summary.estimatedKcal != null)
                line(l10n.workoutSummaryKcal,
                    '≈ ${formatInt(context, summary.estimatedKcal!)} kcal'),
              if (summary.records.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.workoutSummaryRecords,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                for (final r in summary.records)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.emoji_events,
                        color: theme.colorScheme.tertiary),
                    title: Text(r.exercise.localizedName(context)),
                    subtitle: Text(l10n.dataRecordChangeLine(
                      formatWeightWithUnit(context, r.newOneRepMax),
                      formatWeightWithUnit(context, r.previousOneRepMax),
                    )),
                  ),
              ],
              ...moduleSummaryActions(summary),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      );
    },
  );
}
