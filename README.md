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
- **Supersérie:** v editoru plánu (ikona řetězu u cviku → „Spojit s dalším
  cvikem“) i během tréninku jde spojit 2–3 po sobě jdoucí cviky (A1, A2…).
  V tréninku jsou v jednom rámečku, střídají se (po A1 se navrhne stejné kolo
  A2) a pauza začne až po posledním cviku kola (podle jeho pauzy).
- **Drop série:** v plánu i v tréninku („Drop série“ za odškrtnutou sérií
  předvyplní váhu o 20 % nižší, zaokrouhlenou na kotouče); štítek „Drop série“,
  pauza až po poslední drop sérii. Počítají se do objemu, ne do rekordů,
  odhadu 1RM, žebříčku posilovny a výzev.
- **Únava svalů:** karta „Regenerace svalů“ na obrazovce Dnes (partie od
  nejunavenější, stav zotaveno / regeneruje se / unaveno s ikonou a %),
  odhad z tréninků za 7 dní (vedlejší partie, drop série, poločas 24/36 h,
  pocit po tréninku); před tréninkem podle plánu jemné upozornění, když je
  partie unavená z ≥ 80 % (trénovat / plán B / odložit); nápověda v editoru
  plánu.
- **Souhrn po tréninku:** délka, počet sérií, objem, odhad kalorií,
  nové osobní rekordy (odhad 1RM) a volitelný pocit (lehké / akorát /
  náročné).
- **Dnes:** dnešní plány podle dnů v týdnu, pokračování rozpracovaného
  tréninku, pitný režim, váha, aktuální období.
- **Druh série celým slovem:** rozcvička a drop série mají místo čísla ikonu
  a štítek „Rozcvička“ / „Drop série“ (v tréninku, editoru plánu i v popisu
  sérií); v aplikaci nejsou jednopísmenné ani tečkové zkratky (jen jednotky
  jako kg, lb, ml, min, s a 1RM).
- **Progresivní přetížení:** karta na obrazovce Pokrok – pro každou partii
  (hlavní partie cviků) porovná poslední 2 týdny s 2 týdny předtím: objem
  pracovních sérií (drop série se počítají) a odhad 1RM cvik po cviku.
  Stav slovem i ikonou: zlepšuje se (objem +2,5 % nebo 1RM cviku +1 %),
  stagnuje, klesá (objem −10 % bez zlepšení 1RM), drží (pokles v dietě)
  a důvod („Bench press: 1RM +3 %“, „Objem +8 %“). Týdny s nemocí, pauzou
  nebo zraněním partie se vynechají. Stagnace 3+ týdny → tip (přidat
  1–2 opakování / sérii / 2,5 kg či 5 lb). Se zapnutou ranní připomínkou
  přijde v pondělí ráno týdenní souhrn.
- **Odznaky:** série týdnů s progresem (2–52 týdnů), mistr partie (8 týdnů
  progresu či udržení, z toho 4 s progresem), osobní rekordy (1, 10, 50)
  a pravidelnost podle plánu (4, 12, 26 týdnů). Nové odznaky se ukážou
  v souhrnu po tréninku se sdílením obrázku; galerie (získané barevně
  s datem, zamčené šedě s návodem a postupem) z obrazovky Pokrok i z Profilu.
- **Vzhled:** v Profilu světlý / tmavý / podle systému; tmavý motiv pro
  všechny obrazovky, karty a grafy.
- **Tón zpráv:** v onboardingu i v Profilu „Přátelský“ nebo „Přísný
  trenér“ – hravý sarkasmus („Gauč tě určitě vytrénuje sám.“) po
  vynechání/odložení tréninku, v ranní připomínce, připomínkách pití, po
  plánu B, v souhrnu po tréninku, v tipech při stagnaci a v dialogu únavy
  (tam přísně doporučí odpočinek). Všechny texty: docs/coach_tone.md. Bez urážek
  a vulgarismů; při nemoci, zranění, 7 dní po nemoci a při únavě partie
  ≥ 80 % se vždy použije přátelský text – zdraví má přednost.
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
- **Cviky:** knihovna 55 cviků s návodem (CZ/EN), hledáním a filtrem.
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
- **Jazyky:** 10 jazyků (EN, CS, DE, ES, FR, PL, PT-BR, IT, SK, NL) –
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
  výzvy, žebříček přátel (tréninky, objem), společný streak a žebříček
  posilovny (odhad 1RM v 16 cvicích – bench, dřep, mrtvý tah, tlaky,
  bicepsové zdvihy, shyby a dipy se zátěží… – a tréninky v měsíci, filtr
  pohlaví a věku, „Překonej mě“). Než se nastaví Firebase
  (`docs/social.md`), aplikace funguje dál a sekce Přátelé jen hlásí,
  že není nastavená.
- **Automatická progrese:** po tréninku podle plánu navrhne v souhrnu
  („Příště“) nové cíle cviků – dvojitá progrese v rozsahu opakování,
  přírůstek podle partie a vybavení, odlehčení o 10 % po 2 neúspěších;
  při nemoci, zranění partie, zotavování a dietě „drží“. Režim v Profilu
  (vypnuto / navrhovat / použít automaticky s „Vrátit“), nastavení u cviku
  v editoru plánu, štítek čekajícího návrhu v editoru plánu (schéma v10).
- **Záloha do cloudu:** automatická záloha databáze do Firebase Cloud
  Storage (po tréninku a jednou denně, volitelně jen přes Wi-Fi), obnovení
  na novém telefonu (`docs/social.md`, „Automatická záloha“).
- **Hodinky Wear OS:** aplikace pro hodinky ve složce `wear/` – zápis
  sérií, úprava váhy a opakování, pauza (`docs/wear_os.md`).
- **Premium:** připravené, ale vypnuté (`kPremiumLaunched = false`) –
  kapitola 5a. Automatická progrese, automatická záloha do cloudu
  a hodinky budou po spuštění součástí Premium; obnovení existující
  zálohy zůstane vždy zdarma.
- **Jazyky:** angličtina, čeština, němčina, španělština, francouzština,
  polština, portugalština (Brazílie), italština, slovenština, nizozemština.

Na iOS zatím není widget a Live Activity (potřebují Xcode na Macu).
Reklamy nejsou součástí verzí 2 a 3; Premium je v kódu, ale vypnuté.

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

Když má cvik na wger.de animovaný GIF / WebP, skript ho stáhne přednostně
(v aplikaci se pak přehrává animace místo střídání dvou obrázků). Seznam
stažených obrázků se ukládá do `tool/media/wger_media.json`.

### Animace cviků z koupeného balíčku (Gym Visual, ExerciseAnimatic)

Aplikace umí přehrát animovaný GIF nebo WebP (klepnutím se animace
zastaví / spustí). Postup:

1. Kup balíček animací s licencí pro použití v mobilní aplikaci
   (např. Gym Visual <https://www.gymvisual.com> nebo ExerciseAnimatic).
   Licenci si přečti – obvykle zakazuje
   soubory dál šířit jinak než uvnitř aplikace.
2. Vyber soubory pro cviky z aplikace a dej je do jedné složky, např.
   `C:\animace`. Pojmenuj je podle slugu cviku: `bench_press.gif`,
   `back_squat.webp`, … (seznam slugů je v `lib/data/seed/seed_data.dart`,
   první text v každém `SeedExercise(...)`). Velikost písmen, mezery
   a pomlčky nevadí: `Bench-Press.GIF` = `bench_press`.
3. Když nechceš soubory přejmenovávat, vytvoř `udaje.csv`:
   ```csv
   slug,file,author,license,author_url,source_url
   *,,Gym Visual,,,https://www.gymvisual.com
   bench_press,0025-barbell-bench-press.gif,,,,
   back_squat,0043-barbell-full-squat.gif,,,,
   ```
   Řádek s `*` platí pro všechny soubory (autor, licence, odkaz). Prázdné
   buňky se doplní z něj. Místo CSV jde i JSON se stejnými údaji.
4. Spusť z kořene projektu:
   ```powershell
   dart run tool/media_import.dart C:\animace --author "Gym Visual" --url https://www.gymvisual.com
   # nebo s údaji ze souboru
   dart run tool/media_import.dart C:\animace --meta C:\animace\udaje.csv
   flutter run
   ```
   Skript zkopíruje soubory do `assets/exercises/<slug>.gif` (nebo `.webp`),
   zapíše `tool/media/purchased_media.json` a přegeneruje
   `lib/data/seed/exercise_media.dart`. Koupená animace má přednost před
   obrázky z wger.de; cviky bez animace dál ukazují obrázky z wger.de.
   Na konci vypíše cviky, které ještě žádnou ukázku nemají.
5. Další balíček přidáš stejným příkazem (nové soubory se přidají nebo
   přepíšou starší). `--replace` smaže všechny dřív importované animace
   a začne znovu. Pozdější `dart run tool/wger_import.dart` koupené
   animace nepřepíše.

Tipy: GIF bývá velký (kolem 1 MB). Skript upozorní, když obrázky cviků
přesáhnou 40 MB – pak je převeď na animovaný WebP (výrazně menší) nebo
zmenši na šířku kolem 480 px (např. `ffmpeg -i in.gif -vf scale=480:-1
-loop 0 out.webp`). Pod animací aplikace ukazuje „Animace: autor“
(a licenci, je-li vyplněná); klepnutí otevře odkaz `source_url`.

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
    seed/seed_data.dart     55 cviků + 3 domácí 5min rutiny
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
| firebase_storage, connectivity_plus, device_info_plus | záloha do cloudu (Wi-Fi, název zařízení) |
| qr_flutter, mobile_scanner | QR kód přítele |
| watch_connectivity | spojení s hodinkami Wear OS (i ve `wear/`) |
| wear_plus (jen `wear/`) | kulatý displej a úsporný režim hodinek |
| purchases_flutter | předplatné Premium (RevenueCat), zatím vypnuté |

## 5. Co musíš nastavit ručně

- **Doména webu a odkazy do obchodů:** `kWebBaseUrl`, `kPlayStoreUrl`,
  `kAppStoreUrl` v `lib/modules/links/deep_links.dart`, název na kartách
  (`kShareAppName`) a stejné údaje v `docs/web/challenge.html`.
- **Přátelé:** Firebase podle `docs/social.md`.
- **Záloha do cloudu:** Cloud Storage v EU a nasazení `storage.rules`
  (`docs/social.md`, kapitola „Automatická záloha“).
- **Health Connect:** v Google Play Console vyplnit prohlášení o zdravotních
  oprávněních; u Applu zapnout HealthKit pro App ID `cz.dedina.fitnessApp`.
- **iOS:** pro Firebase, Health a Apple přihlášení zapnout v Apple Developer
  u App ID schopnosti Push Notifications, HealthKit a Sign in with Apple.
- **Hodinky (Wear OS):** samostatný projekt ve složce `wear/` – sestavení,
  spárování emulátorů a vydání v Google Play podle `docs/wear_os.md`.
- **Premium (až bude živnostenský list):** viz kapitola 5a.

## 5a. Premium (zatím vypnuté)

Aplikace je teď celá zdarma: v `lib/premium/premium.dart` je
`kPremiumLaunched = false`, takže je vše odemčené a nikde se neukáže
nákup ani paywall. Zapisování tréninků zůstane zdarma vždy.

**Premium na půl roku zdarma pro první uživatele:** po dokončení
úvodního nastavení (stávající uživatelé při prvním otevření po
aktualizaci) se jednou ukáže hláška „Premium na půl roku zdarma“ a do
profilu se uloží datum konce (`UserProfiles.premiumGiftUntil`, 6 měsíců).
V Profilu je pak řádek „Premium zdarma – platí do …“. Dárek se dává jen
dokud je `kPremiumLaunched = false`; po spuštění plateb se dodrží
(funkce zůstanou odemčené do uloženého data) a noví uživatelé už
dostanou jen zkušební měsíc z obchodu. Dárek je uložený v telefonu
(a v záloze), ne v RevenueCat – kdo aplikaci přeinstaluje bez obnovení
zálohy, o něj po spuštění plateb přijde.

Co bude v Premium (roční předplatné 8 USD / 8 EUR, první měsíc zdarma):
neomezeně vlastních plánů (zdarma 3), všechny hotové programy (zdarma 2),
víc rutin plánu B (zdarma 3), pruhy období v grafech, celá historie grafů
(zdarma 30 dní), automatické postřehy, návrhy volného času z kalendáře,
export CSV, automatické navyšování zátěže, automatická záloha do cloudu
a aplikace pro hodinky Wear OS.

Spuštění:
1. Google Play Console a App Store Connect: vytvoř roční předplatné
   (stejné ID produktu, např. `premium_yearly`) se zkušební dobou 1 měsíc
   a cenou 8 USD / 8 EUR. U Applu je potřeba smlouva „Paid Apps“
   a bankovní / daňové údaje.
2. <https://app.revenuecat.com>: nový projekt, přidej aplikace Android
   (`cz.dedina.fitness_app`, servisní účet Google Play) a iOS
   (`cz.dedina.fitnessApp`, klíč App Store Connect API). Vytvoř
   entitlement `premium`, k němu oba produkty a nabídku (Offering)
   „default“ s balíčkem typu Annual.
3. Veřejné API klíče z RevenueCat (Project settings → API keys) vlož do
   `kRevenueCatAndroidKey` a `kRevenueCatIosKey` v
   `lib/premium/premium.dart` a přepni `kPremiumLaunched = true`.
4. Doplň skutečné adresy podmínek a zásad ochrany soukromí
   (`kPremiumTermsUrl`, `kPremiumPrivacyUrl` v
   `lib/premium/premium_screen.dart`).
5. Otestuj nákup testovacím účtem (Google Play: licenční testeři,
   iOS: Sandbox v TestFlightu).

Bez vyplněných klíčů aplikace nespadne, jen nákup nebude dostupný.

## 6. Další kroky

1. První build, oprava chyb z překladače, testování na telefonu.
2. Kontrola překladů rodilými mluvčími.
3. Animace cviků: koupit balíček a naimportovat (kapitola 2a).
4. Spuštění Premium (kapitola 5a, až s živnostenským listem).
