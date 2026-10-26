// Regenerace z hodinek a prstenů: denní data (spánek, HRV, klidový tep)
// z Health Connect / Apple Zdraví do tabulky RecoveryDays, tep během
// tréninku do WorkoutSessions a připravenost k tréninku
// (core/readiness.dart, docs/readiness.md). Jen čtení – do Health se
// odsud nic nezapisuje a data zůstávají v telefonu.

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/readiness.dart';
import '../../core/rest_time.dart';
import '../../data/database.dart';
import '../../features/workout/workout_service.dart';
import '../../providers.dart';
import '../../services/live_heart_rate.dart';
import 'health_logic.dart';
import 'health_service.dart';

extension RecoveryQueries on AppDatabase {
  Stream<List<RecoveryDayEntry>> watchRecoveryDays(DateTime since) =>
      (select(recoveryDays)
            ..where((d) => d.day.isBiggerOrEqualValue(startOfDay(since)))
            ..orderBy([(d) => OrderingTerm.asc(d.day)]))
          .watch();

  Future<DateTime?> latestRecoveryDay() async {
    final row = await (select(recoveryDays)
          ..orderBy([(d) => OrderingTerm.desc(d.day)])
          ..limit(1))
        .getSingleOrNull();
    return row?.day;
  }

  Future<void> upsertRecoveryDay(RecoveryDay d) =>
      into(recoveryDays).insertOnConflictUpdate(RecoveryDaysCompanion(
        day: Value(startOfDay(d.day)),
        sleepMinutes: Value(d.sleepMinutes),
        hrvMs: Value(d.hrvMs),
        restingHr: Value(d.restingHr),
      ));

  /// Dokončené tréninky od [since] bez údajů o tepu.
  Future<List<WorkoutSession>> sessionsWithoutHeartRate(DateTime since) =>
      (select(workoutSessions)
            ..where((s) =>
                s.endedAt.isNotNull() &
                s.avgHeartRate.isNull() &
                s.startedAt.isBiggerOrEqualValue(since)))
          .get();

  Future<void> saveSessionHeartRate(
    int sessionId,
    HeartRateSummary hr, {
    int? kcal,
  }) =>
      (update(workoutSessions)..where((s) => s.id.equals(sessionId)))
          .write(WorkoutSessionsCompanion(
        avgHeartRate: Value(hr.average),
        maxHeartRate: Value(hr.max),
        heartRateZones: Value(hr.zoneSeconds.isEmpty ? null : hr.zonesText),
        heartRateKcal: Value(kcal),
      ));

  Stream<WorkoutSession?> watchSession(int id) =>
      (select(workoutSessions)..where((s) => s.id.equals(id)))
          .watchSingleOrNull();
}

RecoveryDay recoveryDayOf(RecoveryDayEntry e) => RecoveryDay(
      day: e.day,
      sleepMinutes: e.sleepMinutes,
      hrvMs: e.hrvMs,
      restingHr: e.restingHr,
    );

class RecoverySync {
  RecoverySync._();

  static final RecoverySync instance = RecoverySync._();

  final HealthService _service = HealthService.instance;
  final SyncThrottle _throttle = SyncThrottle(const Duration(minutes: 15));
  Future<void>? _running;

  /// Zapnutí z Profilu: oprávnění ke čtení. Po úspěchu se data hned
  /// načtou (60 dní zpět).
  Future<HealthAccessResult> enable(AppDatabase db) async {
    final result = await _service.requestReadAccess();
    if (result == HealthAccessResult.granted) {
      await db.updateProfile(
          const UserProfilesCompanion(healthReadEnabled: Value(true)));
      _throttle.reset();
      unawaited(refresh(db));
    }
    return result;
  }

  /// Načte nová denní data a tep k tréninkům bez tepu. Nejvýš jednou za
  /// 15 minut (kromě [force]); souběžné volání počká na běžící.
  Future<void> refresh(AppDatabase db, {bool force = false}) {
    final running = _running;
    if (running != null) return running;
    if (!force && !_throttle.tryAcquire()) return Future.value();
    final task = _refresh(db).catchError((Object e) {
      debugPrint('Recovery refresh failed: $e');
    }).whenComplete(() => _running = null);
    return _running = task;
  }

  Future<void> _refresh(AppDatabase db) async {
    final profile = await db.watchProfile().first;
    if (!profile.healthReadEnabled || !_service.isSupportedPlatform) return;
    if (await _service.availability() != HealthAvailability.available) return;
    final now = DateTime.now();
    final today = startOfDay(now);
    final latest = await db.latestRecoveryDay();
    // Poprvé 60 dní (normální hodnoty), potom od posledního dne − 2
    // (hodinky a prsteny dosynchronizují noc se zpožděním).
    final first = latest == null
        ? DateTime(today.year, today.month, today.day - kReadinessBaselineDays)
        : DateTime(latest.year, latest.month, latest.day - 2);
    final from = DateTime(first.year, first.month, first.day - 1, 12);
    final sleep = await _service.readSleep(from, now);
    final hrv = await _service.readHrv(from, now);
    final rhr = await _service.readRestingHeartRate(from, now);
    for (var d = first;
        !d.isAfter(today);
        d = DateTime(d.year, d.month, d.day + 1)) {
      final day = RecoveryDay(
        day: d,
        sleepMinutes: sleepMinutesForDay(sleep, d),
        hrvMs: hrvForDay(hrv, d),
        restingHr: restingHrForDay(rhr, d),
      );
      if (!day.isEmpty) await db.upsertRecoveryDay(day);
    }
    // Tep k tréninkům za poslední 3 dny, které ho ještě nemají.
    for (final s in await db.sessionsWithoutHeartRate(
        DateTime(today.year, today.month, today.day - 3))) {
      await recordSessionHeartRate(db, s.id, readHealth: true);
    }
  }

  /// Uloží tep tréninku: živé vzorky z hodinek, jinak (a [readHealth])
  /// vzorky z Health Connect / Apple Zdraví.
  Future<void> recordSessionHeartRate(
    AppDatabase db,
    int sessionId, {
    required bool readHealth,
  }) async {
    final session = await db.getSession(sessionId);
    final end = session.endedAt;
    if (end == null || session.avgHeartRate != null) return;
    final profile = await db.watchProfile().first;
    var samples = LiveHeartRate.instance.samplesBetween(session.startedAt, end);
    if (samples.length < 3 &&
        readHealth &&
        profile.healthReadEnabled &&
        _service.isSupportedPlatform) {
      samples = await _service.readHeartRate(session.startedAt, end);
    }
    final birthYear = profile.birthYear;
    final age = birthYear == null ? null : session.startedAt.year - birthYear;
    final hr = summarizeHeartRate(samples,
        start: session.startedAt, end: end, age: age);
    if (hr == null) return;
    final weight = await db.watchLatestWeight().first;
    final kcal = heartRateKcal(
      avgHr: hr.average,
      minutes: end.difference(session.startedAt).inSeconds / 60,
      weightKg: weight?.weightKg,
      age: age,
      sex: sexOf(profile.sex),
    );
    await db.saveSessionHeartRate(sessionId, hr, kcal: kcal);
  }
}

/// Háček po tréninku (module_hub: health:finished): tep z hodinek.
Future<void> recoveryWorkoutFinishedHook(
  WidgetRef ref,
  WorkoutSummary summary,
) async {
  final db = ref.read(databaseProvider);
  await RecoverySync.instance
      .recordSessionHeartRate(db, summary.sessionId, readHealth: true);
}

/// Denní data za posledních 70 dní (60 dní normálu + týden).
final recoveryDaysProvider = StreamProvider<List<RecoveryDay>>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  return db
      .watchRecoveryDays(DateTime(now.year, now.month, now.day - 70))
      .map((rows) => [for (final r in rows) recoveryDayOf(r)]);
});

/// Připravenost na dnešek; null = vypnuto nebo bez dat.
final readinessProvider = Provider<ReadinessReport?>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  if (profile == null || !profile.healthReadEnabled) return null;
  final days = ref.watch(recoveryDaysProvider).valueOrNull;
  if (days == null) return null;
  return evaluateReadiness(days, DateTime.now());
});
