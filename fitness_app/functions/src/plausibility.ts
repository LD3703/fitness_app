// Kontrola nereálných výkonů v žebříčku posilovny – zrcadlo
// lib/modules/social/gym/plausibility.dart (absolutní hranice a skok;
// tělesná váha se v žebříčku nepoužívá).

/**
 * Absolutní hranice kategorií: kg odhadu 1RM u cviků (klíč = slug
 * vestavěného cviku; jednoručky na jednu jednoručku, shyby a dipy jen
 * přidaná zátěž), počet tréninků za měsíc u „workouts“.
 * Stejně jako GymCategory v gym_logic.dart a categoryLimits() ve firestore.rules.
 */
export const GYM_ABSOLUTE_LIMITS = {
  bench_press: 350,
  back_squat: 500,
  deadlift: 500,
  overhead_press: 250,
  incline_bench_press: 300,
  dumbbell_bench_press: 120,
  dumbbell_shoulder_press: 100,
  barbell_curl: 150,
  dumbbell_curl: 80,
  weighted_pull_up: 150,
  weighted_dips: 200,
  barbell_row: 300,
  leg_press: 1000,
  hip_thrust: 500,
  front_squat: 400,
  romanian_deadlift: 400,
  workouts: 62,
} as const satisfies Record<string, number>;

export type GymCategory = keyof typeof GYM_ABSOLUTE_LIMITS;

export const GYM_CATEGORIES = Object.keys(GYM_ABSOLUTE_LIMITS) as GymCategory[];

export function isGymCategory(v: unknown): v is GymCategory {
  return typeof v === "string" && Object.prototype.hasOwnProperty.call(GYM_ABSOLUTE_LIMITS, v);
}

/** Max. skok proti předchozímu maximu (15 %) v okně 14 dní. */
export const GYM_MAX_JUMP = 0.15;
export const GYM_JUMP_WINDOW_MS = 14 * 24 * 60 * 60 * 1000;

/** Od kolika nahlášení se záznam skryje. */
export const GYM_REPORT_HIDE_THRESHOLD = 5;

const EPSILON = 1e-9;

export type ImplausibleReason = "absolute" | "jump";

/** Odhad 1RM v kg (všechno kromě počtu tréninků). */
export function isLift(c: GymCategory): boolean {
  return c !== "workouts";
}

/**
 * Vrátí důvod, proč hodnota neprošla, nebo null.
 * previousValue / previousAt = poslední serverem ověřené maximum.
 */
export function checkGymValue(args: {
  category: GymCategory;
  value: number;
  previousValue?: number | null;
  previousAt?: Date | null;
  now?: Date;
}): ImplausibleReason | null {
  const { category, value, previousValue, previousAt, now } = args;
  if (!Number.isFinite(value) || value < 0) return "absolute";
  if (value > GYM_ABSOLUTE_LIMITS[category] + EPSILON) return "absolute";
  if (!isLift(category)) return null;
  if (
    typeof previousValue === "number" &&
    previousValue > 0 &&
    previousAt instanceof Date &&
    now instanceof Date
  ) {
    // Budoucí čas (posunuté hodiny) bereme jako „nedávno“.
    const recent = now.getTime() - previousAt.getTime() < GYM_JUMP_WINDOW_MS;
    if (recent && value > previousValue * (1 + GYM_MAX_JUMP) + EPSILON) return "jump";
  }
  return null;
}
