// Testy pravidel žebříčku posilovny: skryté záznamy a nahlášení
// (gyms/{gymId}/entries, firestore.rules, docs/social.md).
// Spuštění: cd tool/rules_test && npm ci && npm test  (potřebuje Javu).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  where,
} from 'firebase/firestore';

const GYM = 'gym1';
const OLD = 'old1'; // člen 30 dní, má vlastní záznam
const NEW = 'new1'; // člen 2 dny, má vlastní záznam
const NOENTRY = 'noentry1'; // člen 30 dní, bez záznamu
const CHEAT = 'cheat1'; // vlastník nahlašovaného (skrytého) záznamu

const DAY = 24 * 3600 * 1000;

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-gymbar-gym',
    firestore: { rules: readFileSync('../../firestore.rules', 'utf8') },
  });
});

after(() => env.cleanup());

const entry = (uid, extra = {}) => ({
  uid, category: 'bench_press', nickname: uid, gender: 'male',
  best: 100, bestAt: Timestamp.now(), updatedAt: Timestamp.now(), ...extra,
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    const ago = (days) => Timestamp.fromMillis(Date.now() - days * DAY);
    await setDoc(doc(fs, `gyms/${GYM}`), { name: 'Gym', city: 'Jičín', code: 'ABC234', memberCount: 4 });
    for (const [uid, days] of [[OLD, 30], [NEW, 2], [NOENTRY, 30], [CHEAT, 30]]) {
      await setDoc(doc(fs, `gyms/${GYM}/members/${uid}`), { uid, nickname: uid, gender: 'male', joinedAt: ago(days) });
    }
    await setDoc(doc(fs, `gyms/${GYM}/entries/${OLD}_bench_press`), entry(OLD, { hidden: false }));
    await setDoc(doc(fs, `gyms/${GYM}/entries/${NEW}_bench_press`), entry(NEW, { hidden: false }));
    await setDoc(doc(fs, `gyms/${GYM}/entries/${CHEAT}_bench_press`),
      entry(CHEAT, { best: 300, hidden: true, hiddenReason: 'reports', reportCount: 5 }));
  });
});

const db = (uid) => env.authenticatedContext(uid).firestore();
const entries = (fs) => collection(fs, `gyms/${GYM}/entries`);
const report = (fs, entryId, uid) => doc(fs, `gyms/${GYM}/entries/${entryId}/reports/${uid}`);

describe('skryté záznamy', () => {
  test('žebříček (hidden == false) čte každý člen, bez skrytých', async () => {
    const snap = await assertSucceeds(getDocs(query(entries(db(OLD)),
      where('category', '==', 'bench_press'), where('hidden', '==', false))));
    const ids = snap.docs.map((d) => d.id).sort();
    if (ids.includes(`${CHEAT}_bench_press`)) throw new Error('skrytý záznam v žebříčku');
  });

  test('dotaz bez filtru skrytých pravidla odmítnou', async () => {
    await assertFails(getDocs(query(entries(db(OLD)), where('category', '==', 'bench_press'))));
    await assertFails(getDocs(entries(db(OLD))));
  });

  test('cizí skrytý záznam nejde přečíst ani přímo', async () => {
    await assertFails(getDoc(doc(db(OLD), `gyms/${GYM}/entries/${CHEAT}_bench_press`)));
    await assertSucceeds(getDoc(doc(db(CHEAT), `gyms/${GYM}/entries/${OLD}_bench_press`)));
  });

  test('vlastník vidí své záznamy včetně skrytých', async () => {
    await assertSucceeds(getDoc(doc(db(CHEAT), `gyms/${GYM}/entries/${CHEAT}_bench_press`)));
    await assertSucceeds(getDocs(query(entries(db(CHEAT)), where('uid', '==', CHEAT))));
  });

  test('nečlen žebříček nečte', async () => {
    await assertFails(getDocs(query(entries(db('outsider')),
      where('category', '==', 'bench_press'), where('hidden', '==', false))));
  });

  test('klient pole hidden nezapíše', async () => {
    await assertFails(setDoc(doc(db(NOENTRY), `gyms/${GYM}/entries/${NOENTRY}_bench_press`),
      { ...entry(NOENTRY), updatedAt: serverTimestamp(), hidden: false }));
  });
});

describe('nahlášení', () => {
  const target = `${NEW}_bench_press`;
  const data = (uid) => ({ createdAt: serverTimestamp(), myEntry: `${uid}_bench_press` });

  test('člen aspoň 7 dní s vlastním záznamem nahlásí', async () => {
    await assertSucceeds(setDoc(report(db(OLD), target, OLD), data(OLD)));
  });

  test('čerstvý člen nenahlásí', async () => {
    await assertFails(setDoc(report(db(NEW), `${OLD}_bench_press`, NEW), data(NEW)));
  });

  test('člen bez vlastního záznamu nenahlásí', async () => {
    await assertFails(setDoc(report(db(NOENTRY), target, NOENTRY), data(NOENTRY)));
    // Cizí záznam jako „můj“ neprojde.
    await assertFails(setDoc(report(db(NOENTRY), target, NOENTRY),
      { createdAt: serverTimestamp(), myEntry: `${OLD}_bench_press` }));
  });

  test('bez myEntry, sám sebe ani za jiného nahlásit nejde', async () => {
    await assertFails(setDoc(report(db(OLD), target, OLD), { createdAt: serverTimestamp() }));
    await assertFails(setDoc(report(db(OLD), `${OLD}_bench_press`, OLD), data(OLD)));
    await assertFails(setDoc(report(db(OLD), target, NOENTRY), data(OLD)));
  });
});
