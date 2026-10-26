// Tep posílaný živě z hodinek během tréninku (Wear OS i Apple Watch přes
// modul wear). Po tréninku z něj modul health spočítá průměr, maximum
// a zóny (core/readiness.dart) – i když hodinky do Health Connect /
// Apple Zdraví tep zapíšou až později nebo vůbec.

import 'package:flutter/foundation.dart';

import '../core/readiness.dart';

class LiveHeartRate {
  LiveHeartRate._();

  static final LiveHeartRate instance = LiveHeartRate._();

  /// Poslední hodnota pro zobrazení v telefonu (null = hodinky tep
  /// neposílají nebo je poslední hodnota starší než 30 s).
  final ValueNotifier<int?> current = ValueNotifier(null);

  final List<TimedValue> _samples = [];
  DateTime? _lastAt;

  /// Nejvýš ~3 hodiny po jednom vzorku za sekundu.
  static const _maxSamples = 12000;

  void add(int bpm, {DateTime? at}) {
    if (bpm < 30 || bpm > 240) return;
    final t = at ?? DateTime.now();
    _samples.add((at: t, value: bpm.toDouble()));
    if (_samples.length > _maxSamples) _samples.removeAt(0);
    _lastAt = t;
    current.value = bpm;
    Future<void>.delayed(const Duration(seconds: 30), () {
      final last = _lastAt;
      if (last != null &&
          DateTime.now().difference(last) >= const Duration(seconds: 30)) {
        current.value = null;
      }
    });
  }

  /// Vzorky v rozmezí tréninku.
  List<TimedValue> samplesBetween(DateTime start, DateTime end) => [
        for (final s in _samples)
          if (!s.at.isBefore(start) && !s.at.isAfter(end)) s,
      ];

  /// Po uložení tréninku: starší vzorky už nejsou potřeba.
  void clearBefore(DateTime t) => _samples.removeWhere((s) => s.at.isBefore(t));
}
