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
  maže data sama),
- `onGymEntryWritten`, `onGymReportCreated` – žebříček posilovny (viz
  „Žebříček posilovny“ níže).

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
    (odhad 1RM vestavěných cviků, zaokrouhleno na 0,5 kg) do novinek přátel,
  - **Sdílet statistiky** (`shareWorkoutStatsWithFriends`): počet tréninků
    v měsíci, objem v týdnu, týdny se splněným plánem.
- **Nikdy** se nesdílí: období (nemoc, zranění, dieta…), tělesná váha,
  množství vody. U výzvy na pitný režim jde ven jen procento splnění.
  (Jediná výjimka je **automatická záloha** – celá databáze, jen se
  souhlasem, do soukromého prostoru uživatele, který nikdo jiný nevidí;
  viz „Automatická záloha“ níže.)
- Tělesnou váhu žádná sociální ani serverová funkce nečte ani z ní nic
  nepočítá. Relativní síla (1RM ÷ tělesná váha) v žebříčku přátel byla
  zrušena; staré pole `relStrength` v `users/{uid}` aplikace při dalším
  zveřejnění statistik smaže (`FieldValue.delete()`) a `firestore.rules`
  ho už nepovolí.
- Profil vidí jen přátelé, vyhledávání uživatelů neexistuje. Jediný
  „veřejný“ žebříček je žebříček posilovny – vidí ho jen její členové
  a je v něm jen přezdívka (viz níže). Přítel se přidává jen kódem (QR / odkaz) – kód funguje jako
  pozvánka.
- Smazání účtu (v aplikaci) smaže všechna data na serveru a účet ve
  Firebase Auth (u Apple i zruší přihlašovací token).

---

## Datový model (Firestore)

| Cesta | Kdo čte | Kdo zapisuje | Obsah |
|---|---|---|---|
| `users/{uid}` | vlastník, přátelé | vlastník | `displayName`, `friendCode`, `createdAt`, `updatedAt`, `lang`, `shareRecords`, `shareStats`; se sdílením statistik `workoutsThisMonth` + `statsMonth` („2026-09“), `weeklyVolume` + `statsWeek` („2026-W40“), `weeks` {„2026-W40“: true…} (12 týdnů, splněný plán) |
| `users/{uid}/private/messaging` | vlastník (+ funkce) | vlastník | `fcmTokens` [], `lang` – tokeny nejsou v profilu, aby je přátelé neviděli |
| `users/{uid}/friends/{friendUid}` | vlastník | vlastník; přítel se znalostí kódu | `since`, (`code`) |
| `users/{uid}/feed/{id}` | vlastník | přátelé (fan-out z aplikace); vlastník mění jen `read`, `status`, `handled` | `type` (friend, pr, invite, inviteReply, challenge, challengeDone; `gymOvertaken` zapisuje jen Cloud Function), `fromUid`, `fromName`, `createdAt`, `data` {…}, `read` |
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

---

## Žebříček posilovny

Posilovna = skupina. Kdokoli přihlášený ji může založit (název, město,
volitelně adresa) a dostane **QR kód** pro recepci (Posilovna → ikona QR →
*Sdílet QR*: plakát jako PNG + text s odkazem přes systémové sdílení).
Ostatní se připojí:

- naskenováním QR v aplikaci (**Přátelé → ikona činky → Naskenovat QR
  posilovny**) nebo odkazem `fitnessapp://gym?code=XXXXXX` /
  `<web>/gym?code=XXXXXX` (QR obsahuje webový odkaz, skener v aplikaci
  přijme oba; dokud web na `kWebBaseUrl` neběží, fotoaparát telefonu
  odkaz neotevře – skenuj v aplikaci),
- výběrem ze seznamu (**Najít posilovnu** – hledá podle začátku názvu
  nebo města, bez diakritiky; ukazuje počet členů).

Člověk je vždy jen v **jedné** posilovně a může kdykoli odejít (jeho
záznamy v žebříčku se smažou). Vstup je na obrazovce Přátelé (ikona
činky v liště), přes kartu na obrazovce **Pokrok** a z odkazu.

### Co se zveřejní

Při vstupu (a později v menu *Přezdívka, věk a viditelnost*) uživatel zadá
**přezdívku** (výchozí = jméno pro přátele, max. 24 znaků), volitelně
**pohlaví** (muž / žena / neuvádět – jen pro filtr), volitelně **rok
narození** a přepínač **Ukázat mě v žebříčku posilovny** (vypnuto = jen se
dívá, nic se nezveřejní a jeho záznamy se smažou). Přezdívka, pohlaví
a viditelnost jsou ve Firestore v `users/{uid}/private/gym`; rok narození
se ukládá jen do lokálního profilu (`UserProfiles.birthYear`, jde zadat
i v Profilu → *Rok narození (nepovinné)*, rozsah 1920 … letošní rok − 10).

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
| cviky (klíč = slug vestavěného cviku, viz tabulka níže) | nejlepší odhad 1RM (Epley, `estimateOneRepMax`) z dokončených tréninků, bez rozcvičky a bez sérií nad 12 opakování; na 0,5 kg | tréninky v aktuálním měsíci / všechny |
| `workouts` | počet dokončených tréninků | tento měsíc / nejvíc za jeden měsíc |

Cviky a absolutní hranice odhadu 1RM (`GymCategory` v `gym_logic.dart`):

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
kontrolu reálnosti). Kategorie relativní síly (1RM ÷ tělesná váha) byla
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
  `beatRecord` s cílem = lídrův odhad 1RM (termín 30 dní), u tréninků
  `workoutsInMonth` s cílem o 1 vyšším (do konce měsíce). `fromName` =
  přezdívka, výzva odkazuje na cvik přes `exerciseSlug` (funguje pro
  všechny cviky žebříčku), `remoteId` = `gym:<gymId>:<uid>:<kategorie>:<hodnota>` (podle
  něj se výzva neduplikuje; na server se tyto výzvy nehlásí).
- Kdo byl v kategorii **první** (celkový žebříček, i dělené místo) a někdo
  ho předběhne, dostane novinku `gymOvertaken` (zapíše ji Cloud Function
  `onGymEntryWritten` do `users/{uid}/feed`, push pošle `sendFeedPush`).
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

### Datový model

| Cesta | Kdo čte | Kdo zapisuje | Obsah |
|---|---|---|---|
| `gyms/{gymId}` | přihlášení (veřejný adresář posiloven) | zakladatel vytvoří; `memberCount` ±1 jen spolu se vznikem / zánikem vlastního členství | `name`, `nameLower`, `city`, `cityLower` (malá písmena bez diakritiky – hledání podle prefixu), `address?`, `code`, `createdBy`, `createdAt`, `memberCount` |
| `gymCodes/{code}` | přihlášení (jen get) | zakladatel, jen spolu s posilovnou, nepřepisuje se | `gymId`, `name`, `city` (kód: 6 znaků, abeceda jako u kódu přítele) |
| `gyms/{gymId}/members/{uid}` | členové posilovny | vlastník (`nickname`, `gender`, `ageGroup`) | `nickname`, `gender` (male/female/unspecified), `ageGroup?` (u40/40/50/60), `joinedAt` |
| `gyms/{gymId}/entries/{uid}_{kategorie}` | členové posilovny | vlastník jen pole `uid`, `category`, `nickname`, `gender`, `ageGroup`, `best`, `bestAt`, `bestMonth`, `monthKey`, `updatedAt`; server `hidden`, `hiddenReason`, `reportCount`, `verified` {value, at} | jeden záznam na kategorii (slug cviku, např. `bench_press`, nebo `workouts`); `ageGroup?` = věková skupina (u40/40/50/60, bez roku narození chybí); `best` = celkově, `bestMonth` = v měsíci `monthKey` („2026-10“) |
| `gyms/{gymId}/entries/{id}/reports/{reporterUid}` | jen autor nahlášení (get) | člen posilovny, jednou, ne vlastní záznam | `createdAt` |
| `users/{uid}/private/gym` | vlastník | vlastník | `gymId` (null = v žádné), `nickname`, `gender`, `show`, `updatedAt`; jinou posilovnu smí nastavit, jen když ve staré už není členem |

Proč záznam na kategorii (a ne jeden dokument člena): skrytí nereálné
hodnoty nebo nahlášení se týká jen jedné kategorie a žebříček je jeden
dotaz `where category == … orderBy best desc` (měsíční:
`where category == … where monthKey == … orderBy bestMonth desc`) –
potřebuje složené indexy z `firestore.indexes.json`. Filtr pohlaví, filtr
věku a skryté záznamy řeší aplikace nad načteným seznamem (nejvýš 300
záznamů kategorie), takže věková skupina žádný další index nepotřebuje.

Odchod z posilovny (a smazání účtu) smaže člena, záznamy a sníží
`memberCount`; nahlášení u smazaných záznamů uklidí Cloud Function.
Prázdné posilovny v adresáři zůstávají (mazat je klient nesmí).

### Nasazení

```powershell
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions      # tarif Blaze
```

Indexy se po nasazení několik minut budují – do té doby žebříček hlásí
chybu připojení.

**Bez Cloud Functions** (bez tarifu Blaze) žebříček funguje: aplikace
nereálné hodnoty nezveřejní (absolutní hranice a skok), pravidla
hlídají absolutní hranice a aplikace skrývá záznamy s 5 nahlášeními.
Chybí jen: serverová kontrola skoku a skrývání (`hidden`), počítání
nahlášení (`reportCount` se bez funkce nezvyšuje, takže se nahlášené
záznamy neskryjí) a upozornění „předběhl tě“. Funkce:

- `onGymEntryWritten` – kontrola reálnosti, `verified`, novinka
  `gymOvertaken`, úklid nahlášení po smazání záznamu,
- `onGymReportCreated` – počítání nahlášení, skrytí od 5,
- `cleanupDeletedUser` – navíc odebere člena a záznamy smazaného účtu.

---

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
