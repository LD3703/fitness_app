import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:flutter/foundation.dart';

import '../../../data/database.dart';
import '../social_auth.dart';
import '../social_backend.dart';
import '../social_logic.dart';
import '../social_queries.dart';
import 'gym_logic.dart';
import 'gym_queries.dart';
import 'gym_service.dart';
import 'plausibility.dart';

/// Výsledek zveřejnění: které kategorie neprošly kontrolou reálnosti.
typedef GymPublishResult = ({Set<GymCategory> rejected});

/// Zveřejňování mých hodnot do žebříčku posilovny.
///
/// Volá se z háčků modulu social (SocialPublisher: po tréninku a při
/// synchronizaci, nejvýš jednou za 15 min) a při otevření žebříčku.
/// Ven jde jen: odhad 1RM cviků z [GymCategory.lifts], které uživatel
/// dělal (na 0,5 kg), počet tréninků a věková skupina (u40 / 40 / 50 / 60,
/// z roku narození v profilu – nikdy věk ani rok). Tělesná váha, období
/// ani voda se nepoužijí.
abstract final class GymPublisher {
  static DateTime? _last;

  /// Posilovna, ve které už jsem v tomto běhu aplikace uklidil záznamy
  /// zrušených kategorií.
  static String? _retiredCleanedGym;
  static Future<GymPublishResult?>? _running;

  static const _interval = Duration(minutes: 15);

  /// Kategorie, které při posledním zveřejnění neprošly kontrolou
  /// (žebříček ukáže upozornění).
  static final rejected = ValueNotifier<Set<GymCategory>>(const {});

  static bool get _ready =>
      SocialBackend.available && SocialAuth.instance.currentUser != null;

  /// Přepočítá a zapíše moje záznamy (když jsem v posilovně a chci být
  /// vidět). Bez [force] nejvýš jednou za 15 minut.
  static Future<GymPublishResult?> publish(
    AppDatabase db, {
    bool force = false,
  }) {
    if (!_ready) return Future.value(null);
    final now = DateTime.now();
    final last = _last;
    if (!force && last != null && now.difference(last) < _interval) {
      return Future.value(null);
    }
    _last = now;
    // Souběžná volání (háček + otevření obrazovky) sdílí jeden běh;
    // vynucené volání počká na rozběhnutý a spustí se znovu (mohla se
    // změnit přezdívka nebo viditelnost).
    final running = _running;
    if (running != null && !force) return running;
    final Future<GymPublishResult?> run = running == null
        ? _publish(db, now)
        : running.then((_) => _publish(db, now));
    _running = run;
    unawaited(run.whenComplete(() {
      if (identical(_running, run)) _running = null;
    }));
    return run;
  }

  static Future<GymPublishResult?> _publish(AppDatabase db, DateTime now) async {
    try {
      final service = GymService.instance;
      final membership = await service.membership();
      final gymId = membership?.gymId;
      if (membership == null || gymId == null) return null;
      if (!membership.show) {
        await service.deleteMyEntries(gymId);
        rejected.value = const {};
        return (rejected: const <GymCategory>{});
      }
      final me = service.uid;
      if (me == null) return null;

      if (_retiredCleanedGym != gymId) {
        try {
          await service.deleteRetiredEntries(gymId);
          _retiredCleanedGym = gymId;
        } catch (e) {
          debugPrint('Gym: retired entries cleanup failed: $e');
        }
      }

      // Věková skupina se mění s rokem (a se zadáním roku narození).
      final profile = await db.watchProfile().first;
      final ageGroup = gymAgeGroupFor(profile.birthYear, now.year);
      try {
        await service.syncMemberAgeGroup(gymId, ageGroup);
      } catch (e) {
        debugPrint('Gym: member age group sync failed: $e');
      }

      final values = await _localValues(db, now);
      final existing = await service.myEntries(gymId);
      final month = monthKey(now);
      final nickname = sanitizeGymNickname(membership.nickname ?? '?');

      final changes = <GymCategory, Map<String, Object?>?>{};
      final bad = <GymCategory>{};
      for (final category in GymCategory.values) {
        final v = values[category]!;
        final prev = existing[category];
        // Předchozí maximum: ověřené serverem, jinak poslední zveřejněné.
        final prevValue =
            prev?.verifiedValue ?? (prev == null || prev.hidden ? null : prev.best);
        final prevAt = prev?.verifiedAt ?? prev?.bestAt;

        ImplausibleReason? check(double value) => checkGymValue(
              category: category,
              value: value,
              previousValue: prevValue,
              previousAt: prevAt,
              now: now,
            );

        var best = v.all;
        if (best != null && check(best) != null) {
          bad.add(category);
          best = null;
        }
        var bestMonth = v.month;
        if (bestMonth != null && check(bestMonth) != null) {
          bad.add(category);
          bestMonth = null;
        }
        // Nereálná celková hodnota: necháme dřívější zveřejněnou.
        if (best == null && v.all != null && prev != null && !prev.hidden) {
          best = prev.best;
        }
        if (best == null) {
          if (prev != null && v.all == null) changes[category] = null;
          continue;
        }
        if (bestMonth != null && bestMonth > best) bestMonth = best;

        final unchanged = prev != null &&
            prev.best == best &&
            prev.bestMonth == bestMonth &&
            prev.monthKey == month &&
            prev.nickname == nickname &&
            prev.gender == membership.gender &&
            prev.ageGroup == ageGroup;
        if (unchanged) continue;

        changes[category] = {
          'uid': me,
          'category': category.key,
          'nickname': nickname,
          'gender': membership.gender.name,
          'ageGroup': ageGroup?.key ?? FieldValue.delete(),
          'best': best,
          if (prev == null || prev.bestAt == null || best > prev.best)
            'bestAt': FieldValue.serverTimestamp(),
          'bestMonth': bestMonth ?? FieldValue.delete(),
          'monthKey': month,
          'updatedAt': FieldValue.serverTimestamp(),
        };
      }
      await service.writeMyEntries(gymId, changes);
      rejected.value = bad;
      return (rejected: bad);
    } catch (e) {
      debugPrint('Gym: publish failed: $e');
      return null;
    }
  }

  /// Lokální hodnoty (celkově a za aktuální měsíc), už zaokrouhlené.
  static Future<Map<GymCategory, ({double? all, double? month})>> _localValues(
    AppDatabase db,
    DateTime now,
  ) async {
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1);

    final lifts = <GymCategory, ({double? all, double? month})>{};
    for (final c in GymCategory.lifts) {
      final slug = c.exerciseSlug!;
      // Jen cviky, které uživatel opravdu dělal (jinak se nic nezveřejní).
      final all = await db.gymBestOneRepMax(slug);
      final month = all == null
          ? null
          : await db.gymBestOneRepMax(slug, from: monthStart, to: monthEnd);
      lifts[c] = (
        all: all == null ? null : roundGymLift(all),
        month: month == null ? null : roundGymLift(month),
      );
    }

    final workoutsMonth = await db.socialWorkoutCount(monthStart, monthEnd);
    final workoutsBest = await db.gymBestMonthWorkouts();
    final bestCount =
        workoutsBest > workoutsMonth ? workoutsBest : workoutsMonth;

    return {
      ...lifts,
      GymCategory.workouts: (
        all: bestCount > 0 ? bestCount.toDouble() : null,
        month: workoutsMonth > 0 ? workoutsMonth.toDouble() : null,
      ),
    };
  }

  /// Po odhlášení zapomene stav.
  static void reset() {
    _last = null;
    _retiredCleanedGym = null;
    rejected.value = const {};
  }
}
