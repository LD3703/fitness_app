import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../features/workout/workout_service.dart';
import '../../providers.dart';
import '../../services/sync_controller.dart';
import 'gym/gym_logic.dart';
import 'gym/gym_publisher.dart';
import 'social_auth.dart';
import 'social_backend.dart';
import 'social_calendar.dart';
import 'social_logic.dart';
import 'social_messaging.dart';
import 'social_models.dart';
import 'social_queries.dart';
import 'social_service.dart';

/// Zveřejňování statistik a rekordů přátelům, synchronizace výzev.
///
/// Sdílí se jen to, co uživatel povolil: počty tréninků, objem a splněné
/// týdny (shareWorkoutStatsWithFriends) a rekordy (shareRecordsWithFriends).
/// Nikdy: období, nemoc/zranění, tělesná váha (ani nic z ní odvozeného),
/// množství vody.
abstract final class SocialPublisher {
  static DateTime? _lastStats;
  static DateTime? _lastChallenges;
  static final _reportedProgress = <String, double>{};
  static final _reportedDone = <String>{};
  static final _handledFeed = <String>{};

  static const _statsInterval = Duration(minutes: 15);
  static const _challengeInterval = Duration(minutes: 10);

  static bool get _ready =>
      SocialBackend.available && SocialAuth.instance.currentUser != null;

  /// Jméno, pod kterým mě vidí přátelé.
  static String displayName(UserProfile profile) {
    final n = profile.name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final a = SocialAuth.instance.currentUser?.displayName?.trim();
    if (a != null && a.isNotEmpty) return a;
    return '?';
  }

  static String get _lang {
    try {
      return deviceLocalizations().localeName;
    } catch (_) {
      return 'en';
    }
  }

  // -------------------------------------------------------------------
  // Háčky
  // -------------------------------------------------------------------

  /// [social:finished] – po tréninku.
  static Future<void> onWorkoutFinished(
    WidgetRef ref,
    WorkoutSummary summary,
  ) async {
    if (!_ready) return;
    final db = ref.read(databaseProvider);
    final profile = await db.watchProfile().first;
    await publishStats(db, profile, force: true);
    if (profile.shareRecordsWithFriends && summary.records.isNotEmpty) {
      await publishRecords(profile, summary.records);
    }
    await syncChallenges(db, force: true);
    // Žebříček posilovny (když jsem v nějaké a chci být vidět).
    await GymPublisher.publish(db, force: true);
  }

  /// [social:sync] – po změně dat (omezeno intervaly).
  static Future<void> onSync(Ref ref, UserProfile profile) async {
    if (!_ready) return;
    final db = ref.read(databaseProvider);
    await syncChallenges(db);
    await publishStats(db, profile);
    await GymPublisher.publish(db);
    await SocialMessaging.instance.registerToken();
  }

  // -------------------------------------------------------------------
  // Statistiky
  // -------------------------------------------------------------------

  static Future<void> publishStats(
    AppDatabase db,
    UserProfile profile, {
    bool force = false,
  }) async {
    if (!_ready) return;
    final now = DateTime.now();
    final last = _lastStats;
    if (!force && last != null && now.difference(last) < _statsInterval) {
      return;
    }
    _lastStats = now;
    try {
      final fields = <String, Object?>{
        'displayName': displayName(profile),
        'shareRecords': profile.shareRecordsWithFriends,
        'shareStats': profile.shareWorkoutStatsWithFriends,
        'lang': _lang,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (profile.shareWorkoutStatsWithFriends) {
        final monthStart = DateTime(now.year, now.month);
        final monthEnd = DateTime(now.year, now.month + 1);
        final weekStart = isoWeekStart(now);
        final weekEnd =
            DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
        fields['workoutsThisMonth'] =
            await db.socialWorkoutCount(monthStart, monthEnd);
        fields['statsMonth'] = monthKey(now);
        fields['weeklyVolume'] =
            (await db.socialVolume(weekStart, weekEnd)).roundToDouble();
        fields['statsWeek'] = isoWeekKey(now);
        fields['weeks'] = await _weeks(db, now);
      } else {
        for (final k in [
          'workoutsThisMonth',
          'statsMonth',
          'weeklyVolume',
          'statsWeek',
          'weeks',
        ]) {
          fields[k] = FieldValue.delete();
        }
      }

      // Úklid: relativní síla (1RM ÷ tělesná váha) z dřívějších verzí
      // se už nepočítá ani nesdílí – staré pole smažeme.
      fields['relStrength'] = FieldValue.delete();

      await SocialService.instance.updateMe(fields);
    } catch (e) {
      debugPrint('Social: publish stats failed: $e');
    }
  }

  static Future<Map<String, bool>> _weeks(AppDatabase db, DateTime now) async {
    final keys = recentWeekKeys(now, publishedWeeks);
    final oldest = isoWeekStart(now)
        .subtract(const Duration(days: 7 * (publishedWeeks - 1)));
    final counts = <String, int>{};
    for (final d in await db.socialWorkoutDates(oldest)) {
      final k = isoWeekKey(d);
      counts[k] = (counts[k] ?? 0) + 1;
    }
    final planned = plannedPerWeek(await db.socialPlanWeekdayMasks());
    return {
      for (final k in keys)
        k: isPlanMet(workouts: counts[k] ?? 0, plannedPerWeek: planned),
    };
  }

  // -------------------------------------------------------------------
  // Rekordy
  // -------------------------------------------------------------------

  /// Rekordy vestavěných cviků do novinek přátel. Vlastní cviky se
  /// nesdílí (přítel by je stejně neměl, a výzva by nešla přijmout).
  static Future<void> publishRecords(
    UserProfile profile,
    List<PersonalRecord> records,
  ) async {
    final name = displayName(profile);
    for (final r in records) {
      final slug = r.exercise.slug;
      if (slug == null) continue;
      try {
        await SocialService.instance.fanOut(FeedType.pr, name, {
          'exerciseSlug': slug,
          'exerciseNameEn': r.exercise.nameEn,
          'exerciseNameCs': r.exercise.nameCs,
          'value': roundRecord(r.newOneRepMax),
        });
      } catch (e) {
        debugPrint('Social: publish record failed: $e');
      }
    }
  }

  // -------------------------------------------------------------------
  // Výzvy
  // -------------------------------------------------------------------

  /// Lokální výzvy s remoteId: postup (počet tréninků / % vody) a splnění
  /// (completedAt zapisuje modul sharing) pošle na server.
  static Future<void> syncChallenges(AppDatabase db, {bool force = false}) async {
    if (!_ready) return;
    try {
      // Výzvy „Překonej mě“ ze žebříčku posilovny jsou jen lokální.
      final locals = [
        for (final c in await db.socialRemoteChallenges())
          if (!isGymChallengeRemoteId(c.remoteId)) c,
      ];
      if (locals.isEmpty) return;
      final now = DateTime.now();
      final newlyDone = [
        for (final c in locals)
          if (c.completedAt != null && !_reportedDone.contains(c.remoteId)) c,
      ];
      final last = _lastChallenges;
      final due = force ||
          last == null ||
          now.difference(last) >= _challengeInterval;
      if (newlyDone.isEmpty && !due) return;
      _lastChallenges = now;

      final profile = await db.watchProfile().first;
      final myName = displayName(profile);

      for (final c in locals) {
        final remoteId = c.remoteId!;
        if (c.dismissedAt != null) continue;
        final deadline = c.deadline;
        if (deadline != null &&
            now.isAfter(deadline.add(const Duration(days: 7)))) {
          continue;
        }

        final progress = await _progress(db, c);
        if (progress != null && _reportedProgress[remoteId] != progress) {
          await SocialService.instance
              .reportChallenge(remoteId, progress: progress);
          _reportedProgress[remoteId] = progress;
        }

        final done = c.completedAt;
        if (done != null && !_reportedDone.contains(remoteId)) {
          final remote = await SocialService.instance.getChallenge(remoteId);
          final me = SocialService.instance.uid;
          if (remote != null && me != null && remote.completed[me] == null) {
            await SocialService.instance
                .reportChallenge(remoteId, completedAt: done);
            await SocialService.instance.fanOut(
              FeedType.challengeDone,
              myName,
              {
                'challengeId': remoteId,
                'kind': remote.kind,
                if (remote.exerciseSlug != null)
                  'exerciseSlug': remote.exerciseSlug,
              },
              to: [remote.otherMember(me)],
            );
          }
          _reportedDone.add(remoteId);
        }
      }
    } catch (e) {
      debugPrint('Social: challenge sync failed: $e');
    }
  }

  static Future<double?> _progress(AppDatabase db, Challenge c) async {
    final deadline = c.deadline ?? endOfMonth(c.createdAt);
    switch (c.kind) {
      case ChallengeKind.workoutsInMonth:
        final from = DateTime(c.createdAt.year, c.createdAt.month);
        return (await db.socialWorkoutCount(from, deadline)).toDouble();
      case ChallengeKind.weeklyWater:
        // Ven jde jen procento splnění, nikdy množství.
        final from = isoWeekStart(c.createdAt);
        final ml = await db.socialWaterBetween(from, deadline);
        return completionPercent(ml.toDouble(), c.targetValue).toDouble();
      case ChallengeKind.beatRecord:
        return null;
    }
  }

  // -------------------------------------------------------------------
  // Příchozí položky
  // -------------------------------------------------------------------

  /// Přijatá pozvánka (odpověď přítele) → trénink i do mého kalendáře.
  static Future<void> processInbox(List<FeedItem> items) async {
    if (!_ready) return;
    for (final item in items) {
      if (item.type != FeedType.inviteReply ||
          item.handled ||
          _handledFeed.contains(item.id)) {
        continue;
      }
      _handledFeed.add(item.id);
      try {
        final start = item.date('startAt');
        if (item.data['accepted'] == true &&
            start != null &&
            start.isAfter(DateTime.now())) {
          await addSocialWorkoutToCalendar(
            planName: item.str('planName') ?? '',
            friendName: item.fromName,
            start: start,
            durationMinutes: item.number('durationMinutes')?.round() ?? 60,
            askPermission: false,
          );
        }
        await SocialService.instance.updateFeedItem(item.id, handled: true);
      } catch (e) {
        debugPrint('Social: inbox item failed: $e');
      }
    }
  }

  /// Po odhlášení zapomene, co už odeslal.
  static void reset() {
    _lastStats = null;
    _lastChallenges = null;
    _reportedProgress.clear();
    _reportedDone.clear();
    _handledFeed.clear();
    GymPublisher.reset();
  }
}
