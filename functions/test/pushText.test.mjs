// Testy textů push notifikací (src/pushText.ts).
// Spuštění: cd functions && npm test  (nejdřív zkompiluje do lib/).
import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  exerciseName,
  feedPushText,
  gymValueText,
  PUSH_LANGS,
  pushLang,
  sessionText,
} from '../lib/pushText.js';

function item(type, data = {}, exercise = {}) {
  return {
    type,
    name: 'Eva',
    data,
    exercise: { slug: '', nameCs: '', nameEn: '', ...exercise },
    planName: 'Nohy',
    gymName: 'Iron Gym',
  };
}

const FEED_CASES = [
  item('friend'),
  item('pr', { value: 100 }, { slug: 'deadlift' }),
  item('invite'),
  item('inviteReply', { accepted: true }),
  item('inviteReply', { accepted: false }),
  item('challenge'),
  item('challenge', { role: 'tookOn' }),
  item('challengeDone'),
  item('gymOvertaken', { category: 'weighted_pull_up', value: 20 }),
];

test('jazyk příjemce z localeName', () => {
  assert.equal(pushLang('de'), 'de');
  assert.equal(pushLang('pt_BR'), 'pt');
  assert.equal(pushLang('SK'), 'sk');
  assert.equal(pushLang('ja'), 'en');
  assert.equal(pushLang(''), 'en');
});

test('všechny texty ve všech jazycích: vyplněné, bez zbylých {…}', () => {
  for (const lang of PUSH_LANGS) {
    for (const it of FEED_CASES) {
      const m = feedPushText(it, lang);
      assert.ok(m, `${lang} ${it.type}`);
      for (const s of [m.title, m.body]) {
        assert.ok(s.length > 0, `${lang} ${it.type}`);
        assert.ok(!/[{}]/.test(s), `${lang} ${it.type}: ${s}`);
      }
      assert.ok(m.body.includes('Eva'), `${lang} ${it.type}: ${m.body}`);
    }
    for (const c of ['invite', 'updated', 'cancelled', 'accepted', 'declined']) {
      const m = sessionText(c, lang, { trainerName: 'Tom', clientName: 'Karel', title: 'Záda', weekly: true });
      assert.ok(!/[{}]/.test(m.title + m.body), `${lang} ${c}: ${m.body}`);
      assert.ok(m.body.includes('Záda ('), `${lang} ${c}: ${m.body}`);
    }
  }
  assert.equal(feedPushText(item('unknown'), 'cs'), null);
});

test('názvy cviků v jazyce příjemce', () => {
  assert.equal(exerciseName('bench_press', 'de'), 'Bankdrücken');
  assert.equal(exerciseName('vlastni', 'de'), null);
  assert.equal(
    feedPushText(item('pr', { value: 102.5 }, { slug: 'bench_press' }), 'de').body,
    'Eva hat einen neuen Rekord bei Bankdrücken aufgestellt: 102,5 kg',
  );
  // Vlastní cvik: čeština (a slovenština) bere český název, jinak anglický.
  const custom = { slug: 'x1', nameCs: 'Můj cvik', nameEn: 'My lift' };
  assert.match(feedPushText(item('pr', { value: 50 }, custom), 'cs').body, /Můj cvik/);
  assert.match(feedPushText(item('pr', { value: 50 }, custom), 'fr').body, /My lift/);
});

test('hodnota z žebříčku posilovny', () => {
  assert.equal(gymValueText('weighted_pull_up', 20, 'cs'), 'Shyby se zátěží 20 kg přidané zátěže');
  assert.equal(gymValueText('dumbbell_curl', 22.5, 'en'), 'Dumbbell Curl 22.5 kg per dumbbell');
  assert.equal(gymValueText('workouts', 12, 'pl'), 'Treningi 12');
  // Starý klíč kategorie.
  assert.match(gymValueText('bench', 100, 'es'), /^Press de banca 100 kg$/);
});

test('jméno se vzorem se nedosazuje znovu', () => {
  const m = feedPushText({ ...item('invite'), name: '{plan} $& $1' }, 'en');
  assert.equal(m.body, '{plan} $& $1 invites you to a workout: Nohy');
});
