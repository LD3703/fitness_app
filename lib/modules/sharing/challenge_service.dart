import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../providers.dart';
import 'challenge_progress.dart';
import 'sharing_queries.dart';

/// Výzva i s cvikem, stavem a průběhem (pro kartu Dnes a souhrn).
class ChallengeView {
  const ChallengeView({
    required this.challenge,
    required this.exercise,
    required this.state,
    required this.progress,
  });

  final Challenge challenge;

  /// Cvik výzvy na rekord (null u ostatních druhů nebo neznámého cviku).
  final Exercise? exercise;
  final ChallengeState state;
  final ChallengeProgress progress;
}

/// Metriky potřebné pro průběh výzev – spočítají se jednou pro všechny.
class _Metrics {
  _Metrics(this.db, this.now);

  final AppDatabase db;
  final DateTime now;
  final _best = <int, double?>{};
  int? _workouts;
  int? _water;

  Future<double?> best(int exerciseId) async {
    if (_best.containsKey(exerciseId)) return _best[exerciseId];
    final r = await db.exerciseRecord(exerciseId);
    return _best[exerciseId] = r?.oneRepMax;
  }

  Future<int> workouts() async => _workouts ??=
      await db.finishedSessionCount(monthStart(now), monthEndExclusive(now));

  Future<int> water() async => _water ??=
      await db.waterTotalBetween(weekStart(now), weekEndExclusive(now));
}

/// Cvik výzvy: přednostně podle ID, jinak podle slugu.
Future<Exercise?> _exerciseOf(AppDatabase db, Challenge c) async {
  final id = c.exerciseId;
  if (id != null) {
    final e = await db.exerciseById(id);
    if (e != null) return e;
  }
  final slug = c.exerciseSlug;
  if (slug != null && slug.isNotEmpty) return db.exerciseBySlug(slug);
  return null;
}

Future<ChallengeView> _view(
  AppDatabase db,
  Challenge c,
  _Metrics m,
  DateTime now,
) async {
  final exercise =
      c.kind == ChallengeKind.beatRecord ? await _exerciseOf(db, c) : null;
  final progress = switch (c.kind) {
    ChallengeKind.beatRecord => challengeProgress(
        c.kind,
        c.targetValue,
        bestOneRepMax: exercise == null ? null : await m.best(exercise.id),
      ),
    ChallengeKind.workoutsInMonth => challengeProgress(
        c.kind,
        c.targetValue,
        workoutsThisMonth: await m.workouts(),
      ),
    ChallengeKind.weeklyWater => challengeProgress(
        c.kind,
        c.targetValue,
        waterMlThisWeek: await m.water(),
      ),
  };
  return ChallengeView(
    challenge: c,
    exercise: exercise,
    state: challengeState(
      completedAt: c.completedAt,
      dismissedAt: c.dismissedAt,
      deadline: c.deadline,
      now: now,
    ),
    progress: progress,
  );
}

/// Zkontroluje aktivní výzvy a splněným nastaví completedAt.
/// Vrací počet nově splněných výzev.
Future<int> checkChallenges(AppDatabase db, {DateTime? now}) async {
  final t = now ?? DateTime.now();
  final m = _Metrics(db, t);
  var done = 0;
  for (final c in await db.openChallenges()) {
    final v = await _view(db, c, m, t);
    if (v.state == ChallengeState.active && v.progress.reached) {
      await db.markChallengeCompleted(c.id, t);
      done++;
    }
  }
  return done;
}

/// Propadlé výzvy, které už se v tomto běhu aplikace jednou ukázaly.
/// V databázi jsou hned skryté (dismissedAt), ale do restartu aplikace
/// je karta ještě ukazuje jako „Vypršela“.
final Set<int> _expiredShownThisRun = {};

/// Kolik dní po splnění se výzva ještě ukazuje na kartě Dnes.
const _completedVisibleDays = 2;

/// Výzvy pro kartu Dnes: aktivní, nedávno splněné a (jednou) propadlé.
/// Při výpočtu zároveň označí splněné výzvy (např. voda zapsaná na Dnes)
/// a propadlé skryje.
final todayChallengesProvider =
    StreamProvider.autoDispose<List<ChallengeView>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchChallengeInputs().asyncMap((_) async {
    final now = DateTime.now();
    final m = _Metrics(db, now);
    final result = <ChallengeView>[];
    for (final c in await db.allChallenges()) {
      final dismissed = c.dismissedAt != null;
      if (dismissed && !_expiredShownThisRun.contains(c.id)) continue;
      var v = await _view(db, c, m, now);
      try {
        if (v.state == ChallengeState.active && v.progress.reached) {
          await db.markChallengeCompleted(c.id, now);
          continue; // stream se ozve znovu už se splněnou výzvou
        }
        if (v.state == ChallengeState.expired) {
          _expiredShownThisRun.add(c.id);
          await db.dismissChallenge(c.id, now);
          continue; // znovu se ukáže díky _expiredShownThisRun
        }
      } catch (e) {
        debugPrint('Challenge update failed: $e');
      }
      if (dismissed) {
        // Propadlá, v tomto běhu už skrytá v DB: ukázat jako propadlou.
        v = ChallengeView(
          challenge: c,
          exercise: v.exercise,
          state: ChallengeState.expired,
          progress: v.progress,
        );
      } else if (v.state == ChallengeState.completed) {
        final at = c.completedAt!;
        if (now.difference(at).inDays >= _completedVisibleDays) continue;
      }
      result.add(v);
    }
    return result;
  });
});

/// Skryje výzvu z karty Dnes (i propadlou z tohoto běhu).
Future<void> hideChallenge(AppDatabase db, int id) async {
  _expiredShownThisRun.remove(id);
  await db.dismissChallenge(id, DateTime.now());
}

/// Výzvy splněné od začátku tréninku (souhrn po tréninku).
final completedSinceProvider = StreamProvider.autoDispose
    .family<List<ChallengeView>, DateTime>((ref, since) {
  final db = ref.watch(databaseProvider);
  return db.watchChallengesCompletedSince(since).asyncMap((rows) async {
    final now = DateTime.now();
    final m = _Metrics(db, now);
    return [for (final c in rows) await _view(db, c, m, now)];
  });
});
