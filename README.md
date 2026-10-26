# GymBar

Gym tracker s obdobími (nemoc, cut, bulk), pitným režimem a plánem B.
Specifikace: dokument „Fitness aplikace – specifikace“ v Claude.

Stav: **verze 0.3.x** – MVP + vše z verzí 2 a 3 specifikace, sociální část
(přátelé, výzvy, žebříčky posiloven, srovnání se zemí a světem), trenéři
(aplikace i web gymbar.app/trener), materiály pro fitka (gymbar.app/fitka)
a motivy vzhledu. Premium je připravené, ale zatím nespuštěné
(`kPremiumLaunched = false`), reklamy nejsou. Každý push ověřuje CI
(analýza, testy, sestavení APK telefonu i hodinek).

Funguje:
- **Plány:** vytvoření, přejmenování, smazání, tréninkové dny, plánovaný čas,
  změna pořadí cviků tažením.
- **Série v plánu:** každá série má vlastní počet opakování, cílovou váhu
  a může být rozcvičková; převzetí z minulého tréninku; orientační návrh vah
  podle osobního rekordu; u cviku je vidět rekord (nejtěžší série) a poslední výkon.
- **Trénink:** spuštění z plánu, z obrazovky Dnes i bez plánu; zápis sérií
  s předvyplněním z minula, sloupec „Minule“, časovač pauzy (−15 / +15 /
  přeskočit), přidání cviku i série během tréninku, pokračování po zavření
  aplikace, zahození tréninku.
- **Cíl tréninku:** Síla / Svaly / Výdrž – volí se v úvodu a v Profilu,
  plán může mít vlastní zaměření (editor plánu, schéma v23) a nahoře
  v tréninku jde změnit jen pro daný trénink. Podle zaměření se počítají
  pauzy, varianta hotových programů a tempo automatické progrese.
- **Automatické pauzy:** podle zaměření tréninku (síla = dlouhé, výdrž =
  krátké). Pauza se počítá podle náročnosti
  cviku (těžký vícekloubový → izolovaný → střed těla → kondiční), zaměření
  a volitelného pohlaví v profilu (ženy −15 %). V editoru cviku v plánu jde
  přepnout na ruční pauzu (`core/rest_time.dart`, schéma v14).
- **Supersérie:** v editoru plánu (ikona řetězu u cviku → „Spojit s dalším
  cvikem“) i během tréninku jde spojit 2–3 po sobě jdoucí cviky (A1, A2…).
  V tréninku jsou v jednom rámečku, střídají se (po A1 se navrhne stejné kolo
  A2) a pauza začne až po posledním cviku kola (podle jeho pauzy).
- **Drop série:** v plánu i v tréninku („Drop série“ za odškrtnutou sérií
  předvyplní váhu o 20 % nižší, zaokrouhlenou na kotouče); štítek „Drop série“,
  pauza až po poslední drop sérii. Počítají se do objemu, ne do rekordů,
  žebříčku posilovny a výzev.
- **Únava svalů:** karta „Regenerace svalů“ na obrazovce Dnes (partie od
  nejunavenější, stav zotaveno / regeneruje se / unaveno s ikonou a %),
  odhad z tréninků za 7 dní (vedlejší partie, drop série, poločas 24/36 h,
  pocit po tréninku); před tréninkem podle plánu jemné upozornění, když je
  partie unavená z ≥ 80 % (trénovat / plán B / odložit); nápověda v editoru
  plánu.
- **Souhrn po tréninku:** délka, počet sérií, objem, odhad kalorií,
  nové osobní rekordy (nejtěžší série) a volitelný pocit (lehké / akorát /
  náročné).
- **Dnes:** dnešní plány podle dnů v týdnu, pokračování rozpracovaného
  tréninku, pitný režim, váha, aktuální období.
- **Druh série celým slovem:** rozcvička a drop série mají místo čísla ikonu
  a štítek „Rozcvička“ / „Drop série“ (v tréninku, editoru plánu i v popisu
  sérií); v aplikaci nejsou jednopísmenné ani tečkové zkratky (jen jednotky
  jako kg, lb, ml, min a s).
- **Progresivní přetížení:** karta na obrazovce Pokrok – pro každou partii
  (hlavní partie cviků) porovná poslední 2 týdny s 2 týdny předtím: objem
  pracovních sérií (drop série se počítají) a nejtěžší váhu cvik po cviku.
  Stav slovem i ikonou: zlepšuje se (objem +2,5 % nebo nejtěžší váha cviku +1 %),
  stagnuje, klesá (objem −10 % bez zlepšení váhy), drží (pokles v dietě)
  a důvod („Bench press: nejtěžší váha +3 %“, „Objem +8 %“). Týdny s nemocí, pauzou
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
- **Pokrok:** grafy váhy (průměr za 7 dní + denní vážení), síly (nejtěžší série
  zvoleného cviku) a počtu tréninků za týden; období (nemoc, dieta…) jsou
  v grafech vybarvená pruhem. Pod grafy historie tréninků.
- **Období:** nemoc, zranění, dieta, nabírání, udržování, pauza (přidat,
  ukončit, upravit, smazat) – ikona vlajky na obrazovce Dnes nebo Profil.
  U zranění se vybírá partie: v grafu síly se zranění ukáže jen u cviků
  na tuto partii a v tréninku je u nich upozornění.
- **Povzbuzení:** při nemoci, zranění, do 7 dní po nemoci a v dietě
  povzbuzující hlášky na obrazovce Dnes, během tréninku a v souhrnu.
- **Úvodní průvodce:** při prvním spuštění krok za krokem (Další / Zpět,
  ukazatel kroků): jméno, rok narození, pohlaví, jednotky → cíl tréninku →
  úroveň pokročilosti →
  co sledovat (pitný režim, váha, období a povzbuzení, kalorie; vypnuté
  funkce se skryjí) → pitný režim a váha (jen když se sledují) → motiv
  vzhledu (aplikace se hned přebarví) → tón zpráv → připomínky a kalendář
  (s povolením) → první plán z hotového programu pro zvolenou úroveň
  a cíl → shrnutí.
  Vše je nepovinné a jde změnit v Profilu; tam je i „Průvodce nastavením“
  pro nové projití (`lib/features/onboarding/onboarding_screen.dart`).
- **Odložení / vynechání tréninku:** z obrazovky Dnes (menu ⋮ u plánu),
  s uklidňující hláškou a možností vrátit.
- **Cviky:** knihovna 170 cviků s návodem (10 jazyků), hledáním a filtrem.
- **Hotové programy (17 programů, 39 tréninků):** pro začátečníky (Celé
  tělo 3× a jeho obměna, Celé tělo 2×, Jednoručky doma, Vlastní váha doma,
  Stroje, Síla 5×5, Kruhový trénink), mírně pokročilé (Horní/dolní 4×,
  Push/Pull/Nohy a jejich obměny, Síla – týdenní vlny, Kondice – intervaly)
  a pokročilé (PHUL, Síla – 4 dny, PPL 6× týdně). Při přidání se vybere
  cíl (síla: 4 × 5–6 u hlavních cviků, svaly: hodnoty programu, výdrž:
  3 × 12–20, delší výdrže) a dny; počet sérií se upraví podle úrovně.
  Programy se silovým / kondičním zaměřením mají cíl pevný. Výběr
  i zdroje: `docs/programs.md`, `lib/data/seed/plan_templates.dart`.
- **Úroveň pokročilosti:** začátečník / mírně pokročilý / pokročilý –
  v úvodu a v Profilu (i s tím, kolik zbývá do další). Po půl roce
  pravidelného tréninku aplikace na Dnes navrhne postup, po 12 týdnech
  pauzy návrat o úroveň níž (`lib/core/experience_level.dart`, schéma v25).
- **Plán B:** 5minutová domácí rutina s časovačem (práce/pauza); po dokončení
  nabídne přesun plného tréninku na zítřek.
- **Upozornění:** ranní připomínka ve dny tréninku (s ohledem na nemoc),
  konec pauzy i při zamčeném telefonu, připomínky pití.
- **Kalendář:** naplánované tréninky na 14 dní se zapisují do kalendáře
  telefonu a při změně plánu se samy upraví.
- **Pitný režim:** ve dny tréninku se cíl zvýší o 500 ml.
- **Soukromí:** bez účtu je vše jen v telefonu; cloudové funkce (záloha,
  přátelé, žebříčky, trenér) posílají na server jen to, co popisují zásady
  ochrany soukromí (`docs/web/privacy.html`). V Profilu jde smazat všechna
  data i účet.
- **Jazyky:** 10 jazyků (EN, CS, DE, ES, FR, PL, PT-BR, IT, SK, NL) –
  podle jazyka telefonu. Přeložené jsou i názvy cviků, návody, programy
  a rutiny plánu B; cvik jde vyhledat v kterémkoli jazyce i bez diakritiky.

Verze 2 a 3 (moduly v `lib/modules/`):
- **Statistiky:** objem po týdnech a partiích, kalendář aktivity, jak často
  trénuješ kterou partii, automatické postřehy (návrat po nemoci, shrnutí
  diety a nabírání, nové rekordy, pravidelnost, zanedbaná partie, příliš
  rychlé hubnutí), obrazovka Osobní rekordy, historie a graf nejtěžší série v detailu
  cviku, streak týdnů na obrazovce Dnes.
- **Sdílení a výzvy:** obrázek rekordu a tréninku ke sdílení, výzva odkazem
  („Překonáš mě?“), přijetí výzvy z odkazu, aktivní výzvy s postupem na Dnes.
  Stránka webu pro odkazy: `docs/web/challenge.html`.
- **Kalendář a upozornění:** volný čas a kolize z kalendáře, návrh času
  v editoru plánu, varování na Dnes, kolize v ranní připomínce, tlačítka
  v upozornění (Počítám s tím / Přesunout / Dnes nestíhám), odpočet pauzy
  na zamčené obrazovce (Android), připomínky pití od–do po zvoleném intervalu.
- **Widget na plochu (Android):** voda a dnešní trénink, tlačítko + sklenice.
  Pro iOS je widget i Live Activity odpočtu pauzy hotový, zapne se po
  registraci App Group v Apple Developer účtu (`docs/ios_widget.md`).
- **Health Connect / Apple Zdraví:** zápis tréninků, výměna tělesné váhy.
- **Data:** export CSV, záloha a obnova (soubor do Disku/iCloudu), vlastní
  cviky, jednotky kg/lb a ml/oz, vlastní objem sklenice a láhve.
- **Přátelé (Firebase):** přihlášení Google/Apple, přátelé přes QR nebo
  odkaz, pozvánky na trénink do kalendáře, upozornění na rekordy přátel,
  výzvy, žebříček přátel (tréninky, objem), společný streak a žebříček
  posilovny (nejtěžší váha v 16 cvicích – bench, dřep, mrtvý tah, tlaky,
  bicepsové zdvihy, shyby a dipy se zátěží… – a tréninky v měsíci, filtr
  pohlaví a věku, „Překonej mě“). Adresář posiloven je předplněný
  z OpenStreetMap pro Evropu a Ameriku (posilovny v okolí podle polohy,
  kontrola duplicit, nahlášení „neexistuje“; `docs/gyms_import.md`).
  Než se nastaví Firebase
  (`docs/social.md`), aplikace funguje dál a sekce Přátelé jen hlásí,
  že není nastavená.
- **Automatická progrese:** po tréninku podle plánu navrhne v souhrnu
  („Příště“) nové cíle cviků – dvojitá progrese v rozsahu opakování,
  přírůstek podle partie a vybavení, odlehčení o 10 % po 2 neúspěších;
  podle zaměření: síla úzký rozsah (váha roste častěji), výdrž široký
  rozsah a opakování po 2 (čas po 10 s);
  při nemoci, zranění partie, zotavování a dietě „drží“. Režim v Profilu
  (vypnuto / navrhovat / použít automaticky s „Vrátit“), nastavení u cviku
  v editoru plánu, štítek čekajícího návrhu v editoru plánu (schéma v10).
- **Záloha do cloudu:** automatická záloha databáze do Firebase Cloud
  Storage (po tréninku a jednou denně, volitelně jen přes Wi-Fi), obnovení
  na novém telefonu (`docs/social.md`, „Automatická záloha“).
- **Trenér a klienti:** kdokoli se stane trenérem (zdarma; bez klienta
  60 dní status zanikne), klient se připojí kódem / QR / odkazem a souhlasí
  se sdílením tréninků (váha zvlášť). Trenér vidí klienty, grafy, rekordy
  a historii v aplikaci i na webu gymbar.app/trener, píše komentáře
  a posílá plány, které se klientovi samy uloží; plán jde sdílet i odkazem
  (`docs/coach.md`).
- **Hodinky Wear OS:** aplikace pro hodinky ve složce `wear/` – zápis
  sérií, úprava váhy a opakování, pauza, tep během tréninku a dlaždice
  „Dnes“ s dnešním plánem (`docs/wear_os.md`).
- **Apple Watch:** aplikace pro hodinky (`ios/GymBarWatch`, SwiftUI) se
  stejnými funkcemi a tepem; zapne se po registraci App ID v Apple
  Developer účtu (`docs/apple_watch.md`).
- **Regenerace z hodinek a prstenů:** z Health Connect / Apple Zdraví čte
  spánek, HRV a klidový tep (Galaxy Watch, Apple Watch, Garmin, Oura,
  Galaxy Ring…), porovná je s vlastním normálem za 60 dní a na Dnes ukáže
  připravenost s doporučením; při slabší regeneraci nabídne lehčí trénink
  (o třetinu méně sérií, váhy −10 %, progrese drží) nebo Plán B. Tep
  během tréninku v souhrnu (průměr, maximum, zóny, energie) –
  `docs/readiness.md`.
- **Premium:** připravené, ale vypnuté (`kPremiumLaunched = false`) –
  kapitola 5a. Automatická progrese, automatická záloha do cloudu
  a hodinky budou po spuštění součástí Premium; obnovení existující
  zálohy zůstane vždy zdarma.
- **Jazyky:** angličtina, čeština, němčina, španělština, francouzština,
  polština, portugalština (Brazílie), italština, slovenština, nizozemština.

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
stažených obrázků se ukládá do `tool/media/wger_media.json`. Obrázky se
stahují nejdřív do dočasné složky; když stažení cviku selže (výpadek sítě),
cvik si ponechá předchozí obrázky a stačí skript spustit znovu.

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
   animace nepřepíše. Skript nejdřív zkontroluje všechny soubory (např.
   chybějícího autora) – při chybě se nic nezmění; staré soubory maže až
   po úspěšném importu.

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
   git commit -m "GymBar"
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
   `codemagic.yaml` místo `0000000000` (nech uvozovky; dokud tam jsou
   nuly, workflow hned skončí s upozorněním). Na šifrování (Export
   Compliance) se TestFlight u každého buildu ptát nebude – odpověď
   „jen standardní šifrování“ je v `Info.plist`
   (`ITSAppUsesNonExemptEncryption`, doplní `tool/setup_platforms.dart`).
4. App Store Connect → Users and Access → Integrations → App Store Connect
   API → vytvoř klíč s rolí **App Manager** a stáhni soubor `.p8`.
5. V Codemagic: Team settings → Integrations → Developer Portal → Connect,
   název **codemagic**, vyplň Issuer ID, Key ID a nahraj `.p8`.
6. Spusť workflow **iOS – TestFlight**. Codemagic sám vytvoří certifikát
   a profil, sestaví aplikaci a nahraje ji do TestFlightu.
7. Do iPhonu nainstaluj aplikaci **TestFlight** a v App Store Connect
   (záložka TestFlight) se přidej jako interní tester.

---

## 2d. Vydání pro Android (Google Play)

### Krok 1: upload klíč (jednorázově, na tvém PC)
Klíč podepisuje každou verzi, kterou nahraješ do Google Play. Google pak
aplikaci podepíše svým klíčem (Play App Signing), takže při ztrátě
upload klíče jde požádat o nový – i tak ho **zálohuj** (soubor i hesla
do správce hesel a mimo počítač).

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v `
  -keystore $HOME\upload-keystore.jks -storetype JKS `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Vytvoř soubor `android\key.properties` (je v `.gitignore`, do gitu
nepatří):

```properties
storePassword=<heslo z keytoolu>
keyPassword=<heslo z keytoolu>
keyAlias=upload
storeFile=C:/Users/<tvé jméno>/upload-keystore.jks
```

`storeFile` musí být **absolutní cesta** (s lomítky `/`) – relativní cestu
by Gradle hledal ve složce `app` projektu, který se zrovna sestavuje
(u hodinek ve `wear\android\app`), a podpis by selhal.

Pak `dart run tool/setup_platforms.dart` – doplní do
`android/app/build.gradle.kts` načtení klíče (bez `key.properties` se
release dál podepisuje ladicím klíčem, takže `flutter run --release`
funguje jako dosud). Změněný `build.gradle.kts` commitni.

### Krok 2: build
```powershell
flutter build appbundle --release
```
Výsledek: `build\app\outputs\bundle\release\app-release.aab`.
Před každým nahráním zvyš v `pubspec.yaml` číslo za `+`
(`version: 0.1.0+1` → `0.1.0+2`); Google Play stejné číslo dvakrát
nepřijme. Číslo před `+` je verze, kterou vidí uživatelé.

### Krok 3: Google Play Console
1. Účet vývojáře na <https://play.google.com/console> (25 USD jednorázově,
   ověření totožnosti).
2. *Vytvořit aplikaci* → název, jazyk, aplikace, zdarma.
3. *Obsah aplikace* – podklady jsou v dokumentu „Texty a formuláře pro
   obchody“ (`docs/store/`):
   - Zásady ochrany soukromí → adresa `/privacy` (`docs/web/privacy.html`),
   - Smazání účtu → adresa `/delete-account`
     (`docs/web/delete-account.html`),
   - Bezpečnost dat, Health Connect, hodnocení obsahu (dotazník), cílová
     skupina 16+, reklamy: ne.
4. *Hlavní záznam v obchodu* – texty z `docs/store/google_play/<lokalizace>/` (přidej
   i další jazyky záznamu podle `docs/store/README.md`), ikona
   512 × 512, grafika 1024 × 500, aspoň 2 snímky obrazovky.
5. *Testování → Interní testování* → nahraj první `.aab` **ručně**.
   U nového osobního účtu pak Google vyžaduje uzavřené testování
   (naposledy 12 testerů po 14 dní), než povolí produkční vydání –
   pravidla si ověř přímo v konzoli.

### Krok 4 (volitelné): automatické nahrávání z Codemagicu
Workflow `android-release` v `codemagic.yaml` sestaví `.aab` a nahraje ho
do interního testování jako koncept.
1. Codemagic → Team settings → *Code signing identities* → *Android
   keystores*: nahraj `upload-keystore.jks`, hesla, alias `upload`,
   název reference `upload_keystore`.
2. Servisní účet pro Google Play API: v Google Cloud konzoli zapni
   **Google Play Android Developer API**, vytvoř servisní účet a klíč JSON
   (Google ho stáhne jako `<projekt>-<čísla>.json` – nech ho mimo projekt,
   nebo ho přejmenuj na `play-service-account.json`, ten je v `.gitignore`);
   v Play Console → *Uživatelé a oprávnění* → pozvat e-mail servisního
   účtu s oprávněním vydávat do testovacích stopáží.
   `PACKAGE_NAME` v `codemagic.yaml` musí sedět s `applicationId`.
3. Codemagic → aplikace → *Environment variables*: skupina
   `google_play`, proměnná `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` = celý obsah
   JSON (označit jako Secret).
4. *Start new build* → workflow „Android – Google Play“. Číslo buildu si
   workflow vezme samo (poslední v Google Play + 1).

Workflow běží na Macu M2 (Linux bývá jen v placeném tarifu), takže
čerpá stejných 500 minut zdarma jako iOS buildy.

Hodinky: aplikace z `wear/` se nahrává do stejné aplikace v Play Console
jako samostatný `.aab` pro Wear OS (`docs/wear_os.md`); `setup_wear.dart`
jí nastaví stejný podpis (čte `wear\android\key.properties`, jinak
`android\key.properties` telefonu). Aplikace v telefonu čte jen svůj
`android\key.properties`.

## 2e. Název GymBar, ikona a web gymbar.app

### Ikona, úvodní obrazovka a název pod ikonou (jednorázově, na tvém PC)
Obrázky jsou hotové v `assets/branding` (logo varianta 1, vykresluje je
`tool/branding/render.py`). Do složek `android` a `ios` je dostaneš takto:

```powershell
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
dart run tool/setup_platforms.dart
cd wear
# jen poprvé, když složka wear\android ještě neexistuje (docs/wear_os.md):
flutter create . --platforms android --org cz.dedina --project-name fitness_wear
flutter pub get
dart run tool/setup_wear.dart
dart run flutter_launcher_icons
cd ..
flutter clean
flutter run --release
```

`setup_platforms.dart` nastaví název „GymBar“ pod ikonou (Android
i iOS), malou ikonu upozornění, barvu push upozornění a přepíše schéma
odkazů `fitnessapp://` na `gymbar://`. Změněné soubory v `android/`,
`ios/` a `wear/android/` pak commitni, ať je má i Codemagic.

ID aplikace (`cz.dedina.fitness_app`, `cz.dedina.fitnessApp`) zůstávají –
uživatelé je nevidí a jsou na ně navázané Firebase, podpis a obchody.

### Grafika do obchodů
`docs/store/graphics/play_icon_512.png` (ikona pro Google Play) a
`play_feature_graphic.png` (1024 × 500, „Hlavní obrázek“ v Play Console).
App Store si ikonu vezme z buildu. Názvy aplikace pro obchody jsou
v `docs/store/*/<jazyk>/title.txt` a `name.txt`.

### Web gymbar.app (Firebase Hosting, zdarma i s HTTPS)
Stránky jsou v `docs/web`: úvodní stránka, `/privacy`, `/terms`,
`/delete-account`, `/challenge` (výzvy), `/friend` + `/gym` + `/coach`
(pozvánky, QR kódy), `/plan` (sdílený plán) a `/trener` (web pro trenéry –
sestavuje se zvlášť, `docs/coach.md`).

1. Ve složce projektu: `firebase deploy --only hosting`.
2. Firebase Console → Hosting → *Add custom domain* → `gymbar.app`
   (a případně `www.gymbar.app` s přesměrováním).
3. Záznamy, které Firebase ukáže (TXT a A), zadej v DNS u registrátora
   domény. Ověření a certifikát trvají od pár minut do 24 hodin.
4. Než stránky spustíš, doplň v `docs/web/privacy.html`
   a `delete-account.html` jméno, adresu, e-mail a datum (hledej `[`).
5. Po vydání v App Store doplň ID aplikace v `docs/web/config.js`
   a `kAppStoreUrl` v `lib/modules/links/deep_links.dart`.

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

**Popisy oprávnění na iOS** (kalendář, Apple Zdraví, fotoaparát, uložení
obrázku do Fotek) jsou v `Info.plist` anglicky – iPhone je tak ukáže
všem uživatelům a rozumí jim i kontrola Applu. Skripty v `tool/` je
zapisují a dřívější české výchozí texty samy nahradí anglickými (vlastní
text, který jsi do `Info.plist` napsal ručně, nechají). *Volitelně:*
překlad do dalších jazyků jde přidat v Xcode souborem `InfoPlist.strings`
(File → New → File → Strings File, název `InfoPlist`, pak Localize… pro
každý jazyk, řádky ve tvaru `"NSCameraUsageDescription" = "…";`). Na Windows
to nejde a skripty to nedělají – stačí angličtina.

---

## 3. Struktura projektu

```
lib/
  main.dart                 vstupní bod, lokalizace, téma
  router.dart               navigace (5 záložek + detail cviku)
  providers.dart            Riverpod providery (propojení UI a databáze)
  core/
    formulas.dart           rekord (nejtěžší série), kalorie (MET), klouzavý průměr
    wellbeing.dart          situace podle období (nemoc, po nemoci, dieta)
    injury.dart             zranění podle partie (grafy, upozornění)
    date_utils.dart         začátek/konec dne
  data/
    enums.dart              výčty (partie, vybavení, typ období...)
    tables.dart             tabulky databáze podle specifikace
    database.dart           databáze, počáteční data, dotazy
    seed/seed_data.dart     170 cviků + 3 domácí 5min rutiny
    seed/seed_instructions.dart  návody ke cvikům (CZ/EN)
    seed/plan_templates.dart     hotové programy (role cviků, varianty podle cíle)
    seed/seed_translations.dart  cviky, návody a programy v de/es/fr
    seed/content_i18n.dart       výběr jazyka obsahu, hledání cviků
  services/
    notification_service.dart    upozornění (ráno, pauza, voda)
    calendar_service.dart        zápis tréninků do kalendáře
    sync_controller.dart         přeplánování po změně dat
  l10n/
    app_*.arb               texty aplikace (10 jazyků, šablona app_en.arb)
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
  formulas_test.dart        testy výpočtů (rekordy, kalorie, data)
  helpers_test.dart         testy dnů v týdnu a formátování
  wellbeing_test.dart       testy určení situace (nemoc, po nemoci…)
  charts_data_test.dart     testy dat pro grafy
  injury_test.dart          testy zranění podle partie
  content_i18n_test.dart    testy překladů obsahu a hledání
tool/
  setup_platforms.dart      úprava Android/iOS souborů pro pluginy
  trainer_catalog.dart      katalog cviků pro web trenérů
packages/
  gymbar_coach/             sdílený čistý Dart (aplikace + web): plány,
                            tréninky pro trenéra, statistiky, filtr slov
trainer_web/                web pro trenéry gymbar.app/trener (Flutter web,
                            docs/coach.md)
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
| pdf, printing | vytištěný žebříček posilovny (A4 → tisk / PDF) |
| share_plus, path_provider, file_picker | sdílení, export, záloha |
| home_widget | widget na plochu (Android, iOS) |
| health | Health Connect / Apple Zdraví |
| firebase_*, google_sign_in, sign_in_with_apple | přátelé a výzvy |
| firebase_storage, connectivity_plus, device_info_plus | záloha do cloudu (Wi-Fi, název zařízení) |
| qr_flutter, mobile_scanner | QR kód přítele |
| watch_connectivity | spojení s hodinkami Wear OS (i ve `wear/`) |
| wear_plus (jen `wear/`) | kulatý displej a úsporný režim hodinek |
| purchases_flutter | předplatné Premium (RevenueCat), zatím vypnuté |

## 5. Co musíš nastavit ručně

- **Web a odkazy do obchodů:** doména `gymbar.app` je nastavená
  (`kWebBaseUrl`); po vydání v App Store doplň `kAppStoreUrl`
  v `lib/modules/links/deep_links.dart` a `docs/web/config.js`. Nasazení
  webu: kapitola 2e.
- **Odkazy otevírají rovnou aplikaci (Android App Links):** odkazy
  `https://gymbar.app/challenge|friend|gym` otevře Android přímo v aplikaci,
  když web vrací `/.well-known/assetlinks.json` s otiskem klíče, kterým je
  aplikace podepsaná. Intent-filter přidá `dart run tool/setup_platforms.dart`,
  soubor vytvoří `dart run tool/assetlinks.dart` (ladicí klíč + release klíč
  z `android/key.properties`; po nahrání do Google Play přidej
  `--add <SHA-256>` klíče „App signing key“ z Play Console → App integrity)
  a pak `firebase deploy --only hosting`. Soubor je v `.gitignore`.
  Kontrola v telefonu: `adb shell pm get-app-links cz.dedina.fitness_app`
  (má být `verified`), znovu ověřit:
  `adb shell pm verify-app-links --re-verify cz.dedina.fitness_app`.
- **Přátelé:** Firebase podle `docs/social.md`.
- **Trenéři a klienti, web gymbar.app/trener:** `docs/coach.md` (pravidla
  Firestore, funkce, `flutterfire configure` pro web, autorizovaná doména
  `gymbar.app`, build webu do `docs/web/trener`).
- **Záloha do cloudu:** Cloud Storage v EU a nasazení `storage.rules`
  (`docs/social.md`, kapitola „Automatická záloha“).
- **Health Connect:** v Google Play Console vyplnit prohlášení o zdravotních
  oprávněních; u Applu zapnout HealthKit pro App ID `cz.dedina.fitnessApp`.
- **iOS:** pro Firebase, Health a Apple přihlášení zapnout v Apple Developer
  u App ID schopnosti Push Notifications, HealthKit a Sign in with Apple.
- **Hodinky (Wear OS):** samostatný projekt ve složce `wear/` – sestavení,
  spárování emulátorů a vydání v Google Play podle `docs/wear_os.md`.
- **Vydání v App Store:** krok za krokem v `docs/app_store.md` (účet,
  App ID a jeho funkce, klíče pro Firebase a Codemagic, štítky soukromí,
  poznámky pro kontrolu Applu).
- **Podmínky použití:** `docs/web/terms.html` (na webu `/terms`, souhlas
  před přihlášením k přátelům a žebříčku). Doplň jméno, adresu a datum
  (hledej `[`) stejně jako u zásad ochrany soukromí. Slibují vyřízení
  nahlášení zpravidla do 24 hodin – nahlášení chodí do Firestore
  (`contentReports`), kontroluj je. Upozornění e-mailem: `docs/social.md`,
  „Upozornění e-mailem na nahlášení“.
- **Filtr hrubých slov:** `packages/gymbar_coach/lib/src/text_filter.dart`
  (sdílí ho aplikace i web pro trenéry; v aplikaci přes
  `lib/core/text_filter.dart`) – jen urážky skupin, sexuální vulgarity
  a nacismus, hovorové nadávky projdou. Seznam slov rozšíříš tamtéž (a doplň
  test v `test/text_filter_test.dart`).
- **Zásady ochrany soukromí:** text je v `docs/web/privacy.html` (čeština
  a angličtina, kontakt info@gymbar.app). Doplň v něm jméno, adresu a datum
  (hledej `[`), nahraj ho na web (kapitola 2e) – bude na `/privacy`
  a stejnou adresu zadej v Google Play Console (Obsah aplikace → Zásady
  ochrany soukromí) a v App Store Connect. Aplikace na ni odkazuje
  z Profilu → Soukromí (`kPrivacyPolicyUrl` v
  `lib/modules/links/deep_links.dart`). Při přidání funkce, která posílá
  data jinam (Premium, reklamy, analytika), zásady uprav.
- **Hlášení o pádech (Crashlytics):** viz `docs/social.md`, krok 5a.
- **Premium (až bude živnostenský list):** viz kapitola 5a.

## 5a. Premium (zatím vypnuté)

Aplikace je teď celá zdarma: v `lib/premium/premium.dart` je
`kPremiumLaunched = false`, takže je vše odemčené a nikde se neukáže
nákup ani paywall. Zapisování tréninků zůstane zdarma vždy.

**Premium na půl roku zdarma pro první uživatele:** po dokončení
úvodního nastavení se jednou ukáže hláška „Až spustíme Premium, dostaneš
ho na půl roku zdarma“ a do profilu se uloží, kdy se uživatel stal prvním
uživatelem (`UserProfiles.premiumEarlyAt`, schéma 22; kdo už dřív dostal
dárek s datem, je první uživatel taky). **Půlrok běží až od spuštění
Premium** (`kPremiumLaunchDate` + 6 měsíců), takže dárek nepropadne, dokud
je všechno zdarma. V Profilu je řádek „půl roku zdarma od spuštění
Premium“, po spuštění „platí do …“. S účtem se slib uloží i na server
(`users/{uid}/private/premium`, `lib/modules/social/premium_early_sync.dart`)
a na novém telefonu se po přihlášení vrátí. Bez účtu ho na nový telefon
přenese záloha (Profil → Jednotky a data → Obnovit ze zálohy; jen datum
před spuštěním Premium, `premiumEarlyAfterRestore`). Zapsat ho k účtu
jde jen před spuštěním (pravidla: dokud neexistuje dokument
`config/premium`), takže po spuštění plateb ho nový účet ani
přeinstalování bez zálohy nezíská; noví uživatelé dostanou jen
zkušební měsíc z obchodu.

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
   `lib/premium/premium.dart`, přepni `kPremiumLaunched = true`
   a nastav `kPremiumLaunchDate` na den spuštění (od něj běží půlrok
   zdarma prvních uživatelů). Ve Firestore (konzole) založ dokument
   `config/premium` (např. pole `launchedAt`) – od té chvíle si slib
   „první uživatel“ k účtu nikdo nový neuloží.
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
