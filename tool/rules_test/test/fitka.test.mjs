// Testy pravidel pro doporučení „Doporuč GymBar svému fitku“
// (gymReferrals, firestore.rules, docs/fitka.md).
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
  increment,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';

const MEMBER = 'member1';
const OTHER = 'other1';
const GYM = 'gym1';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-gymbar-fitka',
    firestore: { rules: readFileSync('../../firestore.rules', 'utf8') },
  });
});

after(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    await setDoc(doc(fs, `gyms/${GYM}`), { name: 'Gym', city: 'Jičín', code: 'ABC234', memberCount: 1 });
    await setDoc(doc(fs, `gyms/${GYM}/members/${MEMBER}`), { uid: MEMBER });
  });
});

const db = (uid) => env.authenticatedContext(uid).firestore();
const ref = (fs, uid = MEMBER, gymId = GYM) => doc(fs, `gymReferrals/${gymId}_${uid}`);
const fresh = (uid = MEMBER, gymId = GYM) => ({
  gymId, uid, count: 1, createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
});

describe('gymReferrals', () => {
  test('člen posilovny založí svůj záznam', async () => {
    // Transakce v aplikaci nejdřív čte (záznam ještě není).
    await assertSucceeds(getDoc(ref(db(MEMBER))));
    await assertSucceeds(setDoc(ref(db(MEMBER)), fresh()));
  });

  test('nečlen ani cizí uid záznam nezaloží', async () => {
    await assertFails(setDoc(ref(db(OTHER), OTHER), fresh(OTHER)));
    await assertFails(setDoc(ref(db(OTHER), MEMBER), fresh(MEMBER)));
    await assertFails(setDoc(ref(db(MEMBER)), { ...fresh(), count: 5 }));
    await assertFails(setDoc(ref(db(MEMBER)), { ...fresh(), extra: true }));
    await assertFails(setDoc(doc(db(MEMBER), `gymReferrals/jiny_${MEMBER}`), fresh()));
  });

  test('počet jde jen o jedna nahoru, jen vlastníkem', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(ref(ctx.firestore()), { ...fresh(), createdAt: Timestamp.now(), updatedAt: Timestamp.now() }));
    await assertSucceeds(updateDoc(ref(db(MEMBER)), { count: increment(1), updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref(db(MEMBER)), { count: 10, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref(db(MEMBER)), { count: increment(1), updatedAt: serverTimestamp(), gymId: 'x' }));
    await assertFails(updateDoc(ref(db(OTHER)), { count: increment(1), updatedAt: serverTimestamp() }));
  });

  test('číst jde jen vlastní záznam, mazat nikdo', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(ref(ctx.firestore()), { ...fresh(), createdAt: Timestamp.now(), updatedAt: Timestamp.now() }));
    await assertSucceeds(getDoc(ref(db(MEMBER))));
    await assertFails(getDoc(ref(db(OTHER))));
    await assertFails(getDoc(ref(env.unauthenticatedContext().firestore())));
    await assertFails(deleteDoc(ref(db(MEMBER))));
  });
});

describe('liftStats', () => {
  test('číst smí kdokoli, zapisovat nikdo', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'liftStats/world_bench_press'), { groups: { all_all: { n: 1 } } }));
    await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(), 'liftStats/world_bench_press')));
    await assertSucceeds(getDoc(doc(db(MEMBER), 'liftStats/world_bench_press')));
    await assertFails(setDoc(doc(db(MEMBER), 'liftStats/world_bench_press'), { groups: {} }));
    await assertFails(deleteDoc(doc(db(MEMBER), 'liftStats/world_bench_press')));
  });
});
