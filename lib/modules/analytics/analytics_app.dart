import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/experience_level.dart';
import '../../core/rest_time.dart';
import '../../data/database.dart';
import '../../features/workout/workout_service.dart';
import '../../providers.dart';
import '../../router.dart';
import '../../services/notification_service.dart';
import 'analytics.dart';
import 'analytics_consent_sheet.dart';

/// [analytics:app] – po celou dobu běhu aplikace:
/// - jednou se zeptá na souhlas (dokud neodpoví, nic se neodesílá),
/// - zaznamenává zobrazené obrazovky (vzor cesty bez ID),
/// - nastaví vlastnosti uživatele (úroveň, cíl, tréninky týdně…).
final analyticsAppProvider = Provider<void>((ref) {
  final router = ref.watch(routerProvider);
  final delegate = router.routerDelegate;
  String? lastScreen;
  var asked = false;

  String currentPath() {
    try {
      return delegate.currentConfiguration.fullPath;
    } catch (_) {
      return '';
    }
  }

  void logScreen() {
    final path = currentPath();
    if (path.isEmpty || path == '/loading') return;
    final name = screenNameFor(path);
    if (name == lastScreen) return;
    lastScreen = name;
    Analytics.screen(name);
  }

  void maybeAsk() {
    if (asked || Analytics.consent.value != null || !Analytics.available) {
      return;
    }
    final path = currentPath();
    if (path.isEmpty || path == '/loading') return;
    asked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = delegate.navigatorKey.currentContext;
      if (context == null || !context.mounted) {
        asked = false;
        return;
      }
      await showAnalyticsConsentSheet(context);
    });
  }

  void onRoute() {
    maybeAsk();
    logScreen();
  }

  void setProperties(UserProfile? p) {
    if (p == null || !p.onboardingDone) return;
    Analytics.setUserProperties({
      'level': experienceLevelOf(p.experienceLevel),
      'goal': trainingFocusOf(p.trainingFocus),
      'days_per_week': p.trainingDaysPerWeek,
      'session_min': p.sessionMinutes,
      'skin': p.skin ?? 'classic',
      'units': p.unitSystem,
      'coach_tone': p.coachTone == 1 ? 'strict' : 'friendly',
      'track_water': p.trackWater,
    });
  }

  void onConsent() {
    if (!Analytics.active) return;
    // Po udělení souhlasu hned i aktuální obrazovka a vlastnosti.
    lastScreen = null;
    logScreen();
    setProperties(ref.read(profileProvider).valueOrNull);
  }

  // Otevřené upozornění (klepnutí nebo tlačítko v něm).
  final notifications = NotificationService.instance.responses.listen((r) {
    Analytics.log(AnalyticsEvent.notificationOpen, {
      'action': r.actionId ?? 'open',
    });
  });

  delegate.addListener(onRoute);
  Analytics.consent.addListener(onConsent);
  ref.listen<AsyncValue<UserProfile>>(
    profileProvider,
    (_, next) => setProperties(next.valueOrNull),
    fireImmediately: true,
  );
  ref.onDispose(() {
    notifications.cancel();
    delegate.removeListener(onRoute);
    Analytics.consent.removeListener(onConsent);
  });
  WidgetsBinding.instance.addPostFrameCallback((_) => onRoute());
});

/// [analytics:finished] – dokončený trénink: délka a počet sérií
/// (bez vah a cviků).
Future<void> analyticsWorkoutFinished(
  WidgetRef ref,
  WorkoutSummary summary,
) async {
  Analytics.log(AnalyticsEvent.workoutFinish, {
    'duration_min': summary.duration.inMinutes,
    'sets': summary.setCount,
    'records': summary.records.length,
  });
}
