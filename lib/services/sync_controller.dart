import 'dart:async';
import 'dart:ui' show PlatformDispatcher, Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../l10n/app_localizations.dart';
import '../modules/module_hub.dart';
import '../providers.dart';
import 'calendar_service.dart';
import 'notification_service.dart';

/// Texty pro notifikace a kalendář mimo widgety (podle jazyka telefonu).
AppLocalizations deviceLocalizations() {
  final locale = PlatformDispatcher.instance.locale;
  final supported = AppLocalizations.supportedLocales
      .any((l) => l.languageCode == locale.languageCode);
  return lookupAppLocalizations(
    supported ? Locale(locale.languageCode) : const Locale('en'),
  );
}

/// Po změně plánů, profilu nebo období přeplánuje notifikace
/// a srovná kalendář. Změny se sdružují (2 s), aby se nesynchronizovalo
/// při každém kliknutí.
class SyncController {
  SyncController(this._ref);

  final Ref _ref;
  Timer? _debounce;
  bool _running = false;
  bool _again = false;

  void schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), run);
  }

  Future<void> run() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      final db = _ref.read(databaseProvider);
      final profile = await db.watchProfile().first;
      if (!profile.onboardingDone) return;

      final l10n = deviceLocalizations();
      final now = DateTime.now();
      final planned = await db.plannedWorkouts(now, 14);
      final periods = await db.watchPeriods().first;
      final water = await _water(db, now);

      await NotificationService.instance.reschedule(
        profile: profile,
        planned: planned,
        periods: [
          for (final p in periods)
            (type: p.type, start: p.startDate, end: p.endDate),
        ],
        l10n: l10n,
        locale: l10n.localeName,
        db: db,
        waterTodayMl: water.drunk,
        trainedToday: water.trained,
      );

      if (profile.calendarSyncEnabled) {
        await CalendarService.instance.sync(db, planned, l10n,
            titleTemplate: profile.calendarTitle);
      }

      for (final hook in moduleSyncHooks()) {
        try {
          await hook(_ref, profile);
        } catch (e) {
          debugPrint('Sync hook failed: $e');
        }
      }
    } catch (e) {
      debugPrint('Sync failed: $e');
    } finally {
      _running = false;
      if (_again) {
        _again = false;
        schedule();
      }
    }
  }

  /// Kolik se dnes vypilo a jestli byl trénink (cíl pití +500 ml).
  Future<({int drunk, bool trained})> _water(AppDatabase db, DateTime now) async =>
      (
        drunk: await db.watchWaterTotal(now).first,
        trained: await db.watchWorkoutDoneOn(now).first,
      );

  /// Po zápisu vody (nebo dokončeném tréninku) přepočítá jen připomínky
  /// pití – bez kalendáře a ranních připomínek.
  void scheduleWater() {
    if (_debounce?.isActive ?? false) return; // celá synchronizace už čeká
    _waterDebounce?.cancel();
    _waterDebounce = Timer(const Duration(seconds: 2), _runWater);
  }

  Timer? _waterDebounce;

  Future<void> _runWater() async {
    try {
      final db = _ref.read(databaseProvider);
      final profile = await db.watchProfile().first;
      if (!profile.onboardingDone) return;
      final periods = await db.watchPeriods().first;
      final water = await _water(db, DateTime.now());
      await NotificationService.instance.rescheduleWater(
        profile: profile,
        periods: [
          for (final p in periods)
            (type: p.type, start: p.startDate, end: p.endDate),
        ],
        l10n: deviceLocalizations(),
        waterTodayMl: water.drunk,
        trainedToday: water.trained,
      );
    } catch (e) {
      debugPrint('Water sync failed: $e');
    }
  }

  void dispose() {
    _debounce?.cancel();
    _waterDebounce?.cancel();
  }
}

/// Aktivuje se v kořeni aplikace; poslouchá změny dat a spouští synchronizaci.
final syncControllerProvider = Provider<SyncController>((ref) {
  final controller = SyncController(ref);
  ref.listen(plansProvider, (_, __) => controller.schedule());
  ref.listen(profileProvider, (_, __) => controller.schedule());
  ref.listen(periodsProvider, (_, __) => controller.schedule());
  ref.listen(scheduledTodayProvider, (_, __) => controller.schedule());
  // Nový den (i po návratu z pozadí): posunout okno připomínek
  // (plánují se jen 7 dní dopředu, na iOS voda jen 2 dny).
  ref.listen(currentDayProvider, (_, __) => controller.schedule());
  // Zapsaná voda nebo dokončený trénink: připomínky pití podle toho, kolik
  // ještě chybí (core/water_pace.dart).
  ref.listen(waterTodayProvider, (_, __) => controller.scheduleWater());
  ref.listen(workoutDoneTodayProvider, (_, __) => controller.scheduleWater());
  ref.onDispose(controller.dispose);
  controller.schedule();
  return controller;
});
