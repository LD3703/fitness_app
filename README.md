# Fitness App

Gym tracker s obdobími (nemoc, cut, bulk), pitným režimem a plánem B.
Specifikace: dokument „Fitness aplikace – specifikace“ v Claude.

Stav: **verze 2 a 3 v kódu (fáze 5)** – MVP + vše z verzí 2 a 3 specifikace
(kromě reklam a Premium). Kód je zatím neověřený překladačem – první build
může hlásit chyby, pošli je Claudovi.

Funguje:
- **Plány:** vytvoření, přejmenování, smazání, tréninkové dny, plánovaný čas,
  změna pořadí cviků tažením.
- **Série v plánu:** každá série má vlastní počet opakování, cílovou váhu
  a může být rozcvičková; převzetí z minulého tréninku; orientační návrh vah
  podle osobního rekordu; u cviku je vidět rekord (odhad 1RM) a poslední výkon.
- **Trénink:** spuštění z plánu, z obrazovky Dnes i bez plánu; zápis sérií
  s předvyplněním z minula, sloupec „Minule“, časovač pauzy (−15 / +15 /
  přeskočit), přidání cviku i série během tréninku, pokračování po zavření
  aplikace, zahození tréninku.
- **Souhrn po tréninku:** délka, počet sérií, objem, odhad kalorií
  a nové osobní rekordy (odhad 1RM).
- **Dnes:** dnešní plány podle dnů v týdnu, pokračování rozpracovaného
  tréninku, pitný režim, váha, aktuální období.
- **Pokrok:** grafy váhy (průměr za 7 dní + denní vážení), síly (odhad 1RM
  pro zvolený cvik) a počtu tréninků za týden; období (nemoc, dieta…) jsou
  v grafech vybarvená pruhem. Pod grafy historie tréninků.
- **Období:** nemoc, zranění, dieta, nabírání, udržování, pauza (přidat,
  ukončit, upravit, smazat) – ikona vlajky na obrazovce Dnes nebo Profil.
  U zranění se vybírá partie: v grafu síly se zranění ukáže jen u cviků
  na tuto partii a v tréninku je u nich upozornění.
- **Povzbuzení:** při nemoci, zranění, do 7 dní po nemoci a v dietě
  povzbuzující hlášky na obrazovce Dnes, během tréninku a v souhrnu.
- **Úvodní průvodce a volba funkcí:** při prvním spuštění si uživatel vybere,
  co chce sledovat (pitný režim, váha, období a povzbuzení, kalorie);
  totéž jde měnit v Profilu, vypnuté funkce se skryjí.
- **Odložení / vynechání tréninku:** z obrazovky Dnes (menu ⋮ u plánu),
  s uklidňující hláškou a možností vrátit.
- **Cviky:** knihovna 53 cviků s návodem (CZ/EN), hledáním a filtrem.
- **Hotové programy:** Full body 3×, Horní/dolní 4×, Push/Pull/Legs –
  přidají se jedním klepnutím do Plánů.
- **Plán B:** 5minutová domácí rutina s časovačem (práce/pauza); po dokončení
  nabídne přesun plného tréninku na zítřek.
- **Upozornění:** ranní připomínka ve dny tréninku (s ohledem na nemoc),
  konec pauzy i při zamčeném telefonu, připomínky pití.
- **Kalendář:** naplánované tréninky na 14 dní se zapisují do kalendáře
  telefonu a při změně plánu se samy upraví.
- **Pitný režim:** ve dny tréninku se cíl zvýší o 500 ml.
- **Soukromí:** vše je jen v telefonu; v Profilu jde smazat všechna data.
- **Jazyky:** angličtina, čeština, němčina, španělština, francouzština –
  podle jazyka telefonu. Přeložené jsou i názvy cviků, návody, programy
  a rutiny plánu B; cvik jde vyhledat v kterémkoli jazyce i bez diakritiky.

Verze 2 a 3 (moduly v `lib/modules/`):
- **Statistiky:** objem po týdnech a partiích, kalendář aktivity, jak často
  trénuješ kterou partii, automatické postřehy (návrat po nemoci, shrnutí
  diety a nabírání, nové rekordy, pravidelnost, zanedbaná partie, příliš
  rychlé hubnutí), obrazovka Osobní rekordy, historie a graf 1RM v detailu
  cviku, streak týdnů na obrazovce Dnes.
- **Sdílení a výzvy:** obrázek rekordu a tréninku ke sdílení, výzva odkazem
  („Překonáš mě?“), přijetí výzvy z odkazu, aktivní výzvy s postupem na Dnes.
  Stránka webu pro odkazy: `docs/web/challenge.html`.
- **Kalendář a upozornění:** volný čas a kolize z kalendáře, návrh času
  v editoru plánu, varování na Dnes, kolize v ranní připomínce, tlačítka
  v upozornění (Počítám s tím / Přesunout / Dnes nestíhám), odpočet pauzy
  na zamčené obrazovce (Android), připomínky pití od–do po zvoleném intervalu.
- **Widget na plochu (Android):** voda a dnešní trénink, tlačítko + sklenice.
- **Health Connect / Apple Zdraví:** zápis tréninků, výměna tělesné váhy.
- **Data:** export CSV, záloha a obnova (soubor do Disku/iCloudu), vlastní
  cviky, jednotky kg/lb a ml/oz, vlastní objem sklenice a láhve.
- **Přátelé (Firebase):** přihlášení Google/Apple, přátelé přes QR nebo
  odkaz, pozvánky na trénink do kalendáře, upozornění na rekordy přátel,
  výzvy, žebříčky, společný streak. Než se nastaví Firebase
  (`docs/social.md`), aplikace funguje dál a sekce Přátelé jen hlásí,
  že není nastavená.
- **Polština** jako šestý jazyk.

Na iOS zatím není widget a Live Activity (potřebují Xcode na Macu).
Reklamy a Premium nejsou součástí verzí 2 a 3.

---

## 1. Instalace na Windows (jednorázově, cca 1 hodina)

### 1.1 Zapni režim pro vývojáře
Nastavení → Systém → Pro vývojáře → **Režim pro vývojáře: Zapnuto**.
Flutter ho na Windows potřebuje pro pluginy (databáze je plugin).

### 1.2 Git
Stáhni a nainstaluj **Git for Windows** z https://git-scm.com (výchozí volby stačí).

### 1.3 Flutter SDK
1. Otevři https://docs.flutter.dev/get-started/install/windows a stáhni aktuální
   **stable** ZIP.
2. Rozbal ho do `C:\src\flutter`.
   Nedávej ho do `C:\Program Files` (vadí mu oprávnění ani mezery v cestě).
3. Přidej `C:\src\flutter\bin` do proměnné **Path**:
   Start → napiš „proměnné prostředí“ → Upravit proměnné prostředí pro váš účet →
   Path → Upravit → Nový → `C:\src\flutter\bin` → OK.
4. Otevři **nový** příkazový řádek (PowerShell) a ověř: `flutter --version`

### 1.4 Android Studio
1. Stáhni z https://developer.android.com/studio a nainstaluj (výchozí volby).
2. Při prvním spuštění projdi průvodce – stáhne Android SDK.
3. V Android Studiu: **More Actions → SDK Manager → SDK Tools** a zaškrtni
   **Android SDK Command-line Tools (latest)** → Apply.
4. **Plugins** → vyhledej a nainstaluj **Flutter** (Dart se přidá sám).
5. V PowerShellu potvrď licence: `flutter doctor --android-licenses` (vše `y`).

### 1.5 Kontrola
```
flutter doctor
```
Zelené by měly být řádky **Flutter** a **Android toolchain**.
Řádky Chrome, Visual Studio a Xcode můžeš ignorovat.

### 1.6 Zařízení pro testování
- **Emulátor:** Android Studio → More Actions → Virtual Device Manager →
  Create device (např. Pixel 8, poslední verze Androidu).
- **Vlastní telefon (rychlejší):** Nastavení → O telefonu → 7× klepni na
  „Číslo sestavení“ → v Možnostech pro vývojáře zapni **Ladění USB** →
  připoj kabelem a povol ladění. `flutter devices` by ho měl ukázat.

---

## 2. Spuštění projektu

Rozbal projekt např. do `C:\dev\fitness_app` a v PowerShellu ve složce projektu spusť:

```powershell
# 1) Vygeneruje složky android/ a ios/ (tvoje soubory v lib/ nepřepíše).
#    Místo "cz.tvojejmeno" zvol vlastní identifikátor – později se špatně mění,
#    stane se z něj ID aplikace v obchodech (cz.tvojejmeno.fitness_app).
flutter create . --org cz.tvojejmeno --project-name fitness_app --platforms android,ios

# 2) Upraví nativní soubory pro upozornění a kalendář, stáhne balíčky
#    a vygeneruje překlady
dart run tool/setup_platforms.dart
flutter pub get
flutter gen-l10n

# 3) Vygeneruje kód databáze (lib/data/database.g.dart)
dart run build_runner build

# 4) Testy
flutter test

# 5) Spuštění na emulátoru nebo telefonu
flutter run
```

Při vývoji: v běžící aplikaci stiskni `r` (hot reload) nebo `R` (restart).

### Aktualizace na novou verzi
1. Nahraď v projektu všechno kromě složek `android`, `ios`, `build`
   a `.dart_tool` (tedy `lib`, `test`, `tool`, `docs`, `functions` a soubory
   v kořeni) obsahem nové verze.
2. Spusť:
   ```powershell
   dart run tool/setup_platforms.dart
   flutter pub get
   flutter gen-l10n
   dart run build_runner build
   flutter run
   ```
Skript `tool/setup_platforms.dart` upraví nativní soubory (oprávnění,
odkazy do aplikace, widget, Health Connect, přihlášení, jazyky); úpravy
jednotlivých modulů jsou v `tool/platform/`. Je bezpečné ho spustit opakovaně. Po jeho prvním spuštění
udělej jednou `flutter clean`.
Databáze se při spuštění sama převede na novou verzi, zapsaná data zůstanou.
Po každé změně v `lib/data/tables.dart` nebo `database.dart` znovu spusť krok 3.

Když něco selže, pošli Claudovi celý výpis chyby.

---

## 2a. Obrázky cviků z wger.de

Obrázky se stahují jednorázově na tvém PC a přibalí se do aplikace
(funguje pak i bez internetu):
```powershell
dart run tool/wger_import.dart
flutter run
```
Skript najde pro každý vestavěný cvik odpovídající cvik na wger.de, stáhne
až 2 obrázky do `assets/exercises/` a vygeneruje
`lib/data/seed/exercise_media.dart`. Přiřazení zkontroluj v
`tool/wger_report.csv` (sloupec wger_name); špatné oprav v mapě `_overrides`
na začátku skriptu (ID je v adrese `https://wger.de/en/exercise/<ID>/view/`)
a spusť ho znovu. Licence CC BY-SA vyžaduje uvést autora – aplikace ho
ukazuje pod obrázkem a v „O aplikaci“.

---

## 2b. iOS přes Codemagic

Na Windows iOS verzi sestavit nejde – potřebuje Mac. Codemagic je Mac
v cloudu: 500 minut buildů měsíčně zdarma (M2), bez platební karty.
Jeden build trvá zhruba 10–20 minut. Nastavení je v `codemagic.yaml`.

### Krok 1: kód na GitHub (jednorázově)
1. Založ si účet na github.com a vytvoř **soukromý** repozitář `fitness_app`
   (bez README, bez .gitignore – ten už v projektu je).
2. V `C:\dev\fitness_app` nejdřív spusť `dart run tool/setup_platforms.dart`
   (upraví i soubory pro iOS), pak:
   ```powershell
   git init
   git add .
   git commit -m "Fitness app"
   git branch -M main
   git remote add origin https://github.com/TVUJ_UCET/fitness_app.git
   git push -u origin main
   ```
3. Po každé další změně: `git add .`, `git commit -m "popis"`, `git push`.

### Krok 2: kontrolní build (zdarma, bez Apple účtu)
1. Na codemagic.io se přihlas přes GitHub a přidej aplikaci
   (Add application → GitHub → `fitness_app` → typ Flutter App).
2. Codemagic najde `codemagic.yaml`. Klikni **Start new build** a vyber
   workflow **iOS – kontrola buildu (bez podpisu)**.
3. Když build projde, iOS verze se přeloží. Když ne, pošli Claudovi log
   z kroku, který selhal.

Tenhle build nejde nainstalovat do iPhonu – jen ověří, že kód funguje i na iOS.

### Krok 3: instalace do iPhonu přes TestFlight (placený Apple účet)
1. **Apple Developer Program** (99 USD ročně) na developer.apple.com.
   Jako fyzická osoba se v App Store zobrazí tvoje jméno.
2. Zkontroluj Bundle ID: v `ios/Runner.xcodeproj/project.pbxproj` hledej
   `PRODUCT_BUNDLE_IDENTIFIER` (pro `--org cz.dedina` je to
   `cz.dedina.fitnessApp`). Stejné musí být v `codemagic.yaml`.
3. V App Store Connect → Apps → **+** → New App vytvoř aplikaci s tímto
   Bundle ID. Její **Apple ID** (číslo v App Information) zapiš do
   `codemagic.yaml` místo `0000000000`.
4. App Store Connect → Users and Access → Integrations → App Store Connect
   API → vytvoř klíč s rolí **App Manager** a stáhni soubor `.p8`.
5. V Codemagic: Team settings → Integrations → Developer Portal → Connect,
   název **codemagic**, vyplň Issuer ID, Key ID a nahraj `.p8`.
6. Spusť workflow **iOS – TestFlight**. Codemagic sám vytvoří certifikát
   a profil, sestaví aplikaci a nahraje ji do TestFlightu.
7. Do iPhonu nainstaluj aplikaci **TestFlight** a v App Store Connect
   (záložka TestFlight) se přidej jako interní tester.

---

## 2c. Jazyky

Aplikace se přepne podle jazyka telefonu; nepodporovaný jazyk = angličtina.
- Texty obrazovek: `lib/l10n/app_<jazyk>.arb` (zdroj je `app_en.arb`,
  popisy proměnných jsou jen v něm).
- Vestavěný obsah: čeština a angličtina v `lib/data/seed/`, ostatní jazyky
  v `seed_translations.dart`.
- Nový jazyk: přidej `app_<kód>.arb` se všemi klíči, doplň blok do
  `seed_translations.dart`, kód jazyka do `_languages` v
  `tool/setup_platforms.dart` a spusť `flutter gen-l10n`.
  Test `content_i18n_test.dart` ohlídá, že v obsahu nic nechybí.

Překlady připravil Claude; před vydáním je dobré nechat je projít rodilým
mluvčím (hlavně krátká tlačítka a názvy cviků).

---

## 3. Struktura projektu

```
lib/
  main.dart                 vstupní bod, lokalizace, téma
  router.dart               navigace (5 záložek + detail cviku)
  providers.dart            Riverpod providery (propojení UI a databáze)
  core/
    formulas.dart           1RM (Epley), kalorie (MET), klouzavý průměr
    wellbeing.dart          situace podle období (nemoc, po nemoci, dieta)
    injury.dart             zranění podle partie (grafy, upozornění)
    date_utils.dart         začátek/konec dne
  data/
    enums.dart              výčty (partie, vybavení, typ období...)
    tables.dart             tabulky databáze podle specifikace
    database.dart           databáze, počáteční data, dotazy
    seed/seed_data.dart     53 cviků + 3 domácí 5min rutiny
    seed/seed_instructions.dart  návody ke cvikům (CZ/EN)
    seed/plan_templates.dart     hotové programy pro začátečníky
    seed/seed_translations.dart  cviky, návody a programy v de/es/fr
    seed/content_i18n.dart       výběr jazyka obsahu, hledání cviků
  services/
    notification_service.dart    upozornění (ráno, pauza, voda)
    calendar_service.dart        zápis tréninků do kalendáře
    sync_controller.dart         přeplánování po změně dat
  l10n/
    app_*.arb               texty aplikace (en, cs, de, es, fr)
  ui/                       téma, navigace, sdílené widgety
  features/
    today/                  Dnes: dnešní trénink, pitný režim, váha, období
    plans/                  seznam plánů, editor plánu, editor sérií cviku
    workout/                průběh tréninku, časovač pauzy, souhrn a PR
    exercises/              knihovna cviků, detail, výběr cviku
    progress/               grafy (váha, síla, frekvence) a historie
    planb/                  plán B – 5 minut doma
    profile/                Profil: jméno, sledované funkce, nastavení
    onboarding/             úvodní průvodce při prvním spuštění
    periods/                období (nemoc, zranění, dieta…)
test/
  formulas_test.dart        testy výpočtů (1RM, kalorie, data)
  helpers_test.dart         testy dnů v týdnu a formátování
  wellbeing_test.dart       testy určení situace (nemoc, po nemoci…)
  charts_data_test.dart     testy dat pro grafy
  injury_test.dart          testy zranění podle partie
  content_i18n_test.dart    testy překladů obsahu a hledání
tool/
  setup_platforms.dart      úprava Android/iOS souborů pro pluginy
codemagic.yaml              buildy pro iOS v cloudu
```

## 4. Použité balíčky

| Balíček | Účel |
| --- | --- |
| flutter_riverpod | stav aplikace |
| go_router | navigace |
| drift + drift_flutter | lokální SQLite databáze |
| intl, flutter_localizations | překlady, formátování čísel |
| flutter_local_notifications, timezone | upozornění |
| device_calendar_plus | kalendář (zápis i čtení) |
| app_links, url_launcher | odkazy do aplikace, otevření webu |
| share_plus, path_provider, file_picker | sdílení, export, záloha |
| home_widget | widget na plochu (Android) |
| health | Health Connect / Apple Zdraví |
| firebase_*, google_sign_in, sign_in_with_apple | přátelé a výzvy |
| qr_flutter, mobile_scanner | QR kód přítele |

## 5. Co musíš nastavit ručně

- **Doména webu a odkazy do obchodů:** `kWebBaseUrl`, `kPlayStoreUrl`,
  `kAppStoreUrl` v `lib/modules/links/deep_links.dart`, název na kartách
  (`kShareAppName`) a stejné údaje v `docs/web/challenge.html`.
- **Přátelé:** Firebase podle `docs/social.md`.
- **Health Connect:** v Google Play Console vyplnit prohlášení o zdravotních
  oprávněních; u Applu zapnout HealthKit pro App ID `cz.dedina.fitnessApp`.
- **iOS:** pro Firebase, Health a Apple přihlášení zapnout v Apple Developer
  u App ID schopnosti Push Notifications, HealthKit a Sign in with Apple.

## 6. Další kroky

1. První build, oprava chyb z překladače, testování na telefonu.
2. Kontrola překladů rodilými mluvčími.
3. Animace cviků (Gym Visual / ExerciseAnimatic).
4. Reklamy a Premium (až s živnostenským listem).
