# Motivy vzhledu

Podle šablon „GymBar – šablony vzhledu“ (návrh v plátně Design, 23. 10.
2026). Uživatel si motiv vybere v **Profil → Motiv** (náhledy všech motivů).
Kód: `lib/ui/skins.dart`, výběr `lib/features/profile/skin_picker.dart`,
testy `test/skins_test.dart`.

| Motiv | Klíč | Pozadí | Hlavní barva | Písma | Ozdoba záhlaví | Rohy |
|---|---|---|---|---|---|---|
| **Klasik** (výchozí) | `classic` | tmavé #111111 | limetková #C8F03C | Archivo Black + Archivo | drobné činky | 16 |
| Květy | `flowers` | krémové #FFF7F4 | malinová #C2336A, levandulová | Fraunces + Nunito | kytičky | 24, tlačítka pilulka |
| Lebky | `skulls` | černé #0A0A0A | krvavě červená #D62B1A | Bebas Neue + Barlow | lebky a blesky, červená čára | 2 |
| Neon | `neon` | noční fialová #0D0A1E | tyrkysová #22E3F0, růžová #FF4FD8 | **Oxanium** + Space Grotesk | synthwave slunce a mřížka, záře karet | 14 |
| Retro gym | `retro` | papírová #F1E6D0 | cihlová #8C2F1B, hořčicová #E0A526 | Alfa Slab One + Work Sans | hvězdy a pruhy 70. let, 2px obrysy | 8 |
| Y2K samolepky | `y2k` | ledově levandulová #E3E8FF | modrá #3A5BFF, růžová #FF3EA5, limetková | Unbounded + DM Sans | nálepky (jiskry, smajlík, motýl), 2px obrysy | 22, tlačítka pilulka |
| Původní | `original` | podle režimu | teal z loga | Archivo + systémové | – | 16 |

- **Výchozí je Klasik** (i pro dřívější uživatele, verze schématu 20 přidala
  `UserProfiles.skin`, null = Klasik).
- Světlý / tmavý režim (Profil → Vzhled) platí jen pro **Původní**; ostatní
  motivy mají pevné barvy a položka Vzhled se u nich nezobrazuje.
- **Neon používá Oxanium místo Orbitronu** ze šablony: Orbitron nemá česká
  písmena (č, ř, ě, ů…), Oxanium je mu nejpodobnější a má je.
- Písma jsou přibalená (`assets/fonts/skins/`, statické řezy z Google Fonts,
  cca 2,7 MB), aplikace je nestahuje. Licence OFL v
  `assets/fonts/skins/licenses/` se ukazují v O aplikaci → Licence.
- Barvy textu mají kontrast aspoň 4,5 : 1 (hlídá `test/skins_test.dart`).
- Ozdoba záhlaví je jen na obrazovce Dnes (`SkinHeaderMotif`). Ze šablon
  zatím nejsou převzaté detaily jednotlivých karet (rekord jako kvítek /
  lebka / nálepka „W“, štítek „jdeme na to“, tvrdé stíny u Retro a Y2K) –
  motiv mění barvy, písma, tvary a záhlaví celé aplikace.
- Logo, sdílené obrázky a plakáty zůstávají v barvách značky.
