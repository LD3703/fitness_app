// Testy veřejného hledání posiloven pro gymbar.app/fitka (src/fitka.ts).
// Spuštění: cd functions && npm test  (nejdřív zkompiluje do lib/).
import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  FITKA_MIN_MEMBERS_SHOWN,
  fitkaGymId,
  fitkaQuery,
  mergeResults,
  normalizeGymSearch,
  publicGym,
} from '../lib/fitka.js';

test('normalizace jako v aplikaci', () => {
  assert.equal(normalizeGymSearch('  Žluťoučký   KŮŇ '), 'zlutoucky kun');
  assert.equal(normalizeGymSearch('x'.repeat(80)).length, 60);
});

test('hledaný text aspoň 2 znaky', () => {
  assert.equal(fitkaQuery('Jičín'), 'jicin');
  assert.equal(fitkaQuery(' a '), null);
  assert.equal(fitkaQuery(undefined), null);
  assert.equal(fitkaQuery(['brno']), null);
});

test('ID posilovny', () => {
  assert.equal(fitkaGymId('osm-n123'), 'osm-n123');
  assert.equal(fitkaGymId('AbC123xyz'), 'AbC123xyz');
  assert.equal(fitkaGymId('../users/x'), null);
  assert.equal(fitkaGymId(''), null);
});

const doc = {
  name: 'Gym Jičín', city: 'Jičín', address: 'Husova 1', code: 'ABC234',
  memberCount: 2, createdBy: 'uid-1', lat: 50.4, lng: 15.3,
};

test('veřejná pole: bez createdBy a polohy, členové až od 5', () => {
  assert.deepEqual(publicGym('g1', doc), {
    id: 'g1', name: 'Gym Jičín', city: 'Jičín', address: 'Husova 1', code: 'ABC234',
  });
  const many = publicGym('g1', { ...doc, memberCount: FITKA_MIN_MEMBERS_SHOWN });
  assert.equal(many.members, FITKA_MIN_MEMBERS_SHOWN);
  assert.equal('createdBy' in many, false);
});

test('skrytá, zmizelá bez členů nebo bez kódu se neukáže', () => {
  assert.equal(publicGym('g', { ...doc, hidden: true }), null);
  assert.equal(publicGym('g', { ...doc, osmMissing: true, memberCount: 0 }), null);
  assert.notEqual(publicGym('g', { ...doc, osmMissing: true, memberCount: 1 }), null);
  assert.equal(publicGym('g', { ...doc, code: '' }), null);
  assert.equal(publicGym('g', { ...doc, name: '  ' }), null);
});

test('spojení výsledků bez duplicit, víc členů první', () => {
  const a = { id: 'a', name: 'B gym', city: '', code: 'AAAA' };
  const b = { id: 'b', name: 'A gym', city: '', code: 'BBBB' };
  const c = { id: 'c', name: 'Z gym', city: '', code: 'CCCC', members: 9 };
  const merged = mergeResults([[a, b], [b, c]]);
  assert.deepEqual(merged.map((g) => g.id), ['c', 'b', 'a']);
  assert.equal(mergeResults([[a, b, c]], 2).length, 2);
});
