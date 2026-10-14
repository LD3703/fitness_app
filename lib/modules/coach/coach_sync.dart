import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

import '../../data/database.dart';
import '../../features/workout/workout_service.dart';
import '../../providers.dart';
import '../social/social_auth.dart';
import '../social/social_backend.dart';
import 'coach_queries.dart';
import 'coach_service.dart';

/// Synchronizace klienta s trenérem (docs/coach.md):
///  - po tréninku a při synchronizaci nahraje tréninky (jen s propojením),
///  - tělesnou váhu jen se zvláštním souhlasem,
///  - plány od trenéra uloží do telefonu (nová verze přepíše starou).
abstract final class CoachSync {
  static DateTime? _lastWorkouts;
  static DateTime? _lastPlans;

  static const _workoutsInterval = Duration(hours: 6);
  static const _plansInterval = Duration(minutes: 10);

  /// Při propojení se nahraje historie za tuto dobu (grafy u trenéra).
  static const backfillDays = 365;

  /// Při běžné synchronizaci se nahrávají jen poslední tréninky
  /// (úpravy starších tréninků trenér nedostane).
  static const recentDays = 14;

  static bool get _ready =>
      SocialBackend.available && SocialAuth.instance.currentUser != null;

  /// [coach:finished] – nahraje právě dokončený trénink.
  static Future<void> onWorkoutFinished(
    WidgetRef ref,
    WorkoutSummary summary,
  ) async {
    if (!_ready) return;
    try {
      final link = await CoachService.instance.myLink();
      if (link == null) return;
      final db = ref.read(databaseProvider);
      final w = await db.coachWorkoutById(summary.sessionId);
      if (w != null) await CoachService.instance.uploadWorkouts([w]);
    } catch (e) {
      debugPrint('Coach: upload after workout failed: $e');
    }
  }

  /// [coach:sync] – plány od trenéra (co 10 min) a poslední tréninky
  /// a váha (co 6 h).
  static Future<void> onSync(Ref ref, UserProfile profile) async {
    if (!_ready) return;
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    try {
      final link = await CoachService.instance.myLink();
      if (link == null) return;
      final lastPlans = _lastPlans;
      if (lastPlans == null || now.difference(lastPlans) >= _plansInterval) {
        _lastPlans = now;
        await importAssignedPlans(db);
      }
      final lastWorkouts = _lastWorkouts;
      if (lastWorkouts == null ||
          now.difference(lastWorkouts) >= _workoutsInterval) {
        _lastWorkouts = now;
        await upload(db, link, days: recentDays);
      }
    } catch (e) {
      debugPrint('Coach: sync failed: $e');
    }
  }

  /// Nahraje tréninky za posledních [days] dní (a váhu, je-li povolená).
  static Future<void> upload(
    AppDatabase db,
    CoachLink link, {
    required int days,
  }) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final workouts = await db.coachWorkoutsSince(from);
    await CoachService.instance.uploadWorkouts(workouts);
    if (link.shareWeight) {
      final weights = await db.coachWeightsSince(
          DateTime.now().subtract(const Duration(days: backfillDays)));
      await CoachService.instance.uploadWeights(weights);
    }
  }

  /// Po propojení s trenérem: historie za rok.
  static Future<void> backfill(AppDatabase db) async {
    final link = await CoachService.instance.myLink();
    if (link == null) return;
    await upload(db, link, days: backfillDays);
    _lastWorkouts = DateTime.now();
    await importAssignedPlans(db);
  }

  /// Plány od trenéra → telefon. Vrací počet nových / změněných plánů.
  static Future<int> importAssignedPlans(AppDatabase db) async {
    var changed = 0;
    for (final a in await CoachService.instance.myAssignedPlans()) {
      final remoteId = assignedPlanRemoteId(a.id);
      final local = await db.planByRemoteId(remoteId);
      if (local != null && (local.remoteVersion ?? 0) >= a.version) continue;
      await db.importCoachPlan(
        a.plan,
        remoteId: remoteId,
        version: a.version,
        from: a.trainerName,
      );
      changed++;
    }
    _lastPlans = DateTime.now();
    return changed;
  }

  /// Po odhlášení zapomene stav.
  static void reset() {
    _lastWorkouts = null;
    _lastPlans = null;
  }
}
