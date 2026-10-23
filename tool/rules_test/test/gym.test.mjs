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
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  increment,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
  writeBatch,
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

describe('úprava a smazání posilovny zakladatelem', () => {
  const FOUNDER = 'founder1';
  const OWN = 'owngym';
  const OSM = 'osmgym';

  const texts = (name, city) => ({
    name, nameLower: name.toLowerCase(), city, cityLower: city.toLowerCase(),
  });

  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const fs = ctx.firestore();
      await setDoc(doc(fs, `gyms/${OWN}`), {
        ...texts('Fitnes Jicin', 'Jicin'), code: 'XYZ234', createdBy: FOUNDER,
        createdAt: Timestamp.now(), memberCount: 1,
      });
      await setDoc(doc(fs, `gymCodes/XYZ234`), { gymId: OWN, name: 'Fitnes Jicin', city: 'Jicin' });
      await setDoc(doc(fs, `gyms/${OWN}/members/${FOUNDER}`), { uid: FOUNDER, nickname: 'f', gender: 'male', joinedAt: Timestamp.now() });
      await setDoc(doc(fs, `gyms/${OSM}`), {
        ...texts('OSM Gym', 'Praha'), code: 'OSM234', createdBy: FOUNDER, source: 'osm', memberCount: 0,
      });
    });
  });

  test('zakladatel opraví název, město a adresu i kopii v kódu', async () => {
    const fs = db(FOUNDER);
    const batch = writeBatch(fs);
    batch.update(doc(fs, `gyms/${OWN}`), { ...texts('Fitness Jičín', 'Jičín'), address: 'Husova 1' });
    batch.update(doc(fs, 'gymCodes/XYZ234'), { name: 'Fitness Jičín', city: 'Jičín' });
    await assertSucceeds(batch.commit());
  });

  test('jiný člen, jiná pole ani nesedící kód nejdou', async () => {
    await assertFails(updateDoc(doc(db(OLD), `gyms/${OWN}`), texts('Hack', 'Hack')));
    await assertFails(updateDoc(doc(db(FOUNDER), `gyms/${OWN}`), { code: 'AAA234' }));
    await assertFails(updateDoc(doc(db(FOUNDER), `gyms/${OWN}`), { memberCount: 99 }));
    await assertFails(updateDoc(doc(db(FOUNDER), `gyms/${OWN}`), { ...texts('', 'Jičín') }));
    await assertFails(updateDoc(doc(db(FOUNDER), 'gymCodes/XYZ234'), { name: 'Něco jiného' }));
  });

  test('importovanou posilovnu (OSM) zakladatel neupraví ani nesmaže', async () => {
    await assertFails(updateDoc(doc(db(FOUNDER), `gyms/${OSM}`), texts('X', 'Y')));
    await assertFails(deleteDoc(doc(db(FOUNDER), `gyms/${OSM}`)));
  });

  test('smazat jde, až v posilovně nikdo není – i s kódem', async () => {
    const fs = db(FOUNDER);
    // Ještě je členem.
    await assertFails(deleteDoc(doc(fs, `gyms/${OWN}`)));
    // Odejde (členství −1), pak smaže posilovnu i kód.
    const leave = writeBatch(fs);
    leave.delete(doc(fs, `gyms/${OWN}/members/${FOUNDER}`));
    leave.update(doc(fs, `gyms/${OWN}`), { memberCount: increment(-1) });
    await assertSucceeds(leave.commit());
    await assertFails(deleteDoc(doc(db(OLD), `gyms/${OWN}`)));
    await assertFails(deleteDoc(doc(fs, 'gymCodes/XYZ234')));
    const del = writeBatch(fs);
    del.delete(doc(fs, `gyms/${OWN}`));
    del.delete(doc(fs, 'gymCodes/XYZ234'));
    await assertSucceeds(del.commit());
  });

  test('s dalšími členy smazat nejde', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), `gyms/${OWN}`), { memberCount: 2 }));
    const fs = db(FOUNDER);
    const leave = writeBatch(fs);
    leave.delete(doc(fs, `gyms/${OWN}/members/${FOUNDER}`));
    leave.update(doc(fs, `gyms/${OWN}`), { memberCount: increment(-1) });
    await assertSucceeds(leave.commit());
    await assertFails(deleteDoc(doc(fs, `gyms/${OWN}`)));
  });
});
