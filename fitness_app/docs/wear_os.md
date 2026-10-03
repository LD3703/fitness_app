# Hodinky s Wear OS

Zápis sérií z hodinek během tréninku: na hodinkách je vidět cvik, „Série 2 z 4“,
váha a opakování s tlačítky +/−, velké tlačítko **Hotovo**, odpočet pauzy
(na konci zavibruje) a seznam cviků. Apple Watch zatím ne (bez Macu nejde
sestavit).

## 1. Jak to funguje

```
 telefon (fitness_app)                         hodinky (wear/, fitness_wear)
 ┌──────────────────────────────┐   Data Layer  ┌──────────────────────────┐
 │ WorkoutScreen (série v paměti,│◄────────────►│ WatchController          │
 │ pauza, DB)                    │  zprávy JSON │ (jen zobrazuje + příkazy) │
 │   └ _WorkoutWearLink (part)   │              │ UI: kulatý displej,       │
 │ WearBridge (lib/modules/wear) │              │ korunka, vibrace          │
 └──────────────────────────────┘              └──────────────────────────┘
```

- **Dvě aplikace, jedno ID.** Hodinky jsou samostatný malý Flutter projekt ve
  složce `wear/`. Musí mít **stejné applicationId** (`cz.dedina.fitness_app`)
  a **stejný podpisový klíč** jako aplikace v telefonu – jinak jim Wearable
  Data Layer zprávy nedoručí. V Google Play jsou pod jednou aplikací (jeden
  záznam v obchodě, dva soubory AAB).
- **Nesamostatná aplikace** (`com.google.android.wearable.standalone = false`):
  hodinky bez telefonu nic nezapíšou (data jsou jen v telefonu). Google Play
  takovou aplikaci na hodinkách bez spárovaného telefonu nenabídne.
- **Přenos:** balíček [`watch_connectivity`](https://pub.dev/packages/watch_connectivity)
  0.2.10 (Wearable `MessageClient`) na obou stranách. Každá zpráva je mapa
  `{fitnessWear: "<JSON>"}`, formát je v `lib/modules/wear/wear_protocol.dart`
  (kopie `wear/lib/wear_protocol.dart` musí být shodná – hlídá to test
  `test/wear_protocol_test.dart`).
- **Zdroj pravdy je telefon.** Hodinky pošlou `hello`, telefon odpoví stavem
  (cvik, série na řadě, váha/opakování, minule, konec pauzy, seznam cviků
  s hotovými sériemi). Příkazy z hodinek: `completeSet`, `adjustWeight ±krok`,
  `adjustReps ±1`, `skipRest`, `nextExercise`, `selectExercise`,
  `finishWorkout` (potvrzuje se v telefonu), `openWorkout`. Telefon na každý
  příkaz odpoví `ack` (ok / důvod) a novým stavem.
- **Zápis jde vždy přes obrazovku tréninku.** Obrazovka tréninku drží série
  v paměti (textová pole, navržená série, pauza), proto se k mostu připojí
  jako obsluha příkazů (`lib/features/workout/workout_screen_wear.dart`, je to
  `part` obrazovky) a příkazy provede svými metodami `_toggleSet`,
  `_onRowEdited`, `_finish` – stejná databáze, stejné supersérie a drop
  série, UI v telefonu se hned překreslí. Místo navrhované Riverpod fronty
  příkazů je to přímé volání: příkaz potřebuje výsledek (potvrzení pro
  hodinky) a obsluha je vždy nejvýš jedna.
- **Když obrazovka tréninku otevřená není** (trénink běží, ale uživatel je
  jinde nebo aplikace byla ukončena), hodinky ukážou „Otevři trénink
  v telefonu“; tlačítko ho otevře, jen když je aplikace v telefonu v popředí
  (Android nedovolí otevírat obrazovky z pozadí).
- **Telefon v kapse:** stačí, když proces aplikace běží (obrazovka tréninku
  zůstala otevřená, telefon zamčený). Když Android aplikaci na pozadí ukončí,
  hodinky po ~50 s ukážou „Telefon neodpovídá“.
- **Pauza:** odpočet počítá telefon; hodinky ho přepočítají na své hodiny
  a na konci zavibrují. Během pauzy drží displej hodinek zapnutý (jinak by
  hodinky usnuly a vibrace by se zpozdila). Upozornění na konec pauzy
  z telefonu se při ovládání z hodinek zruší (nepřijde dvakrát).
- **Jednotky:** váhy jdou v kg, hodinky zobrazují kg / lb podle profilu
  (krok 2,5 kg / 5 lb), cviky na čas v sekundách (krok 5 s).

### Soubory

| Soubor | Co dělá |
| --- | --- |
| `lib/modules/wear/wear_protocol.dart` | formát zpráv (sdílený s hodinkami) |
| `lib/modules/wear/wear_snapshot.dart` | výběr série na řadě, sestavení stavu (testy `test/wear_snapshot_test.dart`) |
| `lib/modules/wear/wear_bridge.dart` | spojení, fronta příkazů, `wearAppProvider`, `wearBridgeProvider` |
| `lib/modules/wear/wear_profile_section.dart` | sekce „Hodinky“ v Profilu (stav, návod) |
| `lib/features/workout/workout_screen_wear.dart` | napojení obrazovky tréninku |
| `tool/platform/wear.dart` | úprava manifestu telefonu (viditelnost aplikací Wear OS / Pixel Watch / Galaxy Wearable) |
| `wear/` | aplikace pro hodinky |
| `wear/tool/setup_wear.dart` | úprava nativních souborů hodinek po `flutter create` |

Úpravy existujících souborů: `workout_screen.dart` (3 importy, `part`,
pole `_wear`, `attach` v initState, `detach` v dispose, `schedulePublish`
v build a `_onRowEdited`), `rest_timer.dart` (gettery `endsAt`,
`totalSeconds`), `module_hub.dart` (značky `[wear:…]`),
`tool/setup_platforms.dart`, `pubspec.yaml` (`# [deps:wear]`).

## 2. První spuštění

### 2.1 Telefon

Jako obvykle (README, kapitola 2) – nový je jen balíček `watch_connectivity`:

```powershell
dart run tool/setup_platforms.dart
flutter pub get
flutter gen-l10n
flutter run
```

Texty sekce „Hodinky“ jsou v `tool/l10n_fragments/wear.json` (10 jazyků) –
před `flutter gen-l10n` je potřeba je sloučit do `lib/l10n/app_*.arb`
(stejně jako fragmenty ostatních modulů).

### 2.2 Aplikace pro hodinky (jednorázově)

V PowerShellu v kořeni projektu:

```powershell
cd wear
flutter create . --platforms android --org cz.dedina --project-name fitness_wear
dart run tool/setup_wear.dart
flutter pub get
```

- `flutter create` vytvoří složku `wear/android/` (tvoje soubory v `wear/lib`
  nepřepíše).
- `setup_wear.dart` nastaví **applicationId stejné jako telefon** (přečte ho
  z `../android/app/build.gradle.kts`; když jsi telefon vytvořil s jiným
  `--org`, vezme to správné, jinak ho zadej:
  `dart run tool/setup_wear.dart cz.tvojejmeno.fitness_app`), `minSdk 30`
  (Wear OS 3 a novější), v manifestu `uses-feature android.hardware.type.watch`,
  `standalone = false`, oprávnění VIBRATE a WAKE_LOCK, a zapíše
  `MainActivity.kt` (vibrace, displej zapnutý během pauzy, otočná korunka).
  Skript je bezpečné spustit znovu (např. po aktualizaci).
- Knihovnu `play-services-wearable` přidává balíček `watch_connectivity` sám,
  `androidx.wear` balíček `wear_plus` – v `build.gradle.kts` není potřeba nic
  dalšího.
- Ikona: zatím výchozí Flutter. Pro vydání zkopíruj ikony z
  `android/app/src/main/res/mipmap-*` telefonu do
  `wear/android/app/src/main/res/mipmap-*` (kulatá ikona se na hodinkách
  ořízne do kruhu).

### 2.3 Emulátor hodinek a spárování

1. Android Studio → **Device Manager** → **+** → **Create Virtual Device** →
   kategorie **Wear OS** → např. *Wear OS Large Round* → systémový obraz
   **Wear OS 5** (API 34) → Finish.
2. Telefonní emulátor musí mít **Google Play** (ikona Play u obrazu, např.
   *Pixel 8* s Google Play, API 34+).
3. Spárování: v Device Manageru u emulátoru hodinek ⋮ → **Pair Wearable** (nebo
   *Tools → Device Manager → Pair Wearable*) → vyber telefon → průvodce
   spustí oba emulátory a na telefonu nainstaluje aplikaci **Pixel Watch / Wear
   OS** – dokonči v ní párování (přihlášení Google účtem v emulátoru telefonu
   je potřeba).
4. Spusť obě aplikace (každou v jiném terminálu):

   ```powershell
   flutter devices                 # najdi ID telefonu a hodinek
   flutter run -d emulator-5554    # telefon (z kořene projektu)
   cd wear
   flutter run -d emulator-5556    # hodinky
   ```

   Ladicí sestavení obou aplikací se podepisují stejným ladicím klíčem
   (`%USERPROFILE%\.android\debug.keystore`), takže spolu mluví. Když telefon
   a hodinky sestavuješ na různých počítačích, nebude to fungovat.

### 2.4 Skutečné hodinky

1. Hodinky spáruj s telefonem běžně (aplikace **Pixel Watch**, **Wear OS by
   Google** nebo **Galaxy Wearable**).
2. Na hodinkách: Nastavení → Systém → Informace → 7× klepni na *Číslo
   sestavení* → **Pro vývojáře** → zapni **Ladění ADB** a **Ladění přes Wi-Fi**
   (hodinky a počítač na stejné Wi-Fi).
3. V *Ladění přes Wi-Fi* → **Spárovat nové zařízení** – ukáže adresu a kód:

   ```powershell
   adb pair 192.168.1.50:37099      # zadej kód z hodinek
   adb connect 192.168.1.50:40123   # adresa z hlavní obrazovky „Ladění přes Wi-Fi“
   cd wear
   flutter run -d 192.168.1.50:40123
   ```

4. Telefon připoj kabelem a spusť `flutter run` z kořene projektu.

### 2.5 Vyzkoušení

1. V telefonu spusť trénink (obrazovka tréninku zůstane otevřená).
2. Na hodinkách otevři aplikaci → ukáže první sérii. Změň váhu +/−, klepni
   **Hotovo** → v telefonu se série odškrtne a začne pauza, hodinky ukážou
   odpočet; na konci zavibrují.
3. Zamkni telefon a pokračuj z hodinek – série se zapisují dál.
4. **Ukončit trénink** na hodinkách → v telefonu se ukáže potvrzovací dialog.
5. Profil → **Hodinky**: stav „Aplikace v hodinkách je připojená“.

## 3. Vydání v Google Play

1. **Podpis:** hodinky podepiš **stejným upload klíčem** jako telefon (stejný
   `key.properties` / keystore, nastavení podpisu v
   `wear/android/app/build.gradle.kts` stejně jako u telefonu). Google Play
   App Signing pak obě podepíše stejným klíčem aplikace.
2. **Číslo verze:** obě sestavení patří k jedné aplikaci, takže `versionCode`
   se nesmí opakovat. Hodinky používají **1 000 000 + číslo sestavení
   telefonu** (`wear/pubspec.yaml`: `version: 0.1.0+1000001` k telefonu
   `0.1.0+1`). Při každém vydání zvyš obě.
3. Sestavení: `cd wear` → `flutter build appbundle` →
   `wear/build/app/outputs/bundle/release/app-release.aab`.
4. Play Console → aplikace → **Test and release → Advanced settings → Form
   factors** → **Add form factor → Wear OS** → potvrď. Nahraj **snímky
   obrazovky z hodinek** (kulaté 384 × 384, bez rámečku hodinek) a vyplň
   popis pro hodinky v hlavním záznamu obchodu.
5. **Release → Wear OS only** (samostatná řada vydání pro hodinky) → nové
   vydání → nahraj AAB hodinek. Telefon dál vydáváš ve své řadě.
6. Google aplikaci pro hodinky kontroluje zvlášť (kvalita Wear OS: čitelnost
   na kulatém displeji, ovládání, ztmavený režim). První kontrola trvá déle.
7. Uživatel si aplikaci do hodinek nainstaluje z Play na hodinkách, nebo ji
   Play nabídne po instalaci v telefonu („Aplikace v hodinkách“).

Podrobnosti a aktuální požadavky (cílové API pro Wear OS, snímky):
developer.android.com → *Wear OS → Package and distribute* a
*Standalone vs non-standalone apps*.

## 4. Texty v hodinkách

Jen čeština a angličtina podle jazyka hodinek (`wear/lib/strings.dart`,
jednoduché gettery; ostatní jazyky anglicky). Plná lokalizace přes ARB je
tu zbytečně složitá – textů je pár a názvy cviků posílá telefon už
přeložené v jazyce aplikace. Další jazyk = další větev v `WearStrings`.

## 5. Premium

Hodinky jsou funkce Premium (`PremiumFeature.wearOs`); dokud je
`kPremiumLaunched = false`, nic není omezené. Po spuštění bez předplatného
most běží dál, ale hodinkám posílá jen stav `WearPhase.premiumRequired`
(hodinky ukážou „Aplikace pro hodinky je součástí Premium“) a každý příkaz
odmítne s důvodem `WearAckReason.premiumRequired` (`WearBridge._allowed`).
Po koupi se hodinkám hned pošle nový stav. Sekce Hodinky v Profilu ukáže
místo stavu spojení upoutávku Premium. `kWearProtocolVersion` se nemění:
starší aplikace v hodinkách neznámou fázi přečte jako `idle`.

## 6. Známá omezení

- Hodinky fungují jen s běžící aplikací v telefonu a otevřenou obrazovkou
  tréninku (žádná služba na pozadí). Agresivní správa baterie (Xiaomi,
  Huawei, některé Samsungy) může aplikaci na pozadí ukončit – pak je potřeba
  telefon odemknout a trénink otevřít.
- Nejsou rozcvičky/drop série přidávané z hodinek, propojení supersérií ani
  přidání cviku – to jde jen v telefonu (hodinky to pak ukážou).
- Úsporný režim (ambient) ukazuje jen cvik a sérii; odpočet se v něm
  neukazuje, protože během pauzy displej zůstává zapnutý.
- Korunka/luneta posouvá obsah přes vlastní kód v `MainActivity.kt`
  (balíček `wearable_rotary` je ukončený). Když skript `setup_wear.dart`
  neproběhne, aplikace funguje, jen bez korunky a výrazné vibrace.
