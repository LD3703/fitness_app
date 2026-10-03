import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import 'native.dart';
import 'strings.dart';
import 'wear_protocol.dart';

/// Co hodinky právě ukazují.
enum WatchPhase {
  /// Čeká se na první odpověď telefonu.
  connecting,

  /// Telefon neodpovídá (aplikace v telefonu neběží nebo je mimo dosah).
  unreachable,
  idle,
  openOnPhone,
  active,

  /// Hodinky jsou v telefonu funkce Premium a uživatel ji nemá.
  premiumRequired,
}

class _Pending {
  _Pending(this.command, this.timeout);

  final WearCommand command;
  final Timer timeout;
}

/// Dočasná úprava váhy / opakování na hodinkách, než ji potvrdí telefon.
class _Edit {
  _Edit(this.key, this.weightKg, this.value);

  final String key;
  double? weightKg;
  int? value;
  DateTime at = DateTime.now();
}

/// Stav aplikace v hodinkách a komunikace s telefonem.
///
/// Telefon je jediný zdroj pravdy: posílá stav tréninku a provádí příkazy.
/// Hodinky jen zobrazují a úpravy +/- ukážou hned (dočasně, dokud nepřijde
/// stav z telefonu). Odškrtnutí série posílá hodnoty, které uživatel vidí.
class WatchController extends ChangeNotifier {
  WatchController({WearStrings? strings})
      : strings = strings ?? WearStrings.device();

  final WearStrings strings;
  final WatchConnectivity _watch = WatchConnectivity();

  static const _heartbeat = Duration(seconds: 15);
  static const _staleAfter = Duration(seconds: 50);
  static const _commandTimeout = Duration(seconds: 6);
  static const _editHold = Duration(milliseconds: 2500);

  StreamSubscription<Map<String, dynamic>>? _sub;
  AppLifecycleListener? _lifecycle;
  Timer? _heartbeatTimer;
  Timer? _connectTimer;
  Timer? _restTicker;
  Timer? _noticeTimer;

  WearState? _state;
  int? _boot;
  int _seq = 0;
  DateTime? _lastStateAt;
  bool _unreachable = false;

  DateTime? _restEnd;
  int _restTotal = 0;
  bool _restAlerted = false;

  int _nextId = 1;
  final _pending = <int, _Pending>{};
  _Edit? _edit;
  String? _notice;
  bool _showList = false;
  bool _disposed = false;

  // -------------------------------------------------------------------
  // Stav pro UI
  // -------------------------------------------------------------------

  WearState? get state => _state;
  String? get notice => _notice;
  bool get showList => _showList;

  WatchPhase get phase {
    final s = _state;
    if (s == null) {
      return _unreachable ? WatchPhase.unreachable : WatchPhase.connecting;
    }
    if (_unreachable) return WatchPhase.unreachable;
    return switch (s.phase) {
      WearPhase.idle => WatchPhase.idle,
      WearPhase.openOnPhone => WatchPhase.openOnPhone,
      WearPhase.active => WatchPhase.active,
      WearPhase.premiumRequired => WatchPhase.premiumRequired,
    };
  }

  WearCurrentSet? get current => _state?.current;

  bool get isResting => _restEnd != null;

  Duration get restRemaining {
    final end = _restEnd;
    if (end == null) return Duration.zero;
    final left = end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// 1.0 = pauza právě začala, 0.0 = konec.
  double get restProgress {
    if (_restEnd == null || _restTotal <= 0) return 0;
    return (restRemaining.inMilliseconds / (_restTotal * 1000)).clamp(0.0, 1.0);
  }

  bool isPending(String commandName) =>
      _pending.values.any((p) => p.command.name == commandName);

  String _setKey(WearCurrentSet c) =>
      '${_state?.sessionId}:${c.blockIndex}:${c.exerciseId}:${c.setIndex}';

  /// Zobrazovaná váha (v kg) – dočasná úprava z hodinek má přednost.
  double? weightKgOf(WearCurrentSet c) {
    final edit = _edit;
    if (edit != null && edit.key == _setKey(c)) return edit.weightKg;
    return c.weightKg;
  }

  int? valueOf(WearCurrentSet c) {
    final edit = _edit;
    if (edit != null && edit.key == _setKey(c)) return edit.value;
    return c.value;
  }

  /// Váha v zobrazovaných jednotkách (kg / lb).
  double? displayWeight(double? kg) {
    final s = _state;
    if (kg == null || s == null || s.kgPerUnit <= 0) return null;
    return _round2(kg / s.kgPerUnit);
  }

  static double _round2(double v) => (v * 100).round() / 100;

  /// 82.5 → „82,5“ (čeština) / „82.5“; 80.0 → „80“.
  String formatNumber(double v) {
    final rounded = _round2(v);
    final text = rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
    return strings.cs ? text.replaceAll('.', ',') : text;
  }

  /// „60 × 10“, „10 ×“ (bez váhy), „30 s“.
  String describeSet(double? weightKg, int? value, {required bool isDuration}) {
    if (value == null) return '–';
    if (isDuration) return '$value s';
    final w = displayWeight(weightKg);
    return w == null ? '$value ×' : '${formatNumber(w)} × $value';
  }

  // -------------------------------------------------------------------
  // Start a konec
  // -------------------------------------------------------------------

  void start() {
    _sub = _watch.messageStream.listen(
      _onMessage,
      onError: (Object e) => debugPrint('Wear: $e'),
    );
    _lifecycle = AppLifecycleListener(
      onResume: _startHeartbeat,
      onPause: _stopHeartbeat,
    );
    _startHeartbeat();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _lifecycle?.dispose();
    _stopHeartbeat();
    _restTicker?.cancel();
    _noticeTimer?.cancel();
    for (final p in _pending.values) {
      p.timeout.cancel();
    }
    unawaited(WearNative.keepScreenOn(false));
    super.dispose();
  }

  /// „hello“ hned a pak pravidelně – telefon odpoví aktuálním stavem.
  /// Podle odpovědí se pozná, že aplikace v telefonu běží.
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeat, (_) => _hello());
    _hello();
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _connectTimer?.cancel();
    _connectTimer = null;
  }

  void _hello() {
    _send({'t': WearMsg.hello});
    final last = _lastStateAt;
    final stale = last == null || DateTime.now().difference(last) > _staleAfter;
    if (stale) {
      // Bez odpovědi do 5 s → telefon nedostupný (dál se zkouší).
      _connectTimer?.cancel();
      _connectTimer = Timer(const Duration(seconds: 5), () {
        final l = _lastStateAt;
        if (l == null || DateTime.now().difference(l) > _staleAfter) {
          _setUnreachable(true);
        }
      });
    }
  }

  /// Tlačítko „Zkusit znovu“.
  void retry() {
    _unreachable = false;
    _lastStateAt = null;
    _notify();
    _hello();
  }

  void _setUnreachable(bool value) {
    if (_unreachable == value) return;
    _unreachable = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // -------------------------------------------------------------------
  // Příjem
  // -------------------------------------------------------------------

  void _onMessage(Map<String, dynamic> message) {
    final msg = openWearEnvelope(message);
    if (msg == null || _disposed) return;
    switch (msg['t']) {
      case WearMsg.state:
        _onState(msg);
      case WearMsg.ack:
        final ack = WearAck.fromJson(msg);
        if (ack != null) _onAck(ack);
      case WearMsg.ping:
        _send({'t': WearMsg.hello});
    }
  }

  void _onState(Map<String, Object?> msg) {
    final state = WearState.fromJson(msg['state']);
    if (state == null) return;
    final boot = msg['boot'];
    final seq = msg['seq'];
    if (boot is int && seq is int) {
      // Starší stav téhož běhu aplikace v telefonu (zprávy mimo pořadí).
      if (boot == _boot && seq <= _seq) return;
      _boot = boot;
      _seq = seq;
    }
    final sentAt = msg['sentAtMs'];
    final now = DateTime.now();
    _lastStateAt = now;
    _unreachable = false;
    _connectTimer?.cancel();

    final previousSession = _state?.sessionId;
    _state = state;
    if (state.sessionId != previousSession || state.phase != WearPhase.active) {
      _showList = false;
    }

    // Dočasná úprava platí jen pro stejnou sérii a krátce po klepnutí.
    final edit = _edit;
    final current = state.current;
    if (edit != null &&
        (current == null ||
            edit.key != _setKey(current) ||
            now.difference(edit.at) > _editHold)) {
      _edit = null;
    }

    _updateRest(state, sentAt is int ? sentAt : null, now);
    _notify();
  }

  void _updateRest(WearState state, int? sentAtMs, DateTime now) {
    final endMs = state.restEndsAtMs;
    if (endMs != null && state.phase == WearPhase.active) {
      // Přepočet na hodiny hodinek: zbývá (konec − odesláno) od teď.
      final remainingMs = endMs - (sentAtMs ?? now.millisecondsSinceEpoch);
      final end = now.add(Duration(milliseconds: remainingMs));
      final old = _restEnd;
      if (old == null || old.difference(end).inMilliseconds.abs() > 1500) {
        final wasResting = old != null;
        _restEnd = end;
        _restAlerted = false;
        if (!wasResting) unawaited(WearNative.keepScreenOn(true));
      }
      _restTotal = state.restTotalSeconds;
      _restTicker ??= Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => _tickRest(),
      );
      return;
    }
    final old = _restEnd;
    if (old != null) {
      // Telefon pauzu ukončil: když to bylo (skoro) v čase konce a hodinky
      // ještě nezavibrovaly, zavibrují teď. Přeskočená pauza nevibruje.
      if (!_restAlerted &&
          !now.isBefore(old.subtract(const Duration(seconds: 2)))) {
        unawaited(WearNative.vibrate());
      }
      _stopRest();
    }
  }

  void _tickRest() {
    final end = _restEnd;
    if (end == null) {
      _stopRest();
      return;
    }
    if (!DateTime.now().isBefore(end) && !_restAlerted) {
      _restAlerted = true;
      unawaited(WearNative.vibrate());
      _stopRest();
    }
    _notify();
  }

  void _stopRest() {
    _restTicker?.cancel();
    _restTicker = null;
    if (_restEnd != null) unawaited(WearNative.keepScreenOn(false));
    _restEnd = null;
    _notify();
  }

  void _onAck(WearAck ack) {
    final pending = _pending.remove(ack.id);
    pending?.timeout.cancel();
    final reason = ack.reason;
    if (!ack.ok) {
      _showNotice(switch (reason) {
        WearAckReason.invalid => strings.checkOnPhone,
        WearAckReason.notOpen => strings.openWorkoutOnPhone,
        WearAckReason.phoneLocked => strings.unlockPhone,
        WearAckReason.noWorkout => strings.noWorkout,
        WearAckReason.allDone => strings.allDone,
        WearAckReason.notFound => strings.notFound,
        WearAckReason.unsupported => strings.updateApps,
        WearAckReason.premiumRequired => strings.premiumRequired,
        _ => strings.somethingWrong,
      });
    } else if (reason == WearAckReason.confirmOnPhone) {
      _showNotice(strings.confirmOnPhone);
    }
    _notify();
  }

  void _showNotice(String text) {
    _notice = text;
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(seconds: 3), () {
      _notice = null;
      _notify();
    });
    _notify();
  }

  // -------------------------------------------------------------------
  // Odesílání
  // -------------------------------------------------------------------

  void _send(Map<String, Object?> payload) {
    unawaited(_sendAsync(payload));
  }

  Future<void> _sendAsync(Map<String, Object?> payload) async {
    try {
      await _watch.sendMessage(wearEnvelope(payload));
    } catch (e) {
      debugPrint('Wear send failed: $e');
    }
  }

  void _command(WearCommand command) {
    final id = _nextId++;
    final timeout = Timer(_commandTimeout, () {
      if (_pending.remove(id) != null) _showNotice(strings.notResponding);
    });
    _pending[id] = _Pending(command, timeout);
    _send(command.toJson(id));
    _notify();
  }

  // -------------------------------------------------------------------
  // Akce z UI
  // -------------------------------------------------------------------

  void completeSet() {
    final c = current;
    if (c == null || isPending('completeSet')) return;
    final weight = c.isDuration ? null : weightKgOf(c);
    final value = valueOf(c);
    if (!c.isDuration && c.weightRequired && weight == null) {
      _showNotice(strings.weightMissing);
      return;
    }
    if (value == null || value <= 0) {
      _showNotice(strings.checkOnPhone);
      return;
    }
    _command(WearCompleteSet(
      blockIndex: c.blockIndex,
      exerciseId: c.exerciseId,
      setIndex: c.setIndex,
      weightKg: weight,
      value: value,
    ));
  }

  void adjustWeight(int delta) {
    final c = current;
    final s = _state;
    if (c == null || s == null || c.isDuration) return;
    final shown = displayWeight(weightKgOf(c)) ?? 0;
    final next = _round2(shown + delta * s.weightStep);
    final edit = _editFor(c)
      ..weightKg = next <= 0 ? null : next * s.kgPerUnit
      ..at = DateTime.now();
    _edit = edit;
    _command(WearAdjustWeight(
      blockIndex: c.blockIndex,
      exerciseId: c.exerciseId,
      setIndex: c.setIndex,
      delta: delta,
    ));
  }

  void adjustValue(int delta) {
    final c = current;
    if (c == null) return;
    final step = c.isDuration ? kWearDurationStep : 1;
    final now = valueOf(c) ?? 0;
    final next = (now + delta * step).clamp(1, 3600).toInt();
    final edit = _editFor(c)
      ..value = next
      ..at = DateTime.now();
    _edit = edit;
    _command(WearAdjustReps(
      blockIndex: c.blockIndex,
      exerciseId: c.exerciseId,
      setIndex: c.setIndex,
      delta: delta,
    ));
  }

  _Edit _editFor(WearCurrentSet c) {
    final key = _setKey(c);
    final edit = _edit;
    if (edit != null && edit.key == key) return edit;
    return _Edit(key, c.weightKg, c.value);
  }

  void skipRest() {
    // Hned schovat odpočet, telefon pak pošle stav bez pauzy.
    _restAlerted = true;
    _stopRest();
    _command(const WearSkipRest());
  }

  void nextExercise() => _command(const WearNextExercise());

  void selectExercise(WearExerciseItem item) {
    _showList = false;
    _command(WearSelectExercise(
      blockIndex: item.blockIndex,
      exerciseId: item.exerciseId,
    ));
  }

  void finishWorkout() => _command(const WearFinishWorkout());

  void openWorkout() => _command(const WearOpenWorkout());

  void toggleList(bool show) {
    if (_showList == show) return;
    _showList = show;
    _notify();
  }
}
