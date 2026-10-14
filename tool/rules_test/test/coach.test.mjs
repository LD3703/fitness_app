// Testy pravidel Firestore pro trenéra a klienta (firestore.rules, docs/coach.md).
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
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const TRAINER = 'trainer1';
const CLIENT = 'client1';
const STRANGER = 'stranger1';
const CODE = 'ABC234';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-gymbar',
    firestore: { rules: readFileSync('../../firestore.rules', 'utf8') },
  });
});

after(() => env.cleanup());

beforeEach(() => env.clearFirestore());

const db = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

/** Data bez pravidel (stav před testem). */
const seed = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

const trainerDoc = () => ({
  name: 'Trenér Tom',
  code: CODE,
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
});

const linkDoc = (shareWeight = false) => ({
  clientUid: CLIENT,
  trainerUid: TRAINER,
  clientName: 'Klient Karel',
  trainerName: 'Trenér Tom',
  shareWeight,
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
});

/** Trenér a propojený klient. */
async function seedLinked({ shareWeight = false } = {}) {
  await seed(async (f) => {
    await setDoc(doc(f, 'trainers', TRAINER), trainerDoc());
    await setDoc(doc(f, 'trainerCodes', CODE), { uid: TRAINER });
    await setDoc(doc(f, 'coachLinks', CLIENT), linkDoc(shareWeight));
  });
}

const workout = () => ({
  startedAtMs: Date.UTC(2026, 9, 1, 18),
  durationMin: 60,
  title: 'Push',
  exercises: [{ slug: 'bench_press', sets: [{ kg: 60, reps: 8 }] }],
  updatedAt: serverTimestamp(),
});

describe('trenér', () => {
  test('stane se trenérem jen spolu se svým kódem', async () => {
    const f = db(TRAINER);
    const data = { name: 'Trenér Tom', code: CODE, createdAt: serverTimestamp(), updatedAt: serverTimestamp() };
    await assertFails(setDoc(doc(f, 'trainers', TRAINER), data));
    const b = writeBatch(f);
    b.set(doc(f, 'trainers', TRAINER), data);
    b.set(doc(f, 'trainerCodes', CODE), { uid: TRAINER });
    await assertSucceeds(b.commit());
  });

  test('počet klientů si nastavit nesmí', async () => {
    const f = db(TRAINER);
    const b = writeBatch(f);
    b.set(doc(f, 'trainers', TRAINER), {
      name: 'Trenér Tom', code: CODE, clientCount: 99,
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    b.set(doc(f, 'trainerCodes', CODE), { uid: TRAINER });
    await assertFails(b.commit());
  });

  test('profil trenéra jde načíst, seznam všech trenérů ne', async () => {
    await seedLinked();
    await assertSucceeds(getDoc(doc(db(STRANGER), 'trainers', TRAINER)));
    await assertFails(getDocs(collection(db(STRANGER), 'trainers')));
    await assertFails(getDoc(doc(anon(), 'trainers', TRAINER)));
  });

  test('knihovna plánů trenéra je jen jeho', async () => {
    await seedLinked();
    const plan = { plan: { name: 'Nohy', exercises: [] }, updatedAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(db(TRAINER), 'trainers', TRAINER, 'plans', 'p1'), plan));
    await assertFails(getDoc(doc(db(CLIENT), 'trainers', TRAINER, 'plans', 'p1')));
    await assertFails(setDoc(doc(db(CLIENT), 'trainers', TRAINER, 'plans', 'p2'), plan));
  });
});

describe('propojení klient → trenér', () => {
  test('vytvoří ho jen klient a jen k existujícímu trenérovi', async () => {
    await seed((f) => setDoc(doc(f, 'trainers', TRAINER), trainerDoc()));
    const data = { ...linkDoc(), createdAt: serverTimestamp(), updatedAt: serverTimestamp() };
    await assertFails(setDoc(doc(db(TRAINER), 'coachLinks', CLIENT), data));
    await assertFails(setDoc(doc(db(CLIENT), 'coachLinks', CLIENT), { ...data, trainerUid: 'nikdo' }));
    await assertSucceeds(setDoc(doc(db(CLIENT), 'coachLinks', CLIENT), data));
  });

  test('trenér vidí jen svoje klienty', async () => {
    await seedLinked();
    await assertSucceeds(getDoc(doc(db(TRAINER), 'coachLinks', CLIENT)));
    await assertSucceeds(getDocs(query(collection(db(TRAINER), 'coachLinks'),
      where('trainerUid', '==', TRAINER))));
    await assertFails(getDocs(collection(db(TRAINER), 'coachLinks')));
    await assertFails(getDoc(doc(db(STRANGER), 'coachLinks', CLIENT)));
  });

  test('klient nemůže přepsat trenéra, jen jméno a souhlas s váhou', async () => {
    await seedLinked();
    const f = db(CLIENT);
    await assertFails(updateDoc(doc(f, 'coachLinks', CLIENT),
      { trainerUid: STRANGER, updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(f, 'coachLinks', CLIENT),
      { shareWeight: true, updatedAt: serverTimestamp() }));
  });

  test('zrušit smí klient i trenér, cizí ne', async () => {
    await seedLinked();
    await assertFails(deleteDoc(doc(db(STRANGER), 'coachLinks', CLIENT)));
    await assertSucceeds(deleteDoc(doc(db(TRAINER), 'coachLinks', CLIENT)));
  });
});

describe('tréninky klienta', () => {
  test('zapisuje jen klient s platným ID', async () => {
    await seedLinked();
    await assertSucceeds(setDoc(doc(db(CLIENT), 'coachLinks', CLIENT, 'workouts', 's42'), workout()));
    await assertFails(setDoc(doc(db(CLIENT), 'coachLinks', CLIENT, 'workouts', 'x42'), workout()));
    await assertFails(setDoc(doc(db(TRAINER), 'coachLinks', CLIENT, 'workouts', 's43'), workout()));
  });

  test('bez propojení se nenahrávají', async () => {
    await assertFails(setDoc(doc(db(CLIENT), 'coachLinks', CLIENT, 'workouts', 's42'), workout()));
  });

  test('čte klient a jeho trenér, po zrušení propojení už trenér ne', async () => {
    await seedLinked();
    await setDoc(doc(db(CLIENT), 'coachLinks', CLIENT, 'workouts', 's42'), workout());
    const ref = (f) => doc(f, 'coachLinks', CLIENT, 'workouts', 's42');
    await assertSucceeds(getDoc(ref(db(TRAINER))));
    await assertFails(getDoc(ref(db(STRANGER))));
    await deleteDoc(doc(db(CLIENT), 'coachLinks', CLIENT));
    await assertFails(getDoc(ref(db(TRAINER))));
    await assertSucceeds(getDoc(ref(db(CLIENT))));
  });
});

describe('tělesná váha', () => {
  const weight = () => ({ points: [{ d: '2026-10-01', kg: 80 }], updatedAt: serverTimestamp() });
  const ref = (f) => doc(f, 'coachLinks', CLIENT, 'meta', 'weight');

  test('bez souhlasu ji klient nenahraje', async () => {
    await seedLinked({ shareWeight: false });
    await assertFails(setDoc(ref(db(CLIENT)), weight()));
  });

  test('se souhlasem ji trenér vidí, po odvolání už ne', async () => {
    await seedLinked({ shareWeight: true });
    await assertSucceeds(setDoc(ref(db(CLIENT)), weight()));
    await assertSucceeds(getDoc(ref(db(TRAINER))));
    await assertFails(getDoc(ref(db(STRANGER))));
    // Odvolání souhlasu – dokument s váhou ještě nestihl zmizet.
    await updateDoc(doc(db(CLIENT), 'coachLinks', CLIENT),
      { shareWeight: false, updatedAt: serverTimestamp() });
    await assertFails(getDoc(ref(db(TRAINER))));
    await assertSucceeds(getDoc(ref(db(CLIENT))));
  });
});

describe('plány a komentáře od trenéra', () => {
  const plan = () => ({
    plan: { name: 'Nohy', exercises: [] },
    version: 1,
    trainerName: 'Trenér Tom',
    updatedAt: serverTimestamp(),
  });
  const note = () => ({
    workoutId: 's42',
    text: 'Pěkný trénink!',
    trainerName: 'Trenér Tom',
    createdAt: serverTimestamp(),
  });

  test('plán posílá jen trenér klienta, klient ho smí odebrat', async () => {
    await seedLinked();
    const ref = (f) => doc(f, 'coachLinks', CLIENT, 'plans', 'p1');
    await assertFails(setDoc(ref(db(STRANGER)), plan()));
    await assertFails(setDoc(ref(db(CLIENT)), plan()));
    await assertSucceeds(setDoc(ref(db(TRAINER)), plan()));
    await assertSucceeds(getDoc(ref(db(CLIENT))));
    await assertSucceeds(deleteDoc(ref(db(CLIENT))));
  });

  test('komentář píše jen trenér a nejde upravit', async () => {
    await seedLinked();
    const ref = (f) => doc(f, 'coachLinks', CLIENT, 'notes', 'n1');
    await assertFails(setDoc(ref(db(CLIENT)), note()));
    await assertFails(setDoc(ref(db(TRAINER)), { ...note(), text: 'x'.repeat(501) }));
    await assertSucceeds(setDoc(ref(db(TRAINER)), note()));
    await assertSucceeds(getDoc(ref(db(CLIENT))));
    await assertFails(updateDoc(ref(db(TRAINER)), { text: 'Jinak' }));
  });
});

describe('plán sdílený odkazem', () => {
  const shared = (authorUid) => ({
    plan: { name: 'Push', exercises: [] },
    authorUid,
    authorName: 'Karel',
    createdAt: serverTimestamp(),
  });

  test('načte ho kdokoli s odkazem, seznam ne', async () => {
    await assertSucceeds(setDoc(doc(db(CLIENT), 'sharedPlans', 'x1'), shared(CLIENT)));
    await assertSucceeds(getDoc(doc(anon(), 'sharedPlans', 'x1')));
    await assertFails(getDocs(collection(anon(), 'sharedPlans')));
  });

  test('autora nejde podvrhnout, smazat smí jen autor', async () => {
    await assertFails(setDoc(doc(db(CLIENT), 'sharedPlans', 'x2'), shared(STRANGER)));
    await setDoc(doc(db(CLIENT), 'sharedPlans', 'x1'), shared(CLIENT));
    await assertFails(deleteDoc(doc(db(STRANGER), 'sharedPlans', 'x1')));
    await assertSucceeds(deleteDoc(doc(db(CLIENT), 'sharedPlans', 'x1')));
  });
});

describe('ostatní', () => {
  test('profil uživatele cizí nevidí', async () => {
    await seed((f) => setDoc(doc(f, 'users', CLIENT), { displayName: 'Karel' }));
    await assertSucceeds(getDoc(doc(db(CLIENT), 'users', CLIENT)));
    await assertFails(getDoc(doc(db(STRANGER), 'users', CLIENT)));
  });

  test('neznámé kolekce jsou zakázané', async () => {
    await assertFails(setDoc(doc(db(CLIENT), 'cokoli', 'x'), { a: 1 }));
    await assertFails(getDoc(doc(db(CLIENT), 'cokoli', 'x')));
  });
});
