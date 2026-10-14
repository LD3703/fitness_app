// Hlášení o pádech přes Firebase Crashlytics.
//
// - Běží jen s nastaveným Firebase (SocialBackend.available) a jen
//   v release buildu – při ladění se nic neodesílá.
// - Uživatel ho může vypnout v Profilu → Soukromí. Volba je v malém
//   JSON souboru ve složce dokumentů (ne v databázi, aby ji obnovení
//   zálohy nepřepsalo) a při každém startu se nastaví do Crashlytics.
// - Neposíláme identifikátor uživatele ani vlastní klíče s daty
//   z tréninků – jen samotnou chybu (zásady ochrany soukromí, část 3).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../social/social_backend.dart';

/// Odesílat hlášení? Jen v release buildu, s Firebase a se souhlasem
/// uživatele (výchozí zapnuto, oprávněný zájem s možností vypnout).
bool shouldSendCrashReports({
  required bool releaseBuild,
  required bool firebaseReady,
  required bool userEnabled,
}) =>
    releaseBuild && firebaseReady && userEnabled;

abstract final class CrashReporting {
  static const _fileName = 'crash_reporting_settings.json';

  /// Volba uživatele (true = odesílat). Sleduje ji Profil.
  static final enabled = ValueNotifier<bool>(true);

  static bool _installed = false;

  /// Je Crashlytics k dispozici (nastavené Firebase na Androidu / iOS)?
  static bool get available => SocialBackend.available;

  static bool get _active => shouldSendCrashReports(
        releaseBuild: kReleaseMode,
        firebaseReady: available,
        userEnabled: enabled.value,
      );

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Volá se při startu po spuštění Firebase ([crash:init] v module_hub).
  ///
  /// Sběr je v nativním projektu ve výchozím stavu vypnutý
  /// (tool/platform/crash.dart: manifest / Info.plist), takže se nic
  /// neodešle dřív, než ho tady zapneme podle volby uživatele.
  static Future<void> init() async {
    enabled.value = await _readEnabled();
    if (!available) return;
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(_active);
    if (!_active) {
      // Pády zachycené při vypnutém sběru zůstávají v telefonu jako
      // „neodeslané“ – při vypnutém odesílání je smažeme.
      try {
        await FirebaseCrashlytics.instance.deleteUnsentReports();
      } catch (e) {
        debugPrint('Crash reporting: delete unsent failed: $e');
      }
    }
    if (_installed) return;
    _installed = true;

    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      if (_active) {
        unawaited(
          FirebaseCrashlytics.instance.recordFlutterFatalError(details),
        );
      }
      previousFlutterHandler?.call(details);
    };
    final previousPlatformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      if (_active) {
        unawaited(
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
        );
      }
      return previousPlatformHandler?.call(error, stack) ?? _active;
    };
  }

  /// Zapne / vypne odesílání (Profil → Soukromí).
  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode({'enabled': value}));
    } catch (e) {
      debugPrint('Crash reporting: settings write failed: $e');
    }
    if (available) {
      try {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(_active);
        // Po vypnutí smaže hlášení, která ještě nebyla odeslaná.
        if (!value) {
          await FirebaseCrashlytics.instance.deleteUnsentReports();
        }
      } catch (e) {
        debugPrint('Crash reporting: update failed: $e');
      }
    }
  }

  static Future<bool> _readEnabled() async {
    try {
      final file = await _file();
      if (!await file.exists()) return true;
      final json = jsonDecode(await file.readAsString());
      return json is Map && json['enabled'] is bool
          ? json['enabled'] as bool
          : true;
    } catch (e) {
      debugPrint('Crash reporting: settings read failed: $e');
      return true;
    }
  }
}

/// Volba „Odesílat hlášení o pádech“ pro UI.
final crashReportingEnabledProvider = Provider<bool>((ref) {
  final notifier = CrashReporting.enabled;
  void listener() => ref.invalidateSelf();
  notifier.addListener(listener);
  ref.onDispose(() => notifier.removeListener(listener));
  return notifier.value;
});
