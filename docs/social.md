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
další položku vedle `gymbar`), popis fotoaparátu (skenování QR),
`UIBackgroundModes/remote-notification`, soubor
`ios/Runner/Runner.entitlements` (Sign in with Apple + push; když už
existuje např. kvůli HealthKitu, jen doplní klíče) a
`CODE_SIGN_ENTITLEMENTS` v konfiguracích cíle Runner.

> Když skript vypíše „chybí CLIENT_ID / REVERSED_CLIENT_ID“, není zapnutý
> Google (krok 2) – zapni ho, spusť znovu `flutterfire configure` a skript.

`firebase_options.dart`, `google-services.json` a `GoogleService-Info.plist`
klidně commitni (nejsou to tajné klíče – data chrání `firestore.rules`).

### 5a. Hlášení o pádech (Crashlytics)

Modul `crash` (`lib/modules/crash/`) posílá pády aplikace do Firebase
Crashlytics – jen v release buildu, jen s nastaveným Firebase a jen když
to uživatel nevypnul (Profil → Soukromí → *Odesílat hlášení o pádech*,
výchozí zapnuto; volba je v `crash_reporting_settings.json` ve složce
dokumentů aplikace). Neposílá se žádný identifikátor uživatele ani data
z tréninků.

1. Firebase konzole → **Crashlytics** → *Enable Crashlytics*.
2. `flutterfire configure` (krok 5) a potom
   `dart run tool/setup_platforms.dart` – na Androidu doplní Gradle
   plugin `com.google.firebase.crashlytics`, pokud ho FlutterFire nepřidal.
3. Vyzkoušení: release build na telefonu, v aplikaci vyvolat pád
   (dočasně např. `throw Exception('test')` v tlačítku), aplikaci znovu
   spustit – hlášení se odešle při dalším startu a v konzoli se objeví do
   pár minut.

Na iOS běží bez úprav. Nahrávání symbolů (dSYM) pro čitelné *nativní*
pády přidá `flutterfire configure` jen na Macu; pády v Dartu jsou čitelné
i bez nich.

Google Play → Bezpečnost dat: „Diagnostika – protokoly pádů“, sbíraná,
nesdílená, nepovinná (lze vypnout), účel „Analýza / funkčnost aplikace“.

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
  maže data sama) a navíc to, co aplikace smazat nesmí nebo nenajde:
  jeho položky v novinkách přátel, stav moderace jeho záznamů v žebříčku,
  členství a záznamy podle `uid` (i když `private/gym` chybí),
- `onGymEntryWritten`, `onGymReportCreated`, `onGymMemberCreated`,
  `onGymMemberDeleted` – žebříček posilovny (viz „Žebříček posilovny“
  níže; `onGymMemberCreated` vrací do adresáře posilovnu skrytou jako
  neexistující, viz `docs/gyms_import.md`),
- `onContentReportCreated`, `purgeOldContentReports` – nahlášení obsahu
  (viz „Nahlášení a blokování“).

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
8. Menu u přítele → **Odebrat** → tvůj kód v **Můj QR** je nový; přítel se
   starým QR / odkazem přidat nejde.
9. ⚙ → **Smazat účet pro přátele** → ve Firestore po tobě nic nezůstane
   (s nasazenými funkcemi ani tvoje položky v novinkách přátel).

---

## Soukromí

- Sdílí se jen to, co uživatel povolí (Účet a sdílení):
  - **Sdílet rekordy** (`shareRecordsWithFriends`): nové rekordy
    (nejtěžší série vestavěných cviků: váha a opakování) do novinek přátel,
  - **Sdílet statistiky** (`shareWorkoutStatsWithFriends`): počet tréninků
    v měsíci, objem v týdnu, týdny se splněným plánem.
- **Nikdy** se nesdílí: období (nemoc, zranění, dieta…), tělesná váha,
  množství vody. U výzvy na pitný režim jde ven jen procento splnění.
  (Jediná výjimka je **automatická záloha** – celá databáze, jen se
  souhlasem, do soukromého prostoru uživatele, který nikdo jiný nevidí;
  viz „Automatická záloha“ níže.)
- Tělesnou váhu žádná sociální ani serverová funkce nečte ani z ní nic
  nepočítá. Relativní síla (síla ÷ tělesná váha) v žebříčku přátel byla
  zrušena; staré pole `relStrength` v `users/{uid}` aplikace při dalším
  zveřejnění statistik smaže (`FieldValue.delete()`) a `firestore.rules`
  ho už nepovolí.
- Profil vidí jen přátelé, vyhledávání uživatelů neexistuje. Jediný
  „veřejný“ žebříček je žebříček posilovny – vidí ho jen její členové
  a je v něm jen přezdívka (viz níže). Členem se ale může stát kdokoli, kdo
  si posilovnu v aplikaci vybere (kód není podmínkou, jen zkratkou), takže
  žebříček je fakticky veřejný pro lidi z aplikace – zásady to uvádějí. Přítel se přidává jen kódem (QR / odkaz) – kód funguje jako
  pozvánka. Po odebrání nebo zablokování přítele se můj kód vymění
  (starý QR i odkazy přestanou platit), takže se odebraný přítel se
  starým kódem znovu nepřidá.
- Smazání účtu (v aplikaci) smaže všechna data na serveru a účet ve
  Firebase Auth (u Apple i zruší přihlašovací token – aplikace se před
  smazáním vždy znovu přihlásí přes Apple, protože ke zrušení je potřeba
  čerstvý autorizační kód). Když se nepovede odejít z posilovny, smazání
  se přeruší a aplikace ukáže chybu (jde zopakovat).

---

## Datový model (Firestore)

Trenéři a klienti (`trainers`, `trainerCodes`, `coachLinks`,
`sharedPlans`) mají vlastní popis v `docs/coach.md`.

| Cesta | Kdo čte | Kdo zapisuje | Obsah |
|---|---|---|---|
| `users/{uid}` | vlastník, přátelé | vlastník; `friendCode` smí změnit jen na kód, který po zápisu patří jemu (`getAfter` na `friendCodes`) | `displayName`, `friendCode`, `createdAt`, `updatedAt`, `lang`, `shareRecords`, `shareStats`; se sdílením statistik `workoutsThisMonth` + `statsMonth` („2026-09“), `weeklyVolume` + `statsWeek` („2026-W40“), `weeks` {„2026-W40“: true…} (12 týdnů, splněný plán) |
| `users/{uid}/private/messaging` | vlastník (+ funkce) | vlastník | `fcmTokens` [], `lang` – tokeny nejsou v profilu, aby je přátelé neviděli |
| `users/{uid}/friends/{friendUid}` | vlastník | vlastník; přítel se znalostí aktuálního kódu | `since`, (`code`) |
| `users/{uid}/feed/{id}` | vlastník | přátelé (fan-out z aplikace); vlastník mění jen `read`, `status`, `handled` | `type` (friend, pr, invite, inviteReply, challenge, challengeDone; `gymOvertaken` zapisuje jen Cloud Function), `fromUid`, `fromName`, `createdAt`, `data` {…}, `read` |
| `friendCodes/{code}` | přihlášení (jen get) | vlastník kódu; starý kód po výměně smaže | `uid`, `name` |
| `invitations/{id}` | odesílatel, příjemce | odesílatel vytvoří; příjemce mění `status` | `fromUid`, `fromName`, `toUid`, `planName`, `startAt`, `durationMinutes`, `status` (pending/accepted/declined/cancelled), `createdAt` |
| `challenges/{id}` | členové | tvůrce vytvoří; každý člen mění jen svůj klíč | `creatorUid`, `creatorName`, `members` [tvůrce, přítel], `kind` (beatRecord / workoutsInMonth / weeklyWater), `target` (kg / počet / 100 %), `deadline`, `createdAt`, `exerciseSlug`, `exerciseName`, `accepted` {uid: true}, `declined` {}, `completed` {uid: čas}, `progress` {uid: počet nebo %} |

### Toky

- **Přidání přítele**: kód → `friendCodes/{code}` → potvrzení → v jedné
  dávce `users/{on}/friends/{já}` (pravidla ověří kód),
  `users/{já}/friends/{on}` a položka `friend` do jeho novinek.
- **Odebrání / zablokování přítele**: smaže vazbu v obou směrech a pak
  `SocialService.rotateFriendCode()` v jedné dávce vytvoří nový
  `friendCodes/{nový}`, přepíše `friendCode` v profilu a smaže starý
  `friendCodes/{starý}`. Odebraný přítel můj kód znal (je v profilu, který
  přátelé čtou) – nový už nevidí. QR a odkaz v záložce Přátelé se obnoví
  samy (sledují můj profil). Když výměna selže, přítel zůstane odebraný.
- **Rekord**: po tréninku (háček `social:finished`) zapíše aplikace položku
  `pr` do novinek všech přátel – každému zvlášť, takže jednostranná vazba
  (přítel mě mezitím odebral, pravidla zápis odmítnou) nezastaví zápis
  ostatním. „Přijmout výzvu“ vytvoří `challenges/{id}`
  (beatRecord, cíl = rekord přítele, termín 30 dní) a lokální řádek
  v tabulce `Challenges` s `remoteId`; příteli přijde `challenge`/`tookOn`.
- **Výzvy z menu přítele**: překonej můj rekord / tréninky tento měsíc /
  týdenní pitný režim. Přítel přijme v Novinkách → lokální řádek
  s `remoteId` (u vody s vlastním týdenním cílem v ml).
  Výzvy na obrazovce Dnes ukazuje a `completedAt` zapisuje modul `sharing`;
  háček `social:sync` pak pošle na server `completed.{uid}` (+ položku
  `challengeDone` druhému) a průběžně `progress.{uid}`. Každá výzva se
  synchronizuje zvlášť – chyba jedné nezastaví ostatní. Když výzva na
  serveru už není (smazal ji přítel, zrušené přátelství: `not-found` /
  `permission-denied`), lokální výzva zůstane, jen zapomene `remoteId`
  (`socialForgetRemoteId`) a přestane se hlásit.
- **Pozvánka**: `invitations/{id}` + položka `invite`. Příjemce přijme →
  `status`, zápis do jeho kalendáře, položka `inviteReply` odesílateli →
  aplikace odesílatele trénink zapíše i do jeho kalendáře. Položku
  `inviteReply` píše přítel, proto se jí nevěří: aplikace načte
  `invitations/{invitationId}` a zapíše jen pozvánku, kterou poslala ona
  (`fromUid` = já) tomu, kdo odpověděl (`toUid` = `fromUid` položky),
  se stavem `accepted`; název, čas a délku bere z pozvánky
  (`isAcceptedReplyTo` v `social_logic.dart`).
- **Statistiky**: háček po tréninku a `social:sync` (nejvýš jednou za
  15 min) přepíše veřejná pole profilu. Žebříček a společné série se počítají
  v aplikaci z profilů přátel.
- **Push**: Cloud Function `sendFeedPush` reaguje na novou položku
  v novinkách. V popředí aplikace ukáže lokální notifikaci, na pozadí ji
  zobrazí systém. Texty od uživatelů (jméno, cvik, plán, posilovna) se
  zkracují na 60 znaků, titulek na 80 a text na 200. Token se z
  `private/messaging` odebere jen u chyb, po kterých už nikdy fungovat
  nebude (`messaging/registration-token-not-registered`,
  `messaging/invalid-registration-token`), ne např. u
  `messaging/invalid-argument`.

---

## Žebříček posilovny

Posilovna = skupina. Adresář je předplněný posilovnami z OpenStreetMap
pro Evropu a Ameriku (import, okolí podle polohy, kontrola duplicit:
[gyms_import.md](gyms_import.md)). Chybějící posilovnu může kdokoli
přihlášený založit (název, město, volitelně adresa a poloha) a dostane
**QR kód** pro recepci (Posilovna → ikona QR →
*Sdílet QR*: plakát jako PNG + text s odkazem přes systémové sdílení).
Ostatní se připojí:

- naskenováním QR v aplikaci (**Přátelé → ikona činky → Naskenovat QR
  posilovny**) nebo odkazem `gymbar://gym?code=XXXXXX` /
  `<web>/gym?code=XXXXXX` (QR obsahuje webový odkaz, skener v aplikaci
  přijme oba; dokud web na `kWebBaseUrl` neběží, fotoaparát telefonu
  odkaz neotevře – skenuj v aplikaci),
- výběrem ze seznamu (**Najít posilovnu** – nahoře posilovny v okolí,
  hledá podle začátku názvu nebo města i „název město“, bez diakritiky;
  ukazuje vzdálenost a počet členů).

Člověk je vždy jen v **jedné** posilovně a může kdykoli odejít (jeho
záznamy v žebříčku se smažou). Vstup je na obrazovce Přátelé (ikona
činky v liště), přes kartu na obrazovce **Pokrok** a z odkazu.

### Vytištěný žebříček

Menu žebříčku → *Vytisknout žebříček* složí stránku A4 (balíčky `pdf`
a `printing`, `lib/modules/social/ui/gym_print.dart`) a otevře systémový
tisk – tiskárna, nebo *Uložit jako PDF*. Na papíře: posilovna, datum,
bench, dřep, mrtvý tah a legpress, muži a ženy zvlášť, vždy prvních 5 míst
za tento měsíc a celkově, dole QR kód do žebříčku posilovny. Výběr řádků
(`gym/gym_printout.dart`, testy `test/social_gym_printout_test.dart`):
bez skrytých záznamů, bez lidí s `noPrint` a bez neuvedeného pohlaví.
`noPrint` zapisuje do záznamů GymPublisher podle `printable` v
`private/gym`; přepínač je ve formuláři profilu v žebříčku a jde zapnout
jen spolu s *Ukázat mě v žebříčku posilovny*.

### Co se zveřejní

Při vstupu (a později v menu *Přezdívka, věk a viditelnost*) uživatel zadá
**přezdívku** (výchozí = jméno pro přátele, max. 24 znaků), volitelně
**pohlaví** (muž / žena / neuvádět – jen pro filtr), volitelně **rok
narození** a přepínač **Ukázat mě v žebříčku posilovny** (vypnuto = jen se
dívá, nic se nezveřejní a jeho záznamy se smažou). Přezdívka, pohlaví
a viditelnost (i `printable` – „Ukázat mě na vytištěném žebříčku“, bez
pole = ano) jsou ve Firestore v `users/{uid}/private/gym`; rok narození
se ukládá jen do lokálního profilu (`UserProfiles.birthYear`, jde zadat
i v Profilu → *Rok narození (nepovinné)*, rozsah 1920 … letošní rok − 10;
formulář žebříčku bere jen 1920 … letošní rok − 13 a mladším věkovou
skupinu nezveřejní – funkce s účtem jsou od 16, mladší se souhlasem rodiče,
děti pod 13 ne).

**Věková skupina:** ven jde jen skupina `ageGroup` – `u40` (do 39),
`40` (40–49), `50` (50–59), `60` (60+) – nikdy věk ani rok narození.
Počítá se v telefonu z roku narození a aktuálního roku (věk = rozdíl
let; `gymAgeGroupFor` v `gym_logic.dart`), takže se mění s novým rokem.
Bez roku narození se pole nezapíše (smaže) a člověk je vidět jen ve
filtru „Všichni“. `GymPublisher` skupinu při každém zveřejnění přepočítá
a zapíše na záznamy i na člena (`gyms/{gymId}/members/{uid}`), pokud se
změnila.

Kategorie:

| Kategorie | Hodnota | Za měsíc / celkově |
|---|---|---|
| cviky (klíč = slug vestavěného cviku, viz tabulka níže) | nejtěžší váha z dokončených tréninků, bez rozcvičky a drop sérií; na 0,5 kg | tréninky v aktuálním měsíci / všechny |
| `workouts` | počet dokončených tréninků | tento měsíc / nejvíc za jeden měsíc |

Cviky a absolutní hranice váhy (`GymCategory` v `gym_logic.dart`):

| Slug | Hranice | Poznámka |
|---|---|---|
| `bench_press` | 350 kg | |
| `back_squat` | 500 kg | |
| `deadlift` | 500 kg | |
| `overhead_press` | 250 kg | |
| `incline_bench_press` | 300 kg | |
| `dumbbell_bench_press` | 120 kg | na jednu jednoručku (jak se zapisuje) |
| `dumbbell_shoulder_press` | 100 kg | na jednu jednoručku |
| `barbell_curl` | 150 kg | |
| `dumbbell_curl` | 80 kg | na jednu jednoručku |
| `weighted_pull_up` | 150 kg | jen přidaná zátěž |
| `weighted_dips` | 200 kg | jen přidaná zátěž |
| `barbell_row` | 300 kg | |
| `leg_press` | 1000 kg | |
| `hip_thrust` | 500 kg | |
| `front_squat` | 400 kg | |
| `romanian_deadlift` | 400 kg | |
| `workouts` | 62 tréninků za měsíc | |

Zveřejní se jen cviky, které uživatel opravdu dělal (bez sérií se záznam
nevytvoří). Názvy kategorií v aplikaci = přeložené názvy vestavěných cviků
(`gymCategoryLabel`); u jednoruček se ukáže poznámka „na jednu
jednoručku“, u shybů a dipů „jen přidaná zátěž“. Nová kategorie = přidat
konstantu do `GymCategory` (+ do `GymCategory.lifts`), hranici do
`functions/src/plausibility.ts` a do `categoryLimits()` ve
`firestore.rules`, a případně vestavěný cvik. Vestavěné cviky
`weighted_pull_up` (Shyby se zátěží) a `weighted_dips` (Dipy se zátěží)
přibyly kvůli žebříčku ve verzi schématu 7 – stávajícím uživatelům je
doplní migrace (`_syncSeedExercises`); zapisuje se u nich jen přidaná
zátěž.

**Nikdy** se nezveřejní přesný věk, rok narození, tělesná váha, období ani
pitný režim. Tělesná váha se v žebříčku posilovny nepoužívá vůbec (ani pro
kontrolu reálnosti). Kategorie relativní síly (síla ÷ tělesná váha) byla
zrušena.

**Přechod na slugy cviků:** dřívější klíče `bench` a `squat` se nahradily
slugy `bench_press` a `back_squat` (`deadlift` a `workouts` zůstaly).
Aliasy se nedrží: staré záznamy `<uid>_bench`, `<uid>_squat` (i
`<uid>_relStrength`) smaže aplikace při prvním zveřejnění v daném běhu
(`GymService.deleteRetiredEntries` – maže moje záznamy s kategorií, kterou
aplikace nezná) a hned zapíše nové pod novým klíčem. Ověřená hodnota
serveru (`verified`) se u nich začne sbírat znovu (první zápis se tedy
kontroluje jen absolutní hranicí). Staré novinky `gymOvertaken` s klíčem
`bench` / `squat` aplikace i Cloud Function ještě přečtou
(`gymCategoryFromAnyKey`, `LEGACY_CATEGORY_KEYS`). Při odchodu a smazání
účtu se mažou všechny záznamy s mým `uid`.

Filtry (kombinují se): pohlaví všichni / muži / ženy, věk **Všichni / 40+ /
50+ / 60+** (40+ = skupiny 40, 50, 60; 50+ = 50, 60; 60+ = 60; bez
skupiny jen ve „Všichni“), tento měsíc / celkově. První tři (po
filtrování) mají medaili.

Zveřejňuje háček `social:finished` (hned po tréninku), `social:sync`
(nejvýš jednou za 15 min) a otevření žebříčku (`GymPublisher`).

### Výzvy a upozornění

- U lídra kategorie je tlačítko **Překonej mě**: vytvoří lokální výzvu
  (tabulka `Challenges`, stejně jako výzvy od přátel): u cviků
  `beatRecord` s cílem = lídrova nejtěžší váha, překonat = zvednout víc (termín 30 dní), u tréninků
  `workoutsInMonth` s cílem o 1 vyšším (do konce měsíce). `fromName` =
  přezdívka, výzva odkazuje na cvik přes `exerciseSlug` (funguje pro
  všechny cviky žebříčku), `remoteId` = `gym:<gymId>:<uid>:<kategorie>:<hodnota>` (podle
  něj se výzva neduplikuje; na server se tyto výzvy nehlásí).
- Kdo byl v kategorii **první** (celkový žebříček, i dělené místo) a někdo
  ho předběhne, dostane novinku `gymOvertaken` (zapíše ji Cloud Function
  `onGymEntryWritten` do `users/{uid}/feed`, push pošle `sendFeedPush`).
  Nejvýš **jednou za 24 h** pro stejnou posilovnu, kategorii a lídra
  (čas `overtakenNotifiedAt` v dokumentu moderace lídrova záznamu, zápis
  v transakci) – střídání dvou lidí na prvním místě nespamuje. Znovu
  vytvořený záznam (vypnutí a zapnutí „Ukázat mě“, návrat do posilovny)
  se se stejnou hodnotou jako předběhnutí nepočítá (porovnává se
  s dřívější ověřenou hodnotou).
- Kdo je první, může sdílet kartu **„Nejsilnější v <posilovna>“**
  (ikona sdílení u svého řádku).

### Kontrola nereálných výkonů a nahlášení

Pravidla (`lib/modules/social/gym/plausibility.dart`, testy
`test/social_gym_plausibility_test.dart`, zrcadlo
`functions/src/plausibility.ts`):

- absolutní hranice podle tabulky výše (hlídají i `firestore.rules`,
  funkce `categoryLimits()`),
- skok o víc než 15 % proti předchozímu zveřejněnému maximu, pokud bylo
  zveřejněné před méně než 14 dny (u cviků).

Hranice vůči tělesné váze se nepoužívají (tělesná váha do žebříčku
posilovny nevstupuje).

Aplikace nereálnou hodnotu vůbec nezveřejní a ukáže „Výkon vypadá
nereálně, do žebříčku se nezapočítal“. Server (Cloud Function) hlídá
absolutní hranice a skok proti své uložené ověřené hodnotě (`verified`)
a nereálný záznam skryje (`hidden: true`, `hiddenReason: "implausible:…"`).

Každý člen může cizí záznam **nahlásit** jednou (dlouhé podržení nebo
menu u řádku). Cloud Function `onGymReportCreated` nahlášení spočítá
(`reportCount`) a od 5 záznam skryje (`hiddenReason: "reports"`).
Aplikace skrývá záznamy s `reportCount ≥ 5` i sama.

**Stav moderace přežije smazání záznamu.** Vlastník svůj záznam smí
kdykoli smazat (vypnutí „Ukázat mě“, odchod z posilovny) a pak vytvořit
znovu – klient přitom pole `hidden`, `hiddenReason`, `reportCount`
a `verified` zapsat nesmí. Proto je skutečný stav jen na serveru
v `gyms/{gymId}/moderation/{entryId}` (klienti ho nečtou ani nezapisují):
`uid`, `category`, `reportCount`, `hiddenReason` (trvalé skrytí:
`"reports"`, nebo ruční skrytí vývojářem, např. `"manual"`), `verified`
{value, at}, `overtakenNotifiedAt`, `updatedAt`. Po smazání záznamu
zůstává dokument moderace i nahlášení (`entries/{id}/reports`);
`onGymEntryWritten` při vzniku i změně záznamu stav z dokumentu moderace
znovu použije (trvalé skrytí, skok proti dřívější `verified`) a zkopíruje
ho na záznam (aplikace ho čte odtud). Záznam z doby před dokumenty
moderace, který nese stav jen na sobě, při smazání stav do dokumentu
moderace přenese. Skrytí za nereálnou hodnotu se při každé změně hodnoty
počítá znovu. Ruční skrytí: na záznamu `hidden: true` (bez důvodu), nebo
v dokumentu moderace `hiddenReason: "manual"` – obojí je trvalé. Zápisy
serveru nemění `best`, `bestMonth` ani `monthKey`, takže se funkce
nezacyklí. Dokument moderace a nahlášení u mých záznamů maže až smazání
účtu (`cleanupDeletedUser`).

### Datový model

| Cesta | Kdo čte | Kdo zapisuje | Obsah |
|---|---|---|---|
| `gyms/{gymId}` | přihlášení (veřejný adresář posiloven) | zakladatel vytvoří; `memberCount` ±1 jen spolu se vznikem / zánikem vlastního členství | `name`, `nameLower`, `city`, `cityLower` (malá písmena bez diakritiky – hledání podle prefixu), `address?`, `code`, `createdBy`, `createdAt`, `memberCount` |
| `liftStats/{země\|world}_{cvik}` | kdokoli | jen Cloud Function `updateLiftStats` (denně) | `scope`, `category`, `updatedAt`, `groups` – anonymní rozložení vah pro „Jak si vedu“ (viz níže) |
| `gymReferrals/{gymId}_{uid}` | jen vlastník | člen posilovny, jen svůj záznam; `count` jen +1 | `gymId`, `uid`, `count`, `createdAt`, `updatedAt` – „Doporuč GymBar svému fitku“ ([fitka.md](fitka.md)) |
| `gymCodes/{code}` | přihlášení (jen get) | zakladatel, jen spolu s posilovnou, nepřepisuje se | `gymId`, `name`, `city` (kód: 6 znaků, abeceda jako u kódu přítele) |
| `gyms/{gymId}/members/{uid}` | členové posilovny | vlastník (`nickname`, `gender`, `ageGroup`, `uid`) | `uid` (= ID dokumentu; pro úklid po smazání účtu – dotaz collection group; členům z dřívějších verzí ho doplní `GymPublisher` / změna profilu), `nickname`, `gender` (male/female/unspecified), `ageGroup?` (u40/40/50/60), `joinedAt` |
| `gyms/{gymId}/entries/{uid}_{kategorie}` | členové posilovny | vlastník jen pole `uid`, `category`, `nickname`, `gender`, `ageGroup`, `best`, `bestAt`, `bestMonth`, `monthKey`, `noPrint`, `updatedAt`; server `hidden`, `hiddenReason`, `reportCount`, `verified` {value, at} (kopie z dokumentu moderace) | jeden záznam na kategorii (slug cviku, např. `bench_press`, nebo `workouts`); `ageGroup?` = věková skupina (u40/40/50/60, bez roku narození chybí); `best` = celkově, `bestMonth` = v měsíci `monthKey` („2026-10“); `noPrint: true` = nechce být na vytištěném žebříčku (jinak pole chybí) |
| `gyms/{gymId}/entries/{id}/reports/{reporterUid}` | jen autor nahlášení (get) | člen posilovny, jednou, ne vlastní záznam; autor smí smazat | `createdAt`; zůstává i po smazání záznamu vlastníkem |
| `gyms/{gymId}/moderation/{entryId}` | nikdo (jen Cloud Functions) | jen Cloud Functions | stav moderace záznamu (viz výše); zůstává po smazání záznamu, maže ho smazání účtu |
| `users/{uid}/private/gym` | vlastník | vlastník | `gymId` (null = v žádné), `nickname`, `gender`, `show`, `printable?`, `updatedAt`; jinou posilovnu smí nastavit a dokument smazat, jen když v posilovně z `gymId` už není členem |

Proč záznam na kategorii (a ne jeden dokument člena): skrytí nereálné
hodnoty nebo nahlášení se týká jen jedné kategorie a žebříček je jeden
dotaz `where category == … orderBy best desc` (měsíční:
`where category == … where monthKey == … orderBy bestMonth desc`) –
potřebuje složené indexy z `firestore.indexes.json`. Filtr pohlaví, filtr
věku a skryté záznamy řeší aplikace nad načteným seznamem (nejvýš 300
záznamů kategorie), takže věková skupina žádný další index nepotřebuje.

Odchod z posilovny (a smazání účtu) smaže člena, záznamy a sníží
`memberCount`. Nahlášení u mých smazaných záznamů a jejich stav moderace
zůstávají (záznam po návratu zůstane skrytý), maže je až smazání účtu.
Prázdné posilovny v adresáři zůstávají (mazat je klient nesmí). Po smazání
účtu zakladatele Cloud Function odstraní z posilovny `createdBy` (posilovna
zůstane ostatním).
Při odchodu z posilovny (i při smazání účtu z aplikace) smaže svá
nahlášení cizích záznamů už aplikace (`firestore.rules` dovolí autorovi
smazat vlastní `reports/{uid}`) – jen u záznamů, které existují. Nahlášení
u záznamů, které vlastník mezitím smazal (zůstal po nich jen dokument
moderace, který aplikace nevidí), smaže Cloud Function
`onGymMemberDeleted` (po smazání člena; když se mezitím vrátil, nic
nedělá). `reportCount` zůstává.

**Smazání účtu a posilovna:** aplikace nejdřív z posilovny odejde; když
to selže, smazání účtu se přeruší (jinak by zůstalo členství, které by
úklid bez `private/gym` nenašel – pravidla proto smazání `private/gym`
dovolí, jen když `gymId` chybí / je null, nebo už v té posilovně nejsem
členem). `cleanupDeletedUser` najde posilovny z `private/gym` a pojistkou
i podle `uid` (collection group `members`, `entries`, `moderation`), smaže
členství, záznamy i s nahlášeními, stav moderace a moje nahlášení cizích
záznamů.

### Nasazení

```powershell
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions      # tarif Blaze
```

Indexy se po nasazení několik minut budují – do té doby žebříček hlásí
chybu připojení. Kromě složených indexů žebříčku jsou ve
`firestore.indexes.json` i jednopolové indexy pro dotazy collection
group při smazání účtu (`fieldOverrides`): `members.uid`, `entries.uid`,
`moderation.uid`, `feed.fromUid` a `blocked.uid`.

**Bez Cloud Functions** (bez tarifu Blaze) žebříček funguje: aplikace
nereálné hodnoty nezveřejní (absolutní hranice a skok), pravidla
hlídají absolutní hranice a aplikace skrývá záznamy s 5 nahlášeními.
Chybí jen: serverová kontrola skoku a skrývání (`hidden`), počítání
nahlášení (`reportCount` se bez funkce nezvyšuje, takže se nahlášené
záznamy neskryjí) a upozornění „předběhl tě“. Funkce:

- `onGymEntryWritten` – kontrola reálnosti, `verified`, stav moderace
  (`gyms/{gymId}/moderation`) pro znovu vytvořené záznamy, novinka
  `gymOvertaken` (nejvýš 1× za 24 h),
- `onGymReportCreated` – počítání nahlášení, skrytí od 5,
- `onGymMemberDeleted` – po odchodu smaže nahlášení, která člen podal,
- `cleanupDeletedUser` – navíc odebere člena, záznamy, nahlášení a stav
  moderace smazaného účtu.

---

## Srovnání se zemí a světem („Jak si vedu“)

Pokrok → **Jak si vedu** (nebo žebříček posilovny → menu): u každého ze
16 cviků žebříčku, ve kterém má uživatel výkon, ukáže jeho maximálku
a percentil **v jeho zemi** a **ve světě** („lepší než 78 %“), pro všechny
nebo jen pro jeho pohlaví a věkovou skupinu (do 39, 40–49, 50–59, 60+).
Bez přepočtu na tělesnou váhu.

- **Data:** Cloud Function `updateLiftStats` jednou denně projde všechny
  viditelné záznamy žebříčků (`gyms/{gymId}/entries`, bez skrytých),
  vezme `best` (celkově, na 0,5 kg) a zemi posilovny (`gyms/{id}.country`)
  a zapíše anonymní rozložení do `liftStats/{země|world}_{cvik}`
  (logika `functions/src/liftStats.ts`, testy `functions/test/liftStats.test.mjs`).
  Jeden člověk = jedna hodnota na cvik. Do srovnání tedy přispívají jen
  lidé, kteří jsou vidět v žebříčku nějaké posilovny.
- **Dokument:** `scope`, `category`, `updatedAt`, `groups` {„{pohlaví}_{věk}“:
  {`n`, `q`}} – pohlaví `all`/`male`/`female`, věk `all`/`u40`/`40`/`50`/`60`,
  `q` = 19 kvantilů (5., 10., … 95. percentil, nearest-rank) zaokrouhlených
  na 2,5 kg. Přesné rozložení (váha → počet) se nezveřejňuje: z rozdílu dvou
  dnů by šlo vyčíst výkon člověka, který se právě přidal. Skupina s méně než
  **20** lidmi má jen `n`; aplikace u ní ukáže „zatím málo dat“.
- **Aplikace** (`lib/modules/social/gym/strength_rank.dart`, obrazovka
  `ui/strength_rank_screen.dart`, trasa `/gym/rank`): vlastní maximálky
  počítá z lokální databáze (`gymBestWeight`, stejně jako žebříček)
  a nikam je kvůli srovnání neposílá; stáhne jen dva dokumenty na cvik
  (země + svět). Percentil se dopočítá lineárně mezi kvantily; pod 5.
  percentilem 2,5 %, nad 95. 97,5 %, při shodě s několika kvantily jejich
  střed.
- **Země:** země posilovny, ve které je uživatel; jinak region z jazyka
  telefonu (`cs_CZ` → CZ). Neznámá země = jen svět.
- **Moje skupina:** pohlaví z profilu žebříčku, jinak z Profilu; věk
  z roku narození. Bez nich jde jen „Všichni“.
- **Pravidla:** `liftStats` čte kdokoli (i bez přihlášení), zapisuje jen
  funkce.

## Nahlášení a blokování

Pravidla Google Play a App Store pro obsah od uživatelů vyžadují, aby šel
nevhodný obsah nahlásit a uživatel zablokovat.

- **Posilovna** (název, město, adresa): menu na obrazovce posilovny
  (*Nahlásit posilovnu*, jen cizí) a menu na náhledu před připojením.
  Od 5 nahlášení za obsah ji Cloud Function `onContentReportCreated`
  skryje z adresáře (`hidden: true`, `hiddenReason: "reports"`); kdo zná
  kód nebo QR, připojí se dál a členové o nic nepřijdou. Důvody
  „Neexistuje / Duplicita“ se počítají zvlášť a skryjí (vratně) jen
  posilovnu bez členů – viz `docs/gyms_import.md`, „Nahlášení posilovny“.
- **Přítel**: menu u přítele → *Nahlásit* (důvod + volba „Zároveň
  zablokovat“, výchozí zapnuto) nebo *Zablokovat*.
- **Záznam v žebříčku** (přezdívka a výkon): beze změny, viz „Kontrola
  nereálných výkonů a nahlášení“.

Blokování zapíše `users/{já}/blocked/{uid}` (`uid`, `name`, `since`) a zruší
přátelství v obou směrech. `firestore.rules` pak nedovolí vytvořit
přátelství mezi těmito dvěma (ani se starým kódem přítele), takže
blokovaný nemůže posílat novinky, výzvy ani pozvánky. Můj kód přítele se
navíc vymění (jako po odebrání), takže se ani po odblokování nepřidá se
starým. Seznam a odblokování: Přátelé → účet → *Zablokovaní uživatelé*.

Nahlásit jde jen existující cíl (`firestore.rules`): posilovnu, která
existuje a nezaložil jsem ji, a uživatele, kterého mám v seznamu přátel
(aplikace nahlašuje před zablokováním, kdy vazba ještě existuje).

| Cesta | Kdo čte | Kdo zapisuje | Obsah |
|---|---|---|---|
| `contentReports/{kind}_{targetId}_{reporterUid}` | nikdo (jen vývojář v konzoli) | přihlášený, jednou za cíl | `kind` (gym / user), `targetId`, `targetName` (≤ 80 znaků), `reason` (offensive / spam / other), `reporterUid`, `createdAt` |
| `users/{uid}/blocked/{blockedUid}` | vlastník | vlastník | `uid`, `name`, `since` |

**Pro vývojáře:** nová nahlášení jsou ve Firestore v kolekci
`contentReports` a v logu funkcí (Firebase konzole → Functions → Logs,
zpráva „Content report“). Na vážné případy reaguj ručně – posilovnu
skryješ polem `hidden: true`, účet zablokuješ ve Firebase Authentication.
Funkce `purgeOldContentReports` jednou denně maže nahlášení starší než
rok (vyžaduje Cloud Scheduler, je v tarifu Blaze). Smazání účtu smaže
nahlášení, která uživatel podal, nahlášení na něj, záznamy o jeho
zablokování u ostatních (index `blocked.uid` v `firestore.indexes.json`)
a jeho položky v novinkách přátel (index `feed.fromUid`).

Nasazení: `firebase deploy --only firestore:rules,firestore:indexes,functions`.

## Automatická záloha (modul `cloud`)

Přihlášený uživatel (stejné přihlášení Google / Apple jako u Přátel) si
v Profilu → **Záloha do cloudu** zapne automatickou zálohu. Celá databáze
se nahraje do **Firebase Cloud Storage** do jeho soukromé složky; na novém
telefonu ji jedním klepnutím obnoví. Kód: `lib/modules/cloud/`.

### Nastavení (jednou, ve Firebase konzoli)

1. **Tarif Blaze.** Nové úložiště (bucket) ve Firebase od 30. 10. 2024
   vyžaduje tarif Blaze (stejný jako pro Cloud Functions, viz krok 7).
   Nastav si rozpočet s upozorněním.
2. Firebase → **Build → Storage → Začít** → *Production mode* →
   umístění **v EU**: `europe-west1` (Belgie, stejný region jako Cloud
   Functions) nebo více-regionální `EU`.
   **EU je povinné** – souhlas v aplikaci uživateli říká „servery
   v Evropské unii“. Umístění už později nejde změnit.
   Pozor: bezplatná kvóta Cloud Storage platí jen pro regiony v USA,
   v EU se platí od prvního bajtu. Záloha má po kompresi obvykle jednotky
   MB na uživatele (2 soubory), takže jde o haléře měsíčně.
3. Zkontroluj, že `lib/firebase_options.dart` obsahuje `storageBucket:`
   (např. `projekt.firebasestorage.app`). Když ne (Storage jsi zapnul až
   po `flutterfire configure`), spusť `flutterfire configure` znovu. Bez
   `storageBucket` sekce v Profilu jen ukáže „ještě není nastavená“.
4. Nahraj pravidla úložiště a znovu nasaď funkce (úklid záloh po smazání
   účtu):
   ```powershell
   firebase deploy --only storage
   firebase deploy --only functions
   ```
   Pravidla jsou v `storage.rules`, odkaz na ně v `firebase.json`
   (sekce `"storage"`).

Žádné nativní úpravy nejsou potřeba (`firebase_storage`,
`connectivity_plus` a `device_info_plus` se nastaví samy; povolení
`ACCESS_NETWORK_STATE` přidá `connectivity_plus` do manifestu sám).

### Co se ukládá

| Cesta v úložišti | Obsah |
|---|---|
| `users/{uid}/backups/latest.sqlite` | nejnovější záloha |
| `users/{uid}/backups/previous.sqlite` | předchozí záloha (před každým nahráním se do ní přesune dosavadní `latest`) |

- Soubor je konzistentní kopie databáze (`VACUUM INTO`, stejně jako ruční
  záloha v sekci Data) **zkomprimovaná gzipem** (`dart:io`), typ obsahu
  `application/gzip`. Přípona zůstává `.sqlite` kvůli pevným cestám.
- Metadata souboru: `schemaVersion`, `createdAt` (UTC, ISO 8601),
  `deviceName` (např. „Google Pixel 8“), `workouts` (počet tréninků),
  `compression` (`gzip`).
- Klient Storage neumí kopírovat na serveru, proto se `latest` před
  nahráním nové zálohy stáhne a nahraje jako `previous`.
- Telefon **bez tréninků** nikdy nepřepíše zálohu, ve které tréninky jsou
  (typicky nový telefon před obnovením) – záloha se přeskočí.

### Kdy se zálohuje

- Po dokončeném tréninku (háček `[cloud:finished]`) – pokud poslední
  záloha není mladší než 15 minut.
- Po změně dat (háček `[cloud:sync]`, běží i po spuštění aplikace) –
  **nejvýš jednou za 24 hodin**.
- Hned po zapnutí a tlačítkem **Zálohovat teď**.
- Volba **Jen přes Wi-Fi** (výchozí zapnuto, balíček `connectivity_plus`)
  platí pro automatické zálohy; ruční záloha běží vždy.
- Nic z toho neblokuje UI (háčky zálohu jen spustí). Chyby se nehlásí;
  v Profilu se ukáže „Poslední záloha se nepovedla“ a další automatický
  pokus proběhne nejdřív za hodinu.

Nastavení (zapnuto/vypnuto, Wi-Fi, čas poslední zálohy, chyba, čas
souhlasu, komu už se nabídlo obnovení) je v souboru
`cloud_backup_settings.json` ve složce dokumentů aplikace – **ne
v databázi**, aby ho obnovení zálohy nepřepsalo (a bez změny schématu).

### Obnovení

- Profil → **Obnovit z cloudu** → seznam (nejnovější / předchozí, datum,
  počet tréninků, zařízení) → potvrzení → stažení → stejné ověřené
  obnovení jako ze souboru (`BackupService.prepareFile` → `inspect` →
  `restore`: ATTACH, kopie tabulek podle názvů sloupců, při chybě se nic
  nezmění). Záloha z novější verze aplikace se odmítne.
- **Po prvním přihlášení** na telefonu bez tréninků (i po přeinstalaci
  na iPhonu, kde přihlášení přežije) aplikace sama nabídne: „Našli jsme
  zálohu z 3. října 2026. Obsahuje 124 tréninků. Obnovit ji do tohoto
  telefonu?“ Každému účtu jen jednou na zařízení.

### Soukromí a bezpečnost

- Výchozí stav je **vypnuto**. Před zapnutím aplikace ukáže souhlas:
  záloha obsahuje i údaje o zdraví (období nemoci a zranění, tělesná
  váha, pitný režim), ukládá se šifrovaně (šifrování Google Cloud
  v klidu) do soukromého prostoru v Google Firebase (servery v EU),
  přístup má jen uživatel po přihlášení, smaže se se smazáním účtu.
  Čas souhlasu se uloží (`consentAt`).
- `storage.rules`: číst / zapisovat / mazat smí jen přihlášený vlastník
  (`request.auth.uid == uid`) a jen `latest.sqlite` / `previous.sqlite`
  v `users/{uid}/backups/`; velikost pod 50 MB; typ obsahu
  `application/gzip` (nebo `application/x-sqlite3`); vše ostatní je
  zakázané.
- Smazání: Profil → **Smazat zálohy v cloudu** (zároveň vypne
  automatickou zálohu). Smazání účtu v Přátelích zálohy smaže z aplikace
  (`CloudBackupService.deleteAll`) a pojistkou je Cloud Function
  `cleanupDeletedUser` (smaže celou složku `users/{uid}/backups/`).

### Premium

Automatická záloha je funkce Premium (`PremiumFeature.cloudBackup`).
Dokud je `kPremiumLaunched = false`, nic není omezené. Po spuštění bez
předplatného: háčky `cloudWorkoutFinished` / `cloudSync` nic nedělají,
přepínač se ukazuje vypnutý se štítkem „Premium“ a zapnutí i „Zálohovat
teď“ nejdřív otevřou paywall (`requirePremium`). **Obnovení** existující
zálohy (ručně i nabídka po přihlášení) zůstává vždy zdarma, aby nikdo
nepřišel o data.

### Vyzkoušení

1. Profil → Záloha do cloudu → **Přihlas se a zálohuj automaticky** →
   souhlas → „Zálohováno do cloudu.“
2. Firebase → Storage: `users/<uid>/backups/latest.sqlite` s metadaty.
3. **Zálohovat teď** podruhé → vznikne i `previous.sqlite`.
4. Na druhém telefonu (nebo po smazání dat aplikace) se přihlas → nabídka
   obnovení → Obnovit → data jsou zpět.
5. Vypni Wi-Fi a odcvič trénink → automatická záloha se nespustí.
6. Smazat zálohy v cloudu → složka ve Storage je prázdná.
