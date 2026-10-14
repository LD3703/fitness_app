// Skrývání posiloven z adresáře po nahlášení (contentReports, kind "gym").
// Čistá logika bez Firestore – testy: functions/test/gymDirectory.test.mjs
// (npm test ve složce functions). Popis: docs/gyms_import.md, „Nahlášení“.
//
// Dvě skupiny důvodů:
//  - nevhodný obsah (offensive, spam, other): od 5 nahlášení se posilovna
//    skryje trvale (hiddenReason "reports"), i když má členy,
//  - neexistuje / duplicita (closed, duplicate): od 5 nahlášení se skryje
//    jen posilovna bez členů (hiddenReason "closed"). Skrytí je vratné:
//    jakmile do ní někdo vstoupí, znovu se ukáže a tahle nahlášení se
//    začnou počítat od nuly (closedReportsResetAt).

/// Zrcadlo kGymDirectoryReportThreshold v moderation_logic.dart.
export const GYM_DIRECTORY_REPORT_THRESHOLD = 5;
/// Zrcadlo kGymClosedReportThreshold v moderation_logic.dart.
export const GYM_CLOSED_REPORT_THRESHOLD = 5;

export const CONTENT_REASONS = ["offensive", "spam", "other"];
export const CLOSED_REASONS = ["closed", "duplicate"];

export type GymHideReason = "reports" | "closed";

export interface GymReportState {
  /// Nahlášení za nevhodný obsah (všechna).
  contentReports: number;
  /// Nahlášení „neexistuje / duplicita“ od posledního vynulování.
  closedReports: number;
  memberCount: number;
  hidden: boolean;
  hiddenReason: string | null;
}

/// Má se posilovna teď skrýt (a proč)? null = nic neměnit.
export function gymHideDecision(s: GymReportState): GymHideReason | null {
  if (s.contentReports >= GYM_DIRECTORY_REPORT_THRESHOLD) {
    // Trvalé skrytí přebije i dřívější vratné („closed“).
    return s.hidden && s.hiddenReason === "reports" ? null : "reports";
  }
  if (s.hidden) return null;
  if (s.closedReports >= GYM_CLOSED_REPORT_THRESHOLD && s.memberCount <= 0) {
    return "closed";
  }
  return null;
}

/// Vstoupil nový člen: znovu ukázat posilovnu skrytou jako neexistující /
/// duplicitní (zjevně existuje). Trvalé skrytí za obsah zůstává.
export function shouldUnhideOnJoin(gym: { hidden?: unknown; hiddenReason?: unknown }): boolean {
  return gym.hidden === true && gym.hiddenReason === "closed";
}
