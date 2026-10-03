import 'package:drift/drift.dart';

import 'enums.dart';

// Tabulky odpovídají kapitole „Datový model“ ve specifikaci.
// Váhy se ukládají vždy v kg, objemy v ml; převod na lb/oz jen při zobrazení.

@DataClassName('UserProfile')
class UserProfiles extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().nullable()();
  IntColumn get birthYear => integer().nullable()();
  RealColumn get heightCm => real().nullable()();
  IntColumn get unitSystem =>
      intEnum<UnitSystem>().withDefault(const Constant(0))();
  IntColumn get waterGoalMl => integer().withDefault(const Constant(2500))();

  /// Čas ranní připomínky v minutách od půlnoci (450 = 7:30).
  IntColumn get morningReminderMinutes =>
      integer().withDefault(const Constant(450))();
  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();

  // Co chce uživatel sledovat (verze schématu 3). Vypnuté moduly se skryjí.
  BoolColumn get trackWater => boolean().withDefault(const Constant(true))();
  BoolColumn get trackWeight => boolean().withDefault(const Constant(true))();

  /// Období (nemoc, dieta…) a povzbuzující hlášky.
  BoolColumn get trackPeriods => boolean().withDefault(const Constant(true))();

  /// Odhad spálených kalorií v souhrnu tréninku.
  BoolColumn get showCalories => boolean().withDefault(const Constant(true))();

  /// Úvodní průvodce byl dokončen.
  BoolColumn get onboardingDone =>
      boolean().withDefault(const Constant(false))();

  // Připomínky a kalendář (verze schématu 4).
  BoolColumn get morningReminderEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get waterRemindersEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get calendarSyncEnabled =>
      boolean().withDefault(const Constant(false))();

  // Verze schématu 6 (funkce v2 a v3).
  /// Číst kalendář: volná okna, kolize, návrhy časů.
  BoolColumn get calendarReadEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Zápis tréninků a váhy do Health Connect / Apple Zdraví.
  BoolColumn get healthSyncEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Připomínky pití: od–do (minuty od půlnoci) a interval v minutách.
  IntColumn get waterReminderStartMinutes =>
      integer().withDefault(const Constant(9 * 60))();
  IntColumn get waterReminderEndMinutes =>
      integer().withDefault(const Constant(20 * 60))();
  IntColumn get waterReminderIntervalMinutes =>
      integer().withDefault(const Constant(120))();

  /// Vlastní objem sklenice / láhve pro rychlý zápis vody.
  IntColumn get glassMl => integer().withDefault(const Constant(250))();
  IntColumn get bottleMl => integer().withDefault(const Constant(500))();

  /// Co se sdílí s přáteli (sociální funkce v3).
  BoolColumn get shareRecordsWithFriends =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get shareWorkoutStatsWithFriends =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Exercise')
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stabilní identifikátor vestavěných cviků (např. 'bench_press'), u vlastních null.
  TextColumn get slug => text().nullable().unique()();
  TextColumn get nameEn => text()();
  TextColumn get nameCs => text()();
  IntColumn get muscleGroup => intEnum<MuscleGroup>()();
  IntColumn get equipment => intEnum<Equipment>()();
  IntColumn get type => intEnum<ExerciseType>()();
  TextColumn get mediaPath => text().nullable()();
  TextColumn get instructionsEn => text().nullable()();
  TextColumn get instructionsCs => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  /// MET hodnota pro odhad kalorií.
  RealColumn get met => real().withDefault(const Constant(5.0))();
}

@DataClassName('WorkoutPlan')
class WorkoutPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();

  /// Bitová maska dnů: bit 0 = pondělí ... bit 6 = neděle.
  IntColumn get weekdaysMask => integer().withDefault(const Constant(0))();

  /// Plánovaný čas tréninku v minutách od půlnoci.
  IntColumn get plannedTimeMinutes => integer().nullable()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
}

@DataClassName('PlanExercise')
class PlanExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId =>
      integer()
      .customConstraint('NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE')();
  IntColumn get exerciseId =>
      integer()
      .customConstraint('NOT NULL REFERENCES exercises(id)')();
  IntColumn get position => integer()();

  /// Od verze schématu 2 se nepoužívá – cíle jsou po sériích v [PlanSets].
  /// Sloupec zůstává kvůli kompatibilitě se staršími databázemi.
  IntColumn get targetSets => integer().withDefault(const Constant(3))();

  /// Od verze schématu 2 se nepoužívá – viz [PlanSets].
  IntColumn get targetReps => integer().withDefault(const Constant(10))();
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();
}

/// Cílová série cviku v plánu (verze schématu 2).
/// Každá série může mít jiný počet opakování, cílovou váhu a může být
/// rozcvičková.
@DataClassName('PlanSet')
class PlanSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planExerciseId =>
      integer()
      .customConstraint('NOT NULL REFERENCES plan_exercises(id) ON DELETE CASCADE')();
  IntColumn get position => integer()();

  /// Opakování, u cviků na čas sekundy.
  IntColumn get reps => integer()();

  /// Cílová váha v kg; null = bez cíle (předvyplní se z minula).
  RealColumn get weightKg => real().nullable()();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
}

@DataClassName('WorkoutSession')
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId =>
      integer().nullable()
      .customConstraint('NULL REFERENCES workout_plans(id) ON DELETE SET NULL')();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get kind =>
      intEnum<SessionKind>().withDefault(const Constant(0))();
  RealColumn get estimatedKcal => real().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get calendarEventId => text().nullable()();

  /// Kdy byl trénink zapsán do Health Connect / Apple Zdraví (v6).
  DateTimeColumn get healthExportedAt => dateTime().nullable()();
}

@DataClassName('SetEntry')
class SetEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer()
      .customConstraint('NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE')();
  IntColumn get exerciseId =>
      integer()
      .customConstraint('NOT NULL REFERENCES exercises(id)')();
  IntColumn get position => integer()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
}

@DataClassName('WaterEntry')
class WaterEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get loggedAt => dateTime()();
  IntColumn get amountMl => integer()();
}

@DataClassName('BodyWeightEntry')
class BodyWeightEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Den měření (čas 00:00 místního času) – jeden záznam na den.
  DateTimeColumn get day => dateTime().unique()();
  RealColumn get weightKg => real()();
}

@DataClassName('Period')
class Periods extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get type => intEnum<PeriodType>()();
  DateTimeColumn get startDate => dateTime()();

  /// null = období stále probíhá.
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get note => text().nullable()();

  /// U zranění: zasažené partie („shoulders,back“), jinak null.
  /// Viz core/injury.dart.
  TextColumn get muscleGroups => text().nullable()();
}

@DataClassName('ScheduledWorkout')
class ScheduledWorkouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId =>
      integer()
      .customConstraint('NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE')();
  DateTimeColumn get scheduledAt => dateTime()();
  IntColumn get status =>
      intEnum<ScheduleStatus>().withDefault(const Constant(0))();
  TextColumn get calendarEventId => text().nullable()();
}

@DataClassName('HomeRoutine')
class HomeRoutines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get slug => text().nullable().unique()();
  TextColumn get nameEn => text()();
  TextColumn get nameCs => text()();
  IntColumn get targetMuscleGroup => intEnum<MuscleGroup>()();
}

@DataClassName('HomeRoutineExercise')
class HomeRoutineExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId =>
      integer()
      .customConstraint('NOT NULL REFERENCES home_routines(id) ON DELETE CASCADE')();
  IntColumn get exerciseId =>
      integer()
      .customConstraint('NOT NULL REFERENCES exercises(id)')();
  IntColumn get position => integer()();
  IntColumn get workSeconds => integer().withDefault(const Constant(40))();
  IntColumn get restSeconds => integer().withDefault(const Constant(15))();
}

/// Události, které aplikace vytvořila v kalendáři telefonu (verze 4).
/// Slouží k jejich pozdější aktualizaci nebo smazání.
@DataClassName('CalendarLink')
class CalendarLinks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventId => text()();
  IntColumn get planId => integer().nullable()();

  /// Den tréninku (půlnoc místního času).
  DateTimeColumn get day => dateTime()();
}

/// Výzva: překonat rekord, počet tréninků za měsíc, týdenní pitný režim.
/// Vzniká z odkazu od kamaráda nebo od přátel v aplikaci (v6).
@DataClassName('Challenge')
class Challenges extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get kind => intEnum<ChallengeKind>()();

  /// U výzvy na rekord: cvik (vestavěný podle slugu, jinak id).
  TextColumn get exerciseSlug => text().nullable()();
  IntColumn get exerciseId =>
      integer().nullable()
      .customConstraint('NULL REFERENCES exercises(id) ON DELETE SET NULL')();

  /// Cíl: odhad 1RM v kg / počet tréninků / ml vody za týden.
  RealColumn get targetValue => real()();

  /// Kdo výzvu poslal (jméno z odkazu nebo přítel).
  TextColumn get fromName => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deadline => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get dismissedAt => dateTime().nullable()();

  /// ID výzvy na serveru (sociální funkce), jinak null.
  TextColumn get remoteId => text().nullable().unique()();
}
