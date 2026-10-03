// Cloud Functions pro sociální funkce aplikace (docs/social.md).
//
// 1) sendFeedPush – nová položka v novinkách (users/{uid}/feed/{id})
//    → push notifikace na telefony příjemce (FCM).
// 2) cleanupDeletedUser – po smazání účtu ve Firebase Auth smaže všechna
//    data uživatele (aplikace to dělá sama, tohle je pojistka).
//
// Aplikace funguje i bez nasazených funkcí: novinky jsou vidět v aplikaci,
// jen nechodí push.
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import * as logger from "firebase-functions/logger";
import { setGlobalOptions } from "firebase-functions/v2";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onUserDeleted } from "firebase-functions/v2/identity";

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

  await writer.close();
  // Dokument uživatele i s podkolekcemi (friends, feed, private).
  await db.recursiveDelete(userRef);
}

// Spouštěč smazání účtu (v2, firebase-functions 7.4+).
export const cleanupDeletedUser = onUserDeleted(async (event) => {
  const uid = event.data?.uid;
  if (!uid) return;
  await deleteUserData(uid);
  logger.info(`Deleted data of ${uid}`);
});
