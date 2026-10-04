// Nahrazuje výchozí test z `flutter create` (ten hledal neexistující MyApp).

import 'package:fitness_app/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aplikace podporuje všech 10 jazyků', () {
    final codes = AppLocalizations.supportedLocales
        .map((l) => l.languageCode)
        .toSet();
    expect(
      codes,
      containsAll(['en', 'cs', 'de', 'es', 'fr', 'pl', 'pt', 'it', 'sk', 'nl']),
    );
  });
}
