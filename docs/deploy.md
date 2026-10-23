# Nasazení Firebase přes GitHub Actions

Workflow `.github/workflows/deploy.yml` („Nasazení Firebase“) nasadí na
projekt `fitness-app-dc5e4` pravidla, Cloud Functions nebo web. Spouští se
**jen ručně** – po pushi nikdy. Nasazení z PC (`firebase deploy`) funguje
dál stejně, workflow je jen pohodlnější a před nasazením spustí testy.

| Volba | Co nasadí | Předtím otestuje |
| --- | --- | --- |
| `rules` | `firestore:rules`, `firestore:indexes`, `storage` | pravidla v emulátoru (`tool/rules_test`) |
| `functions` | `functions` | `functions`: `npm test` |
| `hosting` | `docs/web` + web pro trenéry (`trainer_web` → `docs/web/trener`) | – |
| `all` | všechno výše | obojí |

Workflow nic nemaže: když by nasazení mělo odstranit Cloud Function nebo
index, který v projektu už není, skončí chybou – smaž je ručně z PC.

## Jednorázové nastavení

### 1. Servisní účet a jeho klíč

1. [Google Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts?project=fitness-app-dc5e4)
   → **IAM & Admin → Service Accounts → Create service account**, název
   např. `github-deploy`.
2. Role: **Firebase Admin**, **Service Account User**, **Cloud Functions
   Admin** a **Cloud Scheduler Admin** (plánované funkce `expireTrainers`
   a `purgeOldContentReports`). Import posiloven (workflow „Import
   posiloven (OSM)“) potřebuje i **Cloud Datastore User**. Veřejná funkce
   `gymDirectory` (hledání na gymbar.app/fitka, docs/fitka.md) může chtít
   **Cloud Run Admin** (chyba `run.services.setIamPolicy`). Když nasazení
   později ohlásí chybějící oprávnění, přidej roli, kterou chyba jmenuje.
3. U účtu **Keys → Add key → Create new key → JSON** – stáhne se soubor.
   Klíč nikam neposílej a nedávej do projektu (`.gitignore` hlídá
   `*service-account*.json`).

### 2. Secret v GitHubu

Repozitář → **Settings → Secrets and variables → Actions → Secrets → New
repository secret**:

- název `FIREBASE_SERVICE_ACCOUNT`, hodnota = celý obsah staženého JSON
  souboru.

Pak soubor z počítače smaž (v GitHubu je zašifrovaný a nejde zpětně
přečíst).

### 3. App Links pro nasazení webu

`docs/web/.well-known/assetlinks.json` vzniká na tvém PC
(`dart run tool/assetlinks.dart`) a v gitu není. Nasazení webu bez něj by
App Links na gymbar.app smazalo, proto ho workflow bere z proměnné:

- **Settings → Secrets and variables → Actions → Variables → New
  repository variable**: název `ASSETLINKS_JSON`, hodnota = obsah souboru
  `docs/web/.well-known/assetlinks.json` (otisky klíčů nejsou tajné).
- Až bude iPhone: `APPLE_APP_SITE_ASSOCIATION` = obsah
  `docs/web/.well-known/apple-app-site-association`.

Bez `ASSETLINKS_JSON` workflow s volbou `hosting` / `all` skončí chybou.
Po každém `dart run tool/assetlinks.dart` (nový klíč) proměnnou aktualizuj.

### 4. Volitelně: schválení před nasazením

Workflow běží v prostředí `production`. V **Settings → Environments →
production → Required reviewers** můžeš zapnout, že každé nasazení musíš
ještě potvrdit.

## Spuštění

GitHub → **Actions → Nasazení Firebase → Run workflow** → větev `main`,
v poli „Co nasadit“ vyber volbu → **Run workflow**.

Volba **force** (výchozí vypnutá) přidá `firebase deploy --force`. Zapni ji
jen jednorázově, když nasazení skončí hláškou „Pass the --force option…“
(např. funkce nově s opakováním při chybě). Pozor: s ní se bez ptaní smažou
i funkce, které už v kódu nejsou.
