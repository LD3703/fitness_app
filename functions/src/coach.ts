// Trenér a klient – čistá logika bez Firestore (docs/coach.md).
// Testy: functions/test/coach.test.mjs (npm test ve složce functions).
import { PushLang, PushMessage, sessionText } from "./pushText.js";

/// Zrcadlo coachInactiveDays v packages/gymbar_coach/lib/src/codes.dart:
/// trenér bez klientů přijde o status po tolika dnech.
export const COACH_INACTIVE_DAYS = 60;

const DAY_MS = 24 * 3600 * 1000;

/// Co zapsat do trainers/{uid} po přepočtu klientů.
///  - zeroSince „now“: právě klesl na 0 klientů (nebo je trenér nový),
///  - „delete“: má klienty, odpočet se ruší,
///  - „keep“: beze změny.
export interface ClientCountUpdate {
  clientCount: number;
  zeroSince: "now" | "delete" | "keep";
}

export function clientCountUpdate(count: number, hasZeroSince: boolean): ClientCountUpdate {
  const n = Math.max(0, Math.floor(count));
  if (n > 0) return { clientCount: n, zeroSince: hasZeroSince ? "delete" : "keep" };
  return { clientCount: 0, zeroSince: hasZeroSince ? "keep" : "now" };
}

/// Hranice pro vypršení: trenéři se zeroSince starším než tohle.
export function trainerExpiryCutoff(nowMs: number): number {
  return nowMs - COACH_INACTIVE_DAYS * DAY_MS;
}

/// Přišel trenér o status?
export function trainerExpired(clientCount: number, zeroSinceMs: number | null, nowMs: number): boolean {
  if (clientCount > 0 || zeroSinceMs == null) return false;
  return zeroSinceMs < trainerExpiryCutoff(nowMs);
}

// ---------------------------------------------------------------------------
// Pozvánky na trénink (coachLinks/{klient}/sessions/{id})
// ---------------------------------------------------------------------------

export interface SessionData {
  status?: unknown;
  startAtMs?: unknown;
  durationMin?: unknown;
  weeks?: unknown;
  title?: unknown;
}

/// Co se s pozvánkou stalo (komu jde push):
///  invite / updated / cancelled → klient, accepted / declined → trenér.
export type SessionChange = "invite" | "updated" | "cancelled" | "accepted" | "declined";

export function sessionChange(
  before: SessionData | undefined,
  after: SessionData | undefined,
): SessionChange | null {
  if (!after) return null;
  if (!before) return after.status === "pending" ? "invite" : null;
  if (before.status !== after.status) {
    switch (after.status) {
      case "cancelled":
      case "accepted":
      case "declined":
        return after.status;
      case "pending":
        return "updated";
      default:
        return null;
    }
  }
  if (after.status !== "pending") return null;
  const changed = (["startAtMs", "durationMin", "weeks", "title"] as const)
    .some((k) => before[k] !== after[k]);
  return changed ? "updated" : null;
}

/// Text notifikace k pozvánce v jazyce příjemce (pushText.ts). Jména
/// a název jsou už zkrácené.
export function sessionPushText(
  change: SessionChange,
  lang: PushLang,
  p: { trainerName: string; clientName: string; title: string; weekly: boolean },
): PushMessage {
  return sessionText(change, lang, p);
}
