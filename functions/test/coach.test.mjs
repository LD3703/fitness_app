// Testy logiky trenér–klient (src/coach.ts).
// Spuštění: cd functions && npm test  (nejdřív zkompiluje do lib/).
import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  COACH_INACTIVE_DAYS,
  clientCountUpdate,
  sessionChange,
  sessionPushText,
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

test('změna pozvánky na trénink → komu push', () => {
  const p = { status: 'pending', startAtMs: 1, durationMin: 60, weeks: 1, title: 'Nohy' };
  assert.equal(sessionChange(undefined, p), 'invite');
  assert.equal(sessionChange(undefined, { ...p, status: 'accepted' }), null);
  assert.equal(sessionChange(p, undefined), null);
  assert.equal(sessionChange(p, { ...p, status: 'accepted' }), 'accepted');
  assert.equal(sessionChange({ ...p, status: 'accepted' }, { ...p, status: 'declined' }), 'declined');
  assert.equal(sessionChange(p, { ...p, status: 'cancelled' }), 'cancelled');
  // Trenér upravil přijatý termín → znovu k potvrzení.
  assert.equal(sessionChange({ ...p, status: 'accepted' }, { ...p, startAtMs: 2 }), 'updated');
  assert.equal(sessionChange(p, { ...p, title: 'Záda' }), 'updated');
  assert.equal(sessionChange(p, { ...p }), null);
  assert.equal(sessionChange({ ...p, status: 'accepted' }, { ...p, status: 'accepted', title: 'X' }), null);
});

test('texty notifikací k pozvánce', () => {
  const p = { trainerName: 'Tom', clientName: 'Karel', title: 'Nohy', weekly: true };
  assert.deepEqual(sessionPushText('invite', 'cs', p), {
    title: 'Pozvánka na trénink', body: 'Tom tě zve na trénink: Nohy (každý týden)',
  });
  assert.equal(sessionPushText('accepted', 'en', { ...p, weekly: false }).body,
    'Karel accepted the workout: Nohy');
  for (const c of ['invite', 'updated', 'cancelled', 'accepted', 'declined']) {
    for (const l of ['cs', 'en']) assert.ok(sessionPushText(c, l, p).body.length > 0);
  }
});
