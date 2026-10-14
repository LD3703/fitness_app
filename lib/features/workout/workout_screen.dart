import 'dart:async';
import 'dart:math' as math;

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
import '../../ui/body_map.dart';
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

enum _BlockAction { linkNext, unlink, note }

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  /// Pauza, která běžela, když uživatel z obrazovky tréninku odešel
  /// (podle ID tréninku). Trénink zůstává rozpracovaný; po návratu do něj
  /// pauza pokračuje a mezitím na její konec upozorní notifikace.
  static final _restOnLeave = <int, ({DateTime endsAt, int totalSeconds})>{};

  final _timer = RestTimer();
  final _blocks = <_Block>[];

  /// Navržená další série (supersérie, drop série) – zvýrazní se.
  _SetRow? _suggested;
  WorkoutSetup? _setup;

  /// Zaměření tréninku (síla / svaly / kondice) – určuje automatické
  /// pauzy. Dá se změnit během tréninku.
  TrainingFocus _focus = TrainingFocus.muscle;
  Object? _loadError;
  bool _busy = false;
  bool _addingExercise = false;

  /// Texty pro notifikaci naplánovanou v dispose (tam už context nejde
  /// použít).
  late AppLocalizations _l10n;

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
    _restoreRest();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  /// Návrat do tréninku během pauzy, která běžela při odchodu z obrazovky:
  /// pauza pokračuje tady, notifikace už není potřeba.
  void _restoreRest() {
    final pending = _restOnLeave.remove(widget.sessionId);
    if (pending == null || !pending.endsAt.isAfter(DateTime.now())) return;
    _timer.resume(pending.endsAt, pending.totalSeconds);
    NotificationService.instance.cancelRestEnd();
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
    final restEnd = _timer.endsAt;
    if (restEnd != null && _timer.remaining > Duration.zero) {
      // Odchod z obrazovky (zpět) trénink neukončí – pauza běží dál.
      // Notifikaci na její konec proto nerušíme, ale naplánujeme (v
      // aplikaci ji onHide nenaplánoval) a po návratu pauza pokračuje.
      _restOnLeave[widget.sessionId] =
          (endsAt: restEnd, totalSeconds: _timer.totalSeconds);
      NotificationService.instance.scheduleRestEnd(_timer.remaining, _l10n);
    } else {
      NotificationService.instance.cancelRestEnd();
    }
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
        _focus = setup.focus;
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
    // Zápis téhle série už probíhá (dvojité klepnutí, příkaz z hodinek
    // současně s klepnutím) – druhý zápis by vložil sérii dvakrát.
    if (row.saving) return;
    final savedId = row.savedId;

    if (savedId != null) {
      row.saving = true;
      await _db.deleteSet(savedId).whenComplete(() {
        row.saving = false;
      });
      if (mounted) setState(() => row.savedId = null);
      return;
    }

    final values = block.parse(row);
    if (values == null) {
      _showMessage(AppLocalizations.of(context).workoutSetInvalid);
      return;
    }
    row.saving = true;
    final id = await _db
        .insertSet(
          sessionId: widget.sessionId,
          exerciseId: block.data.exercise.id,
          // Pozice v rámci slotu bloku (stejný cvik může být v tréninku
          // víckrát, viz blockPositionStride).
          position: setPositionFor(block.slot, index),
          weightKg: values.weightKg,
          reps: block.isDuration ? null : values.value,
          durationSeconds: block.isDuration ? values.value : null,
          isWarmup: row.isWarmup,
          isDrop: row.isDrop && !row.isWarmup,
          supersetGroup: block.group,
        )
        .whenComplete(() {
      row.saving = false;
    });
    if (!mounted) return;
    HapticFeedback.lightImpact();
    // Index se mohl během zápisu změnit (přidaná drop série) – hledáme znovu.
    final blockIndex = _blocks.indexOf(block);
    final rowIndex = block.rows.indexOf(row);
    if (rowIndex >= 0 && rowIndex != index) {
      // Řádek se během zápisu posunul (_syncPositions ho ještě neznal) –
      // pozici v databázi srovnáme s jeho skutečným místem.
      _db.updateSetPosition(id, setPositionFor(block.slot, rowIndex));
    }
    setState(() {
      row.savedId = id;
      if (blockIndex < 0 || rowIndex < 0) return;
      final step = nextAfterSet(_flowBlocks(), blockIndex, rowIndex);
      final b = step.block;
      final r = step.row;
      _suggested = b == null || r == null ? null : _blocks[b].rows[r];
      final rest = step.restSeconds;
      if (rest != null && rest > 0) {
        _timer.start(rest);
      } else {
        // Další série navazuje bez pauzy (supersérie, drop série, pauza
        // 0 s) – případná předchozí pauza se zastaví.
        _timer.skip();
      }
    });
  }

  /// Pauza po sérii cviku (ruční z plánu, nebo automatická).
  int _restOf(_Block b) => b.data.restSecondsFor(_focus, _setup?.sex);

  /// Změna zaměření: automatické pauzy se přepočítají (běžící pauza
  /// doběhne beze změny) a volba se zapamatuje pro další trénink.
  void _setFocus(TrainingFocus focus) {
    if (focus == _focus) return;
    HapticFeedback.selectionClick();
    setState(() => _focus = focus);
    unawaited(_db.setSessionFocus(widget.sessionId, focus));
  }

  List<FlowBlock> _flowBlocks() => [
        for (final b in _blocks)
          (
            group: b.group,
            restSeconds: _restOf(b),
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
    // Během zápisu by se druh v databázi a v řádku rozešel.
    if (row.isDone || row.saving) return;
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
    if (!block.canAddRow) return;
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
  /// návratu do tréninku zůstaly na svých řádcích (v rámci slotu bloku).
  void _syncPositions(_Block block) {
    for (var i = 0; i < block.rows.length; i++) {
      final id = block.rows[i].savedId;
      if (id != null) {
        _db.updateSetPosition(id, setPositionFor(block.slot, i));
      }
    }
  }

  // -------------------------------------------------------------------
  // Supersérie
  // -------------------------------------------------------------------

  List<int?> get _groups => [for (final b in _blocks) b.group];

  /// Nastaví skupiny cviků a u cviků s uloženými sériemi je zapíše
  /// do databáze – jen k sériím daného bloku (stejný cvik může být
  /// v tréninku víckrát a každý výskyt má vlastní skupinu). Volat uvnitř
  /// setState.
  void _applyGroups(List<int?> groups) {
    for (var i = 0; i < _blocks.length; i++) {
      final block = _blocks[i];
      if (block.group == groups[i]) continue;
      block.group = groups[i];
      final ids = [
        for (final r in block.rows)
          if (r.savedId != null) r.savedId!,
      ];
      if (ids.isNotEmpty) _db.setSetsSupersetGroup(ids, groups[i]);
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
      case _BlockAction.note:
        _editNote(_blocks[index]);
    }
  }

  /// Moje poznámka ke cviku (platí pro cvik ve všech trénincích).
  Future<void> _editNote(_Block block) async {
    final l10n = AppLocalizations.of(context);
    final text = await showNoteDialog(
      context,
      title: l10n.exerciseNoteMine,
      initialValue: block.myNote ?? '',
      hintText: l10n.exerciseNoteMineHint,
      maxLength: exerciseNoteMax,
    );
    if (text == null || !mounted) return;
    final exerciseId = block.data.exercise.id;
    try {
      await _db.setExerciseNote(exerciseId, text);
    } catch (e) {
      if (mounted) _showMessage(l10n.errorGeneric);
      return;
    }
    if (!mounted) return;
    setState(() {
      for (final b in _blocks) {
        if (b.data.exercise.id == exerciseId) {
          b.myNote = text.isEmpty ? null : clipNote(text);
        }
      }
    });
  }

  void _addSet(_Block block) {
    if (!block.canAddRow) return;
    setState(() => block.rows.add(block.copyLastRow()));
  }

  void _removeLastSet(_Block block) {
    // Řádek, jehož série se právě zapisuje, nejde odebrat (série by
    // v databázi zůstala bez řádku).
    if (block.rows.length <= 1 ||
        block.rows.last.isDone ||
        block.rows.last.saving) {
      return;
    }
    setState(() {
      final removed = block.rows.removeLast();
      if (identical(_suggested, removed)) _suggested = null;
      removed.dispose();
    });
  }

  /// Přidá cvik na konec tréninku. Cvik, který už v tréninku je, dostane
  /// další volný slot – jeho série se ukládají na vlastní pozice a po
  /// návratu do tréninku se nesmíchají s prvním výskytem
  /// (viz blockPositionStride v workout_service.dart).
  Future<void> _addExercise() async {
    // Dvě souběžná přidání stejného cviku by dostala stejný slot.
    if (_addingExercise) return;
    _addingExercise = true;
    try {
      final exercise = await showExercisePicker(context);
      if (exercise == null || !mounted) return;
      final data = await loadExtraBlock(
        _db,
        widget.sessionId,
        exercise,
        slot: _nextSlotOf(exercise.id),
      );
      if (mounted) setState(() => _blocks.add(_Block.fromData(data)));
    } finally {
      _addingExercise = false;
    }
  }

  /// První volný slot cviku (o jedna víc než nejvyšší použitý).
  int _nextSlotOf(int exerciseId) => _blocks
      .where((b) => b.data.exercise.id == exerciseId)
      .fold<int>(0, (next, b) => math.max(next, b.slot + 1));

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
      if (!discard || !mounted) return;
      // Pauza může běžet i bez odškrtnuté série (série odškrtnutá a zase
      // zrušená) – bez zastavení by dispose naplánoval upozornění na konec
      // pauzy už zahozeného tréninku.
      _timer.skip();
      await _db.discardSession(widget.sessionId);
      if (mounted) _close();
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
        restSeconds: _restOf(block),
        supersetLabel: labels[i],
        suggested: _suggested,
        canLinkNext: canLinkSupersetWithNext(groups, i),
        injured: injured.isNotEmpty &&
            (injured.any((g) => g.overlaps(block.data.exercise.muscleGroup)) ||
                block.data.exercise.muscleGroup == MuscleGroup.fullBody),
        onToggle: (r) => _toggleSet(block, r),
        onEdited: (row) => _onRowEdited(block, row),
        onAddSet: () => _addSet(block),
        onAddDrop: () => _addDrop(block),
        onRemoveSet: () => _removeLastSet(block),
        onCycleKind: (r) => _cycleKind(block, r),
        onAction: (a) => _onBlockAction(i, a),
        trainerName: _setup?.planTrainer,
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

    // Zpět jde vždy (bez dialogu): trénink zůstane rozpracovaný a dá se
    // v něm pokračovat z obrazovky Dnes; odškrtnuté série jsou uložené
    // a běžící pauza pokračuje (viz dispose). Jen během ukončování
    // tréninku se odejít nedá, aby se neztratil souhrn.
    return PopScope(
      canPop: !_busy,
      child: _buildScaffold(context, l10n, setup, wellbeing, injured),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    AppLocalizations l10n,
    WorkoutSetup setup,
    String? wellbeing,
    Set<MuscleGroup> injured,
  ) {
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
          _FocusSelector(focus: _focus, onChanged: _setFocus),
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

  /// Zápis / smazání série v databázi právě probíhá.
  bool saving = false;

  bool get isDone => savedId != null;

  _Kind get kind => _kindOf(isWarmup: isWarmup, isDrop: isDrop);

  void dispose() {
    weight.dispose();
    value.dispose();
  }
}

class _Block {
  _Block(this.data, this.rows, this.group) : myNote = data.exercise.note;

  factory _Block.fromData(WorkoutBlockData data) {
    final isDuration = data.exercise.type == ExerciseType.duration;
    // Uložené série se řadí podle pozice (v rámci slotu bloku, viz
    // blockPositionStride), takže po návratu do tréninku zůstanou na svých
    // řádcích, i když byla některá série přeskočena.
    final savedByRow = <int, SetEntry>{};
    // Série se stejnou pozicí (starší data z doby, kdy se výskyty
    // stejného cviku srážely) se nezahodí – přidají se za ostatní řádky.
    final leftovers = <SetEntry>[];
    for (final s in data.saved) {
      final row = blockRowOf(s.position);
      if (savedByRow.containsKey(row)) {
        leftovers.add(s);
      } else {
        savedByRow[row] = s;
      }
    }
    final maxRow = savedByRow.keys.fold(-1, math.max);

    _SetRow savedRow(SetEntry s) => _SetRow(
          weight: weightInputText(s.weightKg),
          value: '${(isDuration ? s.durationSeconds : s.reps) ?? ''}',
          savedId: s.id,
          isWarmup: s.isWarmup,
          isDrop: s.isDrop && !s.isWarmup,
        );

    // Řádky se párují s cíli plánu postupně: uložená drop série, která
    // v plánu není (vložená tlačítkem „Drop série“), cíl nespotřebuje,
    // takže po návratu do tréninku nezmizí žádná plánovaná série
    // (dřív se počet řádků bral jako max(cíle, poslední pozice + 1)).
    final targets = data.targets;
    var t = 0;
    final rows = <_SetRow>[];
    for (var i = 0; i <= maxRow || t < targets.length; i++) {
      final s = savedByRow[i];
      if (s != null) {
        rows.add(savedRow(s));
        final insertedDrop = s.isDrop &&
            !s.isWarmup &&
            (t >= targets.length || !targets[t].isDrop);
        if (!insertedDrop) t++;
        continue;
      }
      // Cíl z plánu má přednost; chybějící váhu doplníme z minula
      // (ze série stejného druhu – drop série z drop série apod.).
      final target = t < targets.length ? targets[t] : _targetFor(data, t);
      t++;
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
    rows.addAll(leftovers.map(savedRow));
    return _Block(data, rows, data.supersetGroup);
  }

  final WorkoutBlockData data;
  final List<_SetRow> rows;

  /// Supersérie (null = samostatný cvik). Mění se propojením v tréninku.
  int? group;

  /// Moje poznámka ke cviku (dá se upravit během tréninku).
  String? myNote;

  /// Pořadí výskytu cviku v tréninku (viz blockPositionStride).
  int get slot => data.slot;

  /// Další řádek se ještě vejde do rozsahu pozic slotu.
  bool get canAddRow => rows.length < blockPositionStride;

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
/// Volba zaměření tréninku nahoře na obrazovce: síla / svaly / kondice.
/// Podle ní se počítají automatické pauzy mezi sériemi.
class _FocusSelector extends StatelessWidget {
  const _FocusSelector({required this.focus, required this.onChanged});

  final TrainingFocus focus;
  final ValueChanged<TrainingFocus> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<TrainingFocus>(
            showSelectedIcon: false,
            segments: [
              for (final f in TrainingFocus.values)
                ButtonSegment(
                  value: f,
                  label: Text(
                    l10n.trainingFocus(f),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            selected: {focus},
            onSelectionChanged: (v) => onChanged(v.first),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.trainingFocusHint(focus),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

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
    required this.restSeconds,
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
    this.trainerName,
  });

  final _Block block;

  /// Plán je od trenéra – poznámka v plánu je jeho.
  final String? trainerName;

  /// Pauza po sérii (ruční z plánu, nebo automatická).
  final int restSeconds;

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
                ExerciseMuscleIcon(exercise: block.data.exercise, size: 36),
                const SizedBox(width: 10),
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
                Tooltip(
                  message: block.data.restIsAuto
                      ? l10n.restAutoHint
                      : l10n.restManualHint,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (block.data.restIsAuto) ...[
                        Icon(Icons.auto_awesome,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                      ],
                      Text(l10n.workoutRestLabel(restSeconds), style: muted),
                    ],
                  ),
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
                    PopupMenuItem(
                      value: _BlockAction.note,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.edit_note),
                        title: Text(l10n.exerciseNoteMenu),
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
            if (block.data.planNote case final note?)
              _NoteLine(
                icon: trainerName == null
                    ? Icons.sticky_note_2_outlined
                    : Icons.sports,
                label: trainerName == null
                    ? null
                    : l10n.workoutNoteFromTrainer(trainerName!),
                text: note,
              ),
            if (block.myNote case final note?)
              _NoteLine(
                icon: Icons.edit_note,
                text: note,
                onTap: () => onAction(_BlockAction.note),
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

/// Poznámka u cviku v tréninku (z plánu / od trenéra, nebo moje).
class _NoteLine extends StatelessWidget {
  const _NoteLine({
    required this.icon,
    required this.text,
    this.label,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall;
    final line = Padding(
      padding: const EdgeInsets.only(top: 4, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                if (label != null)
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                TextSpan(text: text),
              ]),
              style: style,
            ),
          ),
        ],
      ),
    );
    return onTap == null ? line : InkWell(onTap: onTap, child: line);
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
                semanticLabel: l10n.workoutWeightField(weightUnit),
                onChanged: onEdited,
              ),
            ),
            const SizedBox(
              width: 20,
              child: ExcludeSemantics(
                child: Text('×', textAlign: TextAlign.center),
              ),
            ),
          ],
          SizedBox(
            width: 60,
            child: _NumberField(
              controller: row.value,
              decimal: false,
              semanticLabel: isDuration
                  ? l10n.workoutDurationField
                  : l10n.workoutColReps,
              onChanged: onEdited,
            ),
          ),
          SizedBox(
            width: 48,
            // Čtečka obrazovky hlásí stav série (zaškrtnuto / nezaškrtnuto)
            // a co klepnutí udělá.
            child: MergeSemantics(
              child: Semantics(
                checked: done,
                child: IconButton(
                  tooltip: done
                      ? l10n.workoutMarkSetNotDone
                      : l10n.workoutMarkSetDone,
                  onPressed: onToggle,
                  icon: Icon(
                    done ? Icons.check_circle : Icons.check_circle_outline,
                    color: done ? scheme.primary : null,
                  ),
                ),
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
    required this.semanticLabel,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool decimal;

  /// Popisek pole pro čtečku obrazovky (viditelný je jen v záhlaví
  /// sloupce, pole samo popisek nemá).
  final String semanticLabel;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: MergeSemantics(
        child: Semantics(
          label: semanticLabel,
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
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
      ),
    );
  }
}

/// O kolik sekund tlačítka v liště pauzy zkrátí / prodlouží pauzu.
const _restAdjustSeconds = 15;

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
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              // Dvě skupiny ve Wrap: na úzkém displeji (320 dp, němčina,
              // velké písmo) se tlačítka zalomí na druhý řádek místo
              // přetečení; v každé skupině se dlouhý text zkrátí „…“.
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.workoutRest,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatDuration(
                            timer.remaining + const Duration(milliseconds: 999)),
                        maxLines: 1,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l10n.workoutRestShorten(_restAdjustSeconds),
                        onPressed: () => timer.adjust(-_restAdjustSeconds),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      IconButton(
                        tooltip: l10n.workoutRestExtend(_restAdjustSeconds),
                        onPressed: () => timer.adjust(_restAdjustSeconds),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      Flexible(
                        child: TextButton(
                          onPressed: timer.skip,
                          child: Text(
                            l10n.workoutSkipRest,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
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
              if (summary.muscles.primary.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.workoutSummaryMuscles,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                TrainedBodyMap(
                  sets: summary.muscles,
                  primaryLabel: l10n.bodyMapPrimary,
                  secondaryLabel: l10n.bodyMapSecondary,
                  groupName: l10n.muscleGroup,
                  height: 160,
                ),
              ],
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
                      l10n.statsSetWeightReps(
                          formatWeightWithUnit(context, r.weightKg), r.reps),
                      l10n.statsSetWeightReps(
                          formatWeightWithUnit(context, r.previousWeightKg),
                          r.previousReps),
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
