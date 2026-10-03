import 'dart:async';
import 'dart:ui' show PlatformDispatcher, Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      );

      if (profile.calendarSyncEnabled) {
        await CalendarService.instance.sync(db, planned, l10n);
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

  void dispose() => _debounce?.cancel();
}

/// Aktivuje se v kořeni aplikace; poslouchá změny dat a spouští synchronizaci.
final syncControllerProvider = Provider<SyncController>((ref) {
  final controller = SyncController(ref);
  ref.listen(plansProvider, (_, __) => controller.schedule());
  ref.listen(profileProvider, (_, __) => controller.schedule());
  ref.listen(periodsProvider, (_, __) => controller.schedule());
  ref.listen(scheduledTodayProvider, (_, __) => controller.schedule());
  ref.onDispose(controller.dispose);
  controller.schedule();
  return controller;
});
