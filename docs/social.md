# Přátelé a výzvy (modul `social`, v3 – „Krok 2“)

Přihlášení přes Google / Apple, přátelé přes QR kód nebo odkaz, pozvánky
na společný trénink (zapíšou se oběma do kalendáře), rekordy přátel,
výzvy, žebříček mezi přáteli a společné série týdnů. Běží na Firebase
(Auth, Firestore, Cloud Messaging, volitelně Cloud Functions).

**Dokud Firebase nenastavíš, aplikace funguje normálně** – v Profilu jen
uvidíš „Funkce Přátel ještě nejsou nastavené“. Soubor
`lib/firebase_options.dart` v repu je zástupný; přepíše ho
`flutterfire configure` (krok 5).

---

## Nastavení krok za krokem (Windows, bez Macu)

Budeš potřebovat: Google účet, Node.js 22 LTS (https://nodejs.org),
Flutter, pro iOS Apple Developer účet (99 USD/rok) a Codemagic.

### 1. Projekt ve Firebase

1. Otevři https://console.firebase.google.com → **Přidat projekt**
   (např. `fitness-app`). Google Analytics nepotřebuješ.
2. Nainstaluj Firebase CLI a přihlas se (PowerShell):
   ```powershell
   npm install -g firebase-tools
   firebase login
   ```
3. Nainstaluj FlutterFire CLI:
   ```powershell
   dart pub global activate flutterfire_cli
   ```
   Když příkaz `flutterfire` nejde najít, přidej do proměnné PATH složku
   `%LOCALAPPDATA%\Pub\Cache\bin` a otevři nový terminál.

### 2. Přihlášení (Authentication)

Ve Firebase konzoli → **Build → Authentication → Začít → Sign-in method**:

- **Google** → Zapnout, vyplň e-mail podpory → Uložit.
  (Tím vznikne i „webový OAuth klient“, který Android potřebuje.)
- **Apple** (jen kvůli iPhonu – App Store ho vyžaduje, když nabízíš Google):
  1. https://developer.apple.com → Certificates, IDs & Profiles →
     **Identifiers** → App ID `cz.dedina.fitnessApp` → zaškrtni
     **Sign in with Apple** a **Push Notifications** → Save.
  2. **Identifiers → +** → *Services IDs* → např.
     `cz.dedina.fitnessApp.signin` (popis libovolný). Zapni u něj
     Sign in with Apple → Configure → Primary App ID = `cz.dedina.fitnessApp`,
     Domains = `<projekt>.firebaseapp.com`, Return URL =
     `https://<projekt>.firebaseapp.com/__/auth/handler`
     (přesnou adresu ukáže Firebase u poskytovatele Apple).
  3. **Keys → +** → zaškrtni *Sign in with Apple* (Configure → App ID
     `cz.dedina.fitnessApp`) → stáhni soubor `.p8` (jde stáhnout jen
     jednou!) a poznamenej si **Key ID** a **Team ID** (vpravo nahoře).
  4. Ve Firebase u poskytovatele **Apple** → Zapnout → vyplň Services ID,
     Team ID, Key ID a obsah `.p8` → Uložit.
     (Klíč Firebase potřebuje mimo jiné ke zrušení přihlášení při smazání
     účtu – to App Store vyžaduje.)

### 3. Otisky podpisu Androidu (SHA-1 / SHA-256) pro Google

Bez nich přihlášení přes Google na Androidu skončí chybou.

1. Debug klíč (pro `flutter run`):
   ```powershell
   cd android
   .\gradlew signingReport
   ```
   Z výpisu u `Variant: debug` zkopíruj **SHA1** a **SHA-256**.
2. Klíč pro vydání: když podepisuješ vlastním `upload-keystore.jks`,
   je ve stejném výpisu u `release` (nebo
   `keytool -list -v -keystore upload-keystore.jks`).
3. **Google Play**: Play Console → aplikace → *Testování a vydání →
   Integrita aplikace → Podepisování aplikací* → zkopíruj SHA-1 a SHA-256
   **podpisového klíče aplikace** (Play aplikaci přepodepisuje svým klíčem!).
4. Firebase → ⚙ Nastavení projektu → Vaše aplikace → Android aplikace →
   **Přidat otisk** – přidej všechny otisky z bodů 1–3.

(Android aplikaci ve Firebase vytvoří až krok 5; otisky pak doplň a
`flutterfire configure` spusť znovu.)

### 4. Databáze Firestore

1. Firebase → **Build → Firestore Database → Vytvořit databázi** →
   *Production mode* → umístění **eur3 (Europe)**.
   (Cloud Functions jsou nastavené na region `europe-west1`, který k eur3
   patří. Když zvolíš jiné umístění, změň `REGION` v
   `functions/src/index.ts`.)
2. V kořeni projektu propoj složku s projektem a nahraj pravidla:
   ```powershell
   firebase use --add          # vyber projekt, alias třeba "default"
   firebase deploy --only firestore:rules,firestore:indexes
   ```
   Pravidla jsou v `firestore.rules`, konfigurace v `firebase.json`.

### 5. Propojení aplikace (`flutterfire configure`)

Až po kroku 2 (zapnutý Google), ať konfigurace obsahuje ID klienta:

```powershell
flutterfire configure --platforms=android,ios
```

Vyber projekt. Příkaz:
- přepíše `lib/firebase_options.dart` (skutečné klíče),
- vytvoří `android/app/google-services.json` a přidá Gradle plugin,
- vytvoří `ios/Runner/GoogleService-Info.plist`.

Na Windows může FlutterFire ohlásit, že plist nepřidal do projektu Xcode
(chybí Ruby) – nevadí, aplikace bere nastavení z `firebase_options.dart`
a skript v dalším kroku si z plistu přečte, co potřebuje.

Pak upravit nativní soubory (idempotentní, klidně opakovaně):

```powershell
dart run tool/setup_platforms.dart
```

Modul `social` přidá: Android `minSdk` alespoň 23; iOS schéma
`REVERSED_CLIENT_ID` a `GIDClientID` pro Google Sign-In (z
`GoogleService-Info.plist`; do existujícího pole `CFBundleURLTypes` přidá
další položku vedle `fitnessapp`), popis fotoaparátu (skenování QR),
`UIBackgroundModes/remote-notification`, soubor
`ios/Runner/Runner.entitlements` (Sign in with Apple + push; když už
existuje např. kvůli HealthKitu, jen doplní klíče) a
`CODE_SIGN_ENTITLEMENTS` v konfiguracích cíle Runner.

> Když skript vypíše „chybí CLIENT_ID / REVERSED_CLIENT_ID“, není zapnutý
> Google (krok 2) – zapni ho, spusť znovu `flutterfire configure` a skript.

`firebase_options.dart`, `google-services.json` a `GoogleService-Info.plist`
klidně commitni (nejsou to tajné klíče – data chrání `firestore.rules`).

### 6. Push notifikace na iPhonu (APNs)

1. developer.apple.com → **Keys → +** → *Apple Push Notifications service
   (APNs)* → stáhni `.p8`, poznamenej Key ID.
2. Firebase → ⚙ Nastavení projektu → **Cloud Messaging** → Apple app
   configuration → *APNs Authentication Key* → nahraj `.p8`, Key ID a
   Team ID.
3. Codemagic: při automatickém podepisování se profil vytvoří podle
   schopností App ID (Push Notifications + Sign in with Apple z kroku 2).
   Když používáš ruční profil, vygeneruj ho znovu až po zapnutí schopností.

Android žádné další nastavení pro push nepotřebuje.

### 7. Cloud Functions (volitelné – push a úklid po smazání účtu)

Bez nich vše funguje, jen nechodí push notifikace (novinky jsou vidět
v aplikaci, včetně odznaku v Profilu). Funkce:
- `sendFeedPush` – při nové položce v novinkách pošle push příjemci,
- `cleanupDeletedUser` – po smazání účtu smaže jeho data (pojistka; aplikace
  maže data sama).

Potřebují tarif **Blaze** (platba podle použití, je nutné zadat kartu).
Při malém počtu uživatelů se platí **~0 Kč** (měsíčně zdarma 2 miliony
volání funkcí). Nastav si v Google Cloud **rozpočet s upozorněním**
(např. 25 Kč): Firebase → Využití a fakturace → Podrobnosti a nastavení →
Rozpočty a upozornění.

```powershell
firebase deploy --only functions
```

(Funkce se před nahráním samy přeloží – `npm install` ve složce
`functions` proběhne poprvé ručně: `cd functions; npm install; cd ..`.)
Funkce používají Node.js 22, `firebase-functions` 7 (API v2) a
`firebase-admin` 14.

### 8. Vyzkoušení

1. `flutter run` na dvou telefonech (nebo telefon + emulátor s Google účtem).
2. Profil → **Přátelé a výzvy** → přihlásit.
3. Na prvním: **Můj QR**, na druhém: **Skenovat QR** → Přidat.
4. Odcvič trénink s novým rekordem → druhému přijde „Petr má nový rekord…“
   s tlačítkem **Přijmout výzvu**.
5. Menu u přítele → **Pozvat na trénink** → druhý přijme → trénink je
   v kalendáři u obou.
6. Žebříček, společná série (týdny, kdy oba splnili plán).
7. ⚙ (účet) → vypni sdílení → přítel tvé statistiky neuvidí.
8. ⚙ → **Smazat účet pro přátele** → ve Firestore po tobě nic nezůstane.

---

## Soukromí

- Sdílí se jen to, co uživatel povolí (Účet a sdílení):
  - **Sdílet rekordy** (`shareRecordsWithFriends`): nové rekordy
    (odhad 1RM vestavěných cviků, zaokrouhleno na 0,5 kg) a relativní síla
    (jen poměr 1RM ÷ tělesná váha, zaokrouhlený na 0,05),
  - **Sdílet statistiky** (`shareWorkoutStatsWithFriends`): počet tréninků
    v měsíci, objem v týdnu, týdny se splněným plánem.
- **Nikdy** se nesdílí: období (nemoc, zranění, dieta…), tělesná váha,
  množství vody. U výzvy na pitný režim jde ven jen procento splnění.
- Profil vidí jen přátelé, veřejný žebříček ani vyhledávání uživatelů
  neexistuje. Přítel se přidává jen kódem (QR / odkaz) – kód funguje jako
  pozvánka.
- Smazání účtu (v aplikaci) smaže všechna data na serveru a účet ve
  Firebase Auth (u Apple i zruší přihlašovací token).

---

## Datový model (Firestore)

| Cesta | Kdo čte | Kdo zapisuje | Obsah |
|---|---|---|---|
| `users/{uid}` | vlastník, přátelé | vlastník | `displayName`, `friendCode`, `createdAt`, `updatedAt`, `lang`, `shareRecords`, `shareStats`; se sdílením statistik `workoutsThisMonth` + `statsMonth` („2026-09“), `weeklyVolume` + `statsWeek` („2026-W40“), `weeks` {„2026-W40“: true…} (12 týdnů, splněný plán); se sdílením rekordů `relStrength` {bench, squat, deadlift} |
| `users/{uid}/private/messaging` | vlastník (+ funkce) | vlastník | `fcmTokens` [], `lang` – tokeny nejsou v profilu, aby je přátelé neviděli |
| `users/{uid}/friends/{friendUid}` | vlastník | vlastník; přítel se znalostí kódu | `since`, (`code`) |
| `users/{uid}/feed/{id}` | vlastník | přátelé (fan-out z aplikace); vlastník mění jen `read`, `status`, `handled` | `type` (friend, pr, invite, inviteReply, challenge, challengeDone), `fromUid`, `fromName`, `createdAt`, `data` {…}, `read` |
| `friendCodes/{code}` | přihlášení (jen get) | vlastník kódu | `uid`, `name` |
| `invitations/{id}` | odesílatel, příjemce | odesílatel vytvoří; příjemce mění `status` | `fromUid`, `fromName`, `toUid`, `planName`, `startAt`, `durationMinutes`, `status` (pending/accepted/declined/cancelled), `createdAt` |
| `challenges/{id}` | členové | tvůrce vytvoří; každý člen mění jen svůj klíč | `creatorUid`, `creatorName`, `members` [tvůrce, přítel], `kind` (beatRecord / workoutsInMonth / weeklyWater), `target` (kg / počet / 100 %), `deadline`, `createdAt`, `exerciseSlug`, `exerciseName`, `accepted` {uid: true}, `declined` {}, `completed` {uid: čas}, `progress` {uid: počet nebo %} |

### Toky

- **Přidání přítele**: kód → `friendCodes/{code}` → potvrzení → v jedné
  dávce `users/{on}/friends/{já}` (pravidla ověří kód),
  `users/{já}/friends/{on}` a položka `friend` do jeho novinek.
- **Rekord**: po tréninku (háček `social:finished`) zapíše aplikace položku
  `pr` do novinek všech přátel. „Přijmout výzvu“ vytvoří `challenges/{id}`
  (beatRecord, cíl = rekord přítele, termín 30 dní) a lokální řádek
  v tabulce `Challenges` s `remoteId`; příteli přijde `challenge`/`tookOn`.
- **Výzvy z menu přítele**: překonej můj rekord / tréninky tento měsíc /
  týdenní pitný režim. Přítel přijme v Novinkách → lokální řádek
  s `remoteId` (u vody s vlastním týdenním cílem v ml).
  Výzvy na obrazovce Dnes ukazuje a `completedAt` zapisuje modul `sharing`;
  háček `social:sync` pak pošle na server `completed.{uid}` (+ položku
  `challengeDone` druhému) a průběžně `progress.{uid}`.
- **Pozvánka**: `invitations/{id}` + položka `invite`. Příjemce přijme →
  `status`, zápis do jeho kalendáře, položka `inviteReply` odesílateli →
  aplikace odesílatele trénink zapíše i do jeho kalendáře.
- **Statistiky**: háček po tréninku a `social:sync` (nejvýš jednou za
  15 min) přepíše veřejná pole profilu. Žebříček a společné série se počítají
  v aplikaci z profilů přátel.
- **Push**: Cloud Function `sendFeedPush` reaguje na novou položku
  v novinkách. V popředí aplikace ukáže lokální notifikaci, na pozadí ji
  zobrazí systém.
