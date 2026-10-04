# Tón zpráv – přísný trenér

Přehled všech přísných textů (čeština je master, klíče v `lib/l10n/app_*.arb`).
Varianty se střídají po dnech (`messageVariant`), během jednoho dne zůstává
stejná. Výběr: `lib/ui/coach_messages.dart`, logika tónu:
`lib/core/coach_tone.dart`. Tón se volí v onboardingu i v Profilu
(`UserProfile.coachTone`: 0 = přátelský, 1 = přísný trenér).

## Vynechání / odložení tréninku

Dialog na obrazovce Dnes po „Dnes vynechat“ / „Odložit na zítra“ (`strictSkipMessage`).

1. Tak ty chceš dneska vynechat trénink, ty lenochu? Gauč má radost, svaly ne. — `coachSkip1`
2. Skvělá volba. Gauč tě určitě vytrénuje sám. — `coachSkip2`
3. Výmluva zaznamenána. Do statistik ji nedám, byla by tam moc často. — `coachSkip3`
4. Dneska volno? Aha. A včera jsi byl unavený z čeho přesně? — `coachSkip4`
5. Činky se ptaly, kde jsi. Řekl jsem jim, že máš „důležité věci“. — `coachSkip5`

## Ranní připomínka

Text notifikace s plánem na dnešek; `{plans}` = názvy plánů (`strictMorningBody`).

1. Dobré ráno. Dnes: {plans}. A ne, „mám toho moc“ není cvik. — `coachMorning1`
2. Dnes: {plans}. Činky se samy nezvednou – zkoušel jsem to. — `coachMorning2`
3. {plans} tě dnes čeká. Ozvi se, až dohledáš výmluvu. Nebo radši rovnou přijď. — `coachMorning3`
4. Dnes je na řadě {plans}. Gauč ti dnes smí zamávat jen z dálky. — `coachMorning4`
5. Plán na dnešek: {plans}. Budoucí ty se už teď stydí za dnešní výmluvu. Tak ji nevymýšlej. — `coachMorning5`

## Připomínka pití

Text notifikace; `{goal}` = denní cíl, např. „2 500 ml“ (`strictWaterBody`).

1. Cíl na dnes: {goal}. I kaktus pije víc než ty. — `coachWater1`
2. Láhev není dekorace. Dnešní cíl: {goal}. — `coachWater2`
3. Pij, nebo stagnuj. Dnešní cíl: {goal}. — `coachWater3`
4. Svaly jsou ze tří čtvrtin voda. Tvůj pitný režim zatím ani z čtvrtiny. Cíl: {goal}. — `coachWater4`
5. Žízeň je poslední varování. Nečekej na ni – dnes {goal}. — `coachWater5`

## Plán B – nabídka přesunu

Po dokončení plánu B, nabídka přesunout celý trénink; `{plan}` = název plánu (`strictPlanBPostpone`).

1. Pět minut? Roztomilé. „{plan}“ přesuneš na zítřek, nebo to rovnou vzdáme? — `coachPlanBPostpone1`
2. Zahřívačka hotová. Teď to hlavní: „{plan}“ zítra, nebo dnes zase vyhrál gauč? — `coachPlanBPostpone2`
3. To byla ochutnávka. Celé menu „{plan}“ zítra? — `coachPlanBPostpone3`

## Plán B – hotovo

Hláška po dokončení plánu B (`strictPlanBDone`).

1. Pět minut je víc než nula. Ale nula je hodně nízká laťka. — `coachPlanBDone1`
2. Hotovo. Jen ať se z plánu B nestane plán A. — `coachPlanBDone2`
3. Lepší než nic. Zítra prosím něco víc než „lepší než nic“. — `coachPlanBDone3`

## Souhrn po tréninku

Pochvala nahoře v dialogu souhrnu (`strictDoneMessage`).

1. Hele, ono to jde. Kdo by to byl řekl. — `coachDone1`
2. Dobrá práce. Gauč dnes prohrál. — `coachDone2`
3. Hotovo. Svaly si to zapamatují, výmluvy ne. — `coachDone3`
4. Trénink odškrtnutý. Výmluvy měly dnes volno. — `coachDone4`
5. Tak vidíš. A to se ti ráno ani nechtělo. — `coachDone5`

## Tipy při stagnaci

Karta progresivního přetížení; `{weight}` = přírůstek, např. „2,5 kg“.

- Pořád stejná opakování? Ta činka tě už zná nazpaměť. Přidej 1–2 opakování v každé pracovní sérii. — `coachTipAddReps`
- Zóna pohodlí odhalena. Jedna pracovní série navíc – nekousne. — `coachTipAddSet`
- Ty váhy se už nudí. Přidej {weight} na pracovní série. — `coachTipAddWeight`

## Dialog únavy před tréninkem

Partie unavená ≥ 80 %; `{group}` = partie, `{percent}` = únava v %
(`strictFatigueWarning`). Přísná forma, ale vždy doporučuje odpočinek –
k tréninku netlačí.

1. Žádné hrdinství: partie {group} je unavená na {percent} %. I drsňáci regenerují – chytrá volba je plán B nebo zítřek. Trénuj, jen když se fakt cítíš čerstvě. — `coachFatigueWarning1`
2. Partie {group} má pořád {percent} % únavy. Odpočinek je taky trénink. Plán B, zítra, nebo i tak trénovat? — `coachFatigueWarning2`

## Onboarding

- Nadpis: Tón zpráv — `coachToneTitle`
- Úvod: Jak s tebou mám mluvit? Platí pro připomínky a hlášky v aplikaci. — `onboardingToneIntro`
- Karta „Přátelský“: ukázka `encSkipNormal1` ve tvaru `onboardingToneExample` – Například: „Nevadí, jeden trénink nic nerozhodne. Příště to doženeš.“
- Karta „Přísný trenér“: ukázka `coachSkip2` – Například: „Skvělá volba. Gauč tě určitě vytrénuje sám.“
  a pod ní `coachToneStrictHint` – Drsná láska – kromě nemoci, zranění, zotavování a velké únavy.

## Bezpečnostní pravidla (kdy se přísný tón potlačí)

- **Nemoc, zranění, zotavování po nemoci (7 dní):** přísný tón se nepoužije
  nikde; zobrazí se přátelský / podpůrný text (`strictToneAllowed`).
- **Únava partie ≥ 80 %** (`fatigueWarningPercent`): zprávy, které tlačí do
  tréninku (vynechání, ranní připomínka, plán B, tipy při stagnaci), jsou
  přátelské. `resolveCoachTone(ref)` / `effectiveCoachTone(…, maxFatigue:)`;
  při chybě odhadu únavy se použije přátelský tón.
- **Pití** (`strictWaterBody`) a **dialog únavy** k tréninku netlačí – únava
  se u nich neověřuje, platí jen pravidlo nemoci / zranění / zotavování.
  Přísný dialog únavy vždy doporučuje odpočinek nebo plán B.
- **Souhrn po tréninku:** pokud pro situaci existuje wellbeing hláška
  (`wellbeingMessage(…, MessagePlace.summary, …)` – nemoc, zranění,
  zotavování, rýsování), zobrazí se vždy ona. Přísná pochvala
  (`strictDoneMessage`) jen v normální situaci a jen při zvoleném přísném
  tónu. Únava se tu neověřuje – souhrn k tréninku netlačí a po tréninku
  bývá trénovaná partie skoro vždy nad 80 %.
- **Obsah textů:** hravý sarkasmus, žádné vulgarismy, nikdy se nevysmívá
  postavě, váze, vzhledu ani identitě. Oslovení vždy tykáním; v ostatních
  jazycích přednostně rodově neutrální formulace.
