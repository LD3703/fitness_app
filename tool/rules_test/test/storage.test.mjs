// Testy pravidel Cloud Storage (storage.rules) – zálohy databáze.
import { readFileSync } from 'node:fs';
import { after, before, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { getBytes, ref, uploadBytes } from 'firebase/storage';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-gymbar',
    storage: { rules: readFileSync('../../storage.rules', 'utf8') },
  });
});

after(() => env.cleanup());

const storage = (uid) => env.authenticatedContext(uid).storage();
const data = new Uint8Array([0x1f, 0x8b, 1, 2, 3]);
const gzip = { contentType: 'application/gzip' };

describe('zálohy', () => {
  test('vlastník nahraje a stáhne svou zálohu', async () => {
    const r = ref(storage('u1'), 'users/u1/backups/latest.sqlite');
    await assertSucceeds(uploadBytes(r, data, gzip));
    await assertSucceeds(getBytes(r));
  });

  test('cizí zálohu nikdo jiný nečte ani nepřepíše', async () => {
    const r = ref(storage('u2'), 'users/u1/backups/latest.sqlite');
    await assertFails(getBytes(r));
    await assertFails(uploadBytes(r, data, gzip));
  });

  test('jen dva názvy souborů a typ gzip / sqlite', async () => {
    const s = storage('u1');
    await assertFails(uploadBytes(ref(s, 'users/u1/backups/jiny.sqlite'), data, gzip));
    await assertFails(uploadBytes(ref(s, 'users/u1/backups/previous.sqlite'), data,
      { contentType: 'text/plain' }));
    await assertSucceeds(uploadBytes(ref(s, 'users/u1/backups/previous.sqlite'), data,
      { contentType: 'application/x-sqlite3' }));
    await assertFails(uploadBytes(ref(s, 'users/u1/jinde.bin'), data, gzip));
  });
});
