import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Odpočet pauzy mezi sériemi.
///
/// Počítá s časem konce (ne s odečítáním ticků), takže zůstane přesný
/// i po přepnutí do jiné aplikace. Upozornění na konec pauzy při zamčeném
/// telefonu doplní notifikace v další fázi.
class RestTimer extends ChangeNotifier {
  Timer? _ticker;
  DateTime? _endAt;
  int _totalSeconds = 0;

  bool get isRunning => _endAt != null;

  /// Konec probíhající pauzy (pro hodinky, modul wear).
  DateTime? get endsAt => _endAt;

  /// Celková délka pauzy v sekundách (včetně přidaných).
  int get totalSeconds => _totalSeconds;

  Duration get remaining {
    final end = _endAt;
    if (end == null) return Duration.zero;
    final left = end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Podíl zbývajícího času (1.0 = právě začala, 0.0 = konec).
  double get progress {
    if (!isRunning || _totalSeconds <= 0) return 0;
    return (remaining.inMilliseconds / (_totalSeconds * 1000)).clamp(0.0, 1.0);
  }

  /// Spustí pauzu. Pauza 0 s (nebo záporná) případnou běžící pauzu
  /// zastaví – další série navazuje hned.
  void start(int seconds) {
    if (seconds <= 0) {
      if (isRunning) _stop();
      return;
    }
    _run(DateTime.now().add(Duration(seconds: seconds)), seconds);
  }

  /// Obnoví pauzu s koncem [endAt] (např. po návratu na obrazovku
  /// tréninku); [totalSeconds] je celková délka pro ukazatel průběhu.
  void resume(DateTime endAt, int totalSeconds) {
    if (!endAt.isAfter(DateTime.now())) return;
    _run(endAt, totalSeconds);
  }

  void _run(DateTime endAt, int totalSeconds) {
    _totalSeconds = totalSeconds;
    _endAt = endAt;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    notifyListeners();
  }

  /// Přidá (nebo ubere při záporné hodnotě) sekundy k probíhající pauze.
  void adjust(int seconds) {
    final end = _endAt;
    if (end == null) return;
    _endAt = end.add(Duration(seconds: seconds));
    if (seconds > 0) _totalSeconds += seconds;
    _tick();
  }

  void skip() => _stop();

  void _tick() {
    if (isRunning && remaining == Duration.zero) {
      _stop();
      HapticFeedback.vibrate();
      return;
    }
    notifyListeners();
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
    _endAt = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
