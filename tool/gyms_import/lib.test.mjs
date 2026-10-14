import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  AMERICAS,
  EUROPE,
  OVERPASS_ENDPOINTS,
  PlaceIndex,
  classifyOverpassFailure,
  dedupe,
  generateGymCode,
  geohashEncode,
  gymsQuery,
  haversineKm,
  importHash,
  importedFields,
  normalizeGymSearch,
  overpassRuntimeError,
  parseOverpass,
  parseRegions,
  retryCommand,
  searchKeys,
} from './lib.mjs';

test('geohash odpovídá známým hodnotám', () => {
  assert.equal(geohashEncode(57.64911, 10.40744, 11), 'u4pruydqqvj');
  assert.equal(geohashEncode(0, 0, 1), 's');
  assert.equal(geohashEncode(-33.8688, 151.2093, 6), 'r3gx2f');
});

test('normalizace jako v Dartu', () => {
  assert.equal(normalizeGymSearch('  Gym   Jičín '), 'gym jicin');
  assert.equal(normalizeGymSearch('Fitness Größe ŁÓDŹ'), 'fitness grosse lodz');
  assert.equal(normalizeGymSearch('x'.repeat(80)).length, 60);
  const k = searchKeys('Fit Point', 'Hradec Králové');
  assert.equal(k.nameCity, 'fit point hradec kralove');
  assert.equal(k.cityName, 'hradec kralove fit point');
  assert.equal(searchKeys('Gym', '').nameCity, 'gym');
});

test('vzdálenost', () => {
  const d = haversineKm(50.0755, 14.4378, 49.1951, 16.6068); // Praha – Brno
  assert.ok(d > 180 && d < 190, `${d}`);
});

const sample = {
  elements: [
    { type: 'node', id: 1, lat: 50.43, lon: 15.35, tags: { place: 'town', name: 'Jičín' } },
    { type: 'node', id: 2, lat: 50.5, lon: 15.9, tags: { place: 'village', name: 'Daleko' } },
    // Bod a budova téže posilovny.
    { type: 'node', id: 10, lat: 50.4301, lon: 15.3502, tags: { leisure: 'fitness_centre', name: 'Fit Jičín' } },
    { type: 'way', id: 11, center: { lat: 50.43015, lon: 15.35025 }, tags: {
      leisure: 'fitness_centre', name: 'Fit Jičín', 'addr:city': 'Jičín',
      'addr:street': 'Husova', 'addr:housenumber': '12', website: 'https://fit.example' } },
    // Sportovní centrum s fitness.
    { type: 'way', id: 12, center: { lat: 50.432, lon: 15.36 }, tags: {
      leisure: 'sports_centre', sport: 'swimming;fitness', name: 'Aquapark' } },
    // Sportovní centrum bez fitness – ne.
    { type: 'way', id: 13, center: { lat: 50.432, lon: 15.36 }, tags: { leisure: 'sports_centre', sport: 'tennis', name: 'Tenis' } },
    // Bez názvu – ne.
    { type: 'node', id: 14, lat: 50.43, lon: 15.35, tags: { leisure: 'fitness_centre' } },
    // Soukromá a zavřená – ne.
    { type: 'node', id: 15, lat: 50.43, lon: 15.35, tags: { leisure: 'fitness_centre', name: 'Hotel gym', access: 'private' } },
    { type: 'node', id: 16, lat: 50.43, lon: 15.35, tags: { amenity: 'gym', name: 'Old gym', opening_hours: 'closed' } },
    // Jen značka.
    { type: 'node', id: 17, lat: 50.4305, lon: 15.351, tags: { amenity: 'gym', brand: 'Anytime Fitness' } },
    // Daleko od sídel a bez adresy – vypadne.
    { type: 'node', id: 18, lat: 10, lon: 10, tags: { leisure: 'fitness_centre', name: 'Nowhere' } },
  ],
};

test('převod odpovědi Overpass', () => {
  const gyms = dedupe(parseOverpass(sample, 'CZ'));
  const ids = gyms.map((g) => g.id);
  assert.deepEqual(ids, ['osm-n17', 'osm-w11', 'osm-w12']);
  const fit = gyms.find((g) => g.id === 'osm-w11');
  assert.equal(fit.city, 'Jičín');
  assert.equal(fit.address, 'Husova 12');
  assert.equal(fit.website, 'https://fit.example');
  assert.equal(fit.osm, 'way/11');
  const aqua = gyms.find((g) => g.id === 'osm-w12');
  assert.equal(aqua.city, 'Jičín'); // nejbližší sídlo
  assert.equal(gyms.find((g) => g.id === 'osm-n17').name, 'Anytime Fitness');
});

test('pole dokumentu a otisk', () => {
  const [g] = dedupe(parseOverpass(sample, 'CZ')).filter((x) => x.id === 'osm-w11');
  const f = importedFields(g);
  assert.equal(f.source, 'osm');
  assert.equal(f.nameLower, 'fit jicin');
  assert.equal(f.cityName, 'jicin fit jicin');
  assert.equal(f.geohash.length, 9);
  assert.equal(f.g5, f.geohash.slice(0, 5));
  assert.equal(f.g6, f.geohash.slice(0, 6));
  assert.equal(f.lat, 50.43015);
  assert.equal(f.osmMissing, false);
  assert.ok(!('memberCount' in f) && !('code' in f) && !('hidden' in f));
  const h1 = importHash(g);
  assert.equal(h1, importHash({ ...g }));
  assert.notEqual(h1, importHash({ ...g, name: 'Fit Jičín 2' }));
});

test('PlaceIndex dává přednost městu', () => {
  const idx = new PlaceIndex([
    { name: 'Vesnice', place: 'village', lat: 50.0, lng: 14.0 },
    { name: 'Město', place: 'city', lat: 50.0, lng: 14.012 },
  ]);
  // Vesnice 0,4 km, město 0,9 km → město (váha 0,5).
  assert.equal(idx.nearest(50.0, 14.006)?.name, 'Město');
  assert.equal(idx.nearest(51, 14), null);
});

test('kódy jsou jedinečné a ve správné abecedě', () => {
  const taken = new Set(['AAAAAA']);
  let i = 0;
  const seq = [0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6];
  const code = generateGymCode(() => seq[i++ % seq.length], taken);
  assert.equal(code, 'BCDEFG');
  assert.ok(taken.has('BCDEFG'));
  assert.match(generateGymCode((n) => Math.floor(Math.random() * n), taken), /^[A-HJKMNP-Z2-9]{6}$/);
});

test('regiony a chyby Overpass', () => {
  const regions = parseRegions({ elements: [
    { tags: { 'ISO3166-2': 'US-CA' } }, { tags: { 'ISO3166-2': 'US-TX' } },
    { tags: { 'ISO3166-2': 'MX-BCN' } }, { tags: {} },
  ] }, 'US');
  assert.deepEqual(regions, ['US-CA', 'US-TX']);
  assert.ok(overpassRuntimeError({ remark: 'runtime error: Query timed out in "query" at line 3' }));
  assert.equal(overpassRuntimeError({ elements: [] }), null);
  assert.match(gymsQuery('US-CA'), /area\["ISO3166-2"="US-CA"\]/);
  assert.match(gymsQuery('CZ'), /area\["ISO3166-1"="CZ"\]\[admin_level=2\]/);
});

test('seznam zemí obsahuje země jazykových mutací', () => {
  for (const c of ['CZ', 'SK', 'DE', 'AT', 'CH', 'ES', 'FR', 'BE', 'IT', 'NL', 'PL', 'PT', 'GB', 'IE']) {
    assert.ok(EUROPE.includes(c), c);
  }
  for (const c of ['US', 'CA', 'MX', 'BR', 'AR', 'CO']) assert.ok(AMERICAS.includes(c), c);
  assert.equal(new Set([...EUROPE, ...AMERICAS]).size, EUROPE.length + AMERICAS.length);
});

test('chyby Overpass: 504 jiný server, 429 čekat, timeout po regionech', () => {
  assert.equal(classifyOverpassFailure(504, '<html>Gateway Timeout</html>'), 'retry');
  assert.equal(classifyOverpassFailure(0, 'socket hang up'), 'retry');
  assert.equal(classifyOverpassFailure(503, ''), 'retry');
  assert.equal(classifyOverpassFailure(429, 'rate_limited'), 'busy');
  assert.equal(classifyOverpassFailure(400, 'runtime error: Query timed out'), 'tooBig');
  assert.equal(classifyOverpassFailure(400, 'parse error: unknown'), 'fatal');
  assert.ok(OVERPASS_ENDPOINTS.length >= 2);
  assert.ok(OVERPASS_ENDPOINTS.every((u) => u.startsWith('https://')));
  assert.match(gymsQuery('CZ'), /\[timeout:600\]/);
});

test('příkaz pro nový pokus jen se selhanými zeměmi', () => {
  assert.equal(retryCommand([], 'p'), null);
  assert.equal(retryCommand(['DE', 'US'], null), 'node import_gyms.mjs --countries DE,US');
  assert.equal(retryCommand(['FR'], 'fitness-app-dc5e4'),
    'node import_gyms.mjs --countries FR --project fitness-app-dc5e4');
});
