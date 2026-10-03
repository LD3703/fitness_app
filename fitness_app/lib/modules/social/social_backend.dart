import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';

/// Spuštění Firebase. Když projekt ještě není nastavený
/// (lib/firebase_options.dart je zástupný), aplikace běží dál bez
/// sociálních funkcí.
abstract final class SocialBackend {
  static bool _available = false;

  /// Firebase je nastavené a úspěšně spuštěné.
  static bool get available => _available;

  static bool get supportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> init() async {
    if (!supportedPlatform) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 10));
      }
      _available = true;
    } on UnsupportedError catch (e) {
      debugPrint('Social: Firebase not configured (${e.message}).');
    } catch (e) {
      debugPrint('Social: Firebase init failed: $e');
    }
  }
}

/// Jsou funkce Přátel k dispozici (Firebase nastavené)?
final socialAvailableProvider = Provider<bool>((ref) => SocialBackend.available);

/// Zápisy do Firestore bez připojení nikdy neskončí (čekají ve frontě,
/// než se telefon připojí). Po [timeout] proto přestaneme čekat –
/// zápis se odešle později sám.
Future<void> quietWrite(
  Future<void> write, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  try {
    await write.timeout(timeout);
  } on TimeoutException {
    debugPrint('Social: write queued (offline).');
  }
}
