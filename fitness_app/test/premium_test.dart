import 'package:fitness_app/data/seed/plan_templates.dart';
import 'package:fitness_app/premium/premium_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hasPremiumAccess', () {
    test('před spuštěním Premium je odemčené vše', () {
      expect(
        hasPremiumAccess(
          launched: false,
          profilePremium: false,
          entitlementActive: false,
        ),
        isTrue,
      );
    });

    test('po spuštění rozhoduje profil nebo nárok RevenueCat', () {
      expect(
        hasPremiumAccess(
          launched: true,
          profilePremium: false,
          entitlementActive: false,
        ),
        isFalse,
      );
      expect(
        hasPremiumAccess(
          launched: true,
          profilePremium: true,
          entitlementActive: false,
        ),
        isTrue,
      );
      expect(
        hasPremiumAccess(
          launched: true,
          profilePremium: false,
          entitlementActive: true,
        ),
        isTrue,
      );
    });
  });

  group('Premium na půl roku zdarma', () {
    test('dárek odemkne Premium i po spuštění plateb', () {
      expect(
        hasPremiumAccess(
          launched: true,
          profilePremium: false,
          entitlementActive: false,
          giftActive: true,
        ),
        isTrue,
      );
    });

    test('konec dárku je za 6 měsíců na konci dne', () {
      expect(premiumGiftEnd(DateTime(2026, 10, 3, 19, 56)),
          DateTime(2027, 4, 3, 23, 59, 59));
      // 31. 8. → poslední den února.
      expect(premiumGiftEnd(DateTime(2026, 8, 31)),
          DateTime(2027, 2, 28, 23, 59, 59));
      expect(premiumGiftEnd(DateTime(2027, 8, 31)),
          DateTime(2028, 2, 29, 23, 59, 59));
    });

    test('platnost dárku', () {
      final until = DateTime(2027, 4, 3, 23, 59, 59);
      expect(isPremiumGiftActive(null, DateTime(2027)), isFalse);
      expect(isPremiumGiftActive(until, DateTime(2027, 4, 3, 12)), isTrue);
      expect(isPremiumGiftActive(until, DateTime(2027, 4, 4)), isFalse);
    });

    test('dárek jen jednou, po úvodním nastavení a před spuštěním plateb',
        () {
      expect(
        shouldGrantPremiumGift(
            launched: false, onboardingDone: true, giftUntil: null),
        isTrue,
      );
      expect(
        shouldGrantPremiumGift(
            launched: false, onboardingDone: false, giftUntil: null),
        isFalse,
      );
      expect(
        shouldGrantPremiumGift(
            launched: false,
            onboardingDone: true,
            giftUntil: DateTime(2027, 4, 3)),
        isFalse,
      );
      expect(
        shouldGrantPremiumGift(
            launched: true, onboardingDone: true, giftUntil: null),
        isFalse,
      );
    });
  });

  group('vlastní plány', () {
    test('zdarma nejvýš 3, Premium bez omezení', () {
      expect(canCreateCustomPlan(customPlanCount: 0, premium: false), isTrue);
      expect(canCreateCustomPlan(customPlanCount: 2, premium: false), isTrue);
      expect(canCreateCustomPlan(customPlanCount: 3, premium: false), isFalse);
      expect(canCreateCustomPlan(customPlanCount: 10, premium: true), isTrue);
    });

    test('plány z hotových programů se nepočítají', () {
      final templates = templatePlanNames();
      final fromProgram = templatePrograms.first.plans.first;
      expect(templates, contains(fromProgram.nameEn));
      expect(templates, contains(fromProgram.nameCs));
      expect(
        countCustomPlans([
          fromProgram.nameEn,
          fromProgram.nameCs,
          'Můj plán',
          'Ranní kruhový trénink',
        ]),
        2,
      );
    });

    test('vlastní seznam názvů šablon', () {
      expect(
        countCustomPlans(['A', ' B ', 'C'], templateNames: {'B'}),
        2,
      );
    });
  });

  group('zamčené položky', () {
    test('zdarma první 2 programy', () {
      expect(isProgramLocked(0, premium: false), isFalse);
      expect(isProgramLocked(1, premium: false), isFalse);
      expect(isProgramLocked(2, premium: false), isTrue);
      expect(isProgramLocked(2, premium: true), isFalse);
    });

    test('zdarma první 3 rutiny plánu B', () {
      expect(isHomeRoutineLocked(2, premium: false), isFalse);
      expect(isHomeRoutineLocked(3, premium: false), isTrue);
      expect(isHomeRoutineLocked(5, premium: true), isFalse);
    });
  });

  group('historie grafů', () {
    final now = DateTime(2026, 10, 3, 15, 30);

    test('Premium ukazuje vše', () {
      expect(chartHistoryStart(now, fullHistory: true), isNull);
    });

    test('zdarma od začátku dne před 30 dny', () {
      expect(
        chartHistoryStart(now, fullHistory: false),
        DateTime(2026, 9, 3),
      );
    });

    test('pointsSince filtruje body před začátkem', () {
      final points = [
        (x: DateTime(2026, 8, 1), y: 1.0),
        (x: DateTime(2026, 9, 3), y: 2.0),
        (x: DateTime(2026, 10, 1), y: 3.0),
      ];
      final start = chartHistoryStart(now, fullHistory: false);
      final visible = pointsSince(points, (p) => p.x, start);
      expect(visible.map((p) => p.y), [2.0, 3.0]);
      expect(pointsSince(points, (p) => p.x, null), points);
    });

    test('týdenní graf zdarma jen 5 týdnů', () {
      expect(visibleWeekCount(12, fullHistory: false), kFreeChartWeeks);
      expect(visibleWeekCount(12, fullHistory: true), 12);
      expect(visibleWeekCount(3, fullHistory: false), 3);
    });
  });
}
