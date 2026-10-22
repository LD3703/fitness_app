// Stránka gymbar.app/fitka (docs/web/fitka/, docs/fitka.md): majitel fitka
// si najde svou posilovnu a vytiskne plakát a samolepky. Stránka je
// veřejná (bez přihlášení), ale kolekci gyms smí číst jen přihlášení –
// pravidla Firestore neumí omezit čtení na vybraná pole. Proto hledá
// přes funkci gymDirectory (index.ts, /api/gyms), která vrací jen
// název, město, adresu, kód pro QR a počet členů od 5 výš. Nikdy data
// členů ani createdBy.
//
// Čistá logika bez Firestore – testy: functions/test/fitka.test.mjs.

/// Zrcadlo gymNameMaxLength (gym_logic.dart) a GYM_NAME_MAX (lib.mjs).
export const GYM_NAME_MAX = 60;

/// Kolik posiloven vrátí hledání.
export const FITKA_SEARCH_LIMIT = 20;

/// Počet členů se ukáže až od tohoto čísla (malé číslo nic neřekne
/// a u malé posilovny by šlo odhadnout, kdo v ní je).
export const FITKA_MIN_MEMBERS_SHOWN = 5;

const DIACRITICS: Record<string, string> = {
  "á": "a", "à": "a", "â": "a", "ä": "a", "ã": "a", "å": "a", "ą": "a",
  "č": "c", "ć": "c", "ç": "c",
  "ď": "d",
  "é": "e", "è": "e", "ê": "e", "ë": "e", "ě": "e", "ę": "e",
  "í": "i", "ì": "i", "î": "i", "ï": "i",
  "ľ": "l", "ĺ": "l", "ł": "l",
  "ň": "n", "ń": "n", "ñ": "n",
  "ó": "o", "ò": "o", "ô": "o", "ö": "o", "õ": "o", "ő": "o",
  "ř": "r", "ŕ": "r",
  "š": "s", "ś": "s", "ß": "ss",
  "ť": "t",
  "ú": "u", "ù": "u", "û": "u", "ü": "u", "ů": "u", "ű": "u",
  "ý": "y", "ÿ": "y",
  "ž": "z", "ź": "z", "ż": "z",
};

/// Zrcadlo normalizeGymSearch (gym_logic.dart, tool/gyms_import/lib.mjs).
export function normalizeGymSearch(input: string): string {
  const lower = input.toLowerCase().trim().replace(/\s+/g, " ");
  let s = "";
  for (const ch of lower.split("")) s += DIACRITICS[ch] ?? ch;
  return s.length > GYM_NAME_MAX ? s.substring(0, GYM_NAME_MAX) : s;
}

/// Pole, podle kterých se hledá prefixem (jako GymService.search).
export const FITKA_SEARCH_FIELDS = ["nameCity", "cityName", "nameLower", "cityLower"] as const;

/// Hledaný text z adresy: normalizovaný, aspoň 2 znaky, jinak null.
export function fitkaQuery(raw: unknown): string | null {
  if (typeof raw !== "string") return null;
  const q = normalizeGymSearch(raw);
  return q.length >= 2 ? q : null;
}

/// ID posilovny z adresy (Firestore ID nebo osm-n123), jinak null.
export function fitkaGymId(raw: unknown): string | null {
  if (typeof raw !== "string") return null;
  const id = raw.trim();
  return /^[A-Za-z0-9_-]{3,64}$/.test(id) ? id : null;
}

export interface PublicGym {
  id: string;
  name: string;
  city: string;
  address?: string;
  /// Kód posilovny – QR na plakátu vede na gymbar.app/gym?code=…
  code: string;
  /// Počet členů, jen od FITKA_MIN_MEMBERS_SHOWN.
  members?: number;
}

const str = (v: unknown): string => (typeof v === "string" ? v.trim() : "");

/// Veřejná podoba posilovny, nebo null, když se v adresáři neukazuje
/// (skrytá, zmizelá z OSM bez členů, bez kódu). Stejně jako Gym.isListed.
export function publicGym(id: string, d: Record<string, unknown>): PublicGym | null {
  const members = typeof d.memberCount === "number" ? d.memberCount : 0;
  if (d.hidden === true) return null;
  if (d.osmMissing === true && members <= 0) return null;
  const name = str(d.name);
  const code = str(d.code);
  if (!name || !/^[A-Z0-9]{4,12}$/.test(code)) return null;
  const g: PublicGym = { id, name, city: str(d.city), code };
  const address = str(d.address);
  if (address) g.address = address;
  if (members >= FITKA_MIN_MEMBERS_SHOWN) g.members = members;
  return g;
}

/// Spojí výsledky dotazů (bez duplicit), víc členů první, pak podle názvu.
export function mergeResults(lists: PublicGym[][], limit = FITKA_SEARCH_LIMIT): PublicGym[] {
  const byId = new Map<string, PublicGym>();
  for (const list of lists) for (const g of list) byId.set(g.id, g);
  return [...byId.values()]
    .sort((a, b) => (b.members ?? 0) - (a.members ?? 0) || a.name.localeCompare(b.name))
    .slice(0, limit);
}
