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

  /// Název události v kalendáři (verze schématu 18), „{plan}“ se nahradí
  /// názvem plánu. null = výchozí podle jazyka („Fitko – {plan}“).
  TextColumn get calendarTitle => text().nullable()();

  /// Motiv vzhledu (verze schématu 20): klíč AppSkin (lib/ui/skins.dart),
  /// null = Klasik (výchozí).
  TextColumn get skin => text().nullable()();

  // Verze schématu 6 (funkce v2 a v3).
  /// Číst kalendář: volná okna, kolize, návrhy časů.
  BoolColumn get calendarReadEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Zápis tréninků a váhy do Health Connect / Apple Zdraví.
  BoolColumn get healthSyncEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Čtení regenerace a tepu z hodinek a prstenů přes Health Connect /
  /// Apple Zdraví (v24): spánek, HRV, klidový tep, tep během tréninku.
  BoolColumn get healthReadEnabled =>
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

  /// Vzhled (verze schématu 9): 0 = podle systému, 1 = světlý, 2 = tmavý.
  /// Viz AppTheme.themeModeOf.
  IntColumn get themeMode => integer().withDefault(const Constant(0))();

  /// Tón zpráv (verze schématu 9): 0 = přátelský, 1 = přísný trenér.
  /// Přísný tón se při nemoci, zranění, zotavování a velké únavě
  /// nepoužívá – viz core/coach_tone.dart.
  IntColumn get coachTone => integer().withDefault(const Constant(0))();

  /// Automatická progrese (verze schématu 10): 0 = vypnuto, 1 = navrhovat
  /// po tréninku (výchozí), 2 = použít automaticky (s možností vrátit).
  /// Viz core/auto_progression.dart.
  IntColumn get progressionMode => integer().withDefault(const Constant(1))();

  /// Premium zdarma pro první uživatele (verze schématu 11–21): do kdy
  /// platí, počítáno od prvního zobrazení hlášky. Od verze 22 se nepoužívá
  /// (půlrok běží od spuštění Premium) – nahradil ho [premiumEarlyAt].
  DateTimeColumn get premiumGiftUntil => dateTime().nullable()();

  /// První uživatel (verze schématu 22): kdy dostal slib „Premium na půl
  /// roku zdarma od spuštění Premium“. Nastaví se jen před spuštěním
  /// Premium; s účtem se ukládá i na server (users/{uid}/private/premium),
  /// takže přežije nový telefon. Konec dárku = spuštění Premium + 6 měsíců
  /// (kPremiumLaunchDate). Viz premium_gift.dart.
  DateTimeColumn get premiumEarlyAt => dateTime().nullable()();

  /// Pohlaví (verze schématu 14, volitelné): 0 = muž, 1 = žena,
  /// null = neuvedeno. Jen pro výchozí délku pauz (core/rest_time.dart).
  IntColumn get sex => integer().nullable()();

  /// Cíl tréninku (verze schématu 14, od 23 volba v úvodu a profilu):
  /// index TrainingFocus, výchozí 1 = svaly. Výchozí zaměření tréninků
  /// bez vlastního zaměření plánu (core/rest_time.dart, auto_progression).
  IntColumn get trainingFocus => integer().withDefault(const Constant(1))();

  /// Úroveň pokročilosti (verze schématu 25): index ExperienceLevel,
  /// výchozí 0 = začátečník. Viz core/experience_level.dart.
  IntColumn get experienceLevel => integer().withDefault(const Constant(0))();

  /// Od kdy platí současná úroveň (v25) – od tohoto dne se počítají
  /// tréninky pro návrh další úrovně. null = od prvního tréninku.
  DateTimeColumn get experienceSince => dateTime().nullable()();

  /// Kdy uživatel naposledy odmítl návrh změny úrovně (v25) – další
  /// návrh nejdřív za 30 dní.
  DateTimeColumn get experiencePromptAt => dateTime().nullable()();

  /// Kolikrát týdně chce trénovat (v25, úvod a profil) – doporučení
  /// hotových programů (data/seed/program_fit.dart).
  IntColumn get trainingDaysPerWeek =>
      integer().withDefault(const Constant(3))();

  /// Kolik minut má na trénink (v25) – delší tréninky z hotových programů
  /// se při přidání zkrátí.
  IntColumn get sessionMinutes => integer().withDefault(const Constant(60))();

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

  /// Moje poznámka ke cviku (verze schématu 17), např. nastavení stroje.
  /// Ukazuje se u cviku v každém tréninku; nikam se neposílá.
  TextColumn get note => text().nullable()();
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

  /// Plán od trenéra nebo ze sdíleného odkazu (verze schématu 16,
  /// docs/coach.md): „`coach:<id>`“ / „`shared:<id>`“, jinak null.
  TextColumn get remoteId => text().nullable()();

  /// Verze plánu od trenéra – při vyšší verzi se plán přepíše.
  IntColumn get remoteVersion => integer().nullable()();

  /// Kdo plán poslal (jméno trenéra / autora odkazu).
  TextColumn get remoteFrom => text().nullable()();

  /// Zaměření plánu (verze schématu 23): síla / svaly / výdrž. Trénink
  /// podle plánu ho převezme (pauzy, progrese); null = cíl z profilu.
  IntColumn get focus => intEnum<TrainingFocus>().nullable()();
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
  /// Pauza nastavená ručně; platí, jen když [restAuto] je false.
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();

  /// Pauza automaticky podle cviku, zaměření tréninku a pohlaví
  /// (verze schématu 14, core/rest_time.dart).
  BoolColumn get restAuto => boolean().withDefault(const Constant(true))();

  /// Supersérie (verze schématu 8): po sobě jdoucí cviky se stejnou
  /// hodnotou tvoří jednu supersérii (A1, A2…). null = samostatný cvik.
  IntColumn get supersetGroup => integer().nullable()();

  // Automatická progrese (verze schématu 10, core/auto_progression.dart).
  /// Rozsah opakování (u cviků na čas sekund); null = odvodit z cílových
  /// opakování. Při první automatické změně se uloží.
  IntColumn get repRangeMin => integer().nullable()();
  IntColumn get repRangeMax => integer().nullable()();

  /// Vlastní přírůstek váhy v kg; null = automaticky podle partie
  /// a vybavení.
  RealColumn get progressionIncrementKg => real().nullable()();

  /// Navrhovat po tréninku nové cíle tohoto cviku.
  BoolColumn get autoProgression =>
      boolean().withDefault(const Constant(true))();

  /// Poznámka ke cviku v tomto plánu (verze schématu 17): technika, tempo,
  /// úchop… U plánu od trenéra ji píše trenér (docs/coach.md).
  TextColumn get note => text().nullable()();
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

  /// Drop série (verze 8): navazuje bez pauzy na předchozí sérii s nižší
  /// vahou. Počítá se do objemu, ne do rekordů.
  BoolColumn get isDrop => boolean().withDefault(const Constant(false))();
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

  /// Pocit po tréninku (v8, volitelný): lehké / akorát / náročné.
  IntColumn get feeling => intEnum<WorkoutFeeling>().nullable()();

  /// Zaměření tréninku (v14): síla / svaly / kondice. Podle něj se
  /// počítají automatické pauzy. null = podle profilu.
  IntColumn get focus => intEnum<TrainingFocus>().nullable()();

  // Tep během tréninku (v24, core/readiness.dart): z hodinek (živě) nebo
  // z Health Connect / Apple Zdraví. null = bez dat.
  IntColumn get avgHeartRate => integer().nullable()();
  IntColumn get maxHeartRate => integer().nullable()();

  /// Sekundy v zónách tepu 0–5 („0,120,600,…“), viz HeartRateSummary.
  TextColumn get heartRateZones => text().nullable()();

  /// Energie podle tepu (Keytel 2005), když je známý věk, váha a pohlaví.
  IntColumn get heartRateKcal => integer().nullable()();

  /// Lehčí trénink kvůli slabší regeneraci (v24): o třetinu méně
  /// pracovních sérií, váhy −10 %, progrese po tréninku „drží“.
  BoolColumn get light => boolean().withDefault(const Constant(false))();
}

/// Regenerace za den z hodinek a prstenů (v24): spánek předchozí noci,
/// HRV a klidový tep z Health Connect / Apple Zdraví. Jen v telefonu,
/// do Health se nic nezapisuje (core/readiness.dart, docs/readiness.md).
@DataClassName('RecoveryDayEntry')
class RecoveryDays extends Table {
  /// Den (00:00 místního času) – den probuzení.
  DateTimeColumn get day => dateTime()();
  IntColumn get sleepMinutes => integer().nullable()();
  RealColumn get hrvMs => real().nullable()();
  RealColumn get restingHr => real().nullable()();

  @override
  Set<Column> get primaryKey => {day};
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

  /// Drop série (v8) – počítá se do objemu, ne do rekordů.
  BoolColumn get isDrop => boolean().withDefault(const Constant(false))();

  /// Supersérie v tréninku (v8): série cviků se stejnou hodnotou v jednom
  /// tréninku patří do jedné supersérie. Ukládá se u každé série, aby
  /// seskupení přežilo zavření aplikace i u tréninku bez plánu.
  IntColumn get supersetGroup => integer().nullable()();
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

/// Události v kalendáři telefonu pro tréninky s trenérem (verze 19,
/// modul coach). [sessionKey] = „`c:<id>`“ (jsem klient) nebo
/// „`t:<klient>/<id>`“ (jsem trenér), [version] = updatedAt pozvánky v ms –
/// při změně termínu se události vytvoří znovu.
@DataClassName('CoachCalendarEvent')
class CoachCalendarEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionKey => text()();
  TextColumn get eventId => text()();
  IntColumn get version => integer().withDefault(const Constant(0))();

  /// Začátek termínu (verze schématu 21). Proběhlé termíny se z kalendáře
  /// nemažou; null = starší záznam (bere se jako budoucí).
  DateTimeColumn get startAt => dateTime().nullable()();
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

  /// Cíl: nejtěžší série (recordValue, kg) / počet tréninků / ml vody za týden.
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

/// Získané odznaky (verze schématu 9). Katalog odznaků je v kódu
/// (lib/features/achievements/badges.dart), tady jen co a kdy uživatel
/// získal. [code] je stabilní kód odznaku („overload_streak_4“,
/// „mastery_chest“, „records_10“…), [value] dosažená hodnota (týdny /
/// počet rekordů), u mistrovství počet týdnů.
@DataClassName('Achievement')
class Achievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  DateTimeColumn get earnedAt => dateTime()();
  IntColumn get value => integer().nullable()();
}

/// Automatické změny cílů v plánu (verze schématu 10): návrhy po tréninku
/// i už použité změny. [oldJson] / [newJson] = stav cviku v plánu před
/// a po změně (série a rozsah, viz ProgressionSnapshot v
/// core/auto_progression.dart; [newJson] navíc obsahuje údaje pro
/// zobrazení). [applied] = změna je v plánu; nepoužitý návrh se po
/// „Ponechat“ nebo vrácení smaže. Druh „drží“ se ukládá rovnou jako
/// použitý (nic nemění).
@DataClassName('ProgressionEvent')
class ProgressionEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planExerciseId =>
      integer()
      .customConstraint('NOT NULL REFERENCES plan_exercises(id) ON DELETE CASCADE')();
  IntColumn get sessionId =>
      integer().nullable()
      .customConstraint('NULL REFERENCES workout_sessions(id) ON DELETE SET NULL')();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get kind => intEnum<ProgressionKind>()();
  TextColumn get oldJson => text()();
  TextColumn get newJson => text()();
  BoolColumn get applied => boolean().withDefault(const Constant(false))();
}
