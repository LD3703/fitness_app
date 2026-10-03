import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/coach_tone.dart';
import '../../core/formulas.dart';
import '../../core/superset.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../modules/module_hub.dart';
import '../../modules/wear/wear_bridge.dart';
import '../../modules/wear/wear_protocol.dart';
import '../../modules/wear/wear_snapshot.dart';
import '../../providers.dart';
import '../../services/notification_service.dart';
import '../../ui/coach_messages.dart';
import '../../ui/dialogs.dart';
import '../../ui/format.dart';
import '../../ui/exercise_media_view.dart';
import '../../ui/labels.dart';
import '../../ui/set_format.dart';
import '../../ui/set_kind_chip.dart';
import '../../ui/wellbeing_messages.dart';
import '../exercises/exercise_picker.dart';
import 'rest_timer.dart';
import 'workout_flow.dart';
import 'workout_service.dart';

// Hodinky s Wear OS (modul wear).
part 'workout_screen_wear.dart';

/// Obrazovka probíhajícího tréninku.
///
/// Série se ukládají do databáze hned po odškrtnutí, takže trénink přežije
/// zavření aplikace a dá se v něm pokračovat z obrazovky Dnes.
///
/// Supersérie: cviky se stejnou skupinou se zobrazí pohromadě a střídají
/// se (viz workout_flow.dart) – pauza až po posledním cviku kola. Skupina
/// se ukládá u každé série (SetEntries.supersetGroup), takže propojení
/// cviků během tréninku (i bez plánu) přežije zavření aplikace.
/// Drop série: „Drop série“ přidá za odškrtnutou sérii sérii s vahou o 20 %
/// nižší; mezi sérií a jejími drop sériemi se pauza nespouští.
/// Druh série se ukazuje celým slovem (štítek [SetKindChip]), ne zkratkou.
enum _MenuAction { discard }

enum _BlockAction { linkNext, unlink }

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  final _timer = RestTimer();
  final _blocks = <_Block>[];

  /// Navržená další série (supersérie, drop série) – zvýrazní se.
  _SetRow? _suggested;
  WorkoutSetup? _setup;
  Object? _loadError;
  bool _busy = false;

  late final AppLifecycleListener _lifecycle;

  /// Spojení s hodinkami (workout_screen_wear.dart).
  late final _wear = _WorkoutWearLink(this);

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _onHide, onShow: _onShow);
    _load();
    _wear.attach();
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
    _wear.detach();
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
        // Supersérie musí jít po sobě (např. když cvik mezi nimi zmizel).
        _applyGroups(normalizeSupersetGroups(_groups));
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
      isDrop: row.isDrop && !row.isWarmup,
      supersetGroup: block.group,
    );
    if (!mounted) return;
    HapticFeedback.lightImpact();
    // Index se mohl během zápisu změnit (přidaná drop série) – hledáme znovu.
    final blockIndex = _blocks.indexOf(block);
    final rowIndex = block.rows.indexOf(row);
    setState(() {
      row.savedId = id;
      if (blockIndex < 0 || rowIndex < 0) return;
      final step = nextAfterSet(_flowBlocks(), blockIndex, rowIndex);
      final b = step.block;
      final r = step.row;
      _suggested = b == null || r == null ? null : _blocks[b].rows[r];
      final rest = step.restSeconds;
      if (rest != null) {
        _timer.start(rest);
      } else {
        // Další série navazuje bez pauzy (supersérie, drop série).
        _timer.skip();
      }
    });
  }

  List<FlowBlock> _flowBlocks() => [
        for (final b in _blocks)
          (
            group: b.group,
            restSeconds: b.data.restSeconds,
            rows: [
              for (final r in b.rows)
                (isDone: r.isDone, isWarmup: r.isWarmup, isDrop: r.isDrop),
            ],
          ),
      ];

  /// Úprava už uložené série se hned propíše do databáze.
  void _onRowEdited(_Block block, _SetRow row) {
    _wear.schedulePublish();
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

  /// Klepnutí na číslo série: pracovní → rozcvička → drop → pracovní.
  /// (Drop série nemůže být první.)
  void _cycleKind(_Block block, int index) {
    final row = block.rows[index];
    if (row.isDone) return;
    setState(() {
      if (row.isWarmup) {
        row.isWarmup = false;
        row.isDrop = index > 0;
      } else if (row.isDrop) {
        row.isDrop = false;
      } else {
        row.isWarmup = true;
      }
    });
  }

  /// Přidá drop sérii za poslední odškrtnutou pracovní sérii (a její
  /// případné drop série): stejná opakování, váha o 20 % nižší.
  void _addDrop(_Block block) {
    final anchor = block.rows.lastIndexWhere((r) => r.isDone && !r.isWarmup);
    if (anchor < 0) return;
    var insertAt = anchor + 1;
    while (insertAt < block.rows.length && block.rows[insertAt].isDrop) {
      insertAt++;
    }
    final source = block.rows[insertAt - 1];
    final kg = parseWeightInput(source.weight.text);
    final row = _SetRow(
      weight: kg == null
          ? ''
          : weightInputText(dropSetWeight(kg, step: weightStepKg)),
      value: source.value.text,
      isDrop: true,
    );
    setState(() {
      block.rows.insert(insertAt, row);
      _suggested = row;
    });
    // Drop série se dělá hned – pauzu po předchozí sérii zrušíme.
    _timer.skip();
    _syncPositions(block);
  }

  /// Po vložení řádku doprostřed přepíše pořadí uložených sérií, aby po
  /// návratu do tréninku zůstaly na svých řádcích.
  void _syncPositions(_Block block) {
    for (var i = 0; i < block.rows.length; i++) {
      final id = block.rows[i].savedId;
      if (id != null) _db.updateSetPosition(id, i);
    }
  }

  // -------------------------------------------------------------------
  // Supersérie
  // -------------------------------------------------------------------

  List<int?> get _groups => [for (final b in _blocks) b.group];

  /// Nastaví skupiny cviků a u cviků s uloženými sériemi je zapíše
  /// do databáze. Volat uvnitř setState.
  void _applyGroups(List<int?> groups) {
    for (var i = 0; i < _blocks.length; i++) {
      final block = _blocks[i];
      if (block.group == groups[i]) continue;
      block.group = groups[i];
      if (block.rows.any((r) => r.isDone)) {
        _db.setSessionSupersetGroup(
          widget.sessionId,
          block.data.exercise.id,
          groups[i],
        );
      }
    }
  }

  void _onBlockAction(int index, _BlockAction action) {
    switch (action) {
      case _BlockAction.linkNext:
        final groups = linkSupersetWithNext(_groups, index);
        if (groups == null) {
          _showMessage(AppLocalizations.of(context).supersetTooLarge);
          return;
        }
        setState(() => _applyGroups(groups));
      case _BlockAction.unlink:
        setState(() => _applyGroups(unlinkSuperset(_groups, index)));
    }
  }

  void _addSet(_Block block) =>
      setState(() => block.rows.add(block.copyLastRow()));

  void _removeLastSet(_Block block) {
    if (block.rows.length <= 1 || block.rows.last.isDone) return;
    setState(() {
      final removed = block.rows.removeLast();
      if (identical(_suggested, removed)) _suggested = null;
      removed.dispose();
    });
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
    final db = _db;
    try {
      final summary = await finishWorkout(db, widget.sessionId);
      await runWorkoutFinishedHooks(ref, summary);
      if (!mounted) return;
      final now = DateTime.now();
      final situation = ref.read(situationProvider);
      // Při nemoci, zranění, zotavování a rýsování platí podpůrná hláška;
      // přísná pochvala jen tam, kde žádná není (normální situace).
      // Souhrn k tréninku netlačí, proto se únava neověřuje – po
      // tréninku bývá trénovaná partie skoro vždy nad 80 %.
      final strict =
          effectiveCoachTone(chosenCoachTone(ref), situation) ==
              CoachTone.strict;
      await showWorkoutSummaryDialog(
        context,
        summary,
        encouragement:
            wellbeingMessage(l10n, situation, MessagePlace.summary, now) ??
                (strict ? strictDoneMessage(l10n, now) : null),
        showCalories:
            ref.read(profileProvider).valueOrNull?.showCalories ?? true,
        onFeeling: (f) => db.setSessionFeeling(summary.sessionId, f),
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

  /// Karty cviků; cviky jedné supersérie jsou v jednom rámečku.
  List<Widget> _buildBlocks(BuildContext context, Set<MuscleGroup> injured) {
    final groups = _groups;
    final labels = supersetLabels(groups);
    Widget card(int i) {
      final block = _blocks[i];
      return _BlockCard(
        block: block,
        supersetLabel: labels[i],
        suggested: _suggested,
        canLinkNext: canLinkSupersetWithNext(groups, i),
        injured: injured.isNotEmpty &&
            (injured.contains(block.data.exercise.muscleGroup) ||
                block.data.exercise.muscleGroup == MuscleGroup.fullBody),
        onToggle: (r) => _toggleSet(block, r),
        onEdited: (row) => _onRowEdited(block, row),
        onAddSet: () => _addSet(block),
        onAddDrop: () => _addDrop(block),
        onRemoveSet: () => _removeLastSet(block),
        onCycleKind: (r) => _cycleKind(block, r),
        onAction: (a) => _onBlockAction(i, a),
      );
    }

    final result = <Widget>[];
    var i = 0;
    while (i < _blocks.length) {
      final range = supersetRange(groups, i);
      final label = labels[i];
      if (range.end - range.start < 2 || label == null) {
        result.add(card(i));
        i++;
        continue;
      }
      result.add(_SupersetFrame(
        // „A1“ → „A“
        letter: label.substring(0, label.length - 1),
        children: [for (var k = range.start; k < range.end; k++) card(k)],
      ));
      i = range.end;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final setup = _setup;
    _wear.schedulePublish();

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
          ..._buildBlocks(context, injured),
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

/// Druh série pro párování s minulým tréninkem.
enum _Kind { warmup, working, drop }

_Kind _kindOf({required bool isWarmup, required bool isDrop}) => isWarmup
    ? _Kind.warmup
    : isDrop
        ? _Kind.drop
        : _Kind.working;

class _SetRow {
  _SetRow({
    required String weight,
    required String value,
    this.savedId,
    this.isWarmup = false,
    this.isDrop = false,
  })  : weight = TextEditingController(text: weight),
        value = TextEditingController(text: value);

  /// Rozcvičková série: nepočítá se do objemu ani rekordů.
  bool isWarmup;

  /// Drop série: počítá se do objemu, ne do rekordů; bez pauzy před ní.
  bool isDrop;

  final TextEditingController weight;

  /// Opakování, u cviků na čas sekundy.
  final TextEditingController value;
  int? savedId;

  bool get isDone => savedId != null;

  _Kind get kind => _kindOf(isWarmup: isWarmup, isDrop: isDrop);

  void dispose() {
    weight.dispose();
    value.dispose();
  }
}

class _Block {
  _Block(this.data, this.rows, this.group);

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
          isDrop: s.isDrop && !s.isWarmup,
        ));
      } else {
        // Cíl z plánu má přednost; chybějící váhu doplníme z minula
        // (ze série stejného druhu – drop série z drop série apod.).
        final target = _targetFor(data, i);
        final kind = target == null
            ? _Kind.working
            : _kindOf(isWarmup: target.isWarmup, isDrop: target.isDrop);
        final ordinal = rows.where((r) => r.kind == kind).length;
        final prev = _previousOfKind(data.previous, kind, ordinal) ??
            _lastOfKind(data.previous, kind);
        var weightKg = target?.weightKg ?? prev?.weightKg;
        if (weightKg == null && kind == _Kind.drop && rows.isNotEmpty) {
          // Drop série bez cíle a bez historie: o 20 % méně než předchozí.
          final before = parseWeightInput(rows.last.weight.text);
          if (before != null) {
            weightKg = dropSetWeight(before, step: weightStepKg);
          }
        }
        rows.add(_SetRow(
          weight: weightInputText(weightKg),
          value: '${target?.reps ?? (isDuration ? prev?.durationSeconds : prev?.reps) ?? 10}',
          isWarmup: kind == _Kind.warmup,
          isDrop: kind == _Kind.drop,
        ));
      }
    }
    return _Block(data, rows, data.supersetGroup);
  }

  final WorkoutBlockData data;
  final List<_SetRow> rows;

  /// Supersérie (null = samostatný cvik). Mění se propojením v tréninku.
  int? group;

  bool get isDuration => data.exercise.type == ExerciseType.duration;

  /// U cviků s vlastní vahou je váha volitelná (přidaná zátěž).
  bool get weightRequired =>
      data.exercise.type == ExerciseType.weightReps &&
      data.exercise.equipment != Equipment.bodyweight;

  /// Cíl z plánu pro řádek; za koncem plánu poslední pracovní série
  /// (aby se další přidané řádky nestaly rozcvičkou ani drop sérií).
  static PlanSetDraft? _targetFor(WorkoutBlockData data, int index) {
    if (data.targets.isEmpty) return null;
    if (index < data.targets.length) return data.targets[index];
    return data.targets.where((t) => !t.isWarmup && !t.isDrop).lastOrNull ??
        data.targets.last;
  }

  static _Kind _entryKind(SetEntry s) =>
      _kindOf(isWarmup: s.isWarmup, isDrop: s.isDrop);

  /// [ordinal]-tá série druhu [kind] z minula, nebo null.
  static SetEntry? _previousOfKind(
    List<SetEntry> previous,
    _Kind kind,
    int ordinal,
  ) {
    var n = 0;
    for (final s in previous) {
      if (_entryKind(s) != kind) continue;
      if (n == ordinal) return s;
      n++;
    }
    return null;
  }

  /// Poslední série druhu [kind] z minula (u pracovních série navíc).
  static SetEntry? _lastOfKind(List<SetEntry> previous, _Kind kind) =>
      previous.where((s) => _entryKind(s) == kind).lastOrNull;

  /// Série z minula odpovídající řádku (stejný druh a pořadí v něm).
  SetEntry? previousAt(int index) {
    final kind = rows[index].kind;
    var ordinal = 0;
    for (var i = 0; i < index; i++) {
      if (rows[i].kind == kind) ordinal++;
    }
    return _previousOfKind(data.previous, kind, ordinal);
  }

  /// Nová série = kopie poslední pracovní série.
  _SetRow copyLastRow() {
    final last = rows.where((r) => r.kind == _Kind.working).lastOrNull ??
        rows.lastOrNull;
    return _SetRow(
      weight: last?.weight.text ?? '',
      value: last?.value.text ?? '10',
    );
  }

  /// Jde přidat drop sérii (je odškrtnutá pracovní série)?
  bool get canAddDrop => !isDuration && rows.any((r) => r.isDone && !r.isWarmup);

  /// Čísla řádků: pracovní série číslované od 1, rozcvička a drop série
  /// null (mají místo čísla ikonu a štítek s celým slovem).
  List<int?> rowNumbers() {
    var n = 0;
    return [
      for (final r in rows) r.kind == _Kind.working ? ++n : null,
    ];
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

/// Rámeček kolem cviků jedné supersérie („Supersérie A“).
class _SupersetFrame extends StatelessWidget {
  const _SupersetFrame({required this.letter, required this.children});

  final String letter;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      padding: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: scheme.primary, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                Icon(Icons.link, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  l10n.supersetTitle(letter),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: scheme.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.supersetHint,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({
    required this.block,
    this.supersetLabel,
    this.suggested,
    this.canLinkNext = false,
    this.injured = false,
    required this.onToggle,
    required this.onEdited,
    required this.onAddSet,
    required this.onAddDrop,
    required this.onRemoveSet,
    required this.onCycleKind,
    required this.onAction,
  });

  final _Block block;

  /// „A1“, „A2“… u cviku v supersérii.
  final String? supersetLabel;

  /// Navržená další série (zvýrazní se, pokud je v tomto cviku).
  final _SetRow? suggested;
  final bool canLinkNext;

  /// Cvik zatěžuje partii, kterou má uživatel právě zraněnou.
  final bool injured;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onCycleKind;
  final ValueChanged<_SetRow> onEdited;
  final VoidCallback onAddSet;
  final VoidCallback onAddDrop;
  final VoidCallback onRemoveSet;
  final ValueChanged<_BlockAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelSmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final canRemove = block.rows.length > 1 && !block.rows.last.isDone;
    final numbers = block.rowNumbers();
    final label = supersetLabel;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (label != null) ...[
                  _SupersetBadge(label: label),
                  const SizedBox(width: 8),
                ],
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
                PopupMenuButton<_BlockAction>(
                  tooltip: l10n.supersetMenu,
                  icon: const Icon(Icons.more_vert),
                  onSelected: onAction,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _BlockAction.linkNext,
                      enabled: canLinkNext,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.link),
                        title: Text(l10n.supersetLinkNext),
                      ),
                    ),
                    if (label != null)
                      PopupMenuItem(
                        value: _BlockAction.unlink,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.link_off),
                          title: Text(l10n.supersetUnlink),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (injured)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
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
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Text(
                  describeRecord(context, block.data.record!),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.tertiary),
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: _setColumnWidth,
                    child: _ColumnHeader(l10n.workoutColSet, style: muted),
                  ),
                  Expanded(
                    child: Text(
                      l10n.workoutColPrevious,
                      style: muted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!block.isDuration) ...[
                    SizedBox(
                      width: 72,
                      child: _ColumnHeader(weightUnit,
                          style: muted, center: true),
                    ),
                    const SizedBox(width: 20),
                  ],
                  SizedBox(
                    width: 60,
                    child: _ColumnHeader(
                      block.isDuration ? 's' : l10n.workoutColReps,
                      style: muted,
                      center: true,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            for (var i = 0; i < block.rows.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _SetRowView(
                  number: numbers[i],
                  row: block.rows[i],
                  isDuration: block.isDuration,
                  previous: block.previousAt(i),
                  highlighted: identical(block.rows[i], suggested) &&
                      !block.rows[i].isDone,
                  onToggle: () => onToggle(i),
                  onEdited: () => onEdited(block.rows[i]),
                  onCycleKind: () => onCycleKind(i),
                ),
              ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: onAddSet,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.workoutAddSet),
                ),
                if (block.canAddDrop)
                  TextButton.icon(
                    onPressed: onAddDrop,
                    icon: const Icon(Icons.trending_down),
                    label: Text(l10n.dropAdd),
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

/// Štítek „A1“ cviku v supersérii.
class _SupersetBadge extends StatelessWidget {
  const _SupersetBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Šířka sloupce s číslem série (v záhlaví i v řádcích).
const _setColumnWidth = 32.0;

/// Popisek sloupce: celé slovo, které se v úzkém sloupci zmenší, aby se
/// vešlo (místo zkratek typu „Opak.“).
class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader(this.text, {this.style, this.center = false});

  final String text;
  final TextStyle? style;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: center ? Alignment.center : Alignment.centerLeft,
      child: Text(text, style: style, maxLines: 1),
    );
  }
}

class _SetRowView extends StatelessWidget {
  const _SetRowView({
    required this.number,
    required this.row,
    required this.isDuration,
    required this.previous,
    this.highlighted = false,
    required this.onToggle,
    required this.onEdited,
    required this.onCycleKind,
  });

  /// Číslo pracovní série; null u rozcvičky a drop série.
  final int? number;
  final _SetRow row;
  final bool isDuration;
  final SetEntry? previous;

  /// Navržená další série (supersérie / drop série).
  final bool highlighted;
  final VoidCallback onToggle;
  final VoidCallback onEdited;
  final VoidCallback onCycleKind;

  String _previousText(BuildContext context) {
    final p = previous;
    if (p == null) return '–';
    if (isDuration) return '${p.durationSeconds ?? '–'} s';
    final w = p.weightKg;
    return w == null ? '${p.reps ?? '–'}×' : '${formatWeight(context, w)} × ${p.reps ?? '–'}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final done = row.isDone;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: done ? scheme.primaryContainer.withValues(alpha: 0.5) : null,
        borderRadius: BorderRadius.circular(8),
        border: highlighted
            ? Border.all(color: scheme.primary, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Klepnutím na číslo série přepínáš pracovní → rozcvička → drop.
          // Rozcvička a drop série mají místo čísla ikonu a vedle ní
          // štítek s celým slovem.
          Tooltip(
            message: l10n.dropCycleHint,
            child: InkWell(
              onTap: done ? null : onCycleKind,
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: _setColumnWidth,
                height: 40,
                child: Center(
                  child: number != null
                      ? Text(
                          '$number',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        )
                      : Icon(
                          row.isWarmup ? Icons.whatshot : Icons.trending_down,
                          size: 18,
                          color: row.isWarmup
                              ? scheme.tertiary
                              : scheme.secondary,
                          semanticLabel: row.isWarmup
                              ? l10n.setKindWarmup
                              : l10n.setKindDrop,
                        ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (number == null) ...[
                  ExcludeSemantics(
                    child: SetKindChip(isWarmup: row.isWarmup, showIcon: false),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  _previousText(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
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
  ValueChanged<WorkoutFeeling?>? onFeeling,
}) {
  final l10n = AppLocalizations.of(context);
  final saveFeeling = onFeeling;
  WorkoutFeeling? feeling;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
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
              if (saveFeeling != null) ...[
                const SizedBox(height: 16),
                // Volitelné: upraví zátěž tréninku v odhadu únavy svalů.
                Text(l10n.fatigueFeelingQuestion,
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final f in WorkoutFeeling.values)
                      ChoiceChip(
                        label: Text(switch (f) {
                          WorkoutFeeling.easy => l10n.fatigueFeelingEasy,
                          WorkoutFeeling.ok => l10n.fatigueFeelingOk,
                          WorkoutFeeling.hard => l10n.fatigueFeelingHard,
                        }),
                        selected: feeling == f,
                        onSelected: (selected) {
                          setDialogState(() => feeling = selected ? f : null);
                          saveFeeling(feeling);
                        },
                      ),
                  ],
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
    }),
  );
}
