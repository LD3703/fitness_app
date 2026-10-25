# iOS widget „Dnes“ a Live Activity pauzy

Obdoba Android widgetu a odpočtu pauzy na zamčené obrazovce. Kód je
hotový v gitu, ale **v Xcode projektu je zatím vypnutý** – podepsaný build
(Codemagic → TestFlight) by bez App Group v Apple Developer účtu selhal.
Zapne se jedním příkazem, až bude účet (kroky níže).

## Co obsahuje

- **Widget „Dnes“** (iOS 16.2+): dnešní trénink a voda.
  - Malý: titulek, trénink, voda s pruhem.
  - Střední: navíc tlačítko „+ sklenice“ (přidá vodu bez otevření
    aplikace – iOS otevře aplikaci na pozadí přes odkaz).
  - Zamčená obrazovka: kruh s vodou, obdélník s tréninkem.
  - Barvy stejné jako widget na Androidu, světlý i tmavý režim. Data
    posílá aplikace stejně jako na Androidu (`home_widget`, App Group
    `group.cz.dedina.fitnessApp`). O půlnoci widget sám přepne na data
    pro další den.
- **Live Activity pauzy** (iOS 16.2+): odpočet na zamčené obrazovce
  a v Dynamic Islandu (iPhone 14 Pro a novější), „Další: cvik“ a po
  skončení „Pauza skončila“. Odpočet běží v iOS sám, aplikace posílá jen
  začátek, konec a změnu pauzy. Když jsou Live Activity v Nastavení
  vypnuté, nic se nestane (upozornění na konec pauzy funguje dál).

| Soubor | Účel |
| --- | --- |
| `ios/GymBarWidget/` | rozšíření (SwiftUI): widget, Live Activity, Info.plist, entitlements |
| `ios/Runner/RestLiveActivity.swift` | spouštění Live Activity z aplikace (kanál `gymbar/rest_live_activity`) |
| `lib/modules/widgets/home_widget_service.dart` | data widgetu (Android i iOS) |
| `lib/modules/widgets/rest_live_activity.dart` | Live Activity z Flutteru, volá ji obrazovka tréninku |
| `tool/platform/ios_widget.dart` | zapnutí: cíl GymBarWidget v `project.pbxproj`, App Group, Info.plist, AppDelegate |
| `tool/ios_widget_preview/main.swift` | náhledy jako PNG (vykreslí CI na Macu) |

## Kontrola bez Macu

CI (`.github/workflows/ci.yml`, job **iOS**) na každém pushi na Macu
v GitHub Actions:

1. zapne widget (`dart run tool/ios_widget.dart`) jen pro sebe,
2. sestaví iOS aplikaci bez podpisu (`flutter build ios --no-codesign`) –
   ověří, že Swift kód i Xcode projekt jdou přeložit,
3. vykreslí náhledy widgetu a Live Activity do PNG – artefakt
   **ios-widget-previews** u běhu CI (GitHub → Actions → běh → Artifacts).

## Zapnutí (až bude Apple Developer účet)

### 1. Apple Developer → Certificates, IDs & Profiles

1. **Identifiers → + → App Groups:** `group.cz.dedina.fitnessApp`
   (popis třeba „GymBar widget“).
2. **Identifiers → App ID `cz.dedina.fitnessApp`** → zaškrtni
   **App Groups** → Configure → vyber `group.cz.dedina.fitnessApp` → Save.
   (Existující profily tím přestanou platit – Codemagic si vytvoří nové.)
3. **Identifiers → + → App IDs:** Bundle ID
   `cz.dedina.fitnessApp.GymBarWidget`, popis „GymBar Widget“,
   zaškrtni jen **App Groups** se stejnou skupinou.

### 2. Projekt

```powershell
cd C:\dev\fitness_app
dart run tool/ios_widget.dart
git add ios
git commit -m "iOS widget a Live Activity zapnuté"
git push
```

Nástroj je bezpečné spustit opakovaně. Od té doby ho volá i
`dart run tool/setup_platforms.dart --ios-widget` (bez přepínače
`setup_platforms` cíl nepřidává, ale ani neodebírá).

### 3. Codemagic

Spusť **iOS – TestFlight**. `ios_signing` s `bundle_identifier:
cz.dedina.fitnessApp` stáhne (nebo vytvoří) profily i pro rozšíření
`cz.dedina.fitnessApp.GymBarWidget`. Kdyby build hlásil chybějící profil
pro GymBarWidget, zkontroluj krok 1.3 (App ID rozšíření s App Groups).

### 4. Co vyzkoušet na iPhonu (TestFlight)

- Plocha → podržet → **+** → GymBar: malý a střední widget, po zápisu
  vody v aplikaci se do pár sekund změní; tlačítko **+ sklenice** přidá
  vodu (aplikace se neotevře).
- Zamčená obrazovka → Přizpůsobit → widgety: kruh s vodou, obdélník.
- Trénink → zapsat sérii → pauza: odpočet na zamčené obrazovce
  a v Dynamic Islandu; přeskočení pauzy ho ukončí; po konci pauzy
  „Pauza skončila“.
- Nastavení → GymBar → Live Activity vypnuté: trénink funguje dál
  bez odpočtu.
