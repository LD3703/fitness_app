// Synchronizace tréninků a tělesné váhy s Health Connect / Apple Zdraví.
// Sdílí se jen tréninky a váha – nikdy období (nemoc, zranění…) ani voda.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/database.dart';
import '../../features/workout/workout_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../services/sync_controller.dart';
import 'health_logic.dart';
import 'health_queries.dart';
import 'health_service.dart';

/// Háček po dokončení tréninku (module_hub: health:finished).
/// Zápis do Health běží na pozadí, aby nezdržoval souhrn tréninku.
Future<void> healthWorkoutFinishedHook(
  WidgetRef ref,
  WorkoutSummary summary,
) async {
  final db = ref.read(databaseProvider);
  unawaited(
    HealthSync.instance
        .exportFinishedWorkout(db, summary.sessionId)
        .catchError((Object e) => debugPrint('Health export failed: $e')),
  );
}

/// Háček synchronizace po změně dat (module_hub: health:sync).
Future<void> healthSyncHook(Ref ref, UserProfile profile) =>
    HealthSync.instance.sync(ref.read(databaseProvider), profile);

class HealthSync {
  HealthSync._();

  static final HealthSync instance = HealthSync._();

  static const _exportWindow = Duration(days: 30);
  static const _weightImportDays = 90;
  static const _weightExportDays = 7;

  final HealthService _service = HealthService.instance;
  final SyncThrottle _throttle = SyncThrottle(const Duration(minutes: 10));

  /// Úlohy běží za sebou, aby se trénink nezapsal dvakrát (háček po
  /// tréninku a synchronizace současně).
  Future<void> _queue = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() task) {
    final result = _queue.then((_) => task());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Zapnutí z Profilu: dostupnost + oprávnění. Po úspěchu se další
  /// synchronizace spustí hned (bez čekání na omezení četnosti).
  Future<HealthAccessResult> enable() async {
    final result = await _service.requestAccess();
    if (result == HealthAccessResult.granted) _throttle.reset();
    return result;
  }

  Future<void> exportFinishedWorkout(AppDatabase db, int sessionId) =>
      _serial(() async {
        final profile = await db.watchProfile().first;
        if (!profile.healthSyncEnabled || !_service.isSupportedPlatform) {
          return;
        }
        if (!await _service.isReady()) return;
        final item = await db.healthSessionToExport(sessionId);
        if (item == null) return;
        await _exportSession(
          db,
          item,
          deviceLocalizations(),
          withEnergy: await _service.canWriteWorkoutEnergy(),
        );
      });

  Future<void> sync(AppDatabase db, UserProfile profile) async {
    if (!profile.healthSyncEnabled || !_service.isSupportedPlatform) return;
    if (!_throttle.tryAcquire()) return;
    await _serial(() async {
      if (!await _service.isReady()) return;
      final now = DateTime.now();

      // 1) Tréninky za posledních 30 dní, které v Health ještě nejsou.
      final sessions =
          await db.healthSessionsToExport(now.subtract(_exportWindow));
      if (sessions.isNotEmpty) {
        final l10n = deviceLocalizations();
        final withEnergy = await _service.canWriteWorkoutEnergy();
        for (final item in sessions) {
          try {
            await _exportSession(db, item, l10n, withEnergy: withEnergy);
          } catch (e) {
            debugPrint('Health workout export failed: $e');
          }
        }
      }

      // 2) Tělesná váha – jen když ji uživatel v aplikaci sleduje.
      if (profile.trackWeight) {
        try {
          await _syncWeights(db, now);
        } catch (e) {
          debugPrint('Health weight sync failed: $e');
        }
      }
    });
  }

  Future<void> _exportSession(
    AppDatabase db,
    HealthSessionItem item,
    AppLocalizations l10n, {
    required bool withEnergy,
  }) async {
    final s = item.session;
    final end = s.endedAt;
    if (end == null) return;
    if (!end.isAfter(s.startedAt)) {
      // Nulová délka – Health Connect by záznam odmítl; už to nezkoušej.
      await db.markHealthExported(s.id, DateTime.now());
      return;
    }
    final planB = s.kind == SessionKind.planB;
    final title = planB
        ? l10n.healthPlanBTitle
        : (item.planName ?? l10n.healthWorkoutTitle);
    final kcal = s.estimatedKcal?.round();
    final ok = await _service.writeWorkout(
      planB: planB,
      start: s.startedAt,
      end: end,
      kcal: withEnergy && kcal != null && kcal > 0 ? kcal : null,
      title: title,
    );
    if (ok) await db.markHealthExported(s.id, DateTime.now());
  }

  Future<void> _syncWeights(AppDatabase db, DateTime now) async {
    final today = DateTime(now.year, now.month, now.day);
    final importFrom =
        DateTime(today.year, today.month, today.day - _weightImportDays);
    final exportFrom =
        DateTime(today.year, today.month, today.day - (_weightExportDays - 1));

    final canRead = await _service.canReadWeight();
    final health =
        canRead ? await _service.readWeights(importFrom, now) : <WeightSample>[];

    // a) Import: dny bez záznamu v aplikaci. Existující záznam se nepřepisuje.
    final app = await db.healthWeightsSince(importFrom);
    final toImport = weightsToImport(
      health: health,
      appDays: {for (final e in app) e.day},
    );
    for (final e in toImport.entries) {
      await db.insertWeightIfMissing(e.key, e.value);
    }

    // b) Export: záznamy z posledních 7 dní, které v Health pro ten den chybí.
    if (!await _service.canWriteWeight()) return;
    // Bez práva čtení (Android to pozná) raději nic nezapisujeme – nešlo by
    // poznat, co už v Health je. Na iOS čtení zjistit nejde, proto navíc
    // pamatujeme, co už aplikace zapsala.
    if (!canRead) return;
    final exported =
        pruneExportedWeights(await _loadExported(), exportFrom);
    final toExport = weightsToExport(
      app: [
        for (final e in app) (day: e.day, kg: e.weightKg),
      ],
      health: health,
      from: exportFrom,
      alreadyExported: exported,
    );
    for (final e in toExport) {
      final ok = await _service.writeWeight(weightSampleTime(e.day, now), e.kg);
      if (ok) exported[e.day] = e.kg;
    }
    await _saveExported(exported);
  }

  // Záznam „už zapsáno“ – malý JSON v podpůrné složce aplikace.
  Future<File> _exportedFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/health_weight_exports.json');
  }

  Future<Map<DateTime, double>> _loadExported() async {
    try {
      final file = await _exportedFile();
      if (!await file.exists()) return {};
      return decodeExportedWeights(jsonDecode(await file.readAsString()));
    } catch (e) {
      debugPrint('Health export log read failed: $e');
      return {};
    }
  }

  Future<void> _saveExported(Map<DateTime, double> m) async {
    try {
      final file = await _exportedFile();
      await file.writeAsString(jsonEncode(encodeExportedWeights(m)));
    } catch (e) {
      debugPrint('Health export log write failed: $e');
    }
  }
}
