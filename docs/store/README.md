# Texty do obchodů

Popis aplikace pro Google Play a App Store pro všechny lokalizace
obchodů, které odpovídají jazykům aplikace. Struktura souborů odpovídá
nástroji fastlane (`supply` pro Google Play, `deliver` pro App Store),
takže jde texty později nahrávat automaticky; zatím je stačí zkopírovat
do Play Console a App Store Connect.

Podklady k formulářům (Bezpečnost dat, Health Connect, App Privacy,
hodnocení obsahu) jsou v dokumentu „Texty a formuláře pro obchody“.

## Lokalizace

| Jazyk | Google Play | App Store | Poznámka |
| --- | --- | --- | --- |
| angličtina | en-US (výchozí), en-GB, en-AU, en-CA | en-US (výchozí), en-GB, en-AU, en-CA | GB/AU: britský pravopis (programme), „PB“ místo „PR“ |
| čeština | cs-CZ | cs | |
| slovenština | sk | sk | |
| němčina | de-DE | de-DE | |
| španělština | es-ES, es-419, es-US | es-ES, es-MX | Latinská Amerika: „celular“, vlastní klíčová slova (rutina) |
| francouzština | fr-FR, fr-CA | fr-FR, fr-CA | Kanada: bez slangového „muscu“ |
| italština | it-IT | it | |
| nizozemština | nl-NL | nl-NL | |
| polština | pl-PL | pl | |
| portugalština | pt-BR, pt-PT | pt-BR, pt-PT | Portugalsko: evropská portugalština (telemóvel, ginásio, tykání) |

Aplikace sama má jednu portugalštinu (brazilskou) a jednu španělštinu –
lokalizace obchodu pro Portugalsko a Latinskou Ameriku mění jen popis
v obchodě.

## Soubory

`google_play/<lokalizace>/`

| Soubor | Pole v Play Console | Limit |
| --- | --- | --- |
| `title.txt` | Název aplikace | 30 znaků |
| `short_description.txt` | Krátký popis | 80 znaků |
| `full_description.txt` | Úplný popis | 4000 znaků |
| `changelogs/1.txt` | Poznámky k verzi (číslo = versionCode) | 500 znaků |

`app_store/<lokalizace>/`

| Soubor | Pole v App Store Connect | Limit |
| --- | --- | --- |
| `name.txt` | Name | 30 znaků |
| `subtitle.txt` | Subtitle | 30 znaků |
| `promotional_text.txt` | Promotional Text | 170 znaků |
| `keywords.txt` | Keywords | 100 bajtů |
| `description.txt` | Description (bez widgetu, odpočtu na zamčené obrazovce, Health Connect a Wear OS; s Apple Zdravím) | 4000 znaků |
| `release_notes.txt` | What’s New | 4000 znaků |

Název aplikace je v `google_play/<lokalizace>/title.txt` a
`app_store/<lokalizace>/name.txt` (obojí max. 30 znaků): „GymBar:“
a krátký popis v jazyce obchodu, aby lidé našli aplikaci i podle slov
jako „gym“ nebo „trénink“. Pod ikonou v telefonu je jen „GymBar“. Texty
popisují stav bez Premium a bez reklam – po jejich spuštění je uprav
(hlavně větu „Bez reklam“).
