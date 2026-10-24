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

    test('trenér se statusem má Premium zdarma', () {
      expect(
        hasPremiumAccess(
          launched: true,
          profilePremium: false,
          entitlementActive: false,
          trainer: true,
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

    test('platnost dárku: do spuštění Premium a půl roku po něm', () {
      final early = DateTime(2026, 10, 3);
      final launch = DateTime(2027, 3, 1);
      // Premium ještě neběží: první uživatel má dárek, konec neznámý.
      expect(
          isPremiumGiftActive(
              earlyAt: early, launchDate: null, now: DateTime(2030)),
          isTrue);
      expect(premiumGiftUntil(earlyAt: early, launchDate: null), isNull);
      // Po spuštění: 6 měsíců od spuštění, ne od prvního otevření.
      expect(premiumGiftUntil(earlyAt: early, launchDate: launch),
          DateTime(2027, 9, 1, 23, 59, 59));
      expect(
          isPremiumGiftActive(
              earlyAt: early, launchDate: launch, now: DateTime(2027, 9, 1, 12)),
          isTrue);
      expect(
          isPremiumGiftActive(
              earlyAt: early, launchDate: launch, now: DateTime(2027, 9, 2)),
          isFalse);
      // Kdo není první uživatel, dárek nemá.
      expect(
          isPremiumGiftActive(
              earlyAt: null, launchDate: launch, now: DateTime(2027, 3, 2)),
          isFalse);
      expect(premiumGiftUntil(earlyAt: null, launchDate: launch), isNull);
    });

    test('první uživatel jen jednou, po úvodním nastavení a před spuštěním',
        () {
      expect(
        shouldMarkPremiumEarlyUser(
            launched: false, onboardingDone: true, earlyAt: null),
        isTrue,
      );
      expect(
        shouldMarkPremiumEarlyUser(
            launched: false, onboardingDone: false, earlyAt: null),
        isFalse,
      );
      expect(
        shouldMarkPremiumEarlyUser(
            launched: false,
            onboardingDone: true,
            earlyAt: DateTime(2026, 10, 3)),
        isFalse,
      );
      expect(
        shouldMarkPremiumEarlyUser(
            launched: true, onboardingDone: true, earlyAt: null),
        isFalse,
      );
    });

    test('slib s účtem: nový telefon si ho vezme, nový slib se uloží', () {
      final at = DateTime(2026, 10, 3);
      expect(premiumEarlySync(local: null, server: at), PremiumEarlySync.pull);
      expect(premiumEarlySync(local: at, server: null), PremiumEarlySync.push);
      expect(premiumEarlySync(local: at, server: at), PremiumEarlySync.none);
      expect(
          premiumEarlySync(local: at, server: DateTime(2026, 11)),
          PremiumEarlySync.none);
      expect(premiumEarlySync(local: null, server: null), PremiumEarlySync.none);
    });

    test('slib ze zálohy: telefon má přednost, pozdější datum neplatí', () {
      final early = DateTime(2026, 10, 3);
      final now = DateTime(2026, 12, 1);
      // Telefon slib má – záloha ho nezmění.
      expect(
        premiumEarlyAfterRestore(
            device: early,
            backup: DateTime(2026, 9),
            launchDate: null,
            now: now),
        early,
      );
      // Nový telefon bez účtu: slib se vezme ze zálohy.
      expect(
        premiumEarlyAfterRestore(
            device: null, backup: early, launchDate: null, now: now),
        early,
      );
      expect(
        premiumEarlyAfterRestore(
            device: null,
            backup: early,
            launchDate: DateTime(2027, 1),
            now: now),
        early,
      );
      // Datum po spuštění nebo z budoucnosti je podvržené.
      expect(
        premiumEarlyAfterRestore(
            device: null,
            backup: DateTime(2027, 2),
            launchDate: DateTime(2027, 1),
            now: DateTime(2027, 3)),
        isNull,
      );
      expect(
        premiumEarlyAfterRestore(
            device: null,
            backup: DateTime(2027, 2),
            launchDate: null,
            now: now),
        isNull,
      );
      expect(
        premiumEarlyAfterRestore(
            device: null, backup: null, launchDate: null, now: now),
        isNull,
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
