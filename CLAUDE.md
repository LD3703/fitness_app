# GymBar – pokyny pro Claude

Flutter aplikace GymBar (Android, iOS, Wear OS) + Firebase backend + web pro
trenéry. Vývojář: Lukas (Windows, `C:\dev\fitness_app`). Komunikace, komentáře
v kódu i dokumentace jsou **česky**.

## Struktura

- `lib/` – aplikace (Riverpod, go_router, drift). Volitelné moduly jsou
  v `lib/modules/` a napojují se přes `lib/modules/module_hub.dart` (značky
  `// [modul:místo]`).
- `lib/data/` – drift databáze. Změna tabulek = zvýšit `schemaVersion`
  v `database.dart` a přidat migraci `if (from < N)`.
- `lib/l10n/app_*.arb` – texty v 10 jazycích (cs, en, de, es, fr, it, nl,
  pl, pt, sk); šablona je `app_en.arb` (metadata placeholderů jen tam).
  Nový text vždy do všech 10 souborů, ICU syntaxe.
- `packages/gymbar_coach/` – čistý Dart sdílený aplikací a webem (plány,
  tréninky pro trenéra, statistiky, filtr hrubých slov). Musí fungovat i na
  webu: žádné `1 << 31` a větší posuny, data přes kalendářní den, ne Duration.
- `trainer_web/` – web pro trenéry (Flutter web, gymbar.app/trener).
- `functions/` – Cloud Functions (TypeScript, Node 22, europe-west1).
- `firestore.rules`, `storage.rules`, `firebase.json`, `docs/web/` (Hosting).
- `wear/` – samostatný projekt hodinek.
- Dokumentace: `README.md`, `docs/coach.md`, `docs/social.md`,
  `docs/app_store.md`, `docs/wear_os.md`.

## Ověření před commitem

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze --no-fatal-infos
flutter test
(cd trainer_web && flutter pub get && flutter analyze --no-fatal-infos && flutter test)
(cd wear && flutter pub get && flutter analyze --no-fatal-infos)
(cd functions && npm ci && npm test)
(cd tool/rules_test && npm ci && npm test)   # pravidla Firestore a Storage, potřebuje Javu
```

Totéž běží v GitHub Actions (`.github/workflows/ci.yml`), navíc sestavení
Android APK telefonu i hodinek – po pushi zkontroluj
výsledek a chyby oprav.

## Zásady

- Verze je na třech místech: `pubspec.yaml`, `wear/pubspec.yaml`
  (build number + 1000000) a `lib/app_version.dart`; web v
  `trainer_web/pubspec.yaml`.
- Nové sdílení dat na server = upravit `docs/web/privacy.html` (cs i en)
  a případně `terms.html` a `delete-account.html`.
- Žádné klíče ani tajné soubory do gitu (servisní účet Firebase, upload klíč
  Androidu, `.p8`). Na veřejných stránkách zůstávají zástupné údaje v `[ ]`,
  dokud je Lukas nedodá.
- Filtr slov blokuje jen vyloženě hrubá slova (hovorové nadávky projdou).
- Firebase projekt `fitness-app-dc5e4`, doména gymbar.app, e-mail
  info@gymbar.app. Nasazení (`firebase deploy`) dělá Lukas, pokud neřekne
  jinak.
