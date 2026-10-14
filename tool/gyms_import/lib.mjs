// Čistá logika importu posiloven z OpenStreetMap (bez sítě a Firebase).
// Testy: node --test tool/gyms_import/lib.test.mjs
// Popis: docs/gyms_import.md

// ---------------------------------------------------------------------------
// Země
// ---------------------------------------------------------------------------

/// Evropa (EU, EHP, Spojené království, Švýcarsko, Balkán, malé státy,
/// Ukrajina, Moldavsko). Rusko, Bělorusko a Turecko nejsou ve výchozím
/// seznamu – dají se přidat přes --countries.
export const EUROPE = [
  'AD', 'AL', 'AT', 'BA', 'BE', 'BG', 'CH', 'CY', 'CZ', 'DE', 'DK', 'EE',
  'ES', 'FI', 'FO', 'FR', 'GB', 'GG', 'GI', 'GR', 'HR', 'HU', 'IE', 'IM',
  'IS', 'IT', 'JE', 'LI', 'LT', 'LU', 'LV', 'MC', 'MD', 'ME', 'MK', 'MT',
  'NL', 'NO', 'PL', 'PT', 'RO', 'RS', 'SE', 'SI', 'SK', 'SM', 'UA', 'VA',
  'XK',
];

/// Severní, Střední a Jižní Amerika a Karibik.
export const AMERICAS = [
  'US', 'CA', 'MX', 'PR',
  'BZ', 'CR', 'GT', 'HN', 'NI', 'PA', 'SV',
  'AG', 'AW', 'BB', 'BS', 'CU', 'CW', 'DM', 'DO', 'GD', 'HT', 'JM', 'KN',
  'KY', 'LC', 'TT', 'VC',
  'AR', 'BO', 'BR', 'CL', 'CO', 'EC', 'GY', 'PE', 'PY', 'SR', 'UY', 'VE',
];

/// Velké země se rovnou stahují po regionech (státech, spolkových zemích…),
/// celá země najednou by na serveru Overpass vypršela. Ostatní země se po
/// regionech stáhnou automaticky, když dotaz na celou zemi selže.
export const SPLIT_BY_REGION = new Set([
  'US', 'CA', 'BR', 'MX', 'AR', 'DE', 'FR', 'GB', 'IT', 'ES', 'PL',
]);

export function countriesFor(region) {
  switch (region) {
    case 'europe': return [...EUROPE];
    case 'americas': return [...AMERICAS];
    case 'all': return [...EUROPE, ...AMERICAS];
    default: throw new Error(`Unknown region: ${region}`);
  }
}

// ---------------------------------------------------------------------------
// Dotazy Overpass
// ---------------------------------------------------------------------------

/// Výběr oblasti: celá země (ISO 3166-1) nebo region (ISO 3166-2).
export function areaSelector(code) {
  return code.includes('-')
    ? `area["ISO3166-2"="${code}"]`
    : `area["ISO3166-1"="${code}"][admin_level=2]`;
}

/// Veřejné servery Overpass (stejná data OpenStreetMap). Import je střídá:
/// když jeden vrací 504 nebo neodpovídá, zkusí další.
export const OVERPASS_ENDPOINTS = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
];

/// Limit běhu dotazu na serveru (s). Menší limit server přijme i při
/// zátěži; co se nestihne, stáhne se po regionech.
export const OVERPASS_QUERY_TIMEOUT = 600;

/// Kolik přechodných chyb (504, výpadek…) snese dotaz na celou zemi,
/// než se země stáhne po regionech (menší dotazy projdou spíš).
export const SPLIT_AFTER_FAILURES = 3;

/// Jak naložit s neúspěšnou odpovědí Overpass (status 0 = bez odpovědi):
///  'tooBig' – dotaz je moc velký → po regionech,
///  'busy'   – server omezuje počet dotazů (429) → počkat déle,
///  'fatal'  – chybný dotaz (jiné 4xx) → nemá smysl opakovat,
///  'retry'  – přechodná chyba (504, 502, 503, výpadek) → jiný server.
export function classifyOverpassFailure(status, text) {
  if (status === 400 && /timed out|out of memory|runtime error/i.test(text)) return 'tooBig';
  if (status === 429) return 'busy';
  if (status >= 400 && status < 500) return 'fatal';
  return 'retry';
}

/// Příkaz pro nový pokus jen se zeměmi, které selhaly.
export function retryCommand(failed, project) {
  if (failed.length === 0) return null;
  return `node import_gyms.mjs --countries ${failed.join(',')}` +
    (project ? ` --project ${project}` : '');
}

/// Posilovny + sídla (pro město, když posilovna nemá adresu).
export function gymsQuery(code, timeoutSec = OVERPASS_QUERY_TIMEOUT) {
  return `[out:json][timeout:${timeoutSec}];
${areaSelector(code)}->.a;
(
  nwr["leisure"="fitness_centre"](area.a);
  nwr["leisure"="sports_centre"]["sport"~"(^|;)(fitness|weightlifting|crossfit|bodybuilding)(;|$)"](area.a);
  nwr["amenity"="gym"](area.a);
);
out center qt;
node["place"~"^(city|town|village|suburb)$"](area.a);
out qt;`;
}

/// Seznam regionů země (admin_level 4 s kódem ISO 3166-2).
export function regionsQuery(country) {
  return `[out:json][timeout:180];
${areaSelector(country)}->.c;
rel(area.c)["boundary"="administrative"]["admin_level"="4"]["ISO3166-2"];
out tags;`;
}

/// Kódy regionů z odpovědi [regionsQuery] – jen ty, které patří zemi.
export function parseRegions(json, country) {
  const codes = new Set();
  for (const el of json.elements ?? []) {
    const c = el.tags?.['ISO3166-2'];
    if (typeof c === 'string' && c.startsWith(`${country}-`)) codes.add(c);
  }
  return [...codes].sort();
}

/// Overpass vrací chybu běhu (timeout, paměť) jako HTTP 200 s „remark“.
export function overpassRuntimeError(json) {
  const remark = json?.remark;
  return typeof remark === 'string' && /runtime error|timed out|out of memory/i.test(remark)
    ? remark
    : null;
}

// ---------------------------------------------------------------------------
// Normalizace (stejně jako gym_logic.dart)
// ---------------------------------------------------------------------------

export const GYM_NAME_MAX = 60;
export const GYM_ADDRESS_MAX = 120;
export const GYM_WEBSITE_MAX = 200;

const DIACRITICS = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ą': 'a',
  'č': 'c', 'ć': 'c', 'ç': 'c',
  'ď': 'd',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ě': 'e', 'ę': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ľ': 'l', 'ĺ': 'l', 'ł': 'l',
  'ň': 'n', 'ń': 'n', 'ñ': 'n',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ő': 'o',
  'ř': 'r', 'ŕ': 'r',
  'š': 's', 'ś': 's', 'ß': 'ss',
  'ť': 't',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ů': 'u', 'ű': 'u',
  'ý': 'y', 'ÿ': 'y',
  'ž': 'z', 'ź': 'z', 'ż': 'z',
};

/// Zrcadlo normalizeGymSearch (gym_logic.dart) – malá písmena, bez
/// diakritiky, jedna mezera, nejvýš 60 znaků (UTF-16 jako v Dartu).
export function normalizeGymSearch(input) {
  const lower = input.toLowerCase().trim().replace(/\s+/g, ' ');
  let s = '';
  for (const ch of lower.split('')) s += DIACRITICS[ch] ?? ch;
  return s.length > GYM_NAME_MAX ? s.substring(0, GYM_NAME_MAX) : s;
}

/// Zrcadlo clampText (gym_logic.dart).
export function clampText(input, max) {
  const t = input.trim().replace(/\s+/g, ' ');
  return t.length > max ? t.substring(0, max).trim() : t;
}

/// Hledací klíče „název město“ a „město název“ (prefixové hledání).
export function searchKeys(name, city) {
  const n = normalizeGymSearch(name);
  const c = normalizeGymSearch(city);
  const join = (a, b) => normalizeGymSearch(b ? `${a} ${b}` : a);
  return { nameLower: n, cityLower: c, nameCity: join(n, c), cityName: join(c, n) };
}

// ---------------------------------------------------------------------------
// Geohash (stejně jako lib/modules/social/gym/geohash.dart)
// ---------------------------------------------------------------------------

const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';
export const GEOHASH_PRECISION = 9;

export function geohashEncode(lat, lng, precision = GEOHASH_PRECISION) {
  let latMin = -90, latMax = 90, lngMin = -180, lngMax = 180;
  let hash = '', bit = 0, ch = 0, even = true;
  while (hash.length < precision) {
    if (even) {
      const mid = (lngMin + lngMax) / 2;
      if (lng >= mid) { ch = (ch << 1) | 1; lngMin = mid; } else { ch <<= 1; lngMax = mid; }
    } else {
      const mid = (latMin + latMax) / 2;
      if (lat >= mid) { ch = (ch << 1) | 1; latMin = mid; } else { ch <<= 1; latMax = mid; }
    }
    even = !even;
    if (++bit === 5) { hash += BASE32[ch]; bit = 0; ch = 0; }
  }
  return hash;
}

/// Poloha pro hledání v okolí: celý geohash a buňky přesnosti 5 a 6
/// (dotaz whereIn – stejně jako gymGeoFields v geohash.dart).
export function geoFields(lat, lng) {
  const geohash = geohashEncode(lat, lng);
  return { lat, lng, geohash, g5: geohash.slice(0, 5), g6: geohash.slice(0, 6) };
}

export function haversineKm(lat1, lng1, lat2, lng2) {
  const r = 6371.0088;
  const rad = Math.PI / 180;
  const dLat = (lat2 - lat1) * rad;
  const dLng = (lng2 - lng1) * rad;
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * rad) * Math.cos(lat2 * rad) * Math.sin(dLng / 2) ** 2;
  return 2 * r * Math.asin(Math.min(1, Math.sqrt(a)));
}

// ---------------------------------------------------------------------------
// Převod prvků OSM na posilovny
// ---------------------------------------------------------------------------

const OSM_PREFIX = { node: 'n', way: 'w', relation: 'r' };

/// ID dokumentu ve Firestore: osm-n123, osm-w456, osm-r789.
export function gymDocId(el) {
  return `osm-${OSM_PREFIX[el.type]}${el.id}`;
}

function coords(el) {
  if (typeof el.lat === 'number' && typeof el.lon === 'number') return [el.lat, el.lon];
  if (el.center && typeof el.center.lat === 'number') return [el.center.lat, el.center.lon];
  return null;
}

function isGym(tags) {
  if (tags.leisure === 'fitness_centre' || tags.amenity === 'gym') return true;
  return tags.leisure === 'sports_centre' &&
    /(^|;)(fitness|weightlifting|crossfit|bodybuilding)(;|$)/.test(tags.sport ?? '');
}

const CLOSED_VALUES = new Set(['closed', 'off']);

function isClosedOrPrivate(tags) {
  if (tags.access === 'private' || tags.access === 'no') return true;
  if (CLOSED_VALUES.has((tags.opening_hours ?? '').trim().toLowerCase())) return true;
  return Object.keys(tags).some((k) => /^(disused|abandoned|was|demolished|removed):/.test(k)
    && /^(leisure|amenity)$/.test(k.split(':')[1]));
}

function addressOf(tags) {
  if (tags['addr:full']) return clampText(tags['addr:full'], GYM_ADDRESS_MAX);
  const street = tags['addr:street'] ?? tags['addr:place'];
  const number = tags['addr:housenumber'] ?? tags['addr:conscriptionnumber'];
  if (!street) return '';
  return clampText(number ? `${street} ${number}` : street, GYM_ADDRESS_MAX);
}

function cityFromTags(tags) {
  for (const k of ['addr:city', 'addr:town', 'addr:village', 'addr:municipality', 'addr:hamlet', 'addr:suburb']) {
    const v = tags[k];
    if (typeof v === 'string' && v.trim()) return v.trim();
  }
  return '';
}

function websiteOf(tags) {
  const w = (tags.website ?? tags['contact:website'] ?? tags.url ?? '').trim();
  if (!/^https?:\/\//i.test(w) || w.length > GYM_WEBSITE_MAX) return '';
  return w;
}

/// Index sídel pro hledání nejbližšího města (mřížka 0,1°).
export class PlaceIndex {
  constructor(places) {
    this.cells = new Map();
    for (const p of places) {
      const key = this.#key(p.lat, p.lng);
      if (!this.cells.has(key)) this.cells.set(key, []);
      this.cells.get(key).push(p);
    }
  }

  #key(lat, lng) { return `${Math.floor(lat * 10)}:${Math.floor(lng * 10)}`; }

  /// Nejbližší sídlo do [maxKm]; větší sídlo má přednost, když je skoro
  /// stejně blízko (vesnice těsně u města → město).
  nearest(lat, lng, maxKm = 15) {
    const cy = Math.floor(lat * 10), cx = Math.floor(lng * 10);
    const reach = Math.ceil(maxKm / 11) + 1;
    let best = null, bestScore = Infinity;
    const weight = { city: 0.5, town: 0.75, suburb: 0.9, village: 1 };
    for (let dy = -reach; dy <= reach; dy++) {
      for (let dx = -reach; dx <= reach; dx++) {
        for (const p of this.cells.get(`${cy + dy}:${cx + dx}`) ?? []) {
          const d = haversineKm(lat, lng, p.lat, p.lng);
          if (d > maxKm) continue;
          const score = d * (weight[p.place] ?? 1);
          if (score < bestScore) { bestScore = score; best = p; }
        }
      }
    }
    return best;
  }
}

/// Posilovny a sídla z odpovědi Overpass. [country] = kód ISO 3166-1.
export function parseOverpass(json, country) {
  const places = [];
  const raw = [];
  for (const el of json.elements ?? []) {
    const tags = el.tags ?? {};
    const c = coords(el);
    if (!c) continue;
    if (tags.place && el.type === 'node' && tags.name && !isGym(tags)) {
      places.push({ name: tags.name, place: tags.place, lat: c[0], lng: c[1] });
      continue;
    }
    if (!isGym(tags) || isClosedOrPrivate(tags)) continue;
    const name = clampText(tags.name ?? tags.brand ?? '', GYM_NAME_MAX);
    if (!name) continue;
    raw.push({
      id: gymDocId(el),
      osm: `${el.type}/${el.id}`,
      osmType: el.type,
      name,
      city: clampText(cityFromTags(tags), GYM_NAME_MAX),
      address: addressOf(tags),
      website: websiteOf(tags),
      lat: Math.round(c[0] * 1e6) / 1e6,
      lng: Math.round(c[1] * 1e6) / 1e6,
      country,
      tagCount: Object.keys(tags).length,
    });
  }
  const index = new PlaceIndex(places);
  for (const g of raw) {
    if (!g.city) g.city = clampText(index.nearest(g.lat, g.lng)?.name ?? '', GYM_NAME_MAX);
  }
  return raw.filter((g) => g.city);
}

/// Stejná posilovna zadaná dvakrát (bod i budova) – stejný název do 80 m.
/// Přednost má budova / relace a záznam s víc údaji.
export function dedupe(gyms, maxKm = 0.08) {
  const rank = (g) => (g.osmType === 'node' ? 0 : 1) * 1000 + g.tagCount;
  const byName = new Map();
  for (const g of gyms) {
    const k = normalizeGymSearch(g.name);
    if (!byName.has(k)) byName.set(k, []);
    byName.get(k).push(g);
  }
  const kept = [];
  for (const group of byName.values()) {
    group.sort((a, b) => rank(b) - rank(a));
    const chosen = [];
    for (const g of group) {
      if (chosen.some((c) => haversineKm(c.lat, c.lng, g.lat, g.lng) <= maxKm)) continue;
      chosen.push(g);
    }
    kept.push(...chosen);
  }
  return kept.sort((a, b) => a.id.localeCompare(b.id));
}

// ---------------------------------------------------------------------------
// Dokumenty Firestore
// ---------------------------------------------------------------------------

/// Pole, která import zapisuje (a při změně v OSM přepisuje). memberCount,
/// code, hidden a createdAt se při aktualizaci nemění.
export function importedFields(g) {
  return {
    name: g.name,
    city: g.city,
    ...searchKeys(g.name, g.city),
    address: g.address || null,
    website: g.website || null,
    ...geoFields(g.lat, g.lng),
    country: g.country,
    source: 'osm',
    osm: g.osm,
    osmMissing: false,
  };
}

/// Otisk importovaných polí – podle něj se pozná změna v OSM.
export function importHash(g) {
  const f = importedFields(g);
  const s = JSON.stringify([f.name, f.city, f.address, f.website, f.lat, f.lng, f.country]);
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 16777619) >>> 0;
  }
  return h.toString(36);
}

// Kód posilovny (stejná abeceda a délka jako gym_logic.dart / pravidla).
export const GYM_CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
export const GYM_CODE_LENGTH = 6;

export function generateGymCode(randomInt, taken) {
  for (let attempt = 0; attempt < 1000; attempt++) {
    let code = '';
    for (let i = 0; i < GYM_CODE_LENGTH; i++) {
      code += GYM_CODE_ALPHABET[randomInt(GYM_CODE_ALPHABET.length)];
    }
    if (!taken.has(code)) {
      taken.add(code);
      return code;
    }
  }
  throw new Error('Could not generate a unique gym code');
}
