// Live Activity odpočtu pauzy na iPhonu (zamykací obrazovka a Dynamic
// Island). Nativní strana: ios/Runner/RestLiveActivity.swift (spouštění)
// a ios/GymBarWidget (vzhled); zapíná je tool/ios_widget.dart.
//
// Odpočet běží v iOS sám – aplikace posílá jen začátek, konec a změnu
// pauzy. Obdoba trvalé notifikace s odpočtem na Androidu
// (NotificationService.scheduleRestEnd).

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';

/// Argumenty kanálu pro „show“ (kvůli testům mimo třídu).
Map<String, Object> restLiveActivityArgs({
  required AppLocalizations l10n,
  required DateTime startAt,
  required DateTime endAt,
  String? nextExercise,
}) =>
    {
      'title': l10n.calRestOngoingTitle,
      'doneTitle': l10n.notifRestTitle,
      'doneBody': l10n.notifRestBody,
      'detail': nextExercise == null || nextExercise.trim().isEmpty
          ? l10n.calRestOngoingBody
          : l10n.planBNext(nextExercise.trim()),
      'startMs': startAt.millisecondsSinceEpoch,
      'endMs':
          (endAt.isBefore(startAt) ? startAt : endAt).millisecondsSinceEpoch,
    };

class RestLiveActivity {
  RestLiveActivity._();
  static final instance = RestLiveActivity._();

  static const _channel = MethodChannel('gymbar/rest_live_activity');

  /// Bez cíle GymBarWidget (nebo na iOS < 16.2) kanál neexistuje –
  /// po první chybě se už nevolá.
  bool _available = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool _shown = false;

  /// Ukáže nebo aktualizuje odpočet pauzy končící v [endAt].
  Future<void> show({
    required AppLocalizations l10n,
    required DateTime startAt,
    required DateTime endAt,
    String? nextExercise,
  }) async {
    if (!_available) return;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'show',
        restLiveActivityArgs(
          l10n: l10n,
          startAt: startAt,
          endAt: endAt,
          nextExercise: nextExercise,
        ),
      );
      _shown = ok ?? false;
    } on MissingPluginException {
      _available = false;
    } catch (e) {
      debugPrint('Live Activity failed: $e');
    }
  }

  /// Ukončí odpočet (pauza přeskočena, trénink skončil).
  Future<void> end() async {
    if (!_available || !_shown) return;
    _shown = false;
    try {
      await _channel.invokeMethod<bool>('end');
    } on MissingPluginException {
      _available = false;
    } catch (e) {
      debugPrint('Live Activity end failed: $e');
    }
  }
}
