import 'package:fitness_app/data/enums.dart';
import 'package:fitness_app/modules/sharing/challenge_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('challengeState', () {
    final now = DateTime(2026, 9, 30, 15);

    test('bez termínu je aktivní', () {
      expect(challengeState(now: now), ChallengeState.active);
    });

    test('termín platí celý den', () {
      expect(challengeState(deadline: DateTime(2026, 9, 30), now: now),
          ChallengeState.active);
      expect(
        challengeState(
            deadline: DateTime(2026, 9, 30), now: DateTime(2026, 10, 1)),
        ChallengeState.expired,
      );
    });

    test('splněná má přednost před propadlou, skrytá před vším', () {
      final past = DateTime(2026, 9, 1);
      expect(
        challengeState(completedAt: past, deadline: past, now: now),
        ChallengeState.completed,
      );
      expect(
        challengeState(completedAt: past, dismissedAt: now, now: now),
        ChallengeState.dismissed,
      );
    });
  });

  group('daysLeft', () {
    test('null bez termínu', () {
      expect(daysLeft(null, DateTime(2026, 9, 30)), isNull);
    });

    test('počítá kalendářní dny bez ohledu na čas', () {
      expect(daysLeft(DateTime(2026, 9, 30), DateTime(2026, 9, 30, 23)), 0);
      expect(daysLeft(DateTime(2026, 10, 30), DateTime(2026, 9, 30, 8)), 30);
      expect(daysLeft(DateTime(2026, 9, 29), DateTime(2026, 9, 30)), -1);
    });

    test('přechod na zimní čas nic nerozbije', () {
      expect(daysLeft(DateTime(2026, 10, 26), DateTime(2026, 10, 24, 23)), 2);
    });
  });

  group('časová okna', () {
    test('týden začíná v pondělí', () {
      // 30. 9. 2026 je středa.
      final wed = DateTime(2026, 9, 30, 18);
      expect(weekStart(wed), DateTime(2026, 9, 28));
      expect(weekEndExclusive(wed), DateTime(2026, 10, 5));
      final sun = DateTime(2026, 10, 4, 23);
      expect(weekStart(sun), DateTime(2026, 9, 28));
      final mon = DateTime(2026, 9, 28);
      expect(weekStart(mon), mon);
    });

    test('měsíc včetně přechodu roku', () {
      expect(monthStart(DateTime(2026, 12, 15)), DateTime(2026, 12));
      expect(monthEndExclusive(DateTime(2026, 12, 15)), DateTime(2027));
    });
  });

  group('challengeProgress', () {
    test('rekord: bez rekordu je 0', () {
      final p = challengeProgress(ChallengeKind.beatRecord, 100);
      expect(p.current, 0);
      expect(p.fraction, 0);
      expect(p.reached, isFalse);
    });

    test('rekord je potřeba překonat, rovnost nestačí', () {
      expect(
        challengeProgress(ChallengeKind.beatRecord, 100, bestOneRepMax: 100)
            .reached,
        isFalse,
      );
      final p = challengeProgress(ChallengeKind.beatRecord, 100,
          bestOneRepMax: 100.5);
      expect(p.reached, isTrue);
      expect(p.fraction, 1);
    });

    test('rekord: poměr pro ukazatel', () {
      final p =
          challengeProgress(ChallengeKind.beatRecord, 120, bestOneRepMax: 90);
      expect(p.fraction, closeTo(0.75, 1e-9));
    });

    test('tréninky za měsíc: stačí dosáhnout cíle', () {
      final p = challengeProgress(ChallengeKind.workoutsInMonth, 12,
          workoutsThisMonth: 12, bestOneRepMax: 999, waterMlThisWeek: 1);
      expect(p.current, 12);
      expect(p.reached, isTrue);
      expect(
        challengeProgress(ChallengeKind.workoutsInMonth, 12,
                workoutsThisMonth: 11)
            .reached,
        isFalse,
      );
    });

    test('voda za týden', () {
      final p = challengeProgress(ChallengeKind.weeklyWater, 14000,
          waterMlThisWeek: 7000);
      expect(p.fraction, closeTo(0.5, 1e-9));
      expect(p.reached, isFalse);
    });

    test('nulový cíl je splněný', () {
      final p = challengeProgress(ChallengeKind.weeklyWater, 0);
      expect(p.fraction, 1);
      expect(p.reached, isTrue);
    });
  });

  group('pomocné funkce', () {
    test('roundToHalf', () {
      expect(roundToHalf(116.67), 116.5);
      expect(roundToHalf(116.8), 117);
      expect(roundToHalf(100), 100);
    });

    test('humanizeSlug', () {
      expect(humanizeSlug('bench_press'), 'Bench press');
      expect(humanizeSlug('pull-up'), 'Pull up');
      expect(humanizeSlug(''), '');
    });
  });
}
