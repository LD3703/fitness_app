// Texty a data stránky gymbar.app/fitka (docs/web/fitka/, docs/fitka.md).
// Stránka je statická, test je tady, protože functions má Node a běží v CI.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import vm from 'node:vm';

const web = new URL('../../docs/web/', import.meta.url);

function load(...files) {
  const window = {};
  const ctx = vm.createContext({ window });
  for (const f of files) vm.runInContext(readFileSync(new URL(f, web), 'utf8'), ctx);
  return window;
}

const placeholders = (s) => [...s.matchAll(/\{(\w+)\}/g)].map((m) => m[1]).sort();

test('cs a en mají stejné klíče a zástupné symboly', () => {
  const { FITKA_STRINGS: S } = load('fitka/strings.js');
  assert.deepEqual(Object.keys(S).sort(), ['cs', 'en']);
  assert.deepEqual(Object.keys(S.cs).sort(), Object.keys(S.en).sort());
  for (const k of Object.keys(S.cs)) {
    assert.ok(S.cs[k].trim() && S.en[k].trim(), `prázdný text ${k}`);
    assert.deepEqual(placeholders(S.cs[k]), placeholders(S.en[k]), k);
  }
});

test('každý data-t na stránce má text', () => {
  const { FITKA_STRINGS: S } = load('fitka/strings.js');
  const html = readFileSync(new URL('fitka/index.html', web), 'utf8');
  const keys = [...html.matchAll(/data-t="(\w+)"/g)].map((m) => m[1]);
  assert.ok(keys.length > 20);
  for (const k of keys) assert.ok(k in S.cs, `chybí text ${k}`);
});

test('cviky: jedinečné slugy, výchozí samolepky existují', () => {
  const w = load('fitka/exercises.js');
  const slugs = w.GYMBAR_EXERCISES.map((e) => e.s);
  assert.equal(new Set(slugs).size, slugs.length);
  for (const s of w.GYMBAR_STICKER_DEFAULTS) {
    const e = w.GYMBAR_EXERCISES.find((x) => x.s === s);
    assert.ok(e && e.st, s);
  }
});

test('QR knihovna zakóduje odkaz na samolepku', () => {
  const ctx = vm.createContext({});
  vm.runInContext(readFileSync(new URL('fitka/qrcode.js', web), 'utf8') + ';this.q = qrcode;', ctx);
  const qr = ctx.q(0, 'M');
  qr.addData('https://gymbar.app/ex?id=chest_press_machine&gym=osm-n1234567890');
  qr.make();
  assert.ok(qr.getModuleCount() >= 25);
});
