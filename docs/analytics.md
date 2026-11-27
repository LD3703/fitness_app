# Statistiky používání (Google Analytics pro Firebase)

Modul `analytics` (`lib/modules/analytics/`) posílá anonymní statistiky
používání: které obrazovky a funkce lidé používají a kde aplikaci
přestávají používat. Slouží k rozhodování, co rozvíjet dál.

## Jak to funguje

- **Jen se souhlasem.** Při prvním spuštění po aktualizaci (u nového
  uživatele hned na úvodní obrazovce) se objeví panel
  „Pomůžeš nám vylepšovat GymBar?“ se dvěma stejně velkými tlačítky
  *Ne, díky* / *Ano, pomůžu*. Dokud uživatel neodpoví, nic se
  neodesílá. Když panel jen zavře, zeptá se znovu při dalším spuštění.
  Volbu jde změnit v Profilu → Soukromí → *Sdílet anonymní statistiky
  používání*.
- Volba je v `analytics_settings.json` ve složce dokumentů aplikace
  (jako u hlášení o pádech), takže ji obnovení zálohy nepřepíše.
- **Jen release build s Firebase.** Při ladění (`flutter run`) se nic
  neposílá.
- **Výchozí sběr je vypnutý i nativně**, dokud se Dart nespustí:
  `tool/platform/analytics.dart` (AndroidManifest meta-data a Info.plist,
  Consent Mode se vším zamítnutým). Spouští se v
  `dart run tool/setup_platforms.dart`.
- **Bez reklamních ID:** na Androidu je odebrané oprávnění `AD_ID`
  a `google_analytics_adid_collection_enabled` = false. Na iOS se aplikace
  neptá na App Tracking Transparency (IDFA je proto nulové) a
  `GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED` = false.
- **Bez identifikace:** žádné `setUserId`. Neposílá se jméno, e-mail,
  účet, váha ani údaje o zdraví (menstruace, zranění, tep, Zdraví /
  Health Connect) a ani váhy z tréninků. Google používá jen náhodné ID
  instalace. Po odvolání souhlasu ho `resetAnalyticsData()` smaže.
- Odvoláním souhlasu se sběr hned zastaví.

## Co se posílá

**Obrazovky** (`screen_view`) jdou automaticky z routeru jako vzor cesty
bez ID, například `today`, `plans`, `plans/id`, `workout/sessionId`,
`exercises/id`, `profile`. Přepnutí záložky, i přejetím prstem, se počítá
jako nová obrazovka.

**Události:**

| Událost | Kdy | Parametry |
| --- | --- | --- |
| `onboarding_step` | dokončený krok úvodu | `step` (název kroku), `index` |
| `onboarding_complete` | konec úvodu | `goal`, `level`, `days_per_week`, `session_min`, `program`, `repeat` (průvodce spuštěný znovu z Profilu) |
| `workout_start` | spuštěný trénink | `from_plan`, `light`, `replaced_active` |
| `workout_finish` | dokončený trénink | `duration_min`, `sets`, `records` |
| `workout_discard` | zahozený trénink | `reason` (`manual` / `no_sets`), `done_sets` |
| `plan_create` | nový vlastní plán | – |
| `program_add` | přidaný hotový program | `program` (slug), `source` (`plans` / `onboarding`), `goal`, `days` |
| `plan_schedule` | trénink přidaný do kalendáře na den | `with_time` |
| `water_add` | zapsaná voda | `ml`, `source` (`quick` / `custom` / `widget`) |
| `weight_log` | zapsaná váha (bez hodnoty) | – |
| `reps_slider` | zadání opakování | `via` (`slider` / `preset` / `keyboard`), `duration` |
| `swipe_delete` | smazání přejetím | `item` (`plan`, `plan_exercise`, `workout_exercise`, `workout_set`, `calendar_day`) |
| `notification_open` | klepnutí na upozornění | `action` (`open` nebo ID tlačítka) |
| `share` | sdílení | `kind` (`text`, `workout`, `record`, `challenge`) |

**Vlastnosti uživatele** slouží k rozdělení statistik: `level`, `goal`,
`days_per_week`, `session_min`, `skin`, `units`, `coach_tone`,
`track_water`.

Firebase k tomu sám přidá `first_open`, `session_start`,
`user_engagement` (čas v aplikaci), `app_update`, `app_remove`
(jen Android), verzi aplikace, model telefonu, systém, jazyk a zemi.

Novou událost přidej do `AnalyticsEvent` v `analytics.dart` a do tabulky
výše, a když posílá nový druh údajů, uprav i `docs/web/privacy.html`.
Název události smí mít nejvýš 40 znaků (písmena, číslice, `_`). Na jednu
instalaci jde nejvýš 500 různých názvů událostí a 25 parametrů
u každé.

## Nastavení ve Firebase (jednou, dělá Lukas)

1. Firebase konzole → ⚙ **Nastavení projektu → Integrace → Google
   Analytics → Povolit**. Propoj ho s novým účtem Analytics, region
   **Česko**, a odsouhlas podmínky zpracování dat.
2. Konfigurační soubory (`google-services.json`,
   `GoogleService-Info.plist`) není potřeba stahovat znovu.
3. **Google Analytics → Správce → Shromažďování a uchovávání dat:**
   - *Uchovávání dat* → **2 měsíce** (odpovídá zásadám ochrany soukromí).
   - *Google signály* → **vypnuto**.
   - *Personalizace reklam* → **vypnuto** pro všechny země.
4. **Správce → Nastavení sdílení dat účtu:** vypni všechno kromě
   *Technické podpory*.
5. Vyzkoušení: release build na Androidu a
   `adb shell setprop debug.firebase.analytics.app cz.dedina.fitness_app`,
   v aplikaci odsouhlas statistiky → Firebase konzole → **Analytics →
   DebugView**. Ukončíš to příkazem
   `adb shell setprop debug.firebase.analytics.app .none.`. Bez DebugView
   se data v přehledech objeví do 24 hodin.

## Jak data číst

- **Analytics → Dashboard:** aktivní uživatelé, čas v aplikaci,
  nejčastější obrazovky (*Pages and screens*).
- **Události:** které funkce se používají nejvíc (`water_add`,
  `reps_slider`, `swipe_delete`…). Události jako `workout_finish` označ
  jako *klíčové události* (key events).
- **Retence:** kolik lidí se vrací po 1, 7 a 30 dnech.
- **Kde lidé odpadají:** Google Analytics → *Prozkoumat* → **Trychtýř**
  (Funnel exploration). Úvod: `first_open` → `onboarding_step` s `index`
  0, 1, 2… → `onboarding_complete` → `workout_start` → `workout_finish`.
  Podobně pro první týden: `workout_finish` ve dnech 1–7.
- **Cesta uživatele** (Path exploration) od `session_start`: kam jdou
  po otevření aplikace a kde ji zavírají.
- Rozdělení podle vlastností (úroveň, cíl) najdeš v *Prozkoumat* jako
  dimenzi, pokud ji v *Správce → Vlastní definice* přidáš jako vlastní
  dimenzi na úrovni uživatele (`level`, `goal`…), a u parametrů událostí
  (`source`, `via`, `item`, `program`) jako dimenzi na úrovni události.
- Pro vlastní dotazy jde zapnout export do **BigQuery** (Nastavení
  projektu → Integrace → BigQuery, denní export, zdarma do limitu).

## Obchody

**Google Play → Obsah aplikace → Bezpečnost dat:**
- *Aktivita v aplikaci → Interakce s aplikací*: sbíraná, nesdílená,
  **nepovinná**, účel **Analýza**.
- *ID zařízení nebo jiná ID*: sbíraná, nesdílená, účel **Analýza**
  (vedle funkčnosti aplikace – token upozornění).
- *Reklamní ID*: v manifestu není (oprávnění `AD_ID` je odebrané).
  Ve formuláři „Reklamní ID“ odpověz **ne**.

**App Store → App Privacy** (viz `docs/app_store.md`, kapitola 7):
*Usage Data → Product Interaction* (Analytics, nepropojené s účtem),
u *Identifiers → Device ID* přidej účel Analytics. Tracking: stále **ne**.
`ios/Runner/PrivacyInfo.xcprivacy` už to obsahuje
(`tool/platform/ios_store.dart`).
