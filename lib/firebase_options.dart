// Konfigurace Firebase (projekt fitness-app-dc5e4). Stejný tvar jako
// z `flutterfire configure`; hodnoty vypsal workflow „Konfigurace Firebase
// aplikací“ (docs/deploy.md) – nejsou tajné, jsou v každé vydané aplikaci.
// Android odpovídá android/app/google-services.json.
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
      throw UnsupportedError('Aplikace pro web není nastavená.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
            'Firebase není nastavený pro $defaultTargetPlatform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBAxbOjpnRCVaqhhtVKO4KLbmvwqEAnn0c',
    appId: '1:887495940482:android:157cbe6837a1c2ea03979b',
    messagingSenderId: '887495940482',
    projectId: 'fitness-app-dc5e4',
    storageBucket: 'fitness-app-dc5e4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDNSsUGnT7N7PC1ItCiCDsSPx-R4Sse-wM',
    appId: '1:887495940482:ios:9c10572e26928d4503979b',
    messagingSenderId: '887495940482',
    projectId: 'fitness-app-dc5e4',
    storageBucket: 'fitness-app-dc5e4.firebasestorage.app',
    androidClientId:
        '887495940482-9mhb4i76iiav4463jiv1875rhuaafs9n.apps.googleusercontent.com',
    iosClientId:
        '887495940482-m3cu4q6l15dl62dq9ldrqeo9k4eleh1d.apps.googleusercontent.com',
    iosBundleId: 'cz.dedina.fitnessApp',
  );
}
