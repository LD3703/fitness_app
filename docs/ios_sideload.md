# Vyzkoušení v iPhonu bez Macu a bez placeného účtu

Dokud není Apple Developer účet (TestFlight, README kapitola 2b), jde
GymBar nainstalovat do vlastního iPhonu z Windows přes **Sideloadly**
s **bezplatným Apple ID**. Soubor `.ipa` sestaví GitHub Actions (job
**iOS .ipa pro instalaci bez Macu** v `.github/workflows/ci.yml`) po každém
pushi, i do `main`.

## 1. Stažení .ipa

1. github.com → repozitář `fitness_app` → **Actions** → poslední zelený
   běh **CI** na větvi `main`.
2. Dole v sekci **Artifacts** stáhni **gymbar-ios-ipa** (zip, platí 30 dní)
   a rozbal ho. Uvnitř je (zkoušej v tomto pořadí):
   - `GymBar-zdravi-pauza.ipa` – s Apple Zdraví (spánek, HRV, tep –
     `docs/readiness.md`) a **odpočtem pauzy na zamčené obrazovce**
     (Live Activity, `docs/ios_widget.md`). Zkusmá: rozšíření potřebuje
     další App ID a bezplatné Apple ID ho nemusí dovolit,
   - `GymBar-zdravi.ipa` – jen s Apple Zdravím,
   - `GymBar.ipa` – základní verze, nainstaluje se vždy,
   - `VERZE.txt` – verze a commit.

## 2. Příprava Windows (jednorázově)

1. **iTunes** a **iCloud** z webu Applu (apple.com/itunes,
   support.apple.com → iCloud pro Windows) – verze z Microsoft Store
   Sideloadly nepozná.
2. **Sideloadly** ze sideloadly.io.
3. iPhone připoj kabelem, odemkni a potvrď **Důvěřovat tomuto počítači**.

## 3. Instalace

1. V Sideloadly vyber iPhone, do pole **Apple account** napiš své Apple ID
   a přetáhni do okna `.ipa`. Klikni **Start** a zadej heslo k Apple ID
   (s dvoufázovým ověřením i kód). Heslo jde jen k Applu.
2. iPhone: **Nastavení → Soukromí a zabezpečení → Režim pro vývojáře** –
   zapnout a restartovat (iOS 16 a novější).
3. iPhone: **Nastavení → Obecné → VPN a správa zařízení** → tvé Apple ID →
   **Důvěřovat**.
4. Otevři GymBar.

Nová verze: stáhni nový artefakt a nainstaluj stejně – data v aplikaci
zůstanou (stejné Apple ID a stejný Bundle ID).

## Omezení bezplatného Apple ID

- Aplikace funguje **7 dní**, pak ji Sideloadly znovu nainstaluje (data
  zůstanou). Najednou jdou mít nejvýš 3 takové aplikace.
- **Bez push notifikací** (pozvánky a zprávy od trenéra), **přihlášení
  přes Apple** a otevírání odkazů gymbar.app v aplikaci – to bezplatné
  Apple ID neumí. Místní připomínky (ranní připomínka, konec pauzy)
  a přihlášení přes Google / e-mail fungují.
- **Odpočet pauzy na zamčené obrazovce** (Live Activity) jen ve
  `GymBar-zdravi-pauza.ipa`. V ostatních verzích je odpočet jen
  v aplikaci (na obrazovce tréninku a po odchodu z ní nad spodní
  navigací) a na konci pauzy přijde notifikace.
- Widget Dnes na ploše zůstane prázdný (potřebuje App Group) a aplikace
  pro Apple Watch v `.ipa` není.
- Apple Zdraví jen ve verzích `-zdravi`.

Všechno z toho bude fungovat ve verzi z TestFlightu (README 2b, krok 3).
