// Testy skrývání posiloven po nahlášení (src/gymDirectory.ts).
// Spuštění: cd functions && npm test  (nejdřív zkompiluje do lib/).
import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  GYM_CLOSED_REPORT_THRESHOLD,
  GYM_DIRECTORY_REPORT_THRESHOLD,
  gymHideDecision,
  shouldUnhideOnJoin,
} from '../lib/gymDirectory.js';

const base = { contentReports: 0, closedReports: 0, memberCount: 0, hidden: false, hiddenReason: null };

test('prahy jsou 5', () => {
  assert.equal(GYM_DIRECTORY_REPORT_THRESHOLD, 5);
  assert.equal(GYM_CLOSED_REPORT_THRESHOLD, 5);
});

test('prázdnou posilovnu skryje až 5 nahlášení neexistuje / duplicita', () => {
  assert.equal(gymHideDecision({ ...base, closedReports: 4 }), null);
  assert.equal(gymHideDecision({ ...base, closedReports: 5 }), 'closed');
});

test('posilovnu s členy nahlášení neexistuje / duplicita neskryjí', () => {
  assert.equal(gymHideDecision({ ...base, closedReports: 50, memberCount: 1 }), null);
});

test('5 nahlášení za obsah skryje trvale i posilovnu s členy', () => {
  assert.equal(gymHideDecision({ ...base, contentReports: 4, memberCount: 3 }), null);
  assert.equal(gymHideDecision({ ...base, contentReports: 5, memberCount: 3 }), 'reports');
  // Trvalé skrytí přebije vratné.
  assert.equal(gymHideDecision({ ...base, contentReports: 5, hidden: true, hiddenReason: 'closed' }), 'reports');
  assert.equal(gymHideDecision({ ...base, contentReports: 9, hidden: true, hiddenReason: 'reports' }), null);
});

test('nahlášení neexistuje / duplicita se nesčítají s nahlášeními za obsah', () => {
  assert.equal(gymHideDecision({ ...base, contentReports: 3, closedReports: 3, memberCount: 2 }), null);
});

test('už skrytou posilovnu znovu neskrývá', () => {
  assert.equal(gymHideDecision({ ...base, closedReports: 7, hidden: true, hiddenReason: 'closed' }), null);
});

test('vstup člena ukáže jen posilovnu skrytou jako neexistující', () => {
  assert.equal(shouldUnhideOnJoin({ hidden: true, hiddenReason: 'closed' }), true);
  assert.equal(shouldUnhideOnJoin({ hidden: true, hiddenReason: 'reports' }), false);
  assert.equal(shouldUnhideOnJoin({ hidden: true }), false);
  assert.equal(shouldUnhideOnJoin({ hidden: false, hiddenReason: 'closed' }), false);
});
