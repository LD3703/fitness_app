// ZÁSTUPNÝ SOUBOR – přepíše ho (ve složce trainer_web):
//   flutterfire configure --project=fitness-app-dc5e4 --platforms=web
// Dokud ho nepřepíšeš, web ukáže „Web ještě není nastavený“.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform =>
      throw UnsupportedError('Run flutterfire configure --platforms=web');
}
