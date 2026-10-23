// Testy moderace žebříčku posilovny: hranice skrytí podle počtu členů
// (src/plausibility.ts) a stáří účtu u nahlášení posilovny (src/gymDirectory.ts).
// Spuštění: cd functions && npm test  (nejdřív zkompiluje do lib/).
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { GYM_REPORTER_MIN_ACCOUNT_DAYS, isEstablishedReporter } from '../lib/gymDirectory.js';
import { gymReportThreshold } from '../lib/plausibility.js';

const DAY = 24 * 3600 * 1000;

test('hranice skrytí: třetina členů, nejméně 3, nejvýš 5', () => {
  assert.equal(gymReportThreshold(0), 3);
  assert.equal(gymReportThreshold(4), 3);
  assert.equal(gymReportThreshold(9), 3);
  assert.equal(gymReportThreshold(10), 4);
  assert.equal(gymReportThreshold(12), 4);
  assert.equal(gymReportThreshold(13), 5);
  assert.equal(gymReportThreshold(500), 5);
  assert.equal(gymReportThreshold(Number.NaN), 3);
});

test('nahlášení posilovny se počítá jen od účtu starého aspoň 7 dní', () => {
  assert.equal(GYM_REPORTER_MIN_ACCOUNT_DAYS, 7);
  const now = Date.UTC(2026, 9, 23);
  assert.equal(isEstablishedReporter(now - 7 * DAY, now), true);
  assert.equal(isEstablishedReporter(now - 6 * DAY, now), false);
  assert.equal(isEstablishedReporter(null, now), false);
  assert.equal(isEstablishedReporter(Number.NaN, now), false);
});
