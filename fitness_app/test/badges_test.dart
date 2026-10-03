import 'package:fitness_app/core/progressive_overload.dart';
import 'package:fitness_app/data/enums.dart';
import 'package:fitness_app/features/achievements/badges.dart';
import 'package:fitness_app/modules/stats/stats_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Středa 30. 9. 2026 (týden od 28. 9.).
  final now = DateTime(2026, 9, 30, 12);

  group('katalog', () {
    test('kódy jsou jedinečné a stabilní', () {
      final codes = [for (final b in badgeCatalog) b.code];
      expect(codes.toSet(), hasLength(codes.length));
      expect(codes, contains('overload_streak_2'));
      expect(codes, contains('overload_streak_52'));
      expect(codes, contains('mastery_chest'));
      expect(codes, contains('records_1'));
      expect(codes, contains('records_50'));
      expect(codes, contains('consistency_26'));
      expect(codes, isNot(contains('mastery_fullBody')));
      expect(
        badgeCatalog,
        hasLength(overloadStreakBadgeWeeks.length +
            overloadGroups.length +
            recordBadgeCounts.length +
            consistencyBadgeWeeks.length),
      );
    });

    test('badgeByCode', () {
      expect(badgeByCode('mastery_legs')?.group, MuscleGroup.legs);
      expect(badgeByCode('records_10')?.threshold, 10);
      expect(badgeByCode('unknown'), isNull);
    });
  });

  group('osobní rekordy', () {
    StatPoint p(int day, double y) => (x: DateTime(2026, 9, day), y: y);

    test('první zápis rekord není, rovnost také ne', () {
      expect(
        countPersonalRecords({
          1: [p(1, 100), p(3, 105), p(5, 105), p(8, 104), p(10, 110)],
          2: [p(2, 50)],
        }),
        2,
      );
    });

    test('nezáleží na pořadí bodů', () {
      expect(
        countPersonalRecords({
          1: [p(10, 110), p(1, 100), p(3, 105)],
        }),
        2,
      );
    });
  });

  group('série týdnů se splněným plánem', () {
    test('nejdelší série, probíhající nesplněný týden nepřeruší', () {
      final sessions = [
        // 3 týdny v řadě (31. 8., 7. 9., 14. 9.) po 2 trénincích…
        for (final d in [1, 3, 8, 10, 15, 17]) DateTime(2026, 9, d),
        // …21. 9. jen jeden trénink → přerušeno,
        DateTime(2026, 9, 22),
        // tento týden zatím jeden.
        DateTime(2026, 9, 29),
      ];
      expect(longestWeekStreak(sessions, now, goal: 2), 3);
      expect(longestWeekStreak(sessions, now, goal: 1), 5);
      expect(longestWeekStreak(const [], now, goal: 1), 0);
    });
  });

  group('postup a nové odznaky', () {
    test('splněné prahy a už uložené kódy', () {
      const progress = BadgeProgress(
        overloadStreak: 5,
        masteryRuns: {MuscleGroup.chest: 8, MuscleGroup.back: 3},
        masteredGroups: {MuscleGroup.chest},
        personalRecords: 12,
        consistencyStreak: 4,
      );
      final earned = {for (final b in earnedBadges(progress)) b.code};
      expect(earned, {
        'overload_streak_2',
        'overload_streak_4',
        'mastery_chest',
        'records_1',
        'records_10',
        'consistency_4',
      });
      final fresh = newBadges(progress, {'records_1', 'overload_streak_2'});
      expect(
        {for (final b in fresh) b.code},
        {'overload_streak_4', 'mastery_chest', 'records_10', 'consistency_4'},
      );

      final back = badgeByCode('mastery_back')!;
      expect(progress.progressOf(back), (current: 3, target: 8));
      final streak8 = badgeByCode('overload_streak_8')!;
      expect(progress.progressOf(streak8), (current: 5, target: 8));
      final records50 = badgeByCode('records_50')!;
      expect(progress.progressOf(records50), (current: 12, target: 50));
      // Splněný odznak ukazuje plný postup.
      expect(progress.progressOf(badgeByCode('records_1')!),
          (current: 1, target: 1));
    });

    test('computeBadgeProgress ze surových dat', () {
      GroupOverload g(OverloadStatus s) =>
          GroupOverload(group: MuscleGroup.legs, week: DateTime(2026), status: s);
      final history = OverloadHistory(
        weeks: [for (var i = 0; i < 8; i++) DateTime(2026, 6, 1 + 7 * i)],
        byGroup: {
          MuscleGroup.legs: [
            for (var i = 0; i < 8; i++)
              g(i.isEven
                  ? OverloadStatus.progressing
                  : OverloadStatus.holding),
          ],
        },
        pausedWeeks: List.filled(8, false),
      );
      final progress = computeBadgeProgress(
        overload: history,
        oneRepMaxByExercise: {
          1: [
            (x: DateTime(2026, 9, 1), y: 100),
            (x: DateTime(2026, 9, 8), y: 102),
          ],
        },
        sessionDates: [DateTime(2026, 9, 29)],
        weeklyGoal: 1,
        now: now,
      );
      // Týdny „drží“ sérii neprodlužují, „progres“ ano: 1 týden v řadě.
      expect(progress.overloadStreak, 1);
      expect(progress.masteredGroups, {MuscleGroup.legs});
      expect(progress.masteryRuns[MuscleGroup.legs], 8);
      expect(progress.personalRecords, 1);
      expect(progress.consistencyStreak, 1);
      final codes = {for (final b in earnedBadges(progress)) b.code};
      expect(codes, containsAll(['mastery_legs', 'records_1']));
      expect(codes, isNot(contains('overload_streak_2')));
    });
  });
}
