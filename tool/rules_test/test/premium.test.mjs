// Testy pravidel pro slib „Premium půl roku zdarma“ prvních uživatelů
// (users/{uid}/private/premium, firestore.rules, lib/premium/premium_gift.dart).
// Spuštění: cd tool/rules_test && npm ci && npm test  (potřebuje Javu).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';

const ME = 'user1';
const OTHER = 'user2';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-gymbar-premium',
    firestore: { rules: readFileSync('../../firestore.rules', 'utf8') },
  });
});

after(() => env.cleanup());

beforeEach(() => env.clearFirestore());

const db = (uid) => env.authenticatedContext(uid).firestore();
const premium = (fs, uid = ME) => doc(fs, `users/${uid}/private/premium`);

describe('users/{uid}/private/premium', () => {
  test('před spuštěním Premium si slib uložím k účtu a přečtu ho', async () => {
    await assertSucceeds(setDoc(premium(db(ME)), { earlyAt: serverTimestamp() }));
    await assertSucceeds(getDoc(premium(db(ME))));
  });

  test('cizí slib ani vlastní s jiným časem nebo polem nejde', async () => {
    await assertFails(setDoc(premium(db(OTHER), ME), { earlyAt: serverTimestamp() }));
    await assertFails(setDoc(premium(db(ME)), { earlyAt: Timestamp.fromDate(new Date(2026, 0, 1)) }));
    await assertFails(setDoc(premium(db(ME)), { earlyAt: serverTimestamp(), months: 120 }));
    await assertFails(getDoc(premium(db(OTHER), ME)));
  });

  test('slib nejde přepsat', async () => {
    await assertSucceeds(setDoc(premium(db(ME)), { earlyAt: serverTimestamp() }));
    await assertFails(updateDoc(premium(db(ME)), { earlyAt: serverTimestamp() }));
    await assertFails(setDoc(premium(db(ME)), { earlyAt: serverTimestamp() }));
  });

  test('po spuštění Premium (config/premium) nový slib nevznikne', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'config/premium'), { launchedAt: Timestamp.now() }));
    await assertFails(setDoc(premium(db(ME)), { earlyAt: serverTimestamp() }));
  });

  test('vlastní slib smím smazat (smazání účtu)', async () => {
    await assertSucceeds(setDoc(premium(db(ME)), { earlyAt: serverTimestamp() }));
    await assertSucceeds(deleteDoc(premium(db(ME))));
  });
});
