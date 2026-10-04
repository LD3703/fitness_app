import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../modules/stats/stats_math.dart';
import '../../modules/stats/stats_providers.dart';
import '../../modules/stats/stats_queries.dart';
import '../../modules/stats/streak.dart';
import '../../providers.dart';
import '../overload/overload_providers.dart';
import '../workout/workout_service.dart';
import 'badges.dart';

/// Dotazy na získané odznaky (tabulka Achievements, schéma v9).
extension AchievementQueries on AppDatabase {
  Stream<List<Achievement>> watchAchievements() => (select(achievements)
        ..orderBy([(a) => OrderingTerm.asc(a.earnedAt)]))
      .watch();

  Future<Set<String>> achievementCodes() async =>
      {for (final a in await select(achievements).get()) a.code};

  /// Uloží odznaky; už uložené (stejný kód) se přeskočí.
  Future<void> insertAchievements(Iterable<BadgeDef> badges, DateTime at) =>
      transaction(() async {
        for (final b in badges) {
          await into(achievements).insert(
            AchievementsCompanion.insert(
              code: b.code,
              earnedAt: at,
              value: Value(b.threshold),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      });
}

/// Nejlepší odhad 1RM v každém tréninku podle cviku.
Map<int, List<StatPoint>> oneRepMaxPointsByExercise(
  Iterable<SessionBest> bests,
) {
  final result = <int, List<StatPoint>>{};
  for (final b in bests) {
    (result[b.exerciseId] ??= []).add((x: b.date, y: b.oneRepMax));
  }
  return result;
}

/// Spočítá postup k odznakům z databáze (pro háčky mimo widgety).
Future<BadgeProgress> loadBadgeProgress(
  AppDatabase db,
  UserProfile profile,
  DateTime now,
) async {
  final history = await loadOverloadHistory(db, profile, now);
  final bests = await db.watchSessionBests().first;
  final dates = await db.watchWorkoutDatesSince(DateTime(2000)).first;
  final plans = await db.watchPlans().first;
  return computeBadgeProgress(
    overload: history,
    oneRepMaxByExercise: oneRepMaxPointsByExercise(bests),
    sessionDates: dates,
    weeklyGoal: requiredSessionsPerWeek([for (final p in plans) p.weekdaysMask]),
    now: now,
  );
}

/// Vyhodnotí odznaky, nově splněné uloží a vrátí je.
Future<List<BadgeDef>> evaluateAchievements(AppDatabase db) async {
  final now = DateTime.now();
  final profile = await db.watchProfile().first;
  if (!profile.onboardingDone) return const [];
  final progress = await loadBadgeProgress(db, profile, now);
  final fresh = newBadges(progress, await db.achievementCodes());
  if (fresh.isNotEmpty) await db.insertAchievements(fresh, now);
  return fresh;
}

final achievementsProvider = StreamProvider<List<Achievement>>(
  (ref) => ref.watch(databaseProvider).watchAchievements(),
);

/// Odznaky získané posledním dokončeným tréninkem (pro souhrn).
final newBadgesProvider =
    StateProvider<({int sessionId, List<String> codes})?>((ref) => null);

/// Postup ke všem odznakům (pro galerii; null, dokud se data načítají).
final badgeProgressProvider = Provider<BadgeProgress?>((ref) {
  final history = ref.watch(overloadHistoryProvider);
  final e1rm = ref.watch(statsOneRepMaxByExerciseProvider);
  final dates = ref.watch(statsWorkoutDatesProvider).valueOrNull;
  final plans = ref.watch(plansProvider).valueOrNull;
  if (history == null || e1rm == null || dates == null || plans == null) {
    return null;
  }
  return computeBadgeProgress(
    overload: history,
    oneRepMaxByExercise: e1rm,
    sessionDates: dates,
    weeklyGoal: requiredSessionsPerWeek([for (final p in plans) p.weekdaysMask]),
    now: DateTime.now(),
  );
});

/// Háček po tréninku (badges:finished): uloží nové odznaky a předá je
/// souhrnu.
Future<void> achievementsWorkoutFinished(
  WidgetRef ref,
  WorkoutSummary summary,
) async {
  final fresh = await evaluateAchievements(ref.read(databaseProvider));
  ref.read(newBadgesProvider.notifier).state = (
    sessionId: summary.sessionId,
    codes: [for (final b in fresh) b.code],
  );
}

/// Háček po změně dat (badges:sync) – tiše doplní splněné odznaky
/// (např. po aktualizaci aplikace nebo obnovení zálohy).
Future<void> achievementsSync(Ref ref, UserProfile profile) async {
  final fresh = await evaluateAchievements(ref.read(databaseProvider));
  if (fresh.isNotEmpty) {
    debugPrint('Badges earned: ${fresh.map((b) => b.code).join(', ')}');
  }
}
