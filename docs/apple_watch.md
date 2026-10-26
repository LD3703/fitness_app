# Aplikace pro Apple Watch

Obdoba aplikace pro hodinky s Wear OS (`docs/wear_os.md`): na hodinkách
je vidět cvik, „Série 2 z 4“, váha a opakování s tlačítky +/−, tlačítko
**Hotovo**, odpočet pauzy (na konci zavibruje), seznam cviků, ukončení
tréninku – a **tep** během tréninku. Kód je hotový v gitu, ale **v Xcode
projektu je zatím vypnutý** – podepsaný build by bez App ID aplikace pro
hodinky v Apple Developer účtu selhal.

| Soubor | Účel |
| --- | --- |
| `ios/GymBarWatch/WatchViews.swift` | obrazovky (SwiftUI, watchOS 9+) |
| `ios/GymBarWatch/WatchController.swift` | stav a spojení s telefonem (WCSession), příkazy, pauza |
| `ios/GymBarWatch/WatchProtocol.swift` | protokol – stejný jako `lib/modules/wear/wear_protocol.dart` |
| `ios/GymBarWatch/HeartRateMonitor.swift` | tep přes HKWorkoutSession (jen během tréninku) |
| `ios/GymBarWatch/WatchStrings.swift` | texty v 10 jazycích, generuje `python3 tool/ios_watch_strings.py` z `wear/lib/strings.dart` |
| `tool/platform/ios_watch.dart` | zapnutí: cíl GymBarWatch v `project.pbxproj`, vložení do Runner.app/Watch |
| `test/apple_watch_test.dart` | hlídá shodu protokolu a textů |

## Jak to funguje

- Telefon (modul `lib/modules/wear`, `WearBridge`) mluví s hodinkami
  balíčkem watch_connectivity – na iOS přes **WCSession** se stejnými
  zprávami jako na Wear OS (`{fitnessWear: JSON}`). Zdroj pravdy je
  telefon, série se zapisují vždy přes obrazovku tréninku.
- Sekce Hodinky v Profilu se na iPhonu ukáže až po první zprávě
  z hodinek.
- **Tep:** během tréninku běží `HKWorkoutSession` (silový trénink), tep jde
  nejvýš jednou za 5 s do telefonu (`{t: hr, bpm}`), telefon ho ukazuje
  v záhlaví tréninku a po tréninku z něj spočítá průměr, maximum, zóny
  a energii (`docs/readiness.md`). Trénink se z hodinek do Apple Zdraví
  **neukládá** (`discardWorkout`) – zapisuje ho aplikace v telefonu, aby
  nebyl dvakrát.
- Live Activity pauzy z telefonu (`docs/ios_widget.md`) ukazuje watchOS 11
  i ve Smart Stacku hodinek – i bez této aplikace.

## Kontrola bez Macu

CI (`.github/workflows/ci.yml`, job **iOS**) zapne aplikaci pro hodinky
(`dart run tool/ios_watch.dart`), sestaví iOS aplikaci bez podpisu (Flutter
pozná aplikaci pro hodinky podle `WKCompanionAppBundleIdentifier`
v `ios/GymBarWatch/Info.plist` a sestaví ji pro watchOS) a ověří, že je
v `Runner.app/Watch/GymBarWatch.app`.

## Zapnutí (až bude Apple Developer účet)

1. **Identifiers → + → App IDs:** Bundle ID
   `cz.dedina.fitnessApp.watchkitapp`, popis „GymBar Watch“, zaškrtni
   **HealthKit**.
2. Projekt:
   ```powershell
   dart run tool/ios_watch.dart
   git add ios
   git commit -m "Apple Watch zapnuté"
   git push
   ```
   (nebo `dart run tool/setup_platforms.dart --ios-watch`).
3. Codemagic **iOS – TestFlight**: `ios_signing` s `bundle_identifier:
   cz.dedina.fitnessApp` stáhne (vytvoří) profil i pro
   `…watchkitapp`. Aplikace pro hodinky jde do App Store spolu
   s aplikací v telefonu.
4. Vyzkoušet: iPhone → aplikace Watch → GymBar → Instalovat. Spustit
   trénink v telefonu, otevřít GymBar na hodinkách: série, +/−, Hotovo,
   pauza s vibrací, tep (první spuštění se zeptá na oprávnění Zdraví).

## Známá omezení

- Bez otevřené obrazovky tréninku v telefonu hodinky jen ukážou „Otevři
  trénink v telefonu“ (stejně jako Wear OS).
- WCSession posílá zprávy jen při dosažitelném iPhonu (Bluetooth / Wi-Fi).
- Komplikace a dlaždice (Smart Stack widget) pro dnešní plán zatím nejsou.
