part of 'workout_screen.dart';

// Propojení obrazovky tréninku s hodinkami (modul wear,
// lib/modules/wear/). Je to `part` obrazovky, protože pracuje s jejím
// vnitřním stavem (bloky a řádky v paměti, pauza) – příkazy z hodinek
// provádí přes stejné metody jako klepnutí v telefonu (_toggleSet,
// _onRowEdited, _finish), takže se zapisují do stejné databáze a UI se
// hned překreslí.
//
// Stav pro hodinky se posílá po každém překreslení obrazovky, změně pauzy
// a úpravě řádku. Odesílá se v mikroúloze (ne až po vykreslení snímku),
// protože při zamčeném telefonu se snímky nekreslí, ale příkazy z hodinek
// se zpracovávat musí. Neměnný stav se znovu neposílá (WearBridge.publish).

class _WorkoutWearLink implements WearWorkoutHandler {
  _WorkoutWearLink(this._s);

  final _WorkoutScreenState _s;
  WearBridge? _bridge;
  bool _scheduled = false;
  DateTime? _lastRestEnd;

  static const WearCommandResult _ok = (ok: true, reason: null);
  static const WearCommandResult _notFound =
      (ok: false, reason: WearAckReason.notFound);

  @override
  int get sessionId => _s.widget.sessionId;

  /// Volá se v initState obrazovky.
  void attach() {
    if (!wearSupported) return;
    // Premium (wearOs) hlídá WearBridge: bez předplatného hodinky dostanou
    // stav „premiumRequired“ a příkazy se sem vůbec nedostanou.
    final bridge = _s.ref.read(wearBridgeProvider);
    _bridge = bridge;
    _s._timer.addListener(_onTimer);
    bridge.attach(this);
  }

  /// Volá se v dispose obrazovky (před uvolněním časovače).
  void detach() {
    final bridge = _bridge;
    if (bridge == null) return;
    _bridge = null;
    _s._timer.removeListener(_onTimer);
    bridge.detach(this);
  }

  /// Časovač pauzy hlásí změnu 4× za sekundu – posílá se jen začátek,
  /// konec a úprava pauzy.
  void _onTimer() {
    final end = _s._timer.endsAt;
    if (end == _lastRestEnd) return;
    _lastRestEnd = end;
    schedulePublish();
  }

  void schedulePublish() {
    if (_bridge == null || _scheduled) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      if (_s.mounted) _bridge?.publish();
    });
  }

  // -------------------------------------------------------------------
  // Stav
  // -------------------------------------------------------------------

  WearRowInput _row(_Block block, int index) {
    final row = block.rows[index];
    final previous = block.previousAt(index);
    return (
      isDone: row.isDone,
      isWarmup: row.isWarmup,
      isDrop: row.isDrop,
      weightKg: block.isDuration ? null : parseWeightInput(row.weight.text),
      value: int.tryParse(row.value.text.trim()),
      previousWeightKg: previous?.weightKg,
      previousValue:
          block.isDuration ? previous?.durationSeconds : previous?.reps,
      savedId: row.savedId,
    );
  }

  List<WearBlockInput> _inputs() {
    final context = _s.context;
    return [
      for (final b in _s._blocks)
        (
          exerciseId: b.data.exercise.id,
          name: b.data.exercise.localizedName(context),
          isDuration: b.isDuration,
          weightRequired: b.weightRequired,
          rows: [for (var i = 0; i < b.rows.length; i++) _row(b, i)],
        ),
    ];
  }

  WearSetPosition? _suggestedPosition() {
    final row = _s._suggested;
    if (row == null) return null;
    for (var b = 0; b < _s._blocks.length; b++) {
      final r = _s._blocks[b].rows.indexOf(row);
      if (r >= 0) return (block: b, row: r);
    }
    return null;
  }

  @override
  WearState? buildState() {
    final setup = _s._setup;
    if (!_s.mounted || setup == null || setup.session.endedAt != null) {
      return null;
    }
    // Trénink se právě ukončuje – hodinky dostanou „bez tréninku“, jakmile
    // se session v databázi uzavře.
    if (_s._busy) return null;
    final timer = _s._timer;
    return buildActiveWearState(
      sessionId: sessionId,
      title: setup.planName,
      startedAt: setup.session.startedAt,
      blocks: _inputs(),
      suggested: _suggestedPosition(),
      restEndsAt: timer.isRunning ? timer.endsAt : null,
      restTotalSeconds: timer.totalSeconds,
      unit: weightUnit,
      kgPerUnit: isImperial ? kgPerLb : 1.0,
      weightStep: weightDisplayStep,
    );
  }

  // -------------------------------------------------------------------
  // Příkazy
  // -------------------------------------------------------------------

  @override
  Future<WearCommandResult> handle(WearCommand command) async {
    final s = _s;
    if (!s.mounted || s._setup == null) {
      return (ok: false, reason: WearAckReason.notOpen);
    }
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      // Uživatel cvičí s hodinkami a pauzu hlídají ony – upozornění
      // na konec pauzy z telefonu by přišlo zbytečně podruhé.
      unawaited(NotificationService.instance.cancelRestEnd());
    }
    switch (command) {
      case WearCompleteSet c:
        return _complete(c);
      case WearAdjustWeight c:
        return _adjust(c.blockIndex, c.exerciseId, c.setIndex,
            weightDelta: c.delta);
      case WearAdjustReps c:
        return _adjust(c.blockIndex, c.exerciseId, c.setIndex,
            valueDelta: c.delta);
      case WearSkipRest():
        s._timer.skip();
        return _ok;
      case WearNextExercise():
        return _next();
      case WearSelectExercise c:
        return _select(c.blockIndex, c.exerciseId);
      case WearFinishWorkout():
        // Potvrzovací dialog se ukáže v telefonu (i když je zamčený,
        // počká na odemčení).
        if (!s._busy) unawaited(s._finish());
        return (ok: true, reason: WearAckReason.confirmOnPhone);
      case WearOpenWorkout():
        return _ok;
    }
  }

  int? _blockIndexOf(int blockIndex, int exerciseId) {
    final blocks = _s._blocks;
    if (blockIndex >= 0 &&
        blockIndex < blocks.length &&
        blocks[blockIndex].data.exercise.id == exerciseId) {
      return blockIndex;
    }
    final i = blocks.indexWhere((b) => b.data.exercise.id == exerciseId);
    return i < 0 ? null : i;
  }

  _SetRow? _rowAt(int blockIndex, int exerciseId, int setIndex) {
    final b = _blockIndexOf(blockIndex, exerciseId);
    if (b == null) return null;
    final rows = _s._blocks[b].rows;
    if (setIndex < 0 || setIndex >= rows.length) return null;
    return rows[setIndex];
  }

  Future<WearCommandResult> _complete(WearCompleteSet c) async {
    final b = _blockIndexOf(c.blockIndex, c.exerciseId);
    if (b == null) return _notFound;
    final block = _s._blocks[b];
    if (c.setIndex < 0 || c.setIndex >= block.rows.length) return _notFound;
    final row = block.rows[c.setIndex];
    // Opakovaně doručený příkaz – série už je zapsaná.
    if (row.isDone) return _ok;

    if (!block.isDuration) {
      final kg = c.weightKg;
      row.weight.text = kg == null ? '' : weightInputText(kg);
    }
    row.value.text = '${c.value}';
    if (block.parse(row) == null) {
      schedulePublish();
      return (ok: false, reason: WearAckReason.invalid);
    }
    await _s._toggleSet(block, c.setIndex);
    return row.isDone ? _ok : (ok: false, reason: WearAckReason.error);
  }

  WearCommandResult _adjust(
    int blockIndex,
    int exerciseId,
    int setIndex, {
    int weightDelta = 0,
    int valueDelta = 0,
  }) {
    final b = _blockIndexOf(blockIndex, exerciseId);
    final row = _rowAt(blockIndex, exerciseId, setIndex);
    if (b == null || row == null) return _notFound;
    final block = _s._blocks[b];

    if (weightDelta != 0 && !block.isDuration) {
      final kg = parseWeightInput(row.weight.text);
      final display = (kg == null ? 0.0 : kgToDisplay(kg)) +
          weightDelta * weightDisplayStep;
      final rounded = roundDecimals(display, 2);
      row.weight.text = rounded <= 0 ? '' : plainNumber(rounded);
    }
    if (valueDelta != 0) {
      final step = block.isDuration ? kWearDurationStep : 1;
      final current = int.tryParse(row.value.text.trim()) ?? 0;
      final next = math.min(3600, math.max(1, current + valueDelta * step));
      row.value.text = '$next';
    }
    // Uložená série se hned přepíše v databázi; textová pole se překreslí
    // sama (poslouchají svůj controller).
    _s._onRowEdited(block, row);
    return _ok;
  }

  WearCommandResult _next() {
    final blocks = _inputs();
    final current = pickCurrentSet(blocks, suggested: _suggestedPosition());
    final target =
        current == null ? null : nextExercisePosition(blocks, current.block);
    if (target == null) return (ok: false, reason: WearAckReason.allDone);
    _suggest(target);
    return _ok;
  }

  WearCommandResult _select(int blockIndex, int exerciseId) {
    final b = _blockIndexOf(blockIndex, exerciseId);
    if (b == null) return _notFound;
    final target = firstUndoneInBlock(_inputs(), b);
    if (target == null) return (ok: false, reason: WearAckReason.allDone);
    _suggest(target);
    return _ok;
  }

  /// Zvýrazní sérii v telefonu a hodinky ji ukážou jako další.
  void _suggest(WearSetPosition position) {
    final row = _s._blocks[position.block].rows[position.row];
    // ignore: invalid_use_of_protected_member
    _s.setState(() => _s._suggested = row);
  }
}
