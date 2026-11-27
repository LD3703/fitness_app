// Anonymní statistiky používání přes Google Analytics pro Firebase.
//
// - Jen se souhlasem uživatele (dotaz při spuštění, změna v Profilu →
//   Soukromí). Dokud neodpoví, nic se neodesílá. Výchozí sběr je
//   v nativním projektu vypnutý (tool/platform/analytics.dart), takže
//   se nic neodešle ani před spuštěním Dartu.
// - Jen v release buildu a s nastaveným Firebase – při ladění nic.
// - Bez identifikátoru účtu (žádné setUserId), bez reklamních ID a bez
//   zdravotních údajů (váha, menstruace, zranění, tep, data ze Zdraví).
//   Posíláme jen, které obrazovky a funkce se používají (docs/analytics.md).
// - Volba je v malém JSON souboru ve složce dokumentů (jako u hlášení
//   o pádech), aby ji obnovení zálohy nepřepsalo.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../social/social_backend.dart';

/// Odesílat statistiky? Jen v release buildu, s Firebase a se souhlasem
/// (null = uživatel ještě neodpověděl = ne).
bool shouldSendAnalytics({
  required bool releaseBuild,
  required bool firebaseReady,
  required bool? consent,
}) =>
    releaseBuild && firebaseReady && consent == true;

/// Název obrazovky z cesty routeru: vzor cesty bez ID (`/plans/:id` →
/// `plans/id`), bez parametrů. Prázdná cesta = `root`.
String screenNameFor(String path) {
  final clean = path.split('?').first;
  final parts = [
    for (final part in clean.split('/'))
      if (part.isNotEmpty)
        part.startsWith(':')
            ? part.substring(1)
            // Skutečné ID v cestě (když vzor chybí) se nahradí.
            : RegExp(r'^\d+$').hasMatch(part)
                ? 'id'
                : part,
  ];
  final name = parts.isEmpty ? 'root' : parts.join('/');
  return name.length > 100 ? name.substring(0, 100) : name;
}

/// Parametry pro Firebase: jen text a čísla, text nejvýš 100 znaků,
/// bool jako 0/1, null se vynechá.
Map<String, Object> analyticsParams(Map<String, Object?> params) => {
      for (final MapEntry(:key, :value) in params.entries)
        if (value != null)
          key: switch (value) {
            final bool b => b ? 1 : 0,
            final num n => n,
            final Enum e => e.name,
            _ => value.toString().length > 100
                ? value.toString().substring(0, 100)
                : value.toString(),
          },
    };

/// Názvy událostí na jednom místě (přehled v docs/analytics.md).
abstract final class AnalyticsEvent {
  static const onboardingStep = 'onboarding_step';
  static const onboardingComplete = 'onboarding_complete';
  static const workoutStart = 'workout_start';
  static const workoutFinish = 'workout_finish';
  static const workoutDiscard = 'workout_discard';
  static const planCreate = 'plan_create';
  static const programAdd = 'program_add';
  static const planSchedule = 'plan_schedule';
  static const waterAdd = 'water_add';
  static const weightLog = 'weight_log';
  static const repsSlider = 'reps_slider';
  static const swipeDelete = 'swipe_delete';
  static const notificationOpen = 'notification_open';
  static const share = 'share';
}

abstract final class Analytics {
  static const _fileName = 'analytics_settings.json';

  /// Souhlas: true / false, null = ještě se neptal. Sleduje ho Profil
  /// a dotaz při spuštění.
  static final consent = ValueNotifier<bool?>(null);

  /// Je Firebase k dispozici (Android / iOS s nastaveným projektem)?
  static bool get available => SocialBackend.available;

  static bool get active => shouldSendAnalytics(
        releaseBuild: kReleaseMode,
        firebaseReady: available,
        consent: consent.value,
      );

  static FirebaseAnalytics get _fa => FirebaseAnalytics.instance;

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Volá se při startu po spuštění Firebase ([analytics:init]).
  static Future<void> init() async {
    consent.value = await _readConsent();
    await _apply();
  }

  /// Uloží odpověď (dotaz při spuštění nebo vypínač v Profilu).
  static Future<void> setConsent(bool value) async {
    final wasActive = active;
    consent.value = value;
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode({'consent': value}));
    } catch (e) {
      debugPrint('Analytics: settings write failed: $e');
    }
    await _apply();
    // Odvolaný souhlas: smazat identifikátor instance a neodeslaná data.
    if (wasActive && !value && available) {
      try {
        await _fa.resetAnalyticsData();
      } catch (e) {
        debugPrint('Analytics: reset failed: $e');
      }
    }
  }

  static Future<void> _apply() async {
    if (!available) return;
    final on = active;
    try {
      await _fa.setConsent(
        analyticsStorageConsentGranted: on,
        adStorageConsentGranted: false,
        adUserDataConsentGranted: false,
        adPersonalizationSignalsConsentGranted: false,
      );
      await _fa.setAnalyticsCollectionEnabled(on);
    } catch (e) {
      debugPrint('Analytics: apply failed: $e');
    }
  }

  static Future<bool?> _readConsent() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      return json is Map && json['consent'] is bool
          ? json['consent'] as bool
          : null;
    } catch (e) {
      debugPrint('Analytics: settings read failed: $e');
      return null;
    }
  }

  /// Zaznamená událost (bez souhlasu nic). Chyba nikdy nevyskočí ven.
  static void log(String name, [Map<String, Object?> params = const {}]) {
    if (!active) return;
    unawaited(_fa
        .logEvent(name: name, parameters: analyticsParams(params))
        .catchError((Object e) => debugPrint('Analytics: $name failed: $e')));
  }

  /// Zobrazená obrazovka (název z [screenNameFor]).
  static void screen(String name) {
    if (!active) return;
    unawaited(_fa
        .logScreenView(screenName: name, screenClass: name)
        .catchError((Object e) => debugPrint('Analytics: screen failed: $e')));
  }

  /// Vlastnosti uživatele pro rozdělení statistik (úroveň, cíl…).
  /// Hodnoty nejvýš 36 znaků.
  static void setUserProperties(Map<String, Object?> properties) {
    if (!active) return;
    for (final MapEntry(:key, :value) in properties.entries) {
      var text = switch (value) {
        null => null,
        final bool b => b ? '1' : '0',
        final Enum e => e.name,
        _ => value.toString(),
      };
      if (text != null && text.length > 36) text = text.substring(0, 36);
      unawaited(_fa
          .setUserProperty(name: key, value: text)
          .catchError((Object e) => debugPrint('Analytics: $key failed: $e')));
    }
  }
}

/// Souhlas se statistikami pro UI (null = ještě neodpověděl).
final analyticsConsentProvider = Provider<bool?>((ref) {
  final notifier = Analytics.consent;
  void listener() => ref.invalidateSelf();
  notifier.addListener(listener);
  ref.onDispose(() => notifier.removeListener(listener));
  return notifier.value;
});
