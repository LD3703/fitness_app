#!/usr/bin/env node
// Import posiloven z OpenStreetMap do Firestore (gyms + gymCodes).
// Návod: docs/gyms_import.md
//
//   node import_gyms.mjs --dry-run --countries CZ,SK
//   node import_gyms.mjs --region all --project <firebase-project-id>
//
// Přepínače:
//   --region europe|americas|all   výchozí all (Evropa + Amerika)
//   --countries CZ,SK,US-CA        jen vybrané země / regiony
//   --dry-run                      jen stáhne a uloží out/<země>.json, nic nezapíše
//   --project <id>                 ID projektu Firebase (jinak z klíče)
//   --max-writes <n>               zastaví po n zápisech (bezplatný tarif:
//                                  20 000 zápisů denně), pokračuje další běh
//   --max-age-days <n>             stáří uložené odpovědi Overpass (výchozí 25)
//   --endpoint <url>[,<url>…]      server(y) Overpass (výchozí tři veřejné,
//                                  střídají se, když jeden neodpovídá)
//   --sync-from-firestore          načte stav importu z Firestore (jiný počítač)
//   --backfill-search              doplní hledací klíče posilovnám od uživatelů
//                                  (bez --countries jen to, žádný import)
import { randomInt } from 'node:crypto';
import http from 'node:http';
import https from 'node:https';
import { gunzipSync } from 'node:zlib';
import { existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  OVERPASS_ENDPOINTS,
  OVERPASS_QUERY_TIMEOUT,
  SPLIT_AFTER_FAILURES,
  SPLIT_BY_REGION,
  classifyOverpassFailure,
  countriesFor,
  dedupe,
  generateGymCode,
  gymsQuery,
  importHash,
  importedFields,
  overpassRuntimeError,
  parseOverpass,
  parseRegions,
  regionsQuery,
  retryCommand,
  searchKeys,
} from './lib.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const CACHE = join(HERE, 'cache');
const OUT = join(HERE, 'out');
const STATE = join(HERE, 'state');
const MANIFEST = join(STATE, 'manifest.json');

// ---------------------------------------------------------------- argumenty

function parseArgs(argv) {
  const a = {
    region: 'all', countries: null, dryRun: false, project: null,
    maxWrites: Infinity, maxAgeDays: 25,
    endpoints: [...OVERPASS_ENDPOINTS], endpointIndex: 0,
    syncFromFirestore: false, backfillSearch: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const k = argv[i];
    const next = () => {
      const v = argv[++i];
      if (v === undefined) throw new Error(`Missing value for ${k}`);
      return v;
    };
    switch (k) {
      case '--region': a.region = next(); break;
      case '--countries': a.countries = next().split(',').map((s) => s.trim().toUpperCase()).filter(Boolean); break;
      case '--dry-run': a.dryRun = true; break;
      case '--project': a.project = next(); break;
      case '--max-writes': a.maxWrites = Number(next()); break;
      case '--max-age-days': a.maxAgeDays = Number(next()); break;
      case '--endpoint': a.endpoints = next().split(',').map((s) => s.trim()).filter(Boolean); break;
      case '--sync-from-firestore': a.syncFromFirestore = true; break;
      case '--backfill-search': a.backfillSearch = true; break;
      case '--help': case '-h':
        console.log(readFileSync(fileURLToPath(import.meta.url), 'utf8').split('\n').slice(1, 21).join('\n'));
        process.exit(0);
        break;
      default: throw new Error(`Unknown option ${k}`);
    }
  }
  return a;
}

// ---------------------------------------------------------------- Overpass

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/// POST bez vestavěného fetch: ten po 5 minutách čekání na odpověď spojení
/// utne („fetch failed“), a velký dotaz přitom na serveru běží až
/// OVERPASS_QUERY_TIMEOUT. Vrací { status, text }, status 0 = bez odpovědi.
function post(url, body, timeoutMs) {
  return new Promise((resolve) => {
    const u = new URL(url);
    const req = (u.protocol === 'http:' ? http : https).request(u, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(body),
        'Accept-Encoding': 'gzip',
        'User-Agent': 'GymBar-gym-import/1.1 (https://gymbar.app)',
      },
    }, (res) => {
      const chunks = [];
      res.on('data', (c) => chunks.push(c));
      res.on('error', (e) => resolve({ status: 0, text: String(e.message ?? e) }));
      res.on('end', () => {
        let buf = Buffer.concat(chunks);
        try {
          if (res.headers['content-encoding'] === 'gzip') buf = gunzipSync(buf);
        } catch (e) {
          resolve({ status: 0, text: `poškozená odpověď: ${e.message}` });
          return;
        }
        resolve({ status: res.statusCode ?? 0, text: buf.toString('utf8') });
      });
    });
    req.setTimeout(timeoutMs, () => req.destroy(new Error(`bez odpovědi ${Math.round(timeoutMs / 1000)} s`)));
    req.on('error', (e) => resolve({ status: 0, text: String(e.message ?? e) }));
    req.end(body);
  });
}

function tooBigError(message) {
  const e = new Error(message);
  e.tooBig = true;
  return e;
}

/// Dotaz na Overpass s opakováním. Při přechodné chybě (504, výpadek)
/// přejde na další server; [splittable] = dotaz na celou zemi, který se
/// po SPLIT_AFTER_FAILURES chybách vzdá a země se stáhne po regionech.
async function overpass(args, query, { splittable = false } = {}) {
  const delays = [10, 30, 60, 120, 180, 300, 300];
  const host = (i) => new URL(args.endpoints[i % args.endpoints.length]).host;
  let failures = 0;
  for (let attempt = 0; ; attempt++) {
    const endpoint = args.endpoints[args.endpointIndex % args.endpoints.length];
    const res = await post(endpoint, `data=${encodeURIComponent(query)}`,
      (OVERPASS_QUERY_TIMEOUT + 120) * 1000);
    let kind;
    if (res.status === 200) {
      let json = null;
      try { json = JSON.parse(res.text); } catch { /* useknutá odpověď */ }
      if (json) {
        const err = overpassRuntimeError(json);
        if (err) throw tooBigError(err);
        return json;
      }
      kind = 'retry';
    } else {
      kind = classifyOverpassFailure(res.status, res.text);
    }
    const detail = res.status ? `HTTP ${res.status}` : res.text.slice(0, 80);
    if (kind === 'tooBig') throw tooBigError(res.text.slice(0, 300));
    if (kind === 'fatal') throw new Error(`Overpass ${detail}: ${res.text.slice(0, 300)}`);
    failures++;
    if (splittable && kind === 'retry' && failures >= SPLIT_AFTER_FAILURES) {
      throw tooBigError(`${failures}× ${detail}`);
    }
    if (attempt >= delays.length) throw new Error(`Overpass ${detail} (${failures} pokusů)`);
    const from = host(args.endpointIndex);
    args.endpointIndex = (args.endpointIndex + 1) % args.endpoints.length;
    const wait = kind === 'busy' ? Math.max(delays[attempt], 60) : delays[attempt];
    console.warn(`  ${from}: ${detail}, zkusím ${host(args.endpointIndex)} za ${wait} s…`);
    await sleep(wait * 1000);
  }
}

function cachePath(code) { return join(CACHE, `${code}.json`); }

function cached(code, maxAgeDays) {
  const p = cachePath(code);
  if (!existsSync(p)) return null;
  const ageDays = (Date.now() - statSync(p).mtimeMs) / 86400000;
  if (ageDays > maxAgeDays) return null;
  return JSON.parse(readFileSync(p, 'utf8'));
}

/// Odpověď Overpass pro zemi / region (z cache, nebo ze serveru).
async function fetchArea(args, code, { splittable = false } = {}) {
  const hit = cached(code, args.maxAgeDays);
  if (hit) return hit;
  console.log(`  stahuji ${code}…`);
  const json = await overpass(args, gymsQuery(code), { splittable });
  writeFileSync(cachePath(code), JSON.stringify(json));
  await sleep(5000); // šetrně k veřejnému serveru
  return json;
}

/// Posilovny jedné země (případně složené z regionů).
async function gymsOfCountry(args, country) {
  const parts = [];
  const byRegions = async () => {
    const regionsCache = join(CACHE, `${country}.regions.json`);
    let regions;
    if (existsSync(regionsCache)) {
      regions = JSON.parse(readFileSync(regionsCache, 'utf8'));
    } else {
      regions = parseRegions(await overpass(args, regionsQuery(country)), country);
      writeFileSync(regionsCache, JSON.stringify(regions));
      await sleep(5000);
    }
    if (regions.length === 0) throw new Error(`${country}: no regions found`);
    for (const r of regions) {
      parts.push(...parseOverpass(await fetchArea(args, r), country));
    }
  };
  if (SPLIT_BY_REGION.has(country)) {
    await byRegions();
  } else {
    try {
      parts.push(...parseOverpass(await fetchArea(args, country, { splittable: true }), country));
    } catch (e) {
      if (!e.tooBig) throw e;
      console.warn(`  ${country}: celá země najednou neprošla (${e.message.slice(0, 80)}), stahuji po regionech.`);
      await byRegions();
    }
  }
  return dedupe(parts);
}

// ---------------------------------------------------------------- stav

function loadManifest() {
  if (!existsSync(MANIFEST)) return { gyms: {} };
  return JSON.parse(readFileSync(MANIFEST, 'utf8'));
}

function saveManifest(m) {
  writeFileSync(MANIFEST, JSON.stringify(m));
}

// ---------------------------------------------------------------- Firestore

async function firestore(project) {
  const { initializeApp, applicationDefault } = await import('firebase-admin/app');
  const { getFirestore, FieldValue } = await import('firebase-admin/firestore');
  initializeApp({ credential: applicationDefault(), ...(project ? { projectId: project } : {}) });
  return { db: getFirestore(), FieldValue };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  for (const d of [CACHE, OUT, STATE]) mkdirSync(d, { recursive: true });
  const countries = args.countries ?? countriesFor(args.region);

  let fs = null;
  if (!args.dryRun) fs = await firestore(args.project);

  const manifest = loadManifest();
  // Bez uloženého stavu (první běh na tomto počítači) se stav načte
  // z Firestore, aby se už importované posilovny nezaložily znovu
  // s jiným kódem.
  if (fs && (args.syncFromFirestore || !existsSync(MANIFEST))) {
    console.log('Načítám stav importu z Firestore…');
    const snap = await fs.db.collection('gyms').where('source', '==', 'osm')
      .select('code', 'importHash', 'country', 'osmMissing').get();
    for (const d of snap.docs) {
      const x = d.data();
      manifest.gyms[d.id] = { code: x.code, hash: x.importHash ?? '', country: x.country, missing: x.osmMissing === true };
    }
    saveManifest(manifest);
    console.log(`  ${snap.size} posiloven.`);
  }

  if (fs && args.backfillSearch) {
    await backfillSearch(fs);
    // Bez --countries jen doplnění klíčů, žádný import.
    if (!args.countries) return;
  }

  // Obsazené kódy: všechny gymCodes (posilovny od uživatelů i z importu).
  let taken = null;
  const takenCodes = async () => {
    if (taken) return taken;
    taken = new Set(Object.values(manifest.gyms).map((g) => g.code).filter(Boolean));
    if (fs) {
      const snap = await fs.db.collection('gymCodes').select().get();
      for (const d of snap.docs) taken.add(d.id);
    }
    return taken;
  };

  let writes = 0;
  const summary = [];
  const failed = [];
  let writer = null;
  if (fs) {
    writer = fs.db.bulkWriter();
    writer.onWriteError((err) => {
      // Opakovat jen přechodné chyby (DEADLINE_EXCEEDED, RESOURCE_EXHAUSTED,
      // ABORTED, INTERNAL, UNAVAILABLE), ne ALREADY_EXISTS / NOT_FOUND.
      if (err.failedAttempts < 5 && [4, 8, 10, 13, 14].includes(err.code)) return true;
      console.error(`  zápis ${err.documentRef.path} selhal: ${err.message}`);
      return false;
    });
  }

  outer:
  for (const country of countries) {
    console.log(`${country}:`);
    let gyms;
    try {
      gyms = await gymsOfCountry(args, country);
    } catch (e) {
      console.error(`  ✗ ${country}: ${e.message}`);
      summary.push([country, 'chyba']);
      failed.push(country);
      continue;
    }
    writeFileSync(join(OUT, `${country}.json`), JSON.stringify(gyms, null, 1));
    let created = 0, updated = 0, missing = 0;

    if (fs) {
      const seen = new Set();
      for (const g of gyms) {
        if (writes >= args.maxWrites) { console.log('  dosažen limit --max-writes'); break outer; }
        seen.add(g.id);
        const hash = importHash(g);
        const prev = manifest.gyms[g.id];
        const fields = { ...importedFields(g), importHash: hash, importedAt: fs.FieldValue.serverTimestamp() };
        if (!prev) {
          const code = generateGymCode(randomInt, await takenCodes());
          writer.create(fs.db.doc(`gyms/${g.id}`), {
            ...fields, code, memberCount: 0, createdAt: fs.FieldValue.serverTimestamp(),
          });
          writer.create(fs.db.doc(`gymCodes/${code}`), { gymId: g.id, name: g.name, city: g.city });
          manifest.gyms[g.id] = { code, hash, country };
          writes += 2; created++;
        } else if (prev.hash !== hash || prev.missing) {
          writer.update(fs.db.doc(`gyms/${g.id}`), fields);
          writer.set(fs.db.doc(`gymCodes/${prev.code}`), { gymId: g.id, name: g.name, city: g.city });
          manifest.gyms[g.id] = { ...prev, hash, missing: false };
          writes += 2; updated++;
        }
        if (writes % 1000 < 2) saveManifest(manifest);
      }
      // Posilovny, které z OSM zmizely: jen označit (členové a žebříček
      // zůstávají, prázdné aplikace v seznamu neukáže).
      for (const [id, prev] of Object.entries(manifest.gyms)) {
        if (prev.country !== country || seen.has(id) || prev.missing) continue;
        if (writes >= args.maxWrites) break;
        writer.update(fs.db.doc(`gyms/${id}`), { osmMissing: true });
        manifest.gyms[id] = { ...prev, missing: true };
        writes++; missing++;
      }
      await writer.flush();
      saveManifest(manifest);
    }
    summary.push([country, gyms.length, created, updated, missing]);
    console.log(`  ${gyms.length} posiloven` + (fs ? ` (nové ${created}, změněné ${updated}, zmizelé ${missing})` : ''));
  }

  if (writer) await writer.close();
  if (fs) saveManifest(manifest);
  console.log('\nHotovo. Země | posilovny | nové | změněné | zmizelé');
  for (const row of summary) console.log(row.join(' | '));
  if (fs) console.log(`Zápisů: ${writes}`);
  const again = retryCommand(failed, args.project);
  if (again) {
    console.log(`\nNedokončené země: ${failed.join(', ')}. Hotové části jsou uložené,`);
    console.log(`nový pokus stáhne jen zbytek (třeba za hodinu, až budou servery volnější):`);
    console.log(`  ${again}`);
    process.exitCode = 2;
  }
}

/// Hledací klíče (nameCity, cityName) pro posilovny založené uživateli.
async function backfillSearch(fs) {
  console.log('Doplňuji hledací klíče posilovnám od uživatelů…');
  const snap = await fs.db.collection('gyms').select('name', 'city', 'source', 'nameCity').get();
  const writer = fs.db.bulkWriter();
  let n = 0;
  for (const d of snap.docs) {
    const x = d.data();
    if (x.source === 'osm' || typeof x.nameCity === 'string') continue;
    const { nameCity, cityName } = searchKeys(String(x.name ?? ''), String(x.city ?? ''));
    writer.update(d.ref, { nameCity, cityName });
    n++;
  }
  await writer.close();
  console.log(`  ${n} posiloven.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
