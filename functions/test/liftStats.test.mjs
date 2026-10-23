// Testy statistik „Jak si vedu“ (src/liftStats.ts).
// Spuštění: cd functions && npm test  (nejdřív zkompiluje do lib/).
import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  buildLiftStats,
  quantiles,
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

test('kvantily: 5.–95. percentil na 2,5 kg, bez maxima', () => {
  const values = Array.from({ length: 20 }, (_, i) => 60 + i * 2); // 60 … 98
  const q = quantiles(values);
  assert.equal(q.length, 19);
  assert.equal(q[0], 60);           // 5. percentil = 1. hodnota
  assert.equal(q[18], 95);          // 95. percentil = 19. hodnota (96 → 95), ne maximum 98
  for (const v of q) assert.equal(v % 2.5, 0);
  assert.deepEqual(quantiles([100]), Array(19).fill(100));
});

test('svět a země, skupiny podle pohlaví a věku, malá skupina bez rozložení', () => {
  const entries = [
    e('a', 100), e('b', 100), e('c', 120, { gender: 'female', ageGroup: '40' }),
    e('d', 80, { country: 'SK', gender: null, ageGroup: null }),
  ];
  const docs = buildLiftStats(entries, 2);
  const byId = Object.fromEntries(docs.map((d) => [liftStatsDocId(d.scope, d.category), d]));
  const world = byId.world_bench_press.groups;
  assert.equal(world.all_all.n, 4);
  assert.equal(world.all_all.q.length, 19);
  assert.equal(world.all_all.h, undefined);
  assert.deepEqual(world.male_u40.q, Array(19).fill(100));
  assert.deepEqual(world.female_40, { n: 1 });
  assert.deepEqual(world.female_all, { n: 1 });
  assert.equal(world.all_60, undefined);
  assert.equal(byId.CZ_bench_press.groups.all_all.n, 3);
  assert.deepEqual(byId.SK_bench_press.groups, { all_all: { n: 1 } });
});

test('jeden člověk = jedna hodnota na cvik (nejvyšší)', () => {
  const docs = buildLiftStats([e('a', 100), e('a', 110, { country: 'SK' })], 1);
  const world = docs.find((d) => d.scope === 'world').groups.all_all;
  assert.deepEqual(world, { n: 1, q: Array(19).fill(110) });
  assert.equal(docs.some((d) => d.scope === 'CZ'), false);
});
