import 'package:fitness_app/modules/health/health_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weightsToImport', () {
    test('takes latest sample per day and skips days present in app', () {
      final result = weightsToImport(
        health: [
          (at: DateTime(2026, 9, 1, 7), kg: 80.04),
          (at: DateTime(2026, 9, 1, 21), kg: 81.26),
          (at: DateTime(2026, 9, 2, 8), kg: 79.5),
          (at: DateTime(2026, 9, 3, 8), kg: 5), // nesmysl
        ],
        appDays: {DateTime(2026, 9, 2)},
      );
      expect(result, {DateTime(2026, 9, 1): 81.3});
    });
  });

  group('weightsToExport', () {
    test('exports only recent days missing in Health', () {
      final result = weightsToExport(
        app: [
          (day: DateTime(2026, 9, 20), kg: 80.0), // před oknem
          (day: DateTime(2026, 9, 25), kg: 80.5), // v Health už je
          (day: DateTime(2026, 9, 26), kg: 80.7),
        ],
        health: [(at: DateTime(2026, 9, 25, 6, 30), kg: 80.4)],
        from: DateTime(2026, 9, 24, 15),
      );
      expect(result, [(day: DateTime(2026, 9, 26), kg: 80.7)]);
    });

    test('skips values already exported with the same weight', () {
      final app = [(day: DateTime(2026, 9, 26), kg: 80.7)];
      expect(
        weightsToExport(
          app: app,
          health: const [],
          from: DateTime(2026, 9, 20),
          alreadyExported: {DateTime(2026, 9, 26): 80.7},
        ),
        isEmpty,
      );
      expect(
        weightsToExport(
          app: app,
          health: const [],
          from: DateTime(2026, 9, 20),
          alreadyExported: {DateTime(2026, 9, 26): 81.0},
        ),
        hasLength(1),
      );
    });
  });

  test('weightSampleTime never lies in the future', () {
    final now = DateTime(2026, 9, 30, 6, 15);
    expect(weightSampleTime(DateTime(2026, 9, 29), now),
        DateTime(2026, 9, 29, 8));
    expect(weightSampleTime(DateTime(2026, 9, 30), now), now);
  });

  test('exported weights survive JSON round trip and pruning', () {
    final m = {DateTime(2026, 9, 1): 80.5, DateTime(2026, 9, 28): 79.9};
    final decoded = decodeExportedWeights(encodeExportedWeights(m));
    expect(decoded, m);
    expect(pruneExportedWeights(decoded, DateTime(2026, 9, 20)),
        {DateTime(2026, 9, 28): 79.9});
    expect(decodeExportedWeights('bad'), isEmpty);
  });

  test('SyncThrottle allows one run per interval', () {
    var now = DateTime(2026, 9, 30, 12);
    final t = SyncThrottle(const Duration(minutes: 10), clock: () => now);
    expect(t.tryAcquire(), isTrue);
    now = now.add(const Duration(minutes: 5));
    expect(t.tryAcquire(), isFalse);
    now = now.add(const Duration(minutes: 5));
    expect(t.tryAcquire(), isTrue);
    t.reset();
    expect(t.tryAcquire(), isTrue);
  });
}
