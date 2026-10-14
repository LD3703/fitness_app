// Testy logiky trenér–klient (src/coach.ts).
// Spuštění: cd functions && npm test  (nejdřív zkompiluje do lib/).
import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  COACH_INACTIVE_DAYS,
  clientCountUpdate,
  trainerExpired,
} from '../lib/coach.js';

const DAY = 24 * 3600 * 1000;

test('přepočet klientů', () => {
  assert.deepEqual(clientCountUpdate(0, false), { clientCount: 0, zeroSince: 'now' });
  assert.deepEqual(clientCountUpdate(0, true), { clientCount: 0, zeroSince: 'keep' });
  assert.deepEqual(clientCountUpdate(3, true), { clientCount: 3, zeroSince: 'delete' });
  assert.deepEqual(clientCountUpdate(2, false), { clientCount: 2, zeroSince: 'keep' });
});

test('status vyprší po 60 dnech bez klienta', () => {
  assert.equal(COACH_INACTIVE_DAYS, 60);
  const now = Date.UTC(2026, 9, 13);
  assert.equal(trainerExpired(0, now - 61 * DAY, now), true);
  assert.equal(trainerExpired(0, now - 59 * DAY, now), false);
  assert.equal(trainerExpired(1, now - 300 * DAY, now), false);
  assert.equal(trainerExpired(0, null, now), false);
});
