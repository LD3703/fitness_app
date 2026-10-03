# Brief pro moduly verzí 2 a 3 (pro vývojáře / agenty)

Flutter aplikace pro posilovnu (Android + iOS), lokální data, 5 jazyků.
Specifikace je shrnutá v tomto souboru; drž se jí.

## Technologie
- Flutter 3.47 / Dart 3 (records, patterns, switch výrazy), `environment: sdk ^3.6.0`.
- Riverpod 2 bez generování kódu (`flutter_riverpod ^2.6`): Provider, StreamProvider,
  StateProvider, FutureProvider, `.family`, `.autoDispose`; `ConsumerWidget`,
  `ConsumerStatefulWidget`, `ref.watch/read/listen`.
- go_router 14. Routy modulů jsou top-level (přes celou obrazovku, bez spodní lišty).
- drift 2.26 + drift_flutter. **`lib/data/database.g.dart` v repozitáři NENÍ** (generuje se
  u uživatele přes build_runner). Piš kód podle `lib/data/tables.dart`: datové třídy mají
  název z `@DataClassName`, companiony `XxxCompanion(...)` / `XxxCompanion.insert(...)`,
  pole = názvy getterů, `intEnum<E>()` sloupce mají typ `E`.
- Lokalizace: gen-l10n, `AppLocalizations.of(context)` (soubor `lib/l10n/app_localizations.dart`
  se generuje, v repu není). Placeholdery s typy, plurály ICU.
- **V prostředí není Flutter SDK – nic nejde zkompilovat ani spustit.** Proto:
  - API každého balíčku ověř na pub.dev (WebFetch `https://pub.dev/packages/<balíček>`,
    `.../versions`, `.../example`, dokumentace API `https://pub.dev/documentation/<balíček>/latest/`).
    Používej aktuální stabilní verzi kompatibilní s Flutter 3.47 / Dart 3.10+.
  - Před psaním si přečti existující kód, který používáš (signatury, názvy).
  - Po dopsání si každý soubor znovu projdi očima: importy, závorky, typy, null-safety,
    `const`, `mounted` po `await`, názvy l10n klíčů.

## Pravidla pro sdílené soubory (běží víc modulů paralelně!)
- Kód modulu patří do `lib/modules/<modul>/`. Testy čisté logiky do `test/<modul>_*_test.dart`
  (`package:fitness_app/...`, `flutter_test`).
- Napojení na aplikaci **jen přes `lib/modules/module_hub.dart`**: přidávej řádky hned POD
  své značky `// [<modul>:<místo>]` (značku ponech, cizích značek se nedotýkej).
  Místa: imports, init, app (providery sledované v kořeni), routes, today, progress,
  profile, exercise(Exercise e), plan(int planId), summary(WorkoutSummary), finished
  (hook po tréninku), sync (hook po změně dat, dostane `Ref` a `UserProfile`).
- Odkazy do aplikace: `lib/modules/links/deep_links.dart` – handler pod značku
  `// [links:<modul>]` (+ import pod `// [links-imports:<modul>]`). Konstanty
  `kAppLinkScheme` (`fitnessapp`), `kWebBaseUrl`, `kPlayStoreUrl`, `kAppStoreUrl`,
  pomocná funkce `isAppLink(uri, 'challenge')`.
- Dotazy do DB: `lib/modules/<modul>/<modul>_queries.dart` jako
  `extension <Modul>Queries on AppDatabase { ... }` (uvnitř můžeš používat `select`,
  `into`, `update`, `delete`, `customSelect`, gettery tabulek). **Needituj**
  `lib/data/database.dart` ani `lib/data/tables.dart` – schéma v6 už obsahuje vše níže.
  Kdybys přesto potřeboval změnu schématu, nedělej ji a napiš ji do reportu.
- Texty pro uživatele nikdy natvrdo: `AppLocalizations.of(context).<klic>`. Nové klíče
  zapiš do `tool/l10n_fragments/<modul>.json`:
  `{"statsVolumeTitle": {"en": "Volume", "cs": "Objem"}, "statsWeeks": {"en": "{count} weeks", "cs": "{count} týdnů", "placeholders": {"count": {"type": "int"}}}}`.
  Klíče začínají zkratkou modulu. ARB soubory needituj (sloučí se a přeloží do de/es/fr/pl
  později). Čeština neformálně (tykání), angličtina přátelsky, krátké popisky tlačítek.
  Texty mimo widgety (notifikace, sdílení): `deviceLocalizations()` ze
  `lib/services/sync_controller.dart`.
- Balíčky: do `pubspec.yaml` jen pod značku `# [deps:<modul>]`. Už jsou k dispozici:
  flutter_riverpod, go_router, drift, drift_flutter, intl, flutter_local_notifications 22,
  timezone, device_calendar_plus 0.9, app_links 7, share_plus 13 (API
  `SharePlus.instance.share(ShareParams(...))`), path_provider 2.1, url_launcher 6.3.
- Nativní změny: složky `android/` a `ios/` v repu NEJSOU (vytváří je `flutter create`
  u uživatele na Windows; applicationId `cz.dedina.fitness_app`, iOS bundle id
  `cz.dedina.fitnessApp`, `android/app/src/main/kotlin/cz/dedina/fitness_app/MainActivity.kt`,
  `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts` (Kotlin DSL),
  `ios/Runner/Info.plist`, `ios/Runner/AppDelegate.swift`, `ios/Runner.xcodeproj/project.pbxproj`).
  Změny dělej idempotentní funkcí `bool patch<Modul>()` v `tool/platform/<modul>.dart`
  (čisté dart:io, vzor: `tool/setup_platforms.dart` a `tool/platform/links.dart`) a zaregistruj
  ji pod značky `// [platform-imports:<modul>]` a `// [platform:<modul>]` v
  `tool/setup_platforms.dart`. Nové nativní soubory musí skript celé zapsat.
  Uživatel NEMÁ Mac (iOS se staví přes Codemagic) – nic, co vyžaduje ruční práci v Xcode.
- Úpravy jiných existujících souborů jen když není zbytí, minimální, a uveď je v reportu.

## Užitečné v kódu
- `lib/providers.dart`: databaseProvider, profileProvider (UserProfile), plansProvider,
  sessionHistoryProvider, periodsProvider, situationProvider, injuredGroupsProvider,
  latestWeightProvider, waterTodayProvider, exercisesProvider, chartDays...
- Zápis profilu: `db.updateProfile(UserProfilesCompanion(pole: Value(x)))` (`import 'package:drift/drift.dart' show Value;`).
- `lib/ui/format.dart` (formatWeight, formatInt, formatDuration, parseDecimal),
  `lib/ui/labels.dart` (`l10n.muscleGroup(g)`, `l10n.periodType(t)`, `exercise.localizedName(context)`),
  `lib/ui/dialogs.dart`, `lib/ui/number_input_dialog.dart`, `lib/ui/charts.dart`
  (TimeSeriesChart, WeeklyBarChart, ChartSeries, ChartBand), `lib/core/formulas.dart`
  (estimateOneRepMax Epley, movingAverage, weeklyCounts), `lib/core/wellbeing.dart`,
  `lib/core/injury.dart`, `lib/core/date_utils.dart` (startOfDay).
- `lib/features/workout/workout_service.dart`: `WorkoutSummary` (sessionId, startedAt,
  duration, setCount, volumeKg, estimatedKcal, records: List<PersonalRecord(exercise,
  newOneRepMax, previousOneRepMax)>).
- `lib/services/calendar_service.dart`, `lib/services/notification_service.dart`,
  `lib/services/sync_controller.dart`.

## Schéma v6 (už hotové)
- UserProfile: `calendarReadEnabled`, `healthSyncEnabled`, `waterReminderStartMinutes` (540),
  `waterReminderEndMinutes` (1200), `waterReminderIntervalMinutes` (120), `glassMl` (250),
  `bottleMl` (500), `shareRecordsWithFriends`, `shareWorkoutStatsWithFriends` (+ starší:
  name, unitSystem (UnitSystem.metric/imperial), waterGoalMl, morningReminderMinutes,
  trackWater/Weight/Periods, showCalories, morningReminderEnabled, waterRemindersEnabled,
  calendarSyncEnabled, isPremium).
- WorkoutSession: `healthExportedAt` (DateTime?).
- Tabulka `Challenges` (třída `Challenge`): id, kind (ChallengeKind.beatRecord /
  workoutsInMonth / weeklyWater), exerciseSlug?, exerciseId?, targetValue (kg odhadu 1RM /
  počet tréninků / ml za týden), fromName?, createdAt, deadline?, completedAt?,
  dismissedAt?, remoteId? (unikátní; výzvy od přátel ze serveru).

## Pravidla soukromí
Záznamy o nemoci, zranění, tělesná váha a pitný režim nikdy neopustí telefon
(výjimka: Health Connect / Apple Zdraví, pokud to uživatel zapne). Sociální funkce sdílí
jen to, co uživatel výslovně povolí (rekordy, počty tréninků).

## Na konci
`git add -A && git commit -m "<modul>: ..."` ve svém worktree. V závěrečné zprávě:
přidané/změněné soubory, balíčky s verzemi, počet l10n klíčů, co musí uživatel udělat ručně
(účty, konzole), nejisté API a rizika.
