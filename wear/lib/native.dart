import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Nativní funkce hodinek z MainActivity.kt (zapisuje ji
/// tool/setup_wear.dart): vibrace, displej zapnutý během pauzy a otočná
/// korunka / luneta (rotary input).
///
/// Když skript nebyl spuštěn (MissingPluginException), funkce tiše
/// nedělají nic – aplikace funguje dál, jen bez vibrací a korunky.
abstract final class WearNative {
  static const _channel = MethodChannel('fitness_wear/native');
  static const _rotary = EventChannel('fitness_wear/rotary');
  static const _heartRate = EventChannel('fitness_wear/heart_rate');

  /// Výrazná vibrace (konec pauzy).
  static Future<void> vibrate() async {
    try {
      await _channel.invokeMethod<void>('vibrate');
    } on MissingPluginException {
      await HapticFeedback.heavyImpact();
    } on PlatformException catch (e) {
      debugPrint('vibrate: $e');
    }
  }

  /// Displej zůstane zapnutý (během pauzy, aby odpočet běžel a vibrace
  /// přišla včas).
  static Future<void> keepScreenOn(bool on) async {
    try {
      await _channel.invokeMethod<void>('keepScreenOn', on);
    } on MissingPluginException {
      // Bez nativní části.
    } on PlatformException catch (e) {
      debugPrint('keepScreenOn: $e');
    }
  }

  /// Tep ze senzoru hodinek (tepy/min). Senzor běží, jen dokud se stream
  /// poslouchá; poprvé si aplikace řekne o oprávnění (BODY_SENSORS /
  /// od Wear OS 6 READ_HEART_RATE). Bez nativní části nic nepřijde.
  static final Stream<int> heartRate = _heartRate
      .receiveBroadcastStream()
      .map((event) => event is num ? event.toInt() : 0)
      .where((bpm) => bpm > 0)
      .handleError((Object e) => debugPrint('heart rate: $e'));

  /// Obnoví dlaždici „Dnes“ (TodayTileService.kt).
  static Future<void> updateTile() async {
    try {
      await _channel.invokeMethod<void>('updateTile');
    } on MissingPluginException {
      // Bez nativní části.
    } on PlatformException catch (e) {
      debugPrint('updateTile: $e');
    }
  }

  /// Otočení korunky v pixelech posunu (kladné = dolů).
  static final Stream<double> rotaryEvents = _rotary
      .receiveBroadcastStream()
      .map((event) => event is num ? event.toDouble() : 0.0)
      .handleError((Object e) => debugPrint('rotary: $e'));
}
