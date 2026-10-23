# Trenér a klient (modul `coach`, verze 0.3.9)

Trenér vidí tréninky svých klientů (v aplikaci i na webu
**gymbar.app/trener**), píše k nim komentáře a posílá klientům plány, které
se jim samy uloží do aplikace. Plán jde sdílet i odkazem
`https://gymbar.app/plan?id=…` komukoli.

Pravidla (rozhodnutí vývojáře):

- **Trenérem se může označit kdokoli** – v aplikaci (Profil → Trenér
  a klienti) nebo na webu. Dostane kód (6 znaků) a odkaz
  `https://gymbar.app/coach?code=…`.
- **Status zanikne po 60 dnech bez klienta** (`coachInactiveDays`). Počítá
  Cloud Function `expireTrainers` jednou denně podle `zeroSince` (od kdy
  trenér nemá žádného klienta). Trenér to vidí jako upozornění s datem.
- **Pro trenéry je aplikace zdarma**; platit budou klienti (nebo budou mít
  reklamy). Placení zatím není – až bude Premium, trenér bude mít Premium
  zdarma, dokud má status (`coachPremiumGrantProvider` v
  `lib/modules/coach/coach_service.dart`, napojené přes `modulePremiumGrant`
  v `module_hub.dart`).
- **Klient se připojí sám** (kód, QR nebo odkaz) a při tom **souhlasí**
  se sdílením tréninků. Tělesná váha jen s **druhým souhlasem** (přepínač).
  Jeden trenér na klienta; připojení k jinému trenérovi staré propojení
  zruší.
- Propojení zruší klient i trenér. Pak Cloud Function `onCoachLinkDeleted`
  smaže u trenéra tréninky, váhu, plány a komentáře. Plány v telefonu
  klienta zůstanou.

## Co trenér vidí a co ne

| Vidí | Nevidí |
|---|---|
| tréninky: datum, délku, název plánu, cviky, série (kg, opakování, čas, rozcvička, drop) | poznámky, pocit z tréninku, kalorie |
| grafy a rekordy z nich (počítá `packages/gymbar_coach`) | období nemoci a zranění, pitný režim |
| tělesnou váhu – jen se zvláštním souhlasem | ostatní data z Apple Zdraví / Health Connect |
| plány, které klientovi poslal, a své komentáře | tréninky před propojením starší než rok |

Aplikace po propojení nahraje tréninky za posledních 365 dní, pak vždy po
tréninku a při synchronizaci tréninky za posledních 14 dní (`CoachSync`).

## Části

| Kde | Co |
|---|---|
| `packages/gymbar_coach/` | čistý Dart sdílený aplikací a webem: kódy, formát plánu a tréninku (JSON s krátkými klíči), statistiky (týdny, nejtěžší série, rekordy, souhrn klienta), filtr hrubých slov, `coachName` |
| `lib/modules/coach/` | aplikace: `coach_service.dart` (Firestore), `coach_sync.dart` (nahrávání tréninků, stahování plánů), `coach_queries.dart` (tréninky z databáze, import plánu), obrazovky |
| `trainer_web/` | web pro trenéry (Flutter web): přihlášení, klienti, grafy, historie s komentáři, knihovna plánů, editor plánů, posílání plánů |
| `tool/trainer_catalog.dart` | katalog cviků pro editor na webu (`trainer_web/assets/exercises.json`) z `seed_data.dart` |
| `firestore.rules` | sekce „trenéři“ |
| `functions/src/index.ts`, `coach.ts` | počet klientů, zánik statusu, úklid, push k pozvánkám na trénink |
| `docs/web/join.html` | stránka pro odkazy `/coach` a `/plan`, když aplikace není nainstalovaná |

## Datový model (Firestore)

| Cesta | Kdo čte | Kdo zapisuje | Obsah |
|---|---|---|---|
| `trainers/{uid}` | přihlášení | trenér (jen `name`, `bio`); `clientCount`, `zeroSince` jen funkce | `name`, `bio`, `code`, `createdAt`, `updatedAt` |
| `trainers/{uid}/plans/{id}` | trenér | trenér (web) | knihovna: `plan` (CoachPlan), `updatedAt` |
| `trainerCodes/{kód}` | přihlášení (jen get) | trenér | `uid` |
| `coachLinks/{klient}` | klient, jeho trenér | vytvoří jen klient (souhlas); smaže klient i trenér | `clientUid`, `trainerUid`, `clientName`, `trainerName`, `shareWeight`, `createdAt`, `updatedAt` |
| `coachLinks/{klient}/workouts/s<id>` | klient, trenér | klient | CoachWorkout: `startedAtMs`, `durationMin`, `title`, `exercises` |
| `coachLinks/{klient}/meta/weight` | klient, trenér | klient, jen se `shareWeight` | `points` [{`d`, `kg`}] (max. 400) |
| `coachLinks/{klient}/plans/{id}` | klient, trenér | trenér; klient smí smazat | `plan`, `version`, `trainerName`, `updatedAt` |
| `coachLinks/{klient}/notes/{id}` | klient, trenér | trenér; smazat smí oba | `workoutId`, `text` (max. 500), `trainerName`, `createdAt` |
| `coachLinks/{klient}/sessions/{id}` | klient, trenér | trenér (nová, úprava → znovu `pending`, zrušení); klient jen `status` přijato / odmítnuto | CoachSession: `startAtMs`, `durationMin` (15–480), `weeks` (1–26), `title`, `note`, `planId`, `trainerName`, `status`, `createdAt`, `updatedAt` |
| `sharedPlans/{id}` | kdokoli (jen get) | autor | `plan`, `authorUid`, `authorName`, `createdAt` |

Plán (`CoachPlan.toJson`): `name`, `desc`, `days` (bit 0 = pondělí),
`exercises` [{`slug` nebo jen názvy `en`/`cs` + `muscle`, `equipment`,
`type` u vlastního cviku, `rest`, `restAuto`, `ss` (supersérie), `repMin`,
`repMax`, `note` (poznámka ke cviku, max. 300 znaků), `sets` [{`r`, `kg`,
`w`, `d`}]}].

**Poznámky ke cvikům** (od 0.3.10): trenér napíše poznámku ke cviku v plánu
(na webu „Poznámka pro klienta“, v aplikaci „Poznámka v plánu“). U klienta
se uloží do `PlanExercises.note`, ukáže se v plánu i při tréninku s ikonou
a jménem trenéra a nová verze plánu ji přepíše. Vlastní poznámka klienta ke
cviku (`Exercises.note`, např. nastavení stroje) se trenérovi ani v plánu
nikdy neposílá. Vlastní cvik si aplikace klienta
najde podle názvu, jinak ho založí.

Nová verze plánu: trenér zapíše stejné ID s `version + 1`, aplikace ji při
synchronizaci (nejvýš co 10 minut) stáhne a plán v telefonu přepíše. Plán
z aplikace trenéra má ID `app<id>`, z knihovny na webu ID plánu
v knihovně – opakované poslání tedy klientovi plán aktualizuje.

**Pozvánky na trénink** (od 0.3.12): trenér pozve klienta na trénink
(web: stránka klienta → „Pozvat na trénink“, aplikace: detail klienta) –
datum, čas, délka, jednorázově nebo každý týden až 26 týdnů, volitelně
plán a poznámka. Klient dostane push (Cloud Function
`onCoachSessionWritten`) a kartu na obrazovce Dnes, pozvánku přijme nebo
odmítne; trenér dostane push s odpovědí. Přijaté termíny zapíše aplikace
klientovi i trenérovi do kalendáře telefonu (`coach_calendar.dart`,
tabulka `CoachCalendarEvents` – databáze v19): každý zbývající termín jako
událost s názvem podle Profilu („Fitko – Nohy s Tomem“). Úprava termínu
(klient potvrdí znovu), zrušení, odmítnutí nebo zrušení propojení události
smaže, případně vytvoří znovu. Web nabízí ke každému termínu i soubor .ics
(RRULE pro opakování) do vlastního kalendáře trenéra.

## Nasazení (Windows)

1. **Aplikace:** po rozbalení
   ```
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   dart run tool/setup_platforms.dart
   ```
   (databáze v16 – sloupce `remoteId`, `remoteVersion`, `remoteFrom`
   u plánů; App Links pro `/coach` a `/plan`).
2. **Firebase:** `firebase deploy --only firestore:rules,firestore:indexes,functions,hosting`
   (index `trainers` podle `clientCount` + `zeroSince` pro `expireTrainers`
   se staví pár minut).
3. **App Links:** znovu `dart run tool/assetlinks.dart` (nové cesty) a
   `firebase deploy --only hosting`.
4. **Web pro trenéry** (ve složce `trainer_web`, jednorázově):
   ```
   cd trainer_web
   dart pub global activate flutterfire_cli
   flutterfire configure --project=fitness-app-dc5e4 --platforms=web
   ```
   Přepíše `trainer_web/lib/firebase_options.dart` (zaregistruje ve
   Firebase webovou aplikaci). **Hotovo** – webová aplikace „GymBar web“
   je zaregistrovaná a soubor je v gitu (workflow „Konfigurace Firebase
   aplikací“); znovu je to potřeba jen při změně projektu.
5. **Firebase Console → Authentication → Settings → Authorized domains:**
   přidej `gymbar.app` (jinak přihlášení na webu hlásí „unauthorized-domain“).
6. **Build a nasazení webu** (pokaždé po změně):
   ```
   cd trainer_web
   flutter pub get
   flutter build web --release --base-href /trener/ -o ../docs/web/trener
   cd ..
   firebase deploy --only hosting
   ```
   Výstup `docs/web/trener/` je v `.gitignore`.
7. Po změně vestavěných cviků: `dart run tool/trainer_catalog.dart`.

### Přihlášení přes Apple na webu

Na webu je zatím jen Google (`kAppleWebSignIn = false` v
`trainer_web/lib/backend.dart`). Trenér, který se v aplikaci přihlásil přes
Apple, se na web zatím nedostane (aplikaci může používat normálně). Po
zaplacení Apple Developer účtu: Apple Developer → Identifiers → **Services
ID** (např. `app.gymbar.web`), zapnout Sign in with Apple, doména
`fitness-app-dc5e4.firebaseapp.com`, return URL
`https://fitness-app-dc5e4.firebaseapp.com/__/auth/handler`; ve Firebase →
Authentication → Apple vyplnit Services ID, Team ID, Key ID a klíč. Pak
`kAppleWebSignIn = true` a znovu build.

## Vyzkoušení

1. Telefon A (trenér): Profil → Trenér a klienti → Stát se trenérem.
2. Telefon B (klient): naskenovat QR / zadat kód → souhlas → Propojit.
   Do minuty se u trenéra objeví klient i tréninky za poslední rok.
3. Trenér: plán → Poslat klientovi. Klient: plán se objeví v seznamu plánů
   (podtitul „Od trenéra …“) – nejpozději po další synchronizaci.
4. Web: gymbar.app/trener → přihlásit se stejným Google účtem jako trenér
   → klient → grafy, komentář k tréninku, plán z knihovny.
5. Klient: Zrušit propojení → u trenéra klient zmizí.

## Testy

- `test/coach_test.dart` – kódy, JSON plánu a tréninku, statistiky.
- `functions/test/coach.test.mjs` – počet klientů a zánik statusu
  (`cd functions && npm test`).
- `trainer_web/test/strings_test.dart` – texty webu (`cd trainer_web &&
  flutter test`).
