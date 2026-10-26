# Regenerace z hodinek a prstenů

GymBar čte z **Health Connect** (Android) a **Apple Zdraví** (iOS) data,
která tam zapisují hodinky a prsteny (Galaxy Watch, Pixel Watch, Apple
Watch, Garmin, Oura, Galaxy Ring, Ultrahuman, RingConn…), a podle nich
doporučí, jak dnes trénovat. Jen čtení – do Health se odsud nic nezapisuje
a data zůstávají v telefonu (v automatické záloze, pokud je zapnutá).

Zapnutí: Profil → Health Connect / Apple Zdraví → **Regenerace z hodinek
a prstenů**.

| Co | Kde |
| --- | --- |
| Vyhodnocení (čistý Dart, testy `test/readiness_test.dart`) | `lib/core/readiness.dart` |
| Čtení z Health, denní data (tabulka `RecoveryDays`, schéma v24), tep tréninku | `lib/modules/health/recovery.dart`, `health_service.dart` |
| Karta Připravenost na Dnes, detail `/readiness`, dialog před tréninkem, tep v souhrnu | `lib/modules/health/recovery_ui.dart` |
| Lehčí trénink (o třetinu méně sérií, váhy −10 %, progrese drží) | `workout_service.dart` (`lighterTargets`), `workout_screen.dart`, `HoldReason.readiness` |
| Živý tep z hodinek | `lib/services/live_heart_rate.dart`, `docs/wear_os.md` |
| Oprávnění (READ_SLEEP, READ_HEART_RATE_VARIABILITY, READ_RESTING_HEART_RATE, READ_HEART_RATE; popis HealthKit) | `tool/platform/health.dart` |

## Data

- **Spánek** – fáze spánku (lehký, hluboký, REM, „spí“) v noci od 18:00
  předchozího dne do 14:00. Úseky ze všech zdrojů se sjednotí, takže noc
  zapsaná prstenem i hodinkami se nesečte dvakrát. Bez fází celá spánková
  relace (Health Connect).
- **HRV** – Health Connect RMSSD, HealthKit SDNN (Apple Watch). Denní
  hodnota = medián měření v noci. Typy se mezi sebou neporovnávají – vše se
  hodnotí proti vlastnímu průměru, takže na typu nezáleží.
- **Klidový tep** – medián hodnot zapsaných během dne.
- **Tep během tréninku** – živě z aplikace GymBar v hodinkách, jinak
  vzorky z Health za dobu tréninku (hodinky je někdy zapíšou až po
  synchronizaci – doplní se do 3 dnů).

Synchronizace: při otevření Dnes a návratu do aplikace, nejvýš jednou za
15 minut; poprvé 60 dní zpět (Health Connect k tomu potřebuje oprávnění
k historii, aplikace o něj požádá).

## Vyhodnocení

Každý má jiné „normální“ hodnoty, proto se vše porovnává s vlastním
průměrem za **60 dní** (potřeba je aspoň **14 dní** dat, do té doby
„Učím se“ a hodnotí se jen spánek).

| Údaj | Pravidlo | Body |
| --- | --- | --- |
| HRV | 7denní průměr ln(HRV) (aspoň 3 měření) pod normálem = 60denní průměr − 0,75 SD | 2 |
| HRV | dnešní hodnota pod průměrem − 1,5 SD (prudký pokles) | 1 |
| Klidový tep | dnes o 5–9 tepů nad průměrem | 1 |
| Klidový tep | dnes o 10+ tepů nad průměrem | 2 |
| Klidový tep | 3 dny po sobě o 5+ nad průměrem | 2 |
| Spánek | méně než 6 h / méně než 5 h | 1 / 2 |
| Spánek | méně než 7 h (jen informace) | 0 |
| Spánek | dluh za 3 noci proti 7 h aspoň 3 h | 1 |

**0 bodů = Dobrá** (trénuj podle plánu), **1–2 = Opatrně** (podle plánu,
2 opakování v záloze, delší pauzy, bez rekordů), **3+ = Slabší
regenerace** (lehčí trénink nebo Plán B; když je klidový tep 3 dny zvýšený
a k tomu výrazně nad normálem nebo HRV pod normálem → doporučení
odpočinku a zápisu nemoci).

Spodní mez SD ln(HRV) je 0,08 – u velmi stabilních hodnot by byl normál
tak úzký, že by „mimo“ byla každá noc (běžná variabilita mezi dny je
0,1–0,2).

**Lehčí trénink** (tlačítko na kartě nebo v dialogu před tréninkem):
o třetinu méně pracovních sérií (zaokrouhleno dolů, odebírají se
poslední), váhy pracovních sérií −10 % (zaokrouhlené na krok činky),
automatická progrese po tréninku „drží“ (výkon na slabší den nevypovídá
o síle; odlehčení po neúspěších zůstává).

**Tep během tréninku:** průměr, maximum, čas v zónách podle % maximálního
tepu (208 − 0,7 × věk; 50–60 / 60–70 / 70–80 / 80–90 / 90+ %) a energie
podle tepu (Keytel 2005, rovnice bez VO2max) – jen když je v profilu rok
narození, pohlaví a je zapsaná váha.

## Zdroje

- Watson a kol. (2015): *Recommended Amount of Sleep for a Healthy Adult*,
  konsenzus AASM a SRS – dospělí aspoň 7 h.
  [aasm.org](https://aasm.org/seven-or-more-hours-of-sleep-per-night-a-health-necessity/)
- Knowles a kol. (2018): *Inadequate sleep and muscle strength:
  Implications for resistance training* – po několika kratších nocích
  klesá síla ve vícekloubových cvicích.
  [PubMed 29422383](https://pubmed.ncbi.nlm.nih.gov/29422383/)
- Craven a kol. (2022), metaanalýza: nedostatek spánku = ≤ 6 h za 24 h.
  [Stronger by Science](https://www.strongerbyscience.com/research-spotlight-sleep-loss/)
- Plews a kol. (2012): *Heart rate variability in elite triathletes* –
  7denní průměr ln rMSSD, pokles před přetížením.
  [PubMed 22367011](https://pubmed.ncbi.nlm.nih.gov/22367011/)
- HRV4Training (M. Altini): normální rozsah z 60 dní, „normální je lepší
  než vyšší“.
  [hrv4training.com](https://www.hrv4training.com/blog2/determining-your-normal-range)
- Vesterinen / Kiviniemi (Jyväskylä): trénink řízený HRV – intenzivní
  trénink, když je 7denní průměr v pásmu nejmenší významné změny.
  [JYX](https://jyx.jyu.fi/handle/123456789/45036)
- Oura: připravenost proti vlastním hodnotám (14denní vážený průměr proti
  2 měsícům, klidový tep v noci).
  [support.ouraring.com](https://support.ouraring.com/hc/en-us/articles/360025589793)
- Klidový tep o 5+ nad normálem jako varování – praxe trenérů
  (TrainingPeaks, Athlete Data).
  [TrainingPeaks](https://www.trainingpeaks.com/blog/the-4-signs-of-overtraining)
- Tanaka, Monahan, Seals (2001): *Age-predicted maximal heart rate
  revisited* – 208 − 0,7 × věk.
- Keytel a kol. (2005): *Prediction of energy expenditure from heart rate
  monitoring during submaximal exercise*.
  [PubMed 15966347](https://pubmed.ncbi.nlm.nih.gov/15966347/)

Nejde o lékařské vyhodnocení – texty v aplikaci to říkají a doporučují
řídit se tím, jak se člověk cítí.
