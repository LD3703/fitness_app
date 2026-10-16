// Konfigurace Firebase pro web pro trenéry (projekt fitness-app-dc5e4,
// webová aplikace „GymBar web“). Stejný tvar jako z `flutterfire configure`;
// hodnoty vypsal workflow „Konfigurace Firebase aplikací“ – nejsou tajné.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDxf4ZQY3ohqQ8eTOGYoY3kZ-yF51YpadQ',
    appId: '1:887495940482:web:9b6776f5e98925f803979b',
    messagingSenderId: '887495940482',
    projectId: 'fitness-app-dc5e4',
    authDomain: 'fitness-app-dc5e4.firebaseapp.com',
    storageBucket: 'fitness-app-dc5e4.firebasestorage.app',
  );
}
