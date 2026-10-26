// Výčty ukládané do databáze jako celé číslo (index).
// DŮLEŽITÉ: nové hodnoty přidávej vždy jen NA KONEC výčtu.
// Změna pořadí by rozbila už uložená data.

/// Svalové partie. Pořadí hodnot se nesmí měnit (v databázi je index),
/// nové se přidávají jen na konec.
///
/// [legs] je souhrnná partie „nohy“ (starší a vlastní cviky) – na mapě těla
/// i v únavě znamená stehna, hamstringy a lýtka dohromady. Vestavěné cviky
/// mají od verze schématu 12 přesnou partii ([quads], [hamstrings], [calves]).
enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  legs,
  glutes,
  core,
  fullBody,
  // --- verze schématu 12 ---
  quads,
  hamstrings,
  calves,
  forearms,
  traps,
  lowerBack,
}

/// Pořadí partií pro výběr v aplikaci (filtry, editor cviku, zranění).
const muscleGroupsUiOrder = <MuscleGroup>[
  MuscleGroup.chest,
  MuscleGroup.back,
  MuscleGroup.traps,
  MuscleGroup.lowerBack,
  MuscleGroup.shoulders,
  MuscleGroup.biceps,
  MuscleGroup.triceps,
  MuscleGroup.forearms,
  MuscleGroup.core,
  MuscleGroup.glutes,
  MuscleGroup.legs,
  MuscleGroup.quads,
  MuscleGroup.hamstrings,
  MuscleGroup.calves,
  MuscleGroup.fullBody,
];

/// Přesné partie nohou, které zastupuje souhrnná [MuscleGroup.legs].
const legMuscleGroups = <MuscleGroup>{
  MuscleGroup.quads,
  MuscleGroup.hamstrings,
  MuscleGroup.calves,
};

extension MuscleGroupX on MuscleGroup {
  /// Souhrnná partie, do které patří (stehna, hamstringy, lýtka → nohy).
  MuscleGroup? get parent =>
      legMuscleGroups.contains(this) ? MuscleGroup.legs : null;

  /// Přesné partie, které tahle partie znamená ([MuscleGroup.legs] →
  /// stehna, hamstringy a lýtka; ostatní samy sebe). Celé tělo se tu
  /// nerozkládá – to řeší každé místo zvlášť.
  Set<MuscleGroup> get specific =>
      this == MuscleGroup.legs ? legMuscleGroups : {this};

  /// Týkají se dvě partie téhož (stejná, nebo jedna je souhrnem druhé)?
  bool overlaps(MuscleGroup other) =>
      this == other || parent == other || other.parent == this;

  /// Dolní polovina těla (větší přírůstky váhy, plán B „nohy“).
  bool get isLowerBody =>
      this == MuscleGroup.legs ||
      this == MuscleGroup.glutes ||
      legMuscleGroups.contains(this);
}

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
  /// Překonat nejtěžší sérii v cviku (víc kg, nebo stejně kg na víc opakování).
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

/// Zaměření tréninku (verze schématu 14): síla / svaly / výdrž
/// (conditioning – v aplikaci „Výdrž“). Cíl je v profilu, plán může mít
/// vlastní a na obrazovce tréninku jde změnit. Podle něj se počítají
/// automatické pauzy (core/rest_time.dart), série a opakování hotových
/// programů (plan_templates.dart) a automatická progrese
/// (core/auto_progression.dart).
/// V databázi se ukládá jako index – pořadí neměnit.
enum TrainingFocus { strength, muscle, conditioning }

/// Úroveň pokročilosti (verze schématu 25): začátečník / mírně pokročilý /
/// pokročilý. Zadává se v úvodu a v profilu a postupně se vyvíjí podle
/// historie tréninků (core/experience_level.dart). Podle ní se doporučují
/// hotové programy a upravuje počet sérií (plan_templates.dart).
/// V databázi se ukládá jako index – pořadí neměnit.
enum ExperienceLevel { beginner, intermediate, advanced }

/// Pohlaví z profilu (volitelné). Používá se jen pro výchozí délku pauz.
/// V databázi se ukládá jako index – pořadí neměnit.
enum Sex { male, female }
