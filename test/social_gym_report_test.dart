// Nahlášení v žebříčku posilovny (lib/modules/social/gym/gym_logic.dart):
// hranice skrytí podle počtu členů a kdo smí nahlašovat.
import 'package:fitness_app/modules/social/gym/gym_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hranice skrytí: třetina členů, nejméně 3, nejvýš 5 (jako server)', () {
    expect(gymReportThreshold(0), 3);
    expect(gymReportThreshold(4), 3);
    expect(gymReportThreshold(9), 3);
    expect(gymReportThreshold(10), 4);
    expect(gymReportThreshold(12), 4);
    expect(gymReportThreshold(13), 5);
    expect(gymReportThreshold(500), gymReportHideThreshold);
  });

  group('kdo smí nahlásit', () {
    final now = DateTime(2026, 10, 23, 12);

    test('člen aspoň 7 dní s vlastním záznamem', () {
      expect(
        gymReportBlock(
          joinedAt: now.subtract(const Duration(days: 7)),
          hasOwnEntry: true,
          now: now,
        ),
        isNull,
      );
    });

    test('čerstvý nebo neznámý vstup', () {
      expect(
        gymReportBlock(
          joinedAt: now.subtract(const Duration(days: 6, hours: 23)),
          hasOwnEntry: true,
          now: now,
        ),
        GymReportBlock.tooNew,
      );
      expect(
        gymReportBlock(joinedAt: null, hasOwnEntry: true, now: now),
        GymReportBlock.tooNew,
      );
    });

    test('bez vlastního záznamu', () {
      expect(
        gymReportBlock(
          joinedAt: now.subtract(const Duration(days: 30)),
          hasOwnEntry: false,
          now: now,
        ),
        GymReportBlock.noEntry,
      );
    });
  });
}
