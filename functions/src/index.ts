// Cloud Functions pro sociální funkce aplikace (docs/social.md).
//
// 1) sendFeedPush – nová položka v novinkách (users/{uid}/feed/{id})
//    → push notifikace na telefony příjemce (FCM).
// 2) cleanupDeletedUser – po smazání účtu ve Firebase Auth smaže všechna
//    data uživatele (aplikace to dělá sama, tohle je pojistka), včetně
//    záloh v Cloud Storage (users/{uid}/backups/, modul cloud), jeho
//    položek v novinkách přátel a stavu moderace jeho záznamů v žebříčku.
// 3) onGymEntryWritten – žebříček posilovny: kontrola nereálných výkonů
//    (skryje záznam), znovu použije stav moderace u znovu vytvořeného
//    záznamu a novinka „předběhl tě“ pro dosavadního lídra (nejvýš 1× za
//    24 h pro stejnou posilovnu, kategorii a lídra).
// 4) onGymReportCreated – spočítá nahlášení záznamu (jen od člena aspoň
//    7 dní s vlastním záznamem), od třetiny členů (3–5) ho skryje.
// 5) onGymMemberDeleted – po odchodu z posilovny smaže nahlášení, která
//    člen podal (i u záznamů, které vlastník mezitím smazal).
//    onGymMemberCreated – posilovnu skrytou jako neexistující / duplicitní
//    po vstupu člena znovu ukáže.
//    onGymDeleted – posilovnu smazal zakladatel: uklidí podkolekce, kód
//    a doporučení.
// 6) onContentReportCreated – nahlášení posilovny nebo přítele
//    (contentReports): zapíše do logu pro vývojáře; posilovnu od 5
//    nahlášení za obsah skryje trvale, prázdnou posilovnu od 5 nahlášení
//    „neexistuje / duplicita“ vratně (gymDirectory.ts).
// 7) purgeOldContentReports – jednou denně smaže nahlášení starší než rok.
// 8) onCoachSessionWritten – pozvánka trenéra na trénink: push klientovi
//    (nová, změněná, zrušená) nebo trenérovi (přijatá, odmítnutá).
// 9) gymDirectory – veřejné hledání posilovny pro gymbar.app/fitka
//    (/api/gyms, rewrite ve firebase.json, logika ve fitka.ts).
// 10) updateLiftStats – jednou denně anonymní rozložení nejtěžších vah ze
//    žebříčků posiloven (liftStats/{země|world}_{cvik}) pro srovnání
//    „Jak si vedu“ v aplikaci (logika v liftStats.ts).
//
// Stav moderace záznamu žebříčku (počet nahlášení, skrytí za nahlášení,
// ověřená hodnota) je v gyms/{gymId}/moderation/{entryId} – jen server.
// Zůstává i po smazání záznamu vlastníkem, maže ho jen smazání účtu.
//
// Aplikace funguje i bez nasazených funkcí: novinky jsou vidět v aplikaci,
// jen nechodí push; žebříček posilovny skrývá nahlášené záznamy sám
// a nereálné hodnoty vůbec nezveřejní.
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import {
  DocumentData,
  DocumentReference,
  FieldValue,
  getFirestore,
  QueryDocumentSnapshot,
  Timestamp,
} from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { getStorage } from "firebase-admin/storage";
import * as logger from "firebase-functions/logger";
import { setGlobalOptions } from "firebase-functions/v2";
import {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentWritten,
} from "firebase-functions/v2/firestore";
import { onRequest } from "firebase-functions/v2/https";
import { onUserDeleted } from "firebase-functions/v2/identity";
import { onSchedule } from "firebase-functions/v2/scheduler";
import {
  checkGymValue,
  GYM_CATEGORIES,
  GYM_REPORT_HIDE_THRESHOLD,
  GymCategory,
  gymReportThreshold,
  isGymCategory,
  isLift,
} from "./plausibility.js";
import {
  clientCountUpdate,
  sessionChange,
  SessionData,
  sessionPushText,
  trainerExpiryCutoff,
} from "./coach.js";
import {
  CLOSED_REASONS,
  CONTENT_REASONS,
  gymHideDecision,
  isEstablishedReporter,
  shouldUnhideOnJoin,
} from "./gymDirectory.js";
import {
  FITKA_SEARCH_FIELDS,
  FITKA_SEARCH_LIMIT,
  fitkaGymId,
  fitkaQuery,
  mergeResults,
  PublicGym,
  publicGym,
} from "./fitka.js";
import {
  buildLiftStats,
  gymCountry,
  liftStatsDocId,
  StatEntry,
  statValue,
} from "./liftStats.js";
import { feedPushText, PushLang, pushLang, PushMessage } from "./pushText.js";

// Region funkcí. Musí odpovídat umístění databáze Firestore
// (eur3 → europe-west1, viz docs/social.md).
const REGION = "europe-west1";

setGlobalOptions({ region: REGION, maxInstances: 10 });
initializeApp();
const db = getFirestore();

interface FeedDoc {
  type?: string;
  fromName?: string;
  data?: Record<string, unknown>;
}

function str(v: unknown): string {
  return typeof v === "string" ? v : "";
}

// Číslo (počet), jinak 0.
function count(v: unknown): number {
  return typeof v === "number" && Number.isFinite(v) ? v : 0;
}

// Zkrátí text na [max] znaků (jména a názvy píšou uživatelé; FCM i systém
// mají limity délky notifikace).
function clip(s: string, max: number): string {
  const chars = Array.from(s);
  return chars.length <= max ? s : `${chars.slice(0, max - 1).join("")}…`;
}

// Délky textu notifikace: pole od uživatelů, titulek, text.
const PUSH_FIELD_MAX = 60;
const PUSH_TITLE_MAX = 80;
const PUSH_BODY_MAX = 200;

// Text notifikace k položce novinek v jazyce příjemce (pushText.ts).
// Pole od uživatelů jsou zkrácená (PUSH_FIELD_MAX), celek zkrátí volající.
function pushText(item: FeedDoc, lang: PushLang): PushMessage | null {
  const d = item.data ?? {};
  return feedPushText({
    type: str(item.type),
    name: clip(str(item.fromName) || "?", PUSH_FIELD_MAX),
    data: d,
    exercise: {
      slug: str(d.exerciseSlug),
      nameCs: clip(str(d.exerciseNameCs), PUSH_FIELD_MAX),
      nameEn: clip(str(d.exerciseNameEn), PUSH_FIELD_MAX),
    },
    planName: clip(str(d.planName), PUSH_FIELD_MAX),
    gymName: clip(str(d.gymName), PUSH_FIELD_MAX),
  }, lang);
}

// Chyby FCM, po kterých token už nikdy fungovat nebude.
const DEAD_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

// Pošle push na telefony uživatele [uid] (tokeny v users/{uid}/private/
// messaging). [text] dostane jazyk příjemce; null = nic neposílat.
async function pushToUser(
  uid: string,
  text: (lang: PushLang) => PushMessage | null,
  data: Record<string, string>,
): Promise<void> {
  const privateRef = db.doc(`users/${uid}/private/messaging`);
  const priv = (await privateRef.get()).data() ?? {};
  const tokens = Array.isArray(priv.fcmTokens)
    ? (priv.fcmTokens as unknown[]).filter((t): t is string => typeof t === "string")
    : [];
  if (tokens.length === 0) return;

  const lang = pushLang(str(priv.lang));
  const t = text(lang);
  if (!t) return;

  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: clip(t.title, PUSH_TITLE_MAX),
      body: clip(t.body, PUSH_BODY_MAX),
    },
    data,
    android: { notification: { channelId: "friends" } },
    apns: { payload: { aps: { sound: "default" } } },
  });

  // Neplatné tokeny (odinstalovaná aplikace) odebrat. Jiné chyby (např.
  // messaging/invalid-argument kvůli obsahu zprávy) token nemažou.
  const invalid: string[] = [];
  response.responses.forEach((r, i) => {
    if (DEAD_TOKEN_CODES.has(r.error?.code ?? "")) invalid.push(tokens[i]);
  });
  if (invalid.length > 0) {
    await privateRef.set({ fcmTokens: tokens.filter((tk) => !invalid.includes(tk)) }, { merge: true });
  }
  logger.info(`Push to ${uid}: ${response.successCount} ok, ${response.failureCount} failed`);
}

export const sendFeedPush = onDocumentCreated("users/{uid}/feed/{itemId}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const item = snap.data() as FeedDoc;
  await pushToUser(
    event.params.uid,
    (lang) => pushText(item, lang),
    { type: str(item.type), feedId: event.params.itemId },
  );
});

// Pozvánka trenéra na trénink: nová / změněná / zrušená → klient,
// přijatá / odmítnutá → trenér (jména z propojení coachLinks/{klient}).
export const onCoachSessionWritten = onDocumentWritten(
  "coachLinks/{clientUid}/sessions/{sessionId}",
  async (event) => {
    const before = event.data?.before.data() as SessionData | undefined;
    const after = event.data?.after.data() as SessionData | undefined;
    const change = sessionChange(before, after);
    if (!change || !after) return;
    const clientUid = event.params.clientUid;
    const link = (await db.doc(`coachLinks/${clientUid}`).get()).data();
    if (!link) return;
    const trainerUid = str(link.trainerUid);
    const toTrainer = change === "accepted" || change === "declined";
    const target = toTrainer ? trainerUid : clientUid;
    if (!target) return;
    const params = {
      trainerName: clip(str(link.trainerName) || "?", PUSH_FIELD_MAX),
      clientName: clip(str(link.clientName) || "?", PUSH_FIELD_MAX),
      title: clip(str(after.title) || "?", PUSH_FIELD_MAX),
      weekly: typeof after.weeks === "number" && after.weeks > 1,
    };
    await pushToUser(
      target,
      (lang) => sessionPushText(change, lang, params),
      { type: `coachSession.${change}`, sessionId: event.params.sessionId },
    );
  },
);

// Smaže všechna data uživatele [uid] (stejný rozsah jako aplikace).
async function deleteUserData(uid: string): Promise<void> {
  const writer = db.bulkWriter();
  const userRef = db.doc(`users/${uid}`);

  // U přátel odebrat vazbu na mě.
  const friends = await userRef.collection("friends").get();
  for (const f of friends.docs) {
    writer.delete(db.doc(`users/${f.id}/friends/${uid}`));
  }

  const codes = await db.collection("friendCodes").where("uid", "==", uid).get();
  codes.docs.forEach((d) => writer.delete(d.ref));

  for (const field of ["fromUid", "toUid"]) {
    const inv = await db.collection("invitations").where(field, "==", uid).get();
    inv.docs.forEach((d) => writer.delete(d.ref));
  }

  const challenges = await db.collection("challenges").where("members", "array-contains", uid).get();
  challenges.docs.forEach((d) => writer.delete(d.ref));

  // Doporučení „Doporuč GymBar svému fitku“ (docs/fitka.md).
  const referrals = await db.collection("gymReferrals").where("uid", "==", uid).get();
  referrals.docs.forEach((d) => writer.delete(d.ref));

  // Moje položky v novinkách přátel (pr, pozvánky, výzvy, gymOvertaken –
  // všude fromUid = já). Index feed.fromUid v firestore.indexes.json.
  const myFeedItems = await db.collectionGroup("feed").where("fromUid", "==", uid).get();
  myFeedItems.docs.forEach((d) => writer.delete(d.ref));

  // Posilovny: členství, záznamy v žebříčku (i s jejich nahlášeními)
  // a stav moderace. Posilovna z private/gym; pojistkou je hledání podle
  // uid (collection group members / entries / moderation), kdyby
  // private/gym chybělo nebo ukazovalo jinam.
  const gymIds = new Set<string>();
  const privateGymId = (await db.doc(`users/${uid}/private/gym`).get()).get("gymId");
  if (typeof privateGymId === "string" && privateGymId.length > 0) gymIds.add(privateGymId);
  const memberships = await db.collectionGroup("members").where("uid", "==", uid).get();
  for (const m of memberships.docs) {
    const gymId = gymIdOf(m.ref);
    if (gymId) gymIds.add(gymId);
  }

  // Cesty mých záznamů – smažou se i s podkolekcí reports (až po
  // writer.close, recursiveDelete).
  const entryPaths = new Set<string>();
  const moderation = await db.collectionGroup("moderation").where("uid", "==", uid).get();
  for (const m of moderation.docs) {
    const gymId = gymIdOf(m.ref);
    if (!gymId) continue;
    entryPaths.add(`gyms/${gymId}/entries/${m.id}`);
    writer.delete(m.ref);
  }
  const anyEntries = await db.collectionGroup("entries").where("uid", "==", uid).get();
  for (const e of anyEntries.docs) {
    if (gymIdOf(e.ref)) entryPaths.add(e.ref.path);
  }

  for (const gymId of gymIds) {
    const memberRef = db.doc(`gyms/${gymId}/members/${uid}`);
    if ((await memberRef.get()).exists) {
      writer.delete(memberRef);
      writer.update(db.doc(`gyms/${gymId}`), { memberCount: FieldValue.increment(-1) });
    }
    // Všechny záznamy s mým uid (i zrušených kategorií z dřívějších verzí).
    const entries = await db.collection(`gyms/${gymId}/entries`).where("uid", "==", uid).get();
    entries.docs.forEach((d) => entryPaths.add(d.ref.path));
    for (const c of GYM_CATEGORIES) entryPaths.add(`gyms/${gymId}/entries/${uid}_${c}`);
  }

  // Moje nahlášení cizích záznamů v těchto posilovnách (v dřívějších
  // posilovnách je smazal už onGymMemberDeleted při odchodu).
  for (const gymId of gymIds) {
    (await gymReportsBy(gymId, uid)).forEach((r) => writer.delete(r));
  }

  // Nahlášení obsahu, která jsem podal, a nahlášení mě jako uživatele.
  const myReports = await db.collection("contentReports").where("reporterUid", "==", uid).get();
  myReports.docs.forEach((d) => writer.delete(d.ref));
  const aboutMe = await db.collection("contentReports")
    .where("kind", "==", "user").where("targetId", "==", uid).get();
  aboutMe.docs.forEach((d) => writer.delete(d.ref));
  // U ostatních: záznam „zablokoval jsem <mě>“ (jméno a uid).
  const blockedMe = await db.collectionGroup("blocked").where("uid", "==", uid).get();
  blockedMe.docs.forEach((d) => writer.delete(d.ref));

  // (Až po writer.close – stejný dokument mění i memberCount výše.)
  await writer.close();
  // Moje záznamy v žebříčcích i s nahlášeními (podkolekce reports zůstává
  // po smazání záznamu vlastníkem, viz onGymEntryWritten). Stav moderace
  // je smazaný výš, smazaný účet ho už znovu nevytvoří (keepLegacyModeration).
  await Promise.all([...entryPaths].map((p) => db.recursiveDelete(db.doc(p))));
  // Posilovny, které jsem založil, zůstávají v adresáři pro ostatní
  // členy – jen se odstraní vazba na můj účet.
  const founded = await db.collection("gyms").where("createdBy", "==", uid).get();
  await Promise.all(founded.docs.map((d) => d.ref.update({ createdBy: FieldValue.delete() })));

  // Dokument uživatele i s podkolekcemi (friends, feed, private).
  await db.recursiveDelete(userRef);
}

// Trenér a klient (docs/coach.md): moje propojení jako klient i jako
// trenér (i s tréninky, plány a komentáři), status trenéra s kódem
// a knihovnou plánů a plány sdílené odkazem.

/// Smaže pod [ref] (podkolekce do hloubky) všechny dokumenty naposledy
/// změněné nejpozději v [cutoff] a pak i [ref], pokud je taky starší.
/// Novější data zůstanou – např. když klient mezitím vytvořil nové
/// propojení se stejným ID (coachLinks/{klient}) a nahrál do něj tréninky.
async function deleteStaleTree(ref: DocumentReference, cutoff: Timestamp): Promise<number> {
  let deleted = 0;
  for (const col of await ref.listCollections()) {
    for (const child of await col.listDocuments()) {
      deleted += await deleteStaleTree(child, cutoff);
    }
  }
  const snap = await ref.get();
  if (snap.exists && snap.updateTime && snap.updateTime.toMillis() <= cutoff.toMillis()) {
    await ref.delete();
    deleted++;
  }
  return deleted;
}

/// Čas události jako Timestamp (hranice pro deleteStaleTree).
function eventCutoff(time: string): Timestamp {
  const ms = Date.parse(time);
  return Timestamp.fromMillis(Number.isFinite(ms) ? ms : Date.now());
}

async function deleteCoachData(uid: string): Promise<void> {
  await db.recursiveDelete(db.doc(`coachLinks/${uid}`));
  const asTrainer = await db.collection("coachLinks").where("trainerUid", "==", uid).get();
  await Promise.all(asTrainer.docs.map((d) => db.recursiveDelete(d.ref)));
  const codes = await db.collection("trainerCodes").where("uid", "==", uid).get();
  await Promise.all(codes.docs.map((d) => d.ref.delete()));
  await db.recursiveDelete(db.doc(`trainers/${uid}`));
  const shared = await db.collection("sharedPlans").where("authorUid", "==", uid).get();
  await Promise.all(shared.docs.map((d) => d.ref.delete()));
}

// Smaže zálohy uživatele v Cloud Storage (automatická záloha, modul cloud).
// Bez zapnutého Storage (žádný výchozí bucket) jen zapíše varování.
async function deleteUserBackups(uid: string): Promise<void> {
  try {
    await getStorage().bucket().deleteFiles({ prefix: `users/${uid}/backups/` });
  } catch (e) {
    logger.warn(`Backups of ${uid} not deleted`, e);
  }
}

// Spouštěč smazání účtu (v2, firebase-functions 7.4+). Kroky běží zvlášť,
// aby chyba v jednom nezastavila ostatní; při chybě funkce skončí výjimkou
// a Firebase ji zopakuje (všechny kroky jdou bezpečně pustit znovu).
export const cleanupDeletedUser = onUserDeleted(
  { retry: true, timeoutSeconds: 540, memory: "512MiB" },
  async (event) => {
    const uid = event.data?.uid;
    if (!uid) return;
    const steps: [string, () => Promise<void>][] = [
      ["coach", () => deleteCoachData(uid)],
      ["data", () => deleteUserData(uid)],
      ["backups", () => deleteUserBackups(uid)],
    ];
    const failed: string[] = [];
    for (const [name, run] of steps) {
      try {
        await run();
      } catch (e) {
        failed.push(name);
        logger.error(`Cleanup of ${uid}: step ${name} failed`, e);
      }
    }
    if (failed.length > 0) throw new Error(`Cleanup of ${uid} incomplete: ${failed.join(", ")}`);
    logger.info(`Deleted data of ${uid}`);
  },
);

// ---------------------------------------------------------------------------
// Žebříček posilovny (docs/social.md, „Žebříček posilovny“)
// ---------------------------------------------------------------------------

// ID posilovny z cesty gyms/{gymId}/<kolekce>/{id}, jinak null (stejně
// pojmenovaná podkolekce může být i jinde).
function gymIdOf(ref: DocumentReference): string | null {
  const gym = ref.parent.parent;
  return gym && gym.parent.id === "gyms" ? gym.id : null;
}

// Existující nahlášení uživatele [uid] u cizích záznamů posilovny (id
// dokumentu = uid nahlašujícího) – i u záznamů, které vlastník mezitím
// smazal (zůstal po nich jen dokument moderace, aplikace je nevidí).
// Počet nahlášení (reportCount) v dokumentu moderace zůstává.
async function gymReportsBy(gymId: string, uid: string): Promise<DocumentReference[]> {
  const [entries, moderation] = await Promise.all([
    db.collection(`gyms/${gymId}/entries`).select().get(),
    db.collection(`gyms/${gymId}/moderation`).select().get(),
  ]);
  const ids = new Set<string>();
  entries.docs.forEach((d) => ids.add(d.id));
  moderation.docs.forEach((d) => ids.add(d.id));
  // Vlastní záznamy (`<uid>_<kategorie>`) nahlásit nejde.
  const refs = [...ids]
    .filter((id) => !id.startsWith(`${uid}_`))
    .map((id) => db.doc(`gyms/${gymId}/entries/${id}/reports/${uid}`));
  // Číst je levnější než mazat neexistující dokumenty.
  const found: DocumentReference[] = [];
  for (let i = 0; i < refs.length; i += 100) {
    const snaps = await db.getAll(...refs.slice(i, i + 100));
    snaps.forEach((s) => {
      if (s.exists) found.push(s.ref);
    });
  }
  return found;
}

// Odchod z posilovny (i smazání účtu): smaže moje nahlášení cizích záznamů
// v posilovně. Aplikace maže sama jen nahlášení u existujících záznamů.
// Vstup do posilovny skryté jako neexistující / duplicitní (5 nahlášení,
// bez členů): zjevně existuje → znovu ukázat v adresáři a nahlášení
// „neexistuje / duplicita“ počítat od teď (closedReportsResetAt).
export const onGymMemberCreated = onDocumentCreated("gyms/{gymId}/members/{uid}", async (event) => {
  const { gymId } = event.params;
  const gymRef = db.doc(`gyms/${gymId}`);
  const gym = await gymRef.get();
  if (!gym.exists || !shouldUnhideOnJoin(gym.data() ?? {})) return;
  await gymRef.update({
    hidden: false,
    hiddenReason: FieldValue.delete(),
    closedReportsResetAt: FieldValue.serverTimestamp(),
  });
  logger.info(`Gym ${gymId} shown again – a member joined after closed/duplicate reports`);
});

// Posilovnu smazal zakladatel (jen prázdnou – firestore.rules): uklidí
// podkolekce (záznamy, nahlášení, stav moderace, členy), kód a doporučení.
export const onGymDeleted = onDocumentDeleted("gyms/{gymId}", async (event) => {
  const { gymId } = event.params;
  const code = str(event.data?.get("code"));
  await db.recursiveDelete(db.doc(`gyms/${gymId}`));
  if (code) {
    const codeRef = db.doc(`gymCodes/${code}`);
    if ((await codeRef.get()).get("gymId") === gymId) await codeRef.delete();
  }
  const referrals = await db.collection("gymReferrals").where("gymId", "==", gymId).get();
  const writer = db.bulkWriter();
  referrals.docs.forEach((d) => writer.delete(d.ref));
  await writer.close();
  logger.info(`Gym ${gymId} deleted by its founder – cleaned up (${referrals.size} referral(s))`);
});

export const onGymMemberDeleted = onDocumentDeleted("gyms/{gymId}/members/{uid}", async (event) => {
  const { gymId, uid } = event.params;
  // Mezitím se vrátil → nahlášení i záznamy nechat.
  if ((await db.doc(`gyms/${gymId}/members/${uid}`).get()).exists) return;
  const refs = await gymReportsBy(gymId, uid);
  // Záznamy bývalého člena v žebříčku (aplikace je maže sama, tohle je
  // pojistka proti obejití přes SDK – záznam by zůstal viset).
  const entries = await db.collection(`gyms/${gymId}/entries`).where("uid", "==", uid).get();
  if (refs.length === 0 && entries.empty) return;
  const writer = db.bulkWriter();
  refs.forEach((r) => writer.delete(r));
  await writer.close();
  await Promise.all(entries.docs.map((d) => db.recursiveDelete(d.ref)));
  logger.info(`Gym ${gymId}: former member cleanup – ${refs.length} report(s), ${entries.size} entr(ies)`);
});

type Verified = { value: number; at: Date };

function readVerified(v: unknown): Verified | null {
  if (!v || typeof v !== "object") return null;
  const o = v as Record<string, unknown>;
  if (typeof o.value !== "number" || !(o.at instanceof Timestamp)) return null;
  return { value: o.value, at: o.at.toDate() };
}

function sameVerified(a: Verified | null, b: Verified | null): boolean {
  if (!a || !b) return a === b;
  return a.value === b.value && a.at.getTime() === b.at.getTime();
}

function isEntryHidden(d: DocumentData): boolean {
  return d.hidden === true || count(d.reportCount) >= GYM_REPORT_HIDE_THRESHOLD;
}

// Stav moderace záznamu – gyms/{gymId}/moderation/{entryId}, jen server
// (pravidla klientům čtení i zápis zakazují). Zůstává i po smazání záznamu
// vlastníkem (vypnutí „Ukázat mě“, odchod z posilovny), maže ho jen
// smazání účtu. Trvalé je skrytí za nahlášení ("reports") i ruční skrytí
// vývojářem (jiný důvod, např. "manual"); skrytí za nereálnou hodnotu
// ("implausible:…") se počítá při každé změně hodnoty znovu (proti
// `verified`). Pole: uid, category, reportCount, hiddenReason (trvalé
// skrytí), verified {value, at}, overtakenNotifiedAt (omezení novinky
// „předběhl tě“), updatedAt.
interface Moderation {
  reportCount: number;
  // Důvod trvalého skrytí ("reports", "manual"…), jinak null.
  hiddenReason: string | null;
  verified: Verified | null;
}

function moderationRef(gymId: string, entryId: string): DocumentReference {
  return db.doc(`gyms/${gymId}/moderation/${entryId}`);
}

// Důvod trvalého skrytí – cokoli kromě nereálné hodnoty.
function stickyReason(reason: unknown): string | null {
  const r = str(reason);
  return r && !r.startsWith("implausible") ? r : null;
}

// Trvalé skrytí na samotném záznamu (záznamy z doby před dokumenty
// moderace, ruční `hidden: true` bez důvodu = "manual").
function entryStickyReason(e: DocumentData): string | null {
  if (e.hidden !== true) return null;
  const r = str(e.hiddenReason);
  return r ? stickyReason(r) : "manual";
}

// Stav z dokumentu moderace a ze záznamu (záznamy z doby před dokumenty
// moderace mají stav jen na sobě) – bere se silnější z obou.
function readModeration(mod: DocumentData | undefined, entry: DocumentData | null): Moderation {
  const m = mod ?? {};
  const e = entry ?? {};
  const reportCount = Math.max(count(m.reportCount), count(e.reportCount));
  const hiddenReason =
    reportCount >= GYM_REPORT_HIDE_THRESHOLD
      ? "reports"
      : (stickyReason(m.hiddenReason) ?? entryStickyReason(e));
  const vm = readVerified(m.verified);
  const ve = readVerified(e.verified);
  const verified = vm && ve ? (ve.value > vm.value ? ve : vm) : (vm ?? ve);
  return { reportCount, hiddenReason, verified };
}

function sameModeration(a: Moderation, b: Moderation): boolean {
  return (
    a.reportCount === b.reportCount &&
    a.hiddenReason === b.hiddenReason &&
    sameVerified(a.verified, b.verified)
  );
}

function moderationData(uid: string, category: string, m: Moderation): Record<string, unknown> {
  const data: Record<string, unknown> = {
    uid,
    category,
    reportCount: m.reportCount,
    updatedAt: FieldValue.serverTimestamp(),
  };
  if (m.hiddenReason) data.hiddenReason = m.hiddenReason;
  if (m.verified) data.verified = { value: m.verified.value, at: Timestamp.fromDate(m.verified.at) };
  return data;
}

// Smazaný záznam: když nese stav, který v dokumentu moderace ještě není
// (záznam z doby před dokumenty moderace), přenese ho tam – znovu
// vytvořený záznam tak o skrytí nepřijde. Po smazání účtu (uživatel už
// v Auth není) se nic neukládá.
async function keepLegacyModeration(gymId: string, entryId: string, before: DocumentData): Promise<void> {
  const uid = str(before.uid);
  if (!uid) return;
  const ref = moderationRef(gymId, entryId);
  const mod = (await ref.get()).data();
  const current = readModeration(mod, null);
  const merged = readModeration(mod, before);
  if (sameModeration(current, merged)) return;
  try {
    await getAuth().getUser(uid);
  } catch {
    return;
  }
  await ref.set(moderationData(uid, str(before.category), merged), { merge: true });
}

// Kontrola reálnosti + novinka „předběhl tě“. Stav moderace se bere
// z dokumentu moderace, takže znovu vytvořený záznam je hned zase skrytý
// (nahlášení) a skok se kontroluje proti dřívější ověřené hodnotě. Zápisy
// serveru (hidden, hiddenReason, reportCount, verified) best, bestMonth
// ani monthKey nemění, takže se funkce nezacyklí.
export const onGymEntryWritten = onDocumentWritten("gyms/{gymId}/entries/{entryId}", async (event) => {
  const change = event.data;
  if (!change) return;
  const { gymId, entryId } = event.params;
  const before = change.before.exists ? (change.before.data() ?? null) : null;
  const after = change.after.exists ? (change.after.data() ?? null) : null;

  if (!after) {
    // Záznam smazán (vypnutí „Ukázat mě“, odchod z posilovny): nahlášení
    // i stav moderace zůstávají – maže je až smazání účtu.
    if (before) await keepLegacyModeration(gymId, entryId, before);
    return;
  }
  const modRef = moderationRef(gymId, entryId);
  const category = after.category;
  if (
    (before &&
      before.best === after.best &&
      before.bestMonth === after.bestMonth &&
      before.monthKey === after.monthKey) ||
    !isGymCategory(category) ||
    typeof after.best !== "number"
  ) {
    // Pole hidden musí mít každý záznam – dotaz žebříčku filtruje
    // hidden == false a pravidla jiný dotaz nepustí.
    if (typeof after.hidden !== "boolean") {
      const m = readModeration((await modRef.get()).data(), after);
      await change.after.ref.update({ hidden: m.hiddenReason !== null });
    }
    return;
  }
  const value: number = after.best;
  const now = new Date();
  const mod = readModeration((await modRef.get()).data(), after);
  const verified = mod.verified;

  const reason =
    checkGymValue({
      category,
      value,
      previousValue: verified?.value,
      previousAt: verified?.at,
      now,
    }) ??
    (typeof after.bestMonth === "number"
      ? checkGymValue({ category, value: after.bestMonth })
      : null);

  // Ověřená hodnota roste jen s reálnou hodnotou.
  const nextVerified: Verified | null =
    !reason && (!verified || value > verified.value) ? { value, at: now } : verified;
  const hiddenReason = mod.hiddenReason ?? (reason ? `implausible:${reason}` : null);
  const hidden = hiddenReason !== null;

  await modRef.set(
    moderationData(str(after.uid), category, { ...mod, verified: nextVerified }),
    { merge: true },
  );

  // Stav i na záznam (aplikace ho čte odtud) – jen co se liší.
  const update: Record<string, unknown> = {};
  if (after.hidden !== hidden) update.hidden = hidden;
  if ((str(after.hiddenReason) || null) !== hiddenReason) {
    update.hiddenReason = hiddenReason ?? FieldValue.delete();
  }
  if (count(after.reportCount) !== mod.reportCount) update.reportCount = mod.reportCount;
  if (nextVerified && !sameVerified(readVerified(after.verified), nextVerified)) {
    update.verified = { value: nextVerified.value, at: Timestamp.fromDate(nextVerified.at) };
  }
  if (Object.keys(update).length > 0) await change.after.ref.update(update);

  if (hidden) {
    if (reason) logger.info(`Gym entry ${gymId}/${entryId} hidden: ${reason} (${value})`);
    return;
  }
  // Předchozí hodnota. Nově vytvořený záznam (po vypnutí a zapnutí
  // „Ukázat mě“ nebo po návratu do posilovny) bere dřívější ověřenou
  // hodnotu, aby se stejný výkon nehlásil jako nové předběhnutí.
  const beforeValue = before
    ? (!isEntryHidden(before) && typeof before.best === "number" ? before.best : 0)
    : (verified?.value ?? 0);
  if (value <= beforeValue) return;
  await notifyOvertaken(gymId, category, after, value, beforeValue, now);
});

// Novinka „předběhl tě“ nejvýš jednou za 24 h pro stejnou posilovnu,
// kategorii a dosavadního lídra (čas overtakenNotifiedAt je v dokumentu
// moderace lídrova záznamu – jen server).
const OVERTAKEN_MIN_INTERVAL_MS = 24 * 3600 * 1000;

// Dosavadní lídr (nejlepší z ostatních, celkový žebříček) dostane novinku,
// když ho tahle hodnota předběhla a předtím byl první (i dělené 1. místo).
async function notifyOvertaken(
  gymId: string,
  category: GymCategory,
  entry: DocumentData,
  value: number,
  beforeValue: number,
  now: Date,
): Promise<void> {
  const uid = str(entry.uid);
  const top = await db
    .collection(`gyms/${gymId}/entries`)
    .where("category", "==", category)
    .orderBy("best", "desc")
    .limit(20)
    .get();
  const others = top.docs.filter((d) => {
    const x = d.data();
    return str(x.uid) !== uid && !isEntryHidden(x) && typeof x.best === "number";
  });
  if (others.length === 0) return;
  const leaderValue = others[0].get("best") as number;
  if (!(leaderValue >= beforeValue && value > leaderValue)) return;

  const gym = (await db.doc(`gyms/${gymId}`).get()).data() ?? {};
  const leaders = others.filter((d) => d.get("best") === leaderValue);
  let sent = 0;
  for (const leader of leaders) {
    const leaderUid = str(leader.get("uid"));
    if (!leaderUid) continue;
    const modRef = moderationRef(gymId, leader.id);
    const feedRef = db.collection(`users/${leaderUid}/feed`).doc();
    const notified = await db.runTransaction(async (tx) => {
      const last = (await tx.get(modRef)).get("overtakenNotifiedAt");
      if (last instanceof Timestamp && now.getTime() - last.toMillis() < OVERTAKEN_MIN_INTERVAL_MS) {
        return false;
      }
      tx.set(
        modRef,
        { uid: leaderUid, category, overtakenNotifiedAt: Timestamp.fromDate(now) },
        { merge: true },
      );
      tx.set(feedRef, {
        type: "gymOvertaken",
        fromUid: uid,
        fromName: str(entry.nickname) || "?",
        createdAt: FieldValue.serverTimestamp(),
        read: false,
        data: {
          gymId,
          gymName: str(gym.name),
          category,
          value,
          previousValue: leaderValue,
          lift: isLift(category),
        },
      });
      return true;
    });
    if (notified) sent++;
  }
  logger.info(`Gym ${gymId}: ${uid} overtook ${leaders.length} leader(s) in ${category}, notified ${sent}`);
}

// Nahlášení: spočítá je a od gymReportThreshold(počet členů) – třetina
// členů, 3 až 5 – záznam skryje. Počítají se jen nahlášení s myEntry:
// pravidla je pustí jen od člena, který je v posilovně aspoň 7 dní a má
// v ní vlastní záznam (dřívější jsou už v reportCount). Počet a skrytí se
// ukládají do dokumentu moderace (přežijí smazání a nové vytvoření
// záznamu) a kopírují se na záznam.
export const onGymReportCreated = onDocumentCreated(
  "gyms/{gymId}/entries/{entryId}/reports/{reporterUid}",
  async (event) => {
    const { gymId, entryId } = event.params;
    const entryRef = db.doc(`gyms/${gymId}/entries/${entryId}`);
    const modRef = moderationRef(gymId, entryId);
    const [entrySnap, modSnap, gymSnap] = await Promise.all([
      entryRef.get(),
      modRef.get(),
      db.doc(`gyms/${gymId}`).get(),
    ]);
    const entry = entrySnap.exists ? (entrySnap.data() ?? null) : null;
    if (!entry && !modSnap.exists) return;
    const reportDocs = await entryRef.collection("reports").get();
    const reports = reportDocs.docs.filter((d) => typeof d.get("myEntry") === "string").length;
    const state = readModeration(modSnap.data(), entry);
    // Nahlášení smazaná autorem (odchod z posilovny, smazání účtu) počet
    // nesnižují.
    state.reportCount = Math.max(state.reportCount, reports);
    const threshold = gymReportThreshold(Number(gymSnap.get("memberCount") ?? 0));
    const newlyHidden = state.reportCount >= threshold && state.hiddenReason == null;
    if (state.reportCount >= threshold) state.hiddenReason = "reports";
    const uid = str(entry?.uid) || str(modSnap.get("uid"));
    const category = str(entry?.category) || str(modSnap.get("category"));
    await modRef.set(moderationData(uid, category, state), { merge: true });
    // Pro vývojáře (upozornění e-mailem, docs/social.md): záznam skrytý
    // za nahlášení – zkontrolovat, jestli právem.
    if (newlyHidden) {
      logger.warn(`Leaderboard entry hidden: gym ${gymId} entry ${entryId} ` +
        `reports=${state.reportCount}`);
    }
    if (!entry) return;
    const update: Record<string, unknown> = { reportCount: state.reportCount };
    if (state.hiddenReason) {
      update.hidden = true;
      update.hiddenReason = state.hiddenReason;
    }
    await entryRef.update(update);
  },
);

// ---------------------------------------------------------------------------
// Nahlášení nevhodného obsahu (docs/social.md, „Nahlášení a blokování“)
// ---------------------------------------------------------------------------

const CONTENT_REPORT_MAX_AGE_DAYS = 365;

export const onContentReportCreated = onDocumentCreated(
  "contentReports/{reportId}",
  async (event) => {
    const d = event.data?.data();
    if (!d) return;
    const kind = str(d.kind);
    const targetId = str(d.targetId);
    if (!targetId) return;
    const reports = db.collection("contentReports")
      .where("kind", "==", kind).where("targetId", "==", targetId);
    const total = (await reports.count().get()).data().count;
    // Pro vývojáře: Firebase konzole → Functions → Logs (a kolekce
    // contentReports ve Firestore).
    logger.warn(`Content report: ${kind} ${targetId} "${str(d.targetName)}" ` +
      `reason=${str(d.reason)} total=${total}`);
    if (kind !== "gym") return;

    const gymRef = db.doc(`gyms/${targetId}`);
    const gym = await gymRef.get();
    if (!gym.exists) return;
    // Nahlášení „neexistuje / duplicita“ jen od posledního vstupu člena
    // do skryté posilovny (onGymMemberCreated) – starší se nepočítají.
    const resetAt = gym.get("closedReportsResetAt");
    let closedQuery = reports.where("reason", "in", CLOSED_REASONS);
    if (resetAt instanceof Timestamp) closedQuery = closedQuery.where("createdAt", ">", resetAt);
    const [contentDocs, closedReports] = await Promise.all([
      reports.where("reason", "in", CONTENT_REASONS).get(),
      closedQuery.count().get(),
    ]);
    const contentReports = await countEstablishedReporters(contentDocs.docs);
    const decision = gymHideDecision({
      contentReports,
      closedReports: closedReports.data().count,
      memberCount: Number(gym.get("memberCount") ?? 0),
      hidden: gym.get("hidden") === true,
      hiddenReason: str(gym.get("hiddenReason")) || null,
    });
    if (!decision) return;
    await gymRef.update({ hidden: true, hiddenReason: decision });
    logger.warn(`Gym ${targetId} hidden from the directory (${decision}), ` +
      `content=${contentReports} closed=${closedReports.data().count}`);
  },
);

// Kolik nahlášení je od účtů, které v době nahlášení existovaly aspoň
// GYM_REPORTER_MIN_ACCOUNT_DAYS dní (smazané účty se nepočítají).
async function countEstablishedReporters(docs: QueryDocumentSnapshot[]): Promise<number> {
  const uids = [...new Set(docs.map((d) => str(d.get("reporterUid"))).filter((u) => u))];
  const created = new Map<string, number>();
  for (let i = 0; i < uids.length; i += 100) {
    const res = await getAuth().getUsers(uids.slice(i, i + 100).map((uid) => ({ uid })));
    for (const u of res.users) created.set(u.uid, Date.parse(u.metadata.creationTime));
  }
  return docs.filter((d) => {
    const at = d.get("createdAt");
    const reportedAt = at instanceof Timestamp ? at.toMillis() : Date.now();
    return isEstablishedReporter(created.get(str(d.get("reporterUid"))) ?? null, reportedAt);
  }).length;
}

export const purgeOldContentReports = onSchedule("every 24 hours", async () => {
  const cutoff = Timestamp.fromMillis(Date.now() - CONTENT_REPORT_MAX_AGE_DAYS * 24 * 3600 * 1000);
  const old = await db.collection("contentReports").where("createdAt", "<", cutoff).limit(500).get();
  const writer = db.bulkWriter();
  old.docs.forEach((d) => writer.delete(d.ref));
  await writer.close();
  if (!old.empty) logger.info(`Purged ${old.size} old content reports`);
});

// ---------------------------------------------------------------------------
// Trenér a klient (docs/coach.md)
// ---------------------------------------------------------------------------

// Přepočítá klienty trenéra (clientCount) a odpočet do ztráty statusu
// (zeroSince = od kdy nemá žádného klienta). Počítá se z propojení, takže
// je to odolné proti dvojímu spuštění.
async function recountClients(trainerUid: string): Promise<void> {
  const ref = db.doc(`trainers/${trainerUid}`);
  const agg = await db.collection("coachLinks").where("trainerUid", "==", trainerUid).count().get();
  const count = agg.data().count;
  await db.runTransaction(async (tx) => {
    const t = await tx.get(ref);
    if (!t.exists) return;
    const u = clientCountUpdate(count, t.get("zeroSince") != null);
    const data: Record<string, unknown> = { clientCount: u.clientCount };
    if (u.zeroSince === "now") data.zeroSince = FieldValue.serverTimestamp();
    if (u.zeroSince === "delete") data.zeroSince = FieldValue.delete();
    tx.update(ref, data);
  });
}

// Nový trenér: clientCount 0 a začne odpočet 60 dní (pokud už nemá klienty).
export const onTrainerCreated = onDocumentCreated("trainers/{uid}", async (event) => {
  await recountClients(event.params.uid);
});

// Zrušený status (trenér sám, vypršení, smazání účtu): propojení s klienty
// se zruší i s jejich podkolekcemi, smaže se kód a knihovna plánů.
// Konec statusu trenéra. Maže jen data starší než konec statusu: když se
// mezitím znovu stal trenérem, nový dokument, kód a noví klienti zůstanou.
export const onTrainerDeleted = onDocumentDeleted("trainers/{uid}", async (event) => {
  const uid = event.params.uid;
  const cutoff = eventCutoff(event.time);
  const old = (d: { createTime?: Timestamp }) =>
    !d.createTime || d.createTime.toMillis() <= cutoff.toMillis();
  const links = (await db.collection("coachLinks").where("trainerUid", "==", uid).get())
    .docs.filter(old);
  for (const d of links) await deleteStaleTree(d.ref, cutoff);
  const codes = (await db.collection("trainerCodes").where("uid", "==", uid).get())
    .docs.filter(old);
  await Promise.all(codes.map((d) => d.ref.delete()));
  await deleteStaleTree(db.doc(`trainers/${uid}`), cutoff);
  logger.info(`Trainer ${uid} removed (${links.length} links)`);
});

export const onCoachLinkCreated = onDocumentCreated("coachLinks/{clientUid}", async (event) => {
  const trainerUid = event.data?.get("trainerUid");
  if (typeof trainerUid === "string") await recountClients(trainerUid);
});

// Zrušené propojení: smaže tréninky, váhu, plány a komentáře klienta
// (trenér k nim už nesmí mít přístup) a přepočítá klienty trenéra.
// Při přepojení na jiného trenéra aplikace staré propojení smaže a hned
// vytvoří nové se stejným ID – maže se proto jen to, co je starší než
// smazání (nové propojení a nově nahrané tréninky zůstanou).
export const onCoachLinkDeleted = onDocumentDeleted("coachLinks/{clientUid}", async (event) => {
  await deleteStaleTree(db.doc(`coachLinks/${event.params.clientUid}`), eventCutoff(event.time));
  const trainerUid = event.data?.get("trainerUid");
  if (typeof trainerUid === "string") await recountClients(trainerUid);
});

// Trenér, který 60 dní nemá žádného klienta, přijde o status
// (index trainers: clientCount + zeroSince ve firestore.indexes.json).
export const expireTrainers = onSchedule("every 24 hours", async () => {
  const cutoff = Timestamp.fromMillis(trainerExpiryCutoff(Date.now()));
  const old = await db.collection("trainers")
    .where("clientCount", "==", 0)
    .where("zeroSince", "<", cutoff)
    .limit(200)
    .get();
  await Promise.all(old.docs.map((d) => d.ref.delete()));
  if (!old.empty) logger.info(`Expired ${old.size} trainers without clients`);
});

// gymbar.app/fitka: hledání posilovny (?q=název nebo město) nebo jedna
// posilovna (?id=…). Volá se přes Hosting (/api/gyms), proto bez CORS.
// Vrací jen veřejná pole (fitka.ts), odpověď se krátce cachuje na CDN.
export const gymDirectory = onRequest(
  { maxInstances: 3, memory: "256MiB", invoker: "public" },
  async (req, res) => {
    if (req.method !== "GET") {
      res.status(405).json({ gyms: [] });
      return;
    }
    const fields = ["name", "city", "address", "code", "memberCount", "hidden", "osmMissing"];
    const id = fitkaGymId(req.query.id);
    let gyms: PublicGym[];
    if (id) {
      const snap = await db.doc(`gyms/${id}`).get();
      const g = snap.exists ? publicGym(id, snap.data() ?? {}) : null;
      gyms = g ? [g] : [];
    } else {
      const q = fitkaQuery(req.query.q);
      if (!q) {
        res.status(400).json({ gyms: [] });
        return;
      }
      const snaps = await Promise.all(FITKA_SEARCH_FIELDS.map((f) =>
        db.collection("gyms")
          .where(f, ">=", q)
          .where(f, "<", q + "\uf8ff")
          .select(...fields)
          .limit(FITKA_SEARCH_LIMIT)
          .get()));
      gyms = mergeResults(snaps.map((s) => s.docs
        .map((d) => publicGym(d.id, d.data()))
        .filter((g): g is PublicGym => g !== null)));
    }
    res.set("Cache-Control", "public, max-age=60, s-maxage=300");
    res.json({ gyms });
  },
);

// Srovnání „Jak si vedu“: rozložení nejtěžších vah podle země posilovny
// a pro celý svět (liftStats.ts). Přepíše všechny dokumenty liftStats
// a smaže ty, pro které už nejsou data.
export const updateLiftStats = onSchedule(
  { schedule: "every 24 hours", memory: "512MiB", timeoutSeconds: 540 },
  async () => {
    const snap = await db.collectionGroup("entries")
      .select("uid", "category", "best", "gender", "ageGroup", "hidden", "reportCount")
      .get();
    // Záznamy z doby před polem hidden doplnit (dotaz žebříčku filtruje
    // hidden == false). Zápis spustí onGymEntryWritten, který ho jen potvrdí.
    const missingHidden = snap.docs.filter((d) => typeof d.get("hidden") !== "boolean");
    if (missingHidden.length > 0) {
      const backfill = db.bulkWriter();
      for (const d of missingHidden) {
        backfill.update(d.ref, { hidden: isEntryHidden(d.data()) }).catch(() => undefined);
      }
      await backfill.close();
      logger.info(`Entries: added hidden to ${missingHidden.length} entr(ies)`);
    }
    const raw: { gymId: string; d: Record<string, unknown> }[] = [];
    for (const doc of snap.docs) {
      const gymId = gymIdOf(doc.ref);
      if (gymId) raw.push({ gymId, d: doc.data() });
    }
    const gymIds = [...new Set(raw.map((r) => r.gymId))];
    const countries = new Map<string, string | null>();
    for (let i = 0; i < gymIds.length; i += 300) {
      const refs = gymIds.slice(i, i + 300).map((id) => db.doc(`gyms/${id}`));
      const gyms = refs.length ? await db.getAll(...refs, { fieldMask: ["country"] }) : [];
      for (const g of gyms) countries.set(g.id, gymCountry(g.data()));
    }
    const entries: StatEntry[] = [];
    for (const { gymId, d } of raw) {
      const value = statValue(d);
      if (value === null || typeof d.uid !== "string") continue;
      entries.push({
        uid: d.uid,
        category: d.category as string,
        value,
        gender: typeof d.gender === "string" ? d.gender : null,
        ageGroup: typeof d.ageGroup === "string" ? d.ageGroup : null,
        country: countries.get(gymId) ?? null,
      });
    }
    const docs = buildLiftStats(entries);
    const writer = db.bulkWriter();
    const keep = new Set<string>();
    for (const doc of docs) {
      const id = liftStatsDocId(doc.scope, doc.category);
      keep.add(id);
      writer.set(db.doc(`liftStats/${id}`), {
        scope: doc.scope,
        category: doc.category,
        groups: doc.groups,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    const old = await db.collection("liftStats").select().get();
    for (const d of old.docs) if (!keep.has(d.id)) writer.delete(d.ref);
    await writer.close();
    logger.info(`liftStats: ${entries.length} entries, ${docs.length} docs`);
  },
);
