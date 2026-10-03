// Spojení aplikace v telefonu s aplikací v hodinkách (Wear OS).
//
// Přenos: balíček watch_connectivity (Wearable Data Layer, MessageClient).
// Funguje, dokud běží proces aplikace v telefonu – obrazovka tréninku
// může být na pozadí nebo telefon zamčený. Když systém aplikaci ukončí,
// hodinky ukážou „Telefon neodpovídá“.
//
// Kdo stav vytváří a příkazy provádí:
// - Obrazovka tréninku se při otevření připojí jako [WearWorkoutHandler]
//   (lib/features/workout/workout_screen_wear.dart). Příkazy z hodinek
//   provede přes své vlastní metody (odškrtnutí série, úprava řádku…),
//   takže se zapisují do stejné databáze a UI v telefonu se hned překreslí.
// - Bez otevřené obrazovky hodinky jen ukážou „Otevři trénink v telefonu“
//   (nebo „Neběží žádný trénink“). Série se zapisují vždy jen přes
//   obrazovku tréninku – nikdy přímo do DB mimo ni, aby se stav obrazovky
//   (série v paměti, pauza) a databáze nerozešly.
//
// Příkazy se zpracovávají postupně (fronta), aby dvojité doručení
// „completeSet“ nezapsalo sérii dvakrát.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show AppLifecycleState;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import '../../data/database.dart';
import '../../premium/premium.dart';
import '../../providers.dart';
import '../../router.dart';
import 'wear_protocol.dart';

/// Hodinky s Wear OS jen na Androidu (Apple Watch zatím ne).
bool get wearSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Jak dlouho po poslední zprávě z hodinek je aplikace v hodinkách
/// považovaná za otevřenou (hodinky se ozývají každých 15 s).
const wearSeenWindow = Duration(seconds: 90);

/// Výsledek příkazu.
typedef WearCommandResult = ({bool ok, String? reason});

/// Obrazovka tréninku připojená k hodinkám.
abstract interface class WearWorkoutHandler {
  int get sessionId;

  /// Aktuální stav pro hodinky; null = ještě se načítá (nic se nepošle).
  WearState? buildState();

  Future<WearCommandResult> handle(WearCommand command);
}

/// Čas poslední zprávy z hodinek (pro stav v Profilu).
final wearLastSeenProvider = StateProvider<DateTime?>((ref) => null);

final wearBridgeProvider = Provider<WearBridge>((ref) {
  final bridge = WearBridge(ref);
  ref.onDispose(bridge.dispose);
  // Premium (wearOs): spojení běží vždy, bez předplatného ale hodinky
  // dostanou jen stav „premiumRequired“ a příkazy se odmítnou
  // (WearBridge._allowed).
  bridge.start();
  return bridge;
});

/// Sleduje se v kořeni aplikace (module_hub: [wear:app]). Hlídá, jestli
/// běží trénink, a podle toho posílá hodinkám stav.
final wearAppProvider = Provider<void>((ref) {
  if (!wearSupported) return;
  final bridge = ref.watch(wearBridgeProvider);
  ref.listen<AsyncValue<WorkoutSession?>>(
    activeSessionProvider,
    (_, next) {
      if (next.hasValue) bridge.setActiveSession(next.valueOrNull?.id);
    },
    fireImmediately: true,
  );
  // Po koupi / vypršení předplatného hned poslat hodinkám nový stav.
  ref.listen<bool>(
    premiumProvider.select((a) => a.isPremium(PremiumFeature.wearOs)),
    (_, __) => bridge.publish(force: true),
  );
});

class WearBridge {
  WearBridge(this._ref);

  final Ref _ref;
  WatchConnectivity? _watch;
  StreamSubscription<Map<String, dynamic>>? _sub;
  WearWorkoutHandler? _handler;
  int? _activeSessionId;

  /// Náhodné ID běhu aplikace – hodinky podle něj poznají restart telefonu
  /// (pořadová čísla stavů začnou znovu od 1).
  final int _boot = math.Random().nextInt(1 << 30);
  int _seq = 0;
  String? _lastSentKey;
  DateTime? _lastSeen;
  Future<void> _queue = Future.value();
  bool _disposed = false;

  bool get isRunning => _watch != null;

  /// Má uživatel hodinky (Premium wearOs)? Před spuštěním Premium vždy.
  bool get _allowed =>
      _ref.read(premiumProvider).isPremium(PremiumFeature.wearOs);

  void start() {
    if (!wearSupported || _watch != null || _disposed) return;
    try {
      final watch = WatchConnectivity();
      _watch = watch;
      _sub = watch.messageStream.listen(
        _onMessage,
        onError: (Object e) => debugPrint('Wear: $e'),
      );
    } catch (e) {
      debugPrint('Wear start failed: $e');
      _watch = null;
    }
  }

  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _sub = null;
    _watch = null;
  }

  // -------------------------------------------------------------------
  // Obrazovka tréninku
  // -------------------------------------------------------------------

  void attach(WearWorkoutHandler handler) {
    _handler = handler;
    _activeSessionId = handler.sessionId;
    publish(force: true);
  }

  void detach(WearWorkoutHandler handler) {
    if (!identical(_handler, handler)) return;
    _handler = null;
    publish(force: true);
  }

  void setActiveSession(int? sessionId) {
    if (_activeSessionId == sessionId) return;
    _activeSessionId = sessionId;
    publish();
  }

  // -------------------------------------------------------------------
  // Odesílání
  // -------------------------------------------------------------------

  bool get _watchAppSeen {
    final seen = _lastSeen;
    return seen != null && DateTime.now().difference(seen) < wearSeenWindow;
  }

  WearState? _currentState() {
    if (!_allowed) return const WearState.premiumRequired();
    final handler = _handler;
    final active = _activeSessionId;
    if (handler != null && active == handler.sessionId) {
      // Obrazovka se ještě načítá → zatím nic neposílat.
      return handler.buildState();
    }
    if (active != null) return WearState.openOnPhone(active);
    return const WearState.idle();
  }

  /// Pošle hodinkám aktuální stav, pokud se změnil ([force] = vždy).
  /// Dokud se aplikace v hodinkách neozve, neposílá se nic (zbytečná
  /// komunikace) – po otevření pošlou hodinky „hello“ a stav si vyžádají.
  void publish({bool force = false}) {
    if (_watch == null || _disposed) return;
    if (!force && !_watchAppSeen) return;
    final state = _currentState();
    if (state == null) return;
    final json = state.toJson();
    final key = jsonEncode(json);
    if (!force && key == _lastSentKey) return;
    _lastSentKey = key;
    _send({
      't': WearMsg.state,
      'boot': _boot,
      'seq': ++_seq,
      'sentAtMs': DateTime.now().millisecondsSinceEpoch,
      'state': json,
    });
  }

  /// Požádá aplikaci v hodinkách, aby se ozvala (tlačítko v Profilu).
  void ping() => _send({'t': WearMsg.ping});

  /// Spárované hodinky (nainstalovaná aplikace Wear OS / Galaxy Wearable /
  /// Pixel Watch) a připojené zařízení (hodinky v dosahu).
  Future<({bool paired, bool reachable})> checkDevices() async {
    final watch = _watch;
    if (watch == null) return (paired: false, reachable: false);
    try {
      final paired = await watch.isPaired;
      final reachable = await watch.isReachable;
      return (paired: paired, reachable: reachable);
    } catch (e) {
      debugPrint('Wear check failed: $e');
      return (paired: false, reachable: false);
    }
  }

  void _send(Map<String, Object?> payload) {
    final watch = _watch;
    if (watch == null) return;
    unawaited(_sendAsync(watch, payload));
  }

  Future<void> _sendAsync(
    WatchConnectivity watch,
    Map<String, Object?> payload,
  ) async {
    try {
      await watch.sendMessage(wearEnvelope(payload));
    } catch (e) {
      debugPrint('Wear send failed: $e');
    }
  }

  // -------------------------------------------------------------------
  // Příjem
  // -------------------------------------------------------------------

  void _markSeen() {
    final now = DateTime.now();
    _lastSeen = now;
    final notifier = _ref.read(wearLastSeenProvider.notifier);
    final previous = notifier.state;
    // Profil stačí obnovit jednou za pár sekund.
    if (previous == null || now.difference(previous).inSeconds >= 5) {
      notifier.state = now;
    }
  }

  void _onMessage(Map<String, dynamic> message) {
    final msg = openWearEnvelope(message);
    if (msg == null || _disposed) return;
    _markSeen();
    switch (msg['t']) {
      case WearMsg.hello:
        publish(force: true);
      case WearMsg.command:
        final id = msg['id'];
        if (id is! int) return;
        final command = WearCommand.fromJson(msg);
        if (command == null) {
          _send(WearAck(id, ok: false, reason: WearAckReason.unsupported)
              .toJson());
          return;
        }
        _queue = _queue.then((_) => _run(id, command));
    }
  }

  Future<void> _run(int id, WearCommand command) async {
    WearCommandResult result;
    try {
      final handler = _handler;
      if (!_allowed) {
        result = (ok: false, reason: WearAckReason.premiumRequired);
      } else if (handler != null && _activeSessionId == handler.sessionId) {
        result = await handler.handle(command);
      } else {
        result = _handleWithoutScreen(command);
      }
    } catch (e) {
      debugPrint('Wear command ${command.name} failed: $e');
      result = (ok: false, reason: WearAckReason.error);
    }
    if (_disposed) return;
    _send(WearAck(id, ok: result.ok, reason: result.reason).toJson());
    // Vždy poslat stav – hodinky podle něj zahodí své dočasné úpravy.
    publish(force: true);
  }

  WearCommandResult _handleWithoutScreen(WearCommand command) {
    final session = _activeSessionId;
    if (session == null) return (ok: false, reason: WearAckReason.noWorkout);
    if (command is WearOpenWorkout) {
      final state = WidgetsBinding.instance.lifecycleState;
      if (state != AppLifecycleState.resumed) {
        return (ok: false, reason: WearAckReason.phoneLocked);
      }
      _ref.read(routerProvider).push('/workout/$session');
      return (ok: true, reason: null);
    }
    return (ok: false, reason: WearAckReason.notOpen);
  }
}
