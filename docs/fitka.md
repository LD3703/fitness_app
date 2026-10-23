# GymBar pro fitka

Fitko vyvěsí plakát s QR kódem a nalepí samolepky na stroje. Za to získá
žebříček posilovny, návody ke strojům a nástroje pro své trenéry. Pro fitka
je všechno **zdarma** a **samoobslužné**: majitel si sadu najde a vytiskne
sám, nebo mu ji pošle člen či trenér.

Zadání z 22. 10. 2026. Hotová je fáze 1, fáze 2 se nezačíná bez Lukase
(viz níže).

## Odkazy

| Odkaz | Kam vede | Kde |
|---|---|---|
| `gymbar.app/gym?code=<kód>` | žebříček posilovny s nabídkou „Připojit se“ (existoval už dřív, QR na plakátu) | `socialGymDeepLink`, `docs/web/join.html` |
| `gymbar.app/ex?id=<slug>&gym=<id>` | detail cviku s ukázkou provedení (samolepka na stroji) | `exerciseDeepLink` v `lib/modules/links/deep_links.dart`, trasa `/exercises/slug/:slug`, web `join.html` |
| `gymbar.app/fitka?gym=<id>&ref=<kód>` | stránka pro majitele s předvybranou posilovnou | `docs/web/fitka/` |

- `id` cviku je **slug** vestavěného cviku (`bench_press`). Slug je stabilní
  napříč verzemi i jazyky, databázová ID ne.
- `gym` u samolepky aplikace zatím nepoužívá. Je připravený pro statistiku
  skenů (fáze 2).
- `/ex` je v App Links (`tool/platform/links.dart`, `tool/assetlinks.dart`,
  `AndroidManifest.xml`). Pro iOS je potřeba znovu vygenerovat
  `apple-app-site-association` (`dart run tool/assetlinks.dart`) a nahrát
  ho do proměnné `APPLE_APP_SITE_ASSOCIATION` (docs/deploy.md).
- Bez nainstalované aplikace web ukáže název cviku nebo kód posilovny
  a tlačítka do obchodů. Ukázka cviku na webu zatím není.

## Stránka gymbar.app/fitka

Statický web v `docs/web/fitka/`, cs/en podle prohlížeče (přepínač nahoře).

1. Úvod pro majitele: žebříček, návody u strojů, trenéři zdarma, 0 Kč.
2. **Hledání posilovny** („Název nebo město“) přes `GET /api/gyms?q=…`,
   předvybraná posilovna přes `?gym=<id>` (`GET /api/gyms?id=…`).
3. **Plakát A4 a A3** „Překonej mě“ s názvem posilovny a QR kódem na
   `/gym?code=…`.
4. **Samolepky na stroje**: majitel zaškrtne stroje (výchozí výběr je 12
   nejběžnějších), na arch A4 se vejde 12 samolepek, víc se vytiskne na další
   archy. Každá má QR na `/ex?id=…&gym=…`, název cviku a logo.
5. **Hecovací samolepky** 10 × 10 cm (žluté, 4 na arch A4) na legpress,
   bench, klec a mrtvý tah s texty, které schválil Lukas („Tady zvedám
   nejvíc já.“, „Zvedneš víc? Pochybuju.“, „Tahle klec je moje.“). QR vede
   do žebříčku fitka (`/gym?code=`). Texty jsou v `strings.js` (`chall`).
6. **Návod k vyvěšení** (recepce, šatna, u činek; samolepky ne na pohyblivé
   části).
7. „Už N členů vašeho fitka používá GymBar“, jen když N ≥ 5 (`memberCount`,
   udržují ho aplikace a pravidla při vstupu a odchodu).

Tisk je HTML s tiskovým CSS (`@page` A4/A3) a `window.print()`, takže jde
vytisknout nebo „Uložit jako PDF“. QR kód kreslí prohlížeč knihovnou
`docs/web/fitka/qrcode.js` (qrcode-generator 1.4.4, MIT, uložená přímo
na webu, ne z CDN). Písmo Archivo je v `docs/web/fitka/fonts/` (OFL). Na
serveru se nic negeneruje.

Soubory:

| Soubor | Obsah |
|---|---|
| `index.html` | stránka a tiskové styly plakátu a archu |
| `fitka.js` | jazyk, hledání, výběr samolepek, tisk |
| `strings.js` | texty cs/en (stejné klíče hlídá `functions/test/fitka_web.test.mjs`) |
| `exercises.js` | **generovaný** seznam cviků: `dart run tool/web_exercises.dart` (hlídá `test/web_exercises_test.dart`) |

Samolepky se nabízejí u cviků na stroji, kladce a s velkou činkou
(`stickerEquipment` v `tool/web_exercises.dart`), výchozí výběr je
`stickerDefaults` tamtéž. Grafika vychází z barev a loga webu
(`favicon.svg` = `assets/branding/logo.svg`). Až Lukas pošle export
artefaktu „GymBar – leták a samolepky“, dá se vzhled sladit.

### Proč hledá Cloud Function

Kolekci `gyms` smí číst jen přihlášení a pravidla Firestore neumí povolit
čtení jen některých polí. Stránka pro majitele je ale veřejná. Proto hledá
funkce **`gymDirectory`** (`functions/src/index.ts`, logika
`functions/src/fitka.ts`, testy `functions/test/fitka.test.mjs`), na kterou
Hosting přesměruje `/api/gyms` (`firebase.json`). Vrací jen název, město,
adresu, kód posilovny (je stejně vytištěný na plakátu) a počet členů od 5.
Nikdy `createdBy`, polohu ani data členů. Skryté posilovny a posilovny
zmizelé z OSM bez členů vynechá (jako `Gym.isListed`). Odpověď se
5 minut cachuje na CDN.

Funkce je veřejná (`invoker: "public"`). Když nasazení skončí chybou
oprávnění `run.services.setIamPolicy`, přidej účtu `github-deploy` roli
**Cloud Run Admin** (docs/deploy.md).

## „Doporuč GymBar svému fitku“ (aplikace)

Žebříček posilovny → tlačítko pod žebříčkem nebo menu → systémové sdílení
s předvyplněnou zprávou pro majitele (`socialGymRecommendText`, 10 jazyků)
a odkazem `gymbar.app/fitka?gym=<id>&ref=<kód>`.

- `ref` = prvních 8 znaků SHA-256 z uid (`gymReferralRef`). Uid se z něj
  vyčíst nedá.
- Po sdílení se zapíše `gymReferrals/{gymId}_{uid}`: `gymId`, `uid`,
  `count`, `createdAt`, `updatedAt`. Pravidla: zakládá jen člen té
  posilovny, každý jen svůj záznam, `count` jde jen o 1 nahoru, číst jde
  jen vlastní záznam, mazat nikdo (testy `tool/rules_test/test/fitka.test.mjs`).
  Po smazání účtu záznamy smaže `cleanupDeletedUser`.
- **Odměna není naprogramovaná** (Premium není spuštěné,
  `kPremiumLaunched = false`). Data jsou připravená, o odměně rozhodne
  Lukas.
- Zmínka je v `docs/web/privacy.html` (všechny jazyky).

## Web pro trenéry

Na stránce Klienti je karta **Materiály pro vaše fitko** s odkazem na
`gymbar.app/fitka` (otevřít / kopírovat). Trenér je přirozený prostředník
k majiteli.

## Ruční kontrola před nasazením

- Vytisknout (nebo uložit do PDF) plakát A4, A3 a arch samolepek
  a zkontrolovat okraje při měřítku 100 %.
- Naskenovat QR na plakátu a samolepce telefonem s aplikací (otevře
  žebříček / cvik) i bez ní (web s tlačítky do obchodů).

---

## Fáze 2 – až budou první partnerská fitka (nezačínat bez Lukase)

- **Formulář „Chci materiály poštou“** na `/fitka`: jméno, e-mail, adresa
  fitka, souhlas. Cloud Function s validací a omezením četnosti (App Check)
  zapíše do `gymPartnerRequests` (klienti ji nečtou). Doplnit `privacy.html`.
- **Partnerský profil fitka**: majitel si posilovnu převezme (ověření
  e-mailem nebo kódem z plakátu), doplní otevírací dobu, fotky a kontakt,
  posílá oznámení členům. Správa na webu po vzoru `trainer_web/`.
- **Statistiky pro fitka**: souhrnné počty (skeny QR podle parametru `gym`,
  noví členové žebříčku, aktivita podle dne v týdnu), žádná data
  o jednotlivcích.
- **Výzvy fitka a žebříček na TV**: měsíční výzva s cenou od fitka a režim
  celé obrazovky pro televizi v recepci.

## Mimo kód – pro Lukase

### Šablony zpráv

**Zpráva od člena majiteli** (sdílení z aplikace, cs):
> Ahoj, cvičím u vás a používám aplikaci GymBar. Má žebříček naší
> posilovny a návody ke strojům přes QR kód. Pro fitko je to zdarma
> a plakát i samolepky si můžete stáhnout tady: [odkaz] Bylo by super,
> kdyby u nás visel!

**Messenger / Instagram fitka (od Lukase):**
> Dobrý den, jsem Lukas, autor aplikace GymBar pro posilovnu. Pro
> [název fitka] jsem připravil zdarma plakát s žebříčkem vaší posilovny
> a QR samolepky s návody ke strojům. Stáhnete si je tady:
> gymbar.app/fitka?gym=[id] Rád pošlu i krátké video, jak to funguje. Díky!

### Video na 60 sekund (natočit telefonem)
1. (0–10 s) „Tohle je žebříček vaší posilovny.“ Ukázat žebříček v aplikaci.
2. (10–25 s) Sken QR na plakátu a připojení k žebříčku.
3. (25–40 s) Sken samolepky na stroji a ukázka provedení cviku.
4. (40–50 s) Trenér posílá klientovi plán.
5. (50–60 s) „Pro fitko zdarma. Materiály na gymbar.app/fitka.“

### Sada poštou
Obálka A4 se 2 plakáty A4, 1 plakátem A3, archem samolepek, krátkým
průvodním dopisem a návodem, kam co nalepit.

### Řetězce fitek
Kontaktovat centrálu, jedna dohoda pokryje všechny pobočky. Pro řetězec
pak připravit hromadný export plakátů pro všechny pobočky.

### Pozor na hromadné e-maily
Zákon č. 480/2004 Sb. omezuje nevyžádaná obchodní sdělení e-mailem i vůči
firmám. Neposílat hromadné e-maily na adresy z importu OSM. Přednost má
Messenger, kontaktní formulář, telefon nebo zpráva přes člena či trenéra.
E-maily posílat jednotlivě s možností odmítnutí. Před větším rozsahem si to
ověřit u právníka.
