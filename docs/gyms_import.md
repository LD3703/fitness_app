# Adresář posiloven z OpenStreetMap

Aby lidé nemuseli posilovny zakládat, předplní se adresář (`gyms` ve
Firestore) posilovnami z [OpenStreetMap](https://www.openstreetmap.org)
pro Evropu a Ameriku. Uživatelé dál můžou přidat posilovnu, která chybí.

- **Zdroj:** OpenStreetMap, značky `leisure=fitness_centre`,
  `amenity=gym` a `leisure=sports_centre` se `sport=fitness`
  (i `weightlifting`, `crossfit`, `bodybuilding`). Bez názvu, soukromé
  (`access=private`) a zavřené se přeskočí.
- **Licence:** ODbL 1.0. V aplikaci je uvedeno „© přispěvatelé
  OpenStreetMap“ (hledání posilovny, detail posilovny z OSM, Licence
  v O aplikaci). Adresář je odvozená databáze – kdyby o něj někdo požádal,
  musíme mu importovaná data poskytnout pod stejnou licencí (soubory
  `tool/gyms_import/out/*.json`). Nejsem právník – před vydáním si to
  ověř.
- **Země:** Evropa (EU, EHP, Spojené království, Švýcarsko, Balkán,
  Ukrajina, Moldavsko, malé státy) a celá Amerika – seznamy `EUROPE`
  a `AMERICAS` v `tool/gyms_import/lib.mjs`. Rusko, Bělorusko a Turecko
  ve výchozím seznamu nejsou, jdou přidat přes `--countries RU,BY,TR`.

## Jak to funguje v aplikaci

| Funkce | Kde | Jak |
|---|---|---|
| Posilovny v okolí | Najít posilovnu (nahoře) | Poloha jen v telefonu → buňky geohashe → dotaz `g6 in [...]` (okruh 2 km); když je tam míň než 5 posiloven, `g5 in [...]` (15 km). Seřazené podle vzdálenosti, v mílích u imperiálních jednotek. |
| Hledání | Najít posilovnu | Prefix polí `nameCity` („mcfit brno“), `cityName` („brno mcfit“), `nameLower`, `cityLower`; s polohou seřazené podle vzdálenosti. |
| Přidání chybějící | Najít posilovnu → Přidat | Volitelně „Jsem teď v této posilovně“ (uloží polohu posilovny). Před založením se ukážou posilovny do 250 m a podobné názvy ve stejném městě („Není to některá z těchto?“). |
| Nahlášení | Detail posilovny → ⋮ | Viz [Nahlášení posilovny](#nahlášení-posilovny) níže. |
| Zmizelé z OSM | – | Import je označí `osmMissing: true`; prázdné aplikace v seznamech neukáže, s členy zůstávají. |

Poloha se neukládá a na server jde jen jako buňky mřížky v dotazu
(řádově 1–5 km). Oprávnění: Android `ACCESS_COARSE_LOCATION`
a `ACCESS_FINE_LOCATION` (Android 12+ nabídne přibližnou polohu), iOS
`NSLocationWhenInUseUsageDescription` – doplní `dart run
tool/setup_platforms.dart`.

## Nahlášení posilovny

Logika: `functions/src/gymDirectory.ts` (testy `functions/test/`,
`npm test` ve složce `functions`), volá ji `onContentReportCreated`.

| Důvody | Práh | Skrytí |
|---|---|---|
| Nevhodný obsah (urážlivé, spam, jiné) | 5 nahlášení | trvalé (`hiddenReason: "reports"`), i s členy |
| **Neexistuje nebo je zavřená**, **Duplicita** | 5 nahlášení | jen posilovna **bez členů**, vratné (`hiddenReason: "closed"`) |

Obě skupiny se počítají zvlášť (3 + 3 nahlášení posilovnu neskryjí).
Každý může jednu posilovnu nahlásit jen jednou.

**Návrat skryté posilovny:** když do posilovny skryté jako neexistující /
duplicitní někdo vstoupí (kódem nebo QR – připojit se jde i do skryté),
Cloud Function `onGymMemberCreated` ji znovu ukáže a zapíše
`closedReportsResetAt`. Od té doby se počítají jen nová nahlášení
„neexistuje / duplicita“ – když posilovna později zase zůstane prázdná,
neskryje ji hned jedno další nahlášení. Trvalé skrytí za obsah vstup
člena nezruší (ručně: smazat `hidden` a `hiddenReason` ve Firebase konzoli).

Dotazy na počty nahlášení potřebují složené indexy z
`firestore.indexes.json` (`contentReports`: kind + targetId + reason
(+ createdAt)).

## Dokument posilovny z importu

`gyms/osm-n123` (n = bod, w = budova, r = relace v OSM):

| Pole | Obsah |
|---|---|
| `name`, `city`, `address`, `website` | z OSM (město z `addr:city`, jinak nejbližší sídlo do 15 km) |
| `nameLower`, `cityLower`, `nameCity`, `cityName` | hledací klíče (malá písmena bez diakritiky, jako `normalizeGymSearch`) |
| `lat`, `lng`, `geohash`, `g5`, `g6` | poloha; `g5` / `g6` = prvních 5 / 6 znaků geohashe |
| `country` | ISO 3166-1 |
| `source: "osm"`, `osm: "way/123"`, `importHash`, `importedAt`, `osmMissing` | stav importu |
| `code`, `memberCount`, `createdAt` | jako u ostatních posiloven; `createdBy` chybí |
| `hidden`, `hiddenReason`, `closedReportsResetAt` | jen Cloud Functions (nahlášení, viz výše) |

Ke každé posilovně patří `gymCodes/{code}` (QR kód na recepci funguje
i pro importované posilovny). Import nikdy nemění `code`, `memberCount`
ani `hidden`.

## Spuštění na GitHubu (bez PC)

Actions → **Import posiloven (OSM)** → Run workflow → země (výchozí
USA, Kanada, Mexiko, Brazílie, Argentina, Kolumbie, Chile, Peru,
Portoriko), volitelně *jen stáhnout a spočítat*. Používá klíč z nasazení
(`FIREBASE_SERVICE_ACCOUNT`, účet `github-deploy` potřebuje i roli
**Cloud Datastore User**). Stav si načte z Firestore – opakovaný běh
nic nezdvojí a dokončí, co předchozí nestihl. Výsledek (`out/*.json`)
je u běhu ke stažení jako artefakt `gyms-out`.

## Spuštění (Windows, PowerShell)

Potřebuješ Node.js 20+ (máš ho kvůli Firebase CLI).

### 1. Klíč servisního účtu

Firebase konzole → ⚙ Nastavení projektu → **Servisní účty** →
**Vygenerovat nový soukromý klíč**. Soubor JSON ulož **mimo projekt**
(např. `C:\keys\gymbar-admin.json`) a nikomu ho neposílej – dává plný
přístup k databázi.

### 2. Zkouška bez zápisu

```powershell
cd C:\dev\fitness_app\tool\gyms_import
npm install
node import_gyms.mjs --dry-run --countries CZ,SK
```

Stáhne data z Overpass API (veřejný server OpenStreetMap), uloží je do
`cache\` a výsledek do `out\CZ.json`, `out\SK.json`. Nic se nezapíše.
Podívej se do souborů, jestli názvy a města sedí.

### 3. Import

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\keys\gymbar-admin.json"
node import_gyms.mjs --countries CZ,SK          # nejdřív malý import
node import_gyms.mjs                            # Evropa + Amerika
```

- **Bezplatný tarif Spark** má limit 20 000 zápisů denně. Každá nová
  posilovna = 2 zápisy (posilovna + kód). Použij
  `--max-writes 19000` a další den spusť znovu – pokračuje, kde skončil
  (stav je v `state\manifest.json`).
- **Tarif Blaze:** zápisy stojí řádově desítky centů za 100 000 posiloven.
- Celý import Evropy a Ameriky trvá kvůli šetrnosti k serveru Overpass
  několik hodin (pauza 5 s mezi dotazy, velké země po regionech). Když
  se přeruší, spusť znovu – stažená data se berou z `cache\` (25 dní).
- **Chyby serveru (504, bez odpovědi):** skript střídá tři veřejné servery
  Overpass (overpass-api.de, overpass.private.coffee, overpass.kumi.systems),
  na odpověď čeká až 12 minut a zemi, která najednou třikrát neprojde,
  stáhne po regionech. Země, které i tak selžou, vypíše na konci i s
  příkazem pro nový pokus (`--countries …`) – stačí ho spustit později.
  Vlastní server: `--endpoint <url>[,<url>…]`.
- Počítač nesmí během importu usnout (Nastavení → Systém → Napájení →
  Režim spánku: Nikdy, po importu vrátit).
- Na jiném počítači (bez `state\`) si skript stav načte z Firestore sám.

### 4. Hledací klíče u starších posiloven

Posilovny založené uživateli před touto verzí nemají `nameCity`
a `cityName` (hledání „název město“). Jednorázově:

```powershell
node import_gyms.mjs --backfill-search
```

(Bez `--countries` jen doplní klíče, nic neimportuje.)

### 5. Pravidla a funkce

```powershell
cd C:\dev\fitness_app
firebase deploy --only firestore:rules,firestore:indexes,functions
```

### Aktualizace

Jednou za 1–3 měsíce spusť import znovu (`node import_gyms.mjs`).
Změněné posilovny se přepíšou, nové přibudou, zmizelé se označí
`osmMissing`. Kdo chce mít svou posilovnu v adresáři správně, může ji
opravit přímo v OpenStreetMap – projeví se při dalším importu.

## Testy

```powershell
cd tool\gyms_import
npm test
```
