// Testy statistik „Jak si vedu“ (src/liftStats.ts).
// Spuštění: cd functions && npm test  (nejdřív zkompiluje do lib/).
import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  buildLiftStats,
  gymCountry,
  LIFT_CATEGORIES,
  liftStatsDocId,
  statValue,
} from '../lib/liftStats.js';

const e = (uid, value, extra = {}) => ({
  uid, category: 'bench_press', value, gender: 'male', ageGroup: 'u40', country: 'CZ', ...extra,
});

test('kategorie jsou jen cviky (ne tréninky)', () => {
  assert.ok(LIFT_CATEGORIES.includes('bench_press'));
  assert.ok(!LIFT_CATEGORIES.includes('workouts'));
  assert.equal(LIFT_CATEGORIES.length, 16);
});

test('hodnota záznamu: skrytý, neznámá kategorie a nesmysl se nepočítají', () => {
  assert.equal(statValue({ category: 'bench_press', best: 100.3 }), 100.5);
  assert.equal(statValue({ category: 'bench_press', best: 100, hidden: true }), null);
  assert.equal(statValue({ category: 'workouts', best: 12 }), null);
  assert.equal(statValue({ category: 'bench_press', best: 0 }), null);
  assert.equal(statValue({ category: 'bench_press', best: '100' }), null);
});

test('země posilovny', () => {
  assert.equal(gymCountry({ country: 'cz' }), 'CZ');
  assert.equal(gymCountry({ country: 'CZE' }), null);
  assert.equal(gymCountry({}), null);
  assert.equal(gymCountry(undefined), null);
});

test('svět a země, skupiny podle pohlaví a věku, malá skupina bez rozložení', () => {
  const entries = [
    e('a', 100), e('b', 100), e('c', 120, { gender: 'female', ageGroup: '40' }),
    e('d', 80, { country: 'SK', gender: null, ageGroup: null }),
  ];
  const docs = buildLiftStats(entries, 2);
  const byId = Object.fromEntries(docs.map((d) => [liftStatsDocId(d.scope, d.category), d]));
  const world = byId.world_bench_press.groups;
  assert.deepEqual(world.all_all, { n: 4, h: [80, 1, 100, 2, 120, 1] });
  assert.deepEqual(world.male_u40, { n: 2, h: [100, 2] });
  assert.deepEqual(world.female_40, { n: 1 });
  assert.deepEqual(world.female_all, { n: 1 });
  assert.equal(world.all_60, undefined);
  assert.deepEqual(byId.CZ_bench_press.groups.all_all, { n: 3, h: [100, 2, 120, 1] });
  assert.deepEqual(byId.SK_bench_press.groups, { all_all: { n: 1 } });
});

test('jeden člověk = jedna hodnota na cvik (nejvyšší)', () => {
  const docs = buildLiftStats([e('a', 100), e('a', 110, { country: 'SK' })], 1);
  const world = docs.find((d) => d.scope === 'world').groups.all_all;
  assert.deepEqual(world, { n: 1, h: [110, 1] });
  assert.equal(docs.some((d) => d.scope === 'CZ'), false);
});
