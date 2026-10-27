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
   a rozbal ho. Uvnitř je:
   - `GymBar.ipa` – základní verze, nainstaluje se vždy,
   - `GymBar-zdravi.ipa` – navíc s oprávněním pro Apple Zdraví (spánek,
     HRV, tep – `docs/readiness.md`). Je zkusmá: kdyby ji Sideloadly
     odmítl, použij `GymBar.ipa`,
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
- **Bez widgetu, Live Activity a aplikace pro Apple Watch** – v `.ipa`
  nejsou (každé rozšíření potřebuje další App ID a App Group).
- Apple Zdraví jen ve `GymBar-zdravi.ipa`.

Všechno z toho bude fungovat ve verzi z TestFlightu (README 2b, krok 3).
