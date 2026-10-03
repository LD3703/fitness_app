// Cloud Functions pro sociální funkce aplikace (docs/social.md).
//
// 1) sendFeedPush – nová položka v novinkách (users/{uid}/feed/{id})
//    → push notifikace na telefony příjemce (FCM).
// 2) cleanupDeletedUser – po smazání účtu ve Firebase Auth smaže všechna
//    data uživatele (aplikace to dělá sama, tohle je pojistka), včetně
//    záloh v Cloud Storage (users/{uid}/backups/, modul cloud).
// 3) onGymEntryWritten – žebříček posilovny: kontrola nereálných výkonů
//    (skryje záznam) a novinka „předběhl tě“ pro dosavadního lídra.
// 4) onGymReportCreated – spočítá nahlášení záznamu, od 5 ho skryje.
//
// Aplikace funguje i bez nasazených funkcí: novinky jsou vidět v aplikaci,
// jen nechodí push; žebříček posilovny skrývá nahlášené záznamy sám
// a nereálné hodnoty vůbec nezveřejní.
import { initializeApp } from "firebase-admin/app";
import { DocumentData, FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { getStorage } from "firebase-admin/storage";
import * as logger from "firebase-functions/logger";
import { setGlobalOptions } from "firebase-functions/v2";
import { onDocumentCreated, onDocumentWritten } from "firebase-functions/v2/firestore";
import { onUserDeleted } from "firebase-functions/v2/identity";
import {
  checkGymValue,
  GYM_CATEGORIES,
  GYM_REPORT_HIDE_THRESHOLD,
  GymCategory,
  isGymCategory,
  isLift,
} from "./plausibility.js";

// Region funkcí. Musí odpovídat umístění databáze Firestore
// (eur3 → europe-west1, viz docs/social.md).
const REGION = "europe-west1";

setGlobalOptions({ region: REGION, maxInstances: 10 });
initializeApp();
const db = getFirestore();

type Lang = "en" | "cs";

interface FeedDoc {
  type?: string;
  fromName?: string;
  data?: Record<string, unknown>;
}

function str(v: unknown): string {
  return typeof v === "string" ? v : "";
}

function num(v: unknown): string {
  if (typeof v !== "number") return "";
  return Number.isInteger(v) ? String(v) : v.toFixed(1);
}

// Názvy kategorií žebříčku posilovny pro text notifikace [cs, en]
// (stejně jako názvy vestavěných cviků v seed_data.dart).
const GYM_CATEGORY_NAMES: Record<GymCategory, [string, string]> = {
  bench_press: ["bench press", "bench press"],
  back_squat: ["dřep s činkou na zádech", "back squat"],
  deadlift: ["mrtvý tah", "deadlift"],
  overhead_press: ["tlaky nad hlavu", "overhead press"],
  incline_bench_press: ["bench press na šikmé lavici", "incline bench press"],
  dumbbell_bench_press: ["tlaky s jednoručkami na rovné lavici", "dumbbell bench press"],
  dumbbell_shoulder_press: ["tlaky s jednoručkami nad hlavu", "dumbbell shoulder press"],
  barbell_curl: ["bicepsový zdvih s velkou činkou", "barbell curl"],
  dumbbell_curl: ["bicepsový zdvih s jednoručkami", "dumbbell curl"],
  weighted_pull_up: ["shyby se zátěží", "weighted pull-up"],
  weighted_dips: ["dipy se zátěží", "weighted dips"],
  barbell_row: ["přítahy velké činky v předklonu", "barbell row"],
  leg_press: ["legpress", "leg press"],
  hip_thrust: ["hip thrust", "hip thrust"],
  front_squat: ["čelní dřep", "front squat"],
  romanian_deadlift: ["rumunský mrtvý tah", "Romanian deadlift"],
  workouts: ["tréninky", "workouts"],
};

// Staré klíče kategorií (před přechodem na slugy cviků).
const LEGACY_CATEGORY_KEYS: Record<string, GymCategory> = {
  bench: "bench_press",
  squat: "back_squat",
};

// Hodnota z žebříčku posilovny pro text notifikace.
function gymValueText(categoryKey: string, value: unknown, lang: Lang): string {
  const cs = lang === "cs";
  const key = LEGACY_CATEGORY_KEYS[categoryKey] ?? categoryKey;
  if (!isGymCategory(key)) return num(value);
  const label = GYM_CATEGORY_NAMES[key][cs ? 0 : 1];
  if (!isLift(key)) return `${label} ${num(value)}`;
  const note = key.startsWith("dumbbell_")
    ? (cs ? " na jednoručku" : " per dumbbell")
    : key.startsWith("weighted_")
      ? (cs ? " přidané zátěže" : " added weight")
      : "";
  return `${label} ${num(value)} kg${note}`;
}

// Text notifikace podle typu položky a jazyka příjemce.
function pushText(item: FeedDoc, lang: Lang): { title: string; body: string } | null {
  const name = str(item.fromName) || "?";
  const d = item.data ?? {};
  const exercise = lang === "cs"
    ? str(d.exerciseNameCs) || str(d.exerciseNameEn) || str(d.exerciseSlug)
    : str(d.exerciseNameEn) || str(d.exerciseSlug);
  const cs = lang === "cs";
  switch (item.type) {
    case "friend":
      return cs
        ? { title: "Nový přítel", body: `${name} si tě přidal(a) do přátel.` }
        : { title: "New friend", body: `${name} added you as a friend.` };
    case "pr":
      return cs
        ? { title: "Nový rekord", body: `${name} má nový rekord v cviku ${exercise}: ${num(d.value)} kg` }
        : { title: "New record", body: `${name} set a new ${exercise} record: ${num(d.value)} kg` };
    case "invite":
      return cs
        ? { title: "Pozvánka na trénink", body: `${name} tě zve na trénink: ${str(d.planName)}` }
        : { title: "Workout invitation", body: `${name} invites you to a workout: ${str(d.planName)}` };
    case "inviteReply":
      if (d.accepted === true) {
        return cs
          ? { title: "Pozvánka přijata", body: `${name} jde s tebou na trénink: ${str(d.planName)}` }
          : { title: "Invitation accepted", body: `${name} is joining your workout: ${str(d.planName)}` };
      }
      return cs
        ? { title: "Pozvánka odmítnuta", body: `${name} tentokrát nemůže.` }
        : { title: "Invitation declined", body: `${name} can't make it this time.` };
    case "challenge":
      if (d.role === "tookOn") {
        return cs
          ? { title: "Výzva přijata", body: `${name} se pokusí překonat tvůj rekord.` }
          : { title: "Challenge accepted", body: `${name} is going for your record.` };
      }
      return cs
        ? { title: "Nová výzva", body: `${name} tě vyzývá. Přijmeš?` }
        : { title: "New challenge", body: `${name} challenges you. Are you in?` };
    case "challengeDone":
      return cs
        ? { title: "Výzva splněna", body: `${name} splnil(a) vaši výzvu!` }
        : { title: "Challenge completed", body: `${name} completed your challenge!` };
    case "gymOvertaken": {
      const gym = str(d.gymName);
      const what = gymValueText(str(d.category), d.value, lang);
      return cs
        ? { title: "Přišel(a) jsi o 1. místo", body: `${name} tě v posilovně ${gym} předběhl(a): ${what}` }
        : { title: "You lost 1st place", body: `${name} overtook you at ${gym}: ${what}` };
    }
    default:
      return null;
  }
}

export const sendFeedPush = onDocumentCreated("users/{uid}/feed/{itemId}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const uid = event.params.uid;
  const item = snap.data() as FeedDoc;

  const privateRef = db.doc(`users/${uid}/private/messaging`);
  const priv = (await privateRef.get()).data() ?? {};
  const tokens = Array.isArray(priv.fcmTokens)
    ? (priv.fcmTokens as unknown[]).filter((t): t is string => typeof t === "string")
    : [];
  if (tokens.length === 0) return;

  const lang: Lang = str(priv.lang).startsWith("cs") ? "cs" : "en";
  const text = pushText(item, lang);
  if (!text) return;

  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification: text,
    data: { type: str(item.type), feedId: event.params.itemId },
    android: { notification: { channelId: "friends" } },
    apns: { payload: { aps: { sound: "default" } } },
  });

  // Neplatné tokeny (odinstalovaná aplikace) odebrat.
  const invalid: string[] = [];
  response.responses.forEach((r, i) => {
    const code = r.error?.code ?? "";
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token" ||
      code === "messaging/invalid-argument"
    ) {
      invalid.push(tokens[i]);
    }
  });
  if (invalid.length > 0) {
    await privateRef.set({ fcmTokens: tokens.filter((t) => !invalid.includes(t)) }, { merge: true });
  }
  logger.info(`Push to ${uid}: ${response.successCount} ok, ${response.failureCount} failed`);
});

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

  // Posilovna: členství a záznamy v žebříčku (nahlášení smaže
  // onGymEntryWritten při smazání záznamu).
  const gymId = (await db.doc(`users/${uid}/private/gym`).get()).get("gymId");
  if (typeof gymId === "string" && gymId.length > 0) {
    const memberRef = db.doc(`gyms/${gymId}/members/${uid}`);
    if ((await memberRef.get()).exists) {
      writer.delete(memberRef);
      writer.update(db.doc(`gyms/${gymId}`), { memberCount: FieldValue.increment(-1) });
    }
    // Všechny záznamy s mým uid (i zrušených kategorií z dřívějších verzí).
    const entries = await db.collection(`gyms/${gymId}/entries`).where("uid", "==", uid).get();
    const paths = new Set(entries.docs.map((d) => d.ref.path));
    for (const c of GYM_CATEGORIES) paths.add(`gyms/${gymId}/entries/${uid}_${c}`);
    paths.forEach((p) => writer.delete(db.doc(p)));
  }

  await writer.close();
  // Dokument uživatele i s podkolekcemi (friends, feed, private).
  await db.recursiveDelete(userRef);
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

// Spouštěč smazání účtu (v2, firebase-functions 7.4+).
export const cleanupDeletedUser = onUserDeleted(async (event) => {
  const uid = event.data?.uid;
  if (!uid) return;
  await deleteUserBackups(uid);
  await deleteUserData(uid);
  logger.info(`Deleted data of ${uid}`);
});

// ---------------------------------------------------------------------------
// Žebříček posilovny (docs/social.md, „Žebříček posilovny“)
// ---------------------------------------------------------------------------

function readVerified(v: unknown): { value: number; at: Date } | null {
  if (!v || typeof v !== "object") return null;
  const o = v as Record<string, unknown>;
  if (typeof o.value !== "number" || !(o.at instanceof Timestamp)) return null;
  return { value: o.value, at: o.at.toDate() };
}

function isEntryHidden(d: DocumentData): boolean {
  const reports = typeof d.reportCount === "number" ? d.reportCount : 0;
  return d.hidden === true || reports >= GYM_REPORT_HIDE_THRESHOLD;
}

function hiddenForPlausibility(d: DocumentData): boolean {
  return d.hidden === true && str(d.hiddenReason).startsWith("implausible");
}

// Kontrola reálnosti + novinka „předběhl tě“. Zápisy serveru (hidden,
// verified, reportCount) best/bestMonth nemění, takže se funkce nezacyklí.
export const onGymEntryWritten = onDocumentWritten("gyms/{gymId}/entries/{entryId}", async (event) => {
  const change = event.data;
  if (!change) return;
  const { gymId, entryId } = event.params;
  const before = change.before.exists ? (change.before.data() ?? null) : null;
  const after = change.after.exists ? (change.after.data() ?? null) : null;

  if (!after) {
    // Záznam smazán (odchod z posilovny) → uklidit nahlášení.
    await db.recursiveDelete(db.collection(`gyms/${gymId}/entries/${entryId}/reports`));
    return;
  }
  if (
    before &&
    before.best === after.best &&
    before.bestMonth === after.bestMonth &&
    before.monthKey === after.monthKey
  ) {
    return;
  }
  const category = after.category;
  if (!isGymCategory(category) || typeof after.best !== "number") return;
  const value: number = after.best;
  const now = new Date();
  const verified = readVerified(after.verified);

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

  const ref = change.after.ref;
  if (reason) {
    await ref.update({ hidden: true, hiddenReason: `implausible:${reason}` });
    logger.info(`Gym entry ${gymId}/${entryId} hidden: ${reason} (${value})`);
    return;
  }

  const update: Record<string, unknown> = {};
  if (!verified || value > verified.value) {
    update.verified = { value, at: Timestamp.fromDate(now) };
  }
  if (hiddenForPlausibility(after)) {
    update.hidden = false;
    update.hiddenReason = FieldValue.delete();
  }
  if (Object.keys(update).length > 0) await ref.update(update);

  const reports = typeof after.reportCount === "number" ? after.reportCount : 0;
  if (reports >= GYM_REPORT_HIDE_THRESHOLD || (after.hidden === true && !hiddenForPlausibility(after))) {
    return;
  }
  const beforeValue =
    before && !isEntryHidden(before) && typeof before.best === "number" ? before.best : 0;
  if (value <= beforeValue) return;
  await notifyOvertaken(gymId, category, after, value, beforeValue);
});

// Dosavadní lídr (nejlepší z ostatních, celkový žebříček) dostane novinku,
// když ho tahle hodnota předběhla a předtím byl první (i dělené 1. místo).
async function notifyOvertaken(
  gymId: string,
  category: GymCategory,
  entry: DocumentData,
  value: number,
  beforeValue: number,
): Promise<void> {
  const uid = str(entry.uid);
  const top = await db
    .collection(`gyms/${gymId}/entries`)
    .where("category", "==", category)
    .orderBy("best", "desc")
    .limit(20)
    .get();
  const others = top.docs
    .map((d) => d.data())
    .filter((d) => str(d.uid) !== uid && !isEntryHidden(d) && typeof d.best === "number");
  if (others.length === 0) return;
  const leaderValue = others[0].best as number;
  if (!(leaderValue >= beforeValue && value > leaderValue)) return;

  const gym = (await db.doc(`gyms/${gymId}`).get()).data() ?? {};
  const leaders = others.filter((d) => d.best === leaderValue);
  const batch = db.batch();
  for (const leader of leaders) {
    batch.set(db.collection(`users/${str(leader.uid)}/feed`).doc(), {
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
  }
  await batch.commit();
  logger.info(`Gym ${gymId}: ${uid} overtook ${leaders.length} leader(s) in ${category}`);
}

// Nahlášení: spočítá je a od GYM_REPORT_HIDE_THRESHOLD záznam skryje.
export const onGymReportCreated = onDocumentCreated(
  "gyms/{gymId}/entries/{entryId}/reports/{reporterUid}",
  async (event) => {
    const { gymId, entryId } = event.params;
    const entryRef = db.doc(`gyms/${gymId}/entries/${entryId}`);
    const entry = await entryRef.get();
    if (!entry.exists) return;
    const count = (await entryRef.collection("reports").count().get()).data().count;
    const update: Record<string, unknown> = { reportCount: count };
    if (count >= GYM_REPORT_HIDE_THRESHOLD) {
      update.hidden = true;
      update.hiddenReason = "reports";
    }
    await entryRef.update(update);
  },
);
