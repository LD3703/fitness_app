// Srovnání síly „Jak si vedu“ (docs/social.md, „Srovnání se zemí
// a světem“): z žebříčků posiloven (gyms/{gymId}/entries) se jednou
// denně spočítají anonymní rozložení nejtěžších vah – pro každou zemi
// (podle země posilovny) a pro celý svět, zvlášť podle pohlaví a věkové
// skupiny. Aplikace z nich spočítá percentil („lepší než 78 %“).
//
// Do statistik jdou jen záznamy, které už jsou v žebříčku vidět ostatním
// členům (ne skryté). Zveřejňují se jen kvantily (5., 10., … 95. percentil,
// zaokrouhlené na 2,5 kg), ne přesné rozložení: z rozdílu skupin (všichni
// − muži) ani dvou denních snímků tak nejde vyčíst výkon jednotlivce
// a nejsilnější člověk (maximum) se neukáže. Skupina s méně než
// LIFT_STATS_MIN_N lidmi má jen počet.
//
// Čistá logika bez Firestore – testy: functions/test/liftStats.test.mjs.
import { GYM_CATEGORIES, GymCategory, isLift } from "./plausibility.js";

/// Nejmenší skupina, pro kterou se rozložení zveřejní (zrcadlo
/// kLiftStatsMinN v strength_rank.dart).
export const LIFT_STATS_MIN_N = 20;

export const LIFT_CATEGORIES = GYM_CATEGORIES.filter(isLift);
export const GENDER_KEYS = ["all", "male", "female"] as const;
export const AGE_KEYS = ["all", "u40", "40", "50", "60"] as const;

/// Rozsah „svět“ v ID dokumentu (země jsou ISO 3166-1, např. CZ).
export const WORLD = "world";

export interface StatEntry {
  uid: string;
  category: string;
  value: number;
  gender: string | null;
  ageGroup: string | null;
  /// Země posilovny (ISO 3166-1), null = neznámá (jen svět).
  country: string | null;
}

export interface StatGroup {
  /// Počet lidí ve skupině.
  n: number;
  /// Kvantily: q[i] = (5·(i+1)). percentil, i = 0…18, na 2,5 kg (jen od MIN_N).
  q?: number[];
}

/// Krok zaokrouhlení kvantilů (kg).
export const LIFT_STATS_STEP = 2.5;

export interface LiftStatsDoc {
  scope: string;
  category: GymCategory;
  groups: Record<string, StatGroup>;
}

/// Klíč skupiny: „{pohlaví}_{věk}“, např. „all_all“, „male_40“.
export const groupKey = (gender: string, age: string): string => `${gender}_${age}`;

/// ID dokumentu liftStats: „{rozsah}_{kategorie}“, např. „CZ_bench_press“.
export const liftStatsDocId = (scope: string, category: string): string => `${scope}_${category}`;

/// Hodnota záznamu do statistik, nebo null (skrytý, nesmyslný, neznámá
/// kategorie). Stejně jako žebříček: na 0,5 kg.
export function statValue(d: Record<string, unknown>): number | null {
  if (d.hidden === true) return null;
  const category = d.category;
  if (typeof category !== "string" || !(LIFT_CATEGORIES as string[]).includes(category)) return null;
  const best = d.best;
  if (typeof best !== "number" || !Number.isFinite(best) || best <= 0) return null;
  return Math.round(best * 2) / 2;
}

/// Země z dokumentu posilovny: ISO 3166-1 alpha-2 velkými písmeny, jinak null.
export function gymCountry(d: Record<string, unknown> | undefined): string | null {
  const c = d?.country;
  if (typeof c !== "string") return null;
  const up = c.trim().toUpperCase();
  return /^[A-Z]{2}$/.test(up) ? up : null;
}

/// 5., 10., … 95. percentil (nejbližší pořadí) zaokrouhlený na 2,5 kg.
export function quantiles(values: number[]): number[] {
  const sorted = [...values].sort((a, b) => a - b);
  const out: number[] = [];
  for (let p = 5; p <= 95; p += 5) {
    const rank = Math.min(sorted.length, Math.max(1, Math.ceil((p / 100) * sorted.length)));
    out.push(Math.round(sorted[rank - 1] / LIFT_STATS_STEP) * LIFT_STATS_STEP);
  }
  return out;
}

/// Statistiky pro všechny rozsahy a kategorie. Jeden člověk = jedna
/// hodnota na kategorii (nejvyšší, kdyby jich bylo víc).
export function buildLiftStats(entries: StatEntry[], minN = LIFT_STATS_MIN_N): LiftStatsDoc[] {
  const best = new Map<string, StatEntry>();
  for (const e of entries) {
    const k = `${e.uid}|${e.category}`;
    const prev = best.get(k);
    if (!prev || e.value > prev.value) best.set(k, e);
  }
  // rozsah → kategorie → skupina → hodnoty
  const acc = new Map<string, Map<string, Map<string, number[]>>>();
  const add = (scope: string, e: StatEntry) => {
    let byCat = acc.get(scope);
    if (!byCat) acc.set(scope, (byCat = new Map()));
    let byGroup = byCat.get(e.category);
    if (!byGroup) byCat.set(e.category, (byGroup = new Map()));
    const genders = ["all", ...(e.gender === "male" || e.gender === "female" ? [e.gender] : [])];
    const ages = ["all", ...((AGE_KEYS as readonly string[]).includes(e.ageGroup ?? "") && e.ageGroup !== "all" ? [e.ageGroup as string] : [])];
    for (const g of genders) {
      for (const a of ages) {
        const key = groupKey(g, a);
        const list = byGroup.get(key);
        if (list) list.push(e.value);
        else byGroup.set(key, [e.value]);
      }
    }
  };
  for (const e of best.values()) {
    add(WORLD, e);
    if (e.country) add(e.country, e);
  }
  const docs: LiftStatsDoc[] = [];
  for (const [scope, byCat] of acc) {
    for (const [category, byGroup] of byCat) {
      const groups: Record<string, StatGroup> = {};
      for (const [key, values] of byGroup) {
        groups[key] = values.length >= minN
          ? { n: values.length, q: quantiles(values) }
          : { n: values.length };
      }
      docs.push({ scope, category: category as GymCategory, groups });
    }
  }
  return docs;
}
