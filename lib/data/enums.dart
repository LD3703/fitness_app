// Výčty ukládané do databáze jako celé číslo (index).
// DŮLEŽITÉ: nové hodnoty přidávej vždy jen NA KONEC výčtu.
// Změna pořadí by rozbila už uložená data.

enum MuscleGroup { chest, back, shoulders, biceps, triceps, legs, glutes, core, fullBody }

enum Equipment { barbell, dumbbell, machine, cable, bodyweight, kettlebell, band }

enum ExerciseType {
  /// Váha × opakování (bench press).
  weightReps,

  /// Jen opakování s vlastní vahou (kliky).
  bodyweightReps,

  /// Výdrž na čas (plank).
  duration,
}

enum UnitSystem { metric, imperial }

enum SessionKind {
  /// Plnohodnotný trénink podle plánu.
  full,

  /// Krátká náhradní rutina doma („Dnes nestíhám“).
  planB,
}

enum PeriodType { illness, injury, cut, bulk, maintenance, pause }

enum ScheduleStatus { planned, done, moved, planB, skipped }

enum ChallengeKind {
  /// Překonat odhad 1RM v cviku.
  beatRecord,

  /// Nejvíc tréninků za měsíc (cíl = počet).
  workoutsInMonth,

  /// Týdenní pitný režim (cíl = ml za týden).
  weeklyWater,
}

/// Pocit po tréninku (volitelný, v souhrnu). Upravuje zátěž tréninku
/// v modelu únavy svalů (viz core/fatigue.dart).
enum WorkoutFeeling { easy, ok, hard }

/// Druh automatické změny cílů v plánu po tréninku (verze schématu 10,
/// viz core/auto_progression.dart): vyšší váha, +1 opakování (u cviků na
/// čas sekundy), odlehčení o 10 %, nebo „drží“ (zvýšení zablokované kvůli
/// nemoci, zranění, zotavování nebo dietě).
enum ProgressionKind { increase, reps, deload, hold }
