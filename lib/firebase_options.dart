// ZÁSTUPNÝ SOUBOR – přepíše ho příkaz `flutterfire configure`
// (návod: docs/social.md). Dokud ho nepřepíšeš, aplikace běží normálně,
// jen funkce Přátel ukážou „ještě nejsou nastavené“.
//
// Tvar odpovídá souboru, který generuje FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Run flutterfire configure');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      default:
        throw UnsupportedError('Run flutterfire configure');
    }
  }
}
