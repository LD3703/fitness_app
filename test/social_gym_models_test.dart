import 'package:fitness_app/modules/social/gym/gym_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Stav skrytí kopíruje na záznam Cloud Function z dokumentu moderace
  // (gyms/{gymId}/moderation/{entryId}).
  GymEntry entry(Map<String, Object?> extra) =>
      GymEntry.fromMap('u1_bench_press', {
        'uid': 'u1',
        'category': 'bench_press',
        'nickname': 'Tom',
        'gender': 'male',
        'best': 100,
        ...extra,
      })!;

  group('GymEntry skrytí', () {
    test('viditelný záznam', () {
      final e = entry({});
      expect(e.isHidden, isFalse);
      expect(e.hiddenForReports, isFalse);
    });

    test('nereálná hodnota', () {
      final e = entry({'hidden': true, 'hiddenReason': 'implausible:jump'});
      expect(e.isHidden, isTrue);
      expect(e.hiddenForReports, isFalse);
    });

    test('nahlášení (od serveru i jen počtem bez funkce)', () {
      final byServer = entry({'hidden': true, 'hiddenReason': 'reports'});
      expect(byServer.isHidden, isTrue);
      expect(byServer.hiddenForReports, isTrue);
      final byCount = entry({'reportCount': 5});
      expect(byCount.isHidden, isTrue);
      expect(byCount.hiddenForReports, isTrue);
    });

    test('ruční skrytí vývojářem je trvalé jako nahlášení', () {
      expect(entry({'hidden': true}).hiddenForReports, isTrue);
      expect(
        entry({'hidden': true, 'hiddenReason': 'manual'}).hiddenForReports,
        isTrue,
      );
    });
  });
}
