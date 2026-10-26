# Hotové programy a úroveň pokročilosti

V Plánech → **Programy** je 17 hotových programů s 39 různými tréninky.
Program se přidá jako běžné (upravitelné) plány; při přidání se vybere cíl
(síla / svaly / výdrž) a dny. Kód: `lib/data/seed/plan_templates.dart`,
překlady `lib/data/seed/seed_translations.dart`.

## Přehled

| Úroveň | Program | Tréninky | Cíl |
| --- | --- | --- | --- |
| začátečník | Celé tělo (začátečník) | A, B – 3× týdně | volitelný |
| začátečník | Celé tělo – obměna | C, D | volitelný |
| začátečník | Celé tělo 2× týdně | 2× A, 2× B | volitelný |
| začátečník | Jednoručky doma | A, B | volitelný |
| začátečník | Vlastní váha doma | A, B (bez vybavení) | volitelný |
| začátečník | Stroje (začátečník) | A, B | volitelný |
| začátečník | Síla 5×5 | A, B | síla |
| začátečník | Kruhový trénink | A, B | výdrž |
| mírně pokročilý | Horní / dolní polovina | horní, dolní – 4× týdně | volitelný |
| mírně pokročilý | Horní / dolní – obměna | horní B, dolní B | volitelný |
| mírně pokročilý | Push / Pull / Nohy | push, pull, nohy | volitelný |
| mírně pokročilý | Push / Pull / Nohy – obměna | push B, pull B, nohy B | volitelný |
| mírně pokročilý | Síla – týdenní vlny | těžký, objemový, střední den | síla |
| mírně pokročilý | Kondice – intervaly | A, B | výdrž |
| pokročilý | Síla + objem (PHUL) | horní/dolní – síla, horní/dolní – objem | svaly |
| pokročilý | Síla – 4 dny | dřep, bench, mrtvý tah, tlak nad hlavu | síla |
| pokročilý | Push / Pull / Nohy 6× týdně | PPL A + PPL B (Po–So) | volitelný |

**Obměny** (`variationOf`) mají stejnou stavbu jako základní program, jen
jiné cviky. Doporučení: po 6–8 týdnech přejít na obměnu a pak zpět –
mírná obměna cviků podporuje rovnoměrný rozvoj svalů a drží motivaci,
příliš častá změna naopak brzdí učení techniky a sledování progrese.

## Úroveň pokročilosti

Zadává se v úvodním průvodci („Jak dlouho cvičíš?“) a v Profilu.

- **Začátečník:** méně než půl roku pravidelného tréninku nebo návrat po
  dlouhé pauze. ACSM: 8–12 opakování, 1–3 série, 2–3× týdně, celé tělo.
- **Mírně pokročilý:** zhruba půl roku až 2 roky pravidelně. ACSM:
  3–4× týdně, rozdělení na horní/dolní nebo push/pull/nohy, víc sérií.
- **Pokročilý:** přes 2 roky. ACSM: 4–6× týdně, periodizace (střídání
  těžkých a lehčích dnů), vyšší objem.

**Co úroveň mění:**

- V úvodu se nabídnou jen programy pro zvolenou úroveň, v Plánech jsou
  „Doporučené pro tebe“ nahoře a pod nimi ostatní úrovně.
- **Počet sérií** (`levelAdjustedSets`): program je sestavený pro jednu
  úroveň; uživatel o úroveň níž má u každého cviku o sérii míň (nejméně 2),
  o úroveň výš o sérii víc u vícekloubových cviků (nejvýš 5). Izolované
  cviky, cviky s jedinou sérií a programy s pevným cílem se nemění.
  Objem je hlavní proměnná pro růst svalů (Schoenfeld a kol. 2017:
  víc týdenních sérií na partii = větší přírůstek, ~10+ sérií týdně);
  začátečník ale roste i z menšího objemu a víc se soustředí na techniku.

**Jak se úroveň vyvíjí** (`lib/core/experience_level.dart`) – aplikace
nic nemění sama, na obrazovce Dnes navrhne změnu a uživatel ji potvrdí
nebo odmítne (další návrh nejdřív za 30 dní). Počítají se dokončené
plnohodnotné tréninky (ne 5minutový Plán B) od zvolení úrovně:

| Postup | Na úrovni aspoň | Tréninků | Za posledních 12 týdnů |
| --- | --- | --- | --- |
| začátečník → mírně pokročilý | 26 týdnů | 48 (~2× týdně) | 18 (1,5× týdně) |
| mírně pokročilý → pokročilý | 78 týdnů | 180 (~2,5× týdně) | 30 (2,5× týdně) |

Po **12 týdnech bez tréninku** aplikace navrhne úroveň o stupeň níž:
síla se při pauze do ~4 týdnů skoro nemění, výrazněji klesá zhruba po
8–12 týdnech. Po návratu se díky „svalové paměti“ vrací rychle, takže
postup zpět nahoru přijde zase s pravidelným tréninkem.

Profil ukazuje, kolik zbývá do další úrovně („12 z 48 tréninků, 8 z 26
týdnů“). Stávající uživatelé (migrace v25) s aspoň 50 tréninky začínají
jako mírně pokročilí, ostatní jako začátečníci.

## Zdroje

- ACSM: Progression Models in Resistance Training for Healthy Adults
  (2009) – doporučení podle úrovně (série, opakování, frekvence).
- Schoenfeld, Ogborn, Krieger: Dose-response relationship between weekly
  resistance training volume and increases in muscle mass (2017).
- Schoenfeld a kol.: Effects of resistance training frequency on measures
  of muscle hypertrophy (2016, 2019) – 2× týdně na partii, při stejném
  objemu frekvence rozhoduje málo.
- Rhea a kol.: A comparison of linear and daily undulating periodized
  programs (2002) – střídání zátěže v týdnu (program Síla – týdenní vlny).
- Mujika, Padilla: Muscular characteristics of detraining in humans (2001);
  McMaster a kol. (2013) – úbytek síly při pauze.
- Fonseca a kol. (2014), Kassiano a kol. (2022) – obměna cviků.
