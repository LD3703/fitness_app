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
