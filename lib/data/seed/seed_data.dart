import '../enums.dart';

/// Vestavěný cvik pro počáteční naplnění databáze.
class SeedExercise {
  const SeedExercise(
    this.slug,
    this.nameEn,
    this.nameCs,
    this.muscleGroup,
    this.equipment,
    this.type,
    this.met,
  );

  final String slug;
  final String nameEn;
  final String nameCs;
  final MuscleGroup muscleGroup;
  final Equipment equipment;
  final ExerciseType type;

  /// Orientační MET hodnota pro odhad kalorií.
  final double met;
}

/// Vestavěná 5minutová domácí rutina (plán B).
class SeedHomeRoutine {
  const SeedHomeRoutine(
    this.slug,
    this.nameEn,
    this.nameCs,
    this.target,
    this.exerciseSlugs, {
    this.workSeconds = 45,
    this.restSeconds = 15,
  });

  final String slug;
  final String nameEn;
  final String nameCs;
  final MuscleGroup target;
  final List<String> exerciseSlugs;
  final int workSeconds;
  final int restSeconds;
}

// Návody jsou v seed_instructions.dart. Jde o stručné body správné
// techniky; před vydáním je vhodná odborná kontrola a doplnění animací.
const seedExercises = <SeedExercise>[
  // Hrudník
  SeedExercise('bench_press', 'Bench Press', 'Bench press',
      MuscleGroup.chest, Equipment.barbell, ExerciseType.weightReps, 6.0),
  SeedExercise('incline_dumbbell_press', 'Incline Dumbbell Press',
      'Tlaky s jednoručkami na šikmé lavici', MuscleGroup.chest,
      Equipment.dumbbell, ExerciseType.weightReps, 6.0),
  SeedExercise('cable_fly', 'Cable Fly', 'Rozpažování na kladce',
      MuscleGroup.chest, Equipment.cable, ExerciseType.weightReps, 5.0),
  SeedExercise('push_up', 'Push-up', 'Klik', MuscleGroup.chest,
      Equipment.bodyweight, ExerciseType.bodyweightReps, 3.8),
  // Záda
  SeedExercise('deadlift', 'Deadlift', 'Mrtvý tah', MuscleGroup.back,
      Equipment.barbell, ExerciseType.weightReps, 6.0),
  SeedExercise('barbell_row', 'Barbell Row',
      'Přítahy velké činky v předklonu', MuscleGroup.back, Equipment.barbell,
      ExerciseType.weightReps, 6.0),
  SeedExercise('lat_pulldown', 'Lat Pulldown', 'Stahování horní kladky',
      MuscleGroup.back, Equipment.cable, ExerciseType.weightReps, 5.0),
  SeedExercise('pull_up', 'Pull-up', 'Shyb', MuscleGroup.back,
      Equipment.bodyweight, ExerciseType.bodyweightReps, 6.0),
  // Ramena
  SeedExercise('overhead_press', 'Overhead Press', 'Tlaky nad hlavu',
      MuscleGroup.shoulders, Equipment.barbell, ExerciseType.weightReps, 6.0),
  SeedExercise('lateral_raise', 'Lateral Raise', 'Upažování s jednoručkami',
      MuscleGroup.shoulders, Equipment.dumbbell, ExerciseType.weightReps, 4.0),
  SeedExercise('pike_push_up', 'Pike Push-up', 'Klik v pozici V',
      MuscleGroup.shoulders, Equipment.bodyweight,
      ExerciseType.bodyweightReps, 3.8),
  // Paže
  SeedExercise('dumbbell_curl', 'Dumbbell Curl',
      'Bicepsový zdvih s jednoručkami', MuscleGroup.biceps,
      Equipment.dumbbell, ExerciseType.weightReps, 4.0),
  SeedExercise('triceps_pushdown', 'Triceps Pushdown',
      'Stahování kladky na triceps', MuscleGroup.triceps, Equipment.cable,
      ExerciseType.weightReps, 4.0),
  SeedExercise('dips', 'Dips', 'Kliky na bradlech', MuscleGroup.triceps,
      Equipment.bodyweight, ExerciseType.bodyweightReps, 5.0),
  // Nohy a hýždě
  SeedExercise('back_squat', 'Back Squat', 'Dřep s činkou na zádech',
      MuscleGroup.legs, Equipment.barbell, ExerciseType.weightReps, 6.0),
  SeedExercise('leg_press', 'Leg Press', 'Legpress', MuscleGroup.legs,
      Equipment.machine, ExerciseType.weightReps, 5.0),
  SeedExercise('romanian_deadlift', 'Romanian Deadlift',
      'Rumunský mrtvý tah', MuscleGroup.legs, Equipment.barbell,
      ExerciseType.weightReps, 6.0),
  SeedExercise('bodyweight_squat', 'Bodyweight Squat', 'Dřep bez zátěže',
      MuscleGroup.legs, Equipment.bodyweight, ExerciseType.bodyweightReps,
      5.0),
  SeedExercise('lunge', 'Lunge', 'Výpad', MuscleGroup.legs,
      Equipment.bodyweight, ExerciseType.bodyweightReps, 4.0),
  SeedExercise('hip_thrust', 'Hip Thrust', 'Hip thrust', MuscleGroup.glutes,
      Equipment.barbell, ExerciseType.weightReps, 5.0),
  SeedExercise('glute_bridge', 'Glute Bridge', 'Hýžďový most',
      MuscleGroup.glutes, Equipment.bodyweight, ExerciseType.bodyweightReps,
      3.5),
  // Střed těla a celé tělo
  SeedExercise('plank', 'Plank', 'Plank', MuscleGroup.core,
      Equipment.bodyweight, ExerciseType.duration, 3.8),
  SeedExercise('crunch', 'Crunch', 'Sklapovačky', MuscleGroup.core,
      Equipment.bodyweight, ExerciseType.bodyweightReps, 3.8),
  SeedExercise('mountain_climber', 'Mountain Climber', 'Horolezec',
      MuscleGroup.fullBody, Equipment.bodyweight, ExerciseType.duration, 8.0),
  SeedExercise('jumping_jack', 'Jumping Jack', 'Skákací panák',
      MuscleGroup.fullBody, Equipment.bodyweight, ExerciseType.duration, 8.0),

  // --- Rozšíření knihovny (verze schématu 4) ---
  // Hrudník
  SeedExercise('dumbbell_bench_press', 'Dumbbell Bench Press',
      'Tlaky s jednoručkami na rovné lavici', MuscleGroup.chest,
      Equipment.dumbbell, ExerciseType.weightReps, 6.0),
  SeedExercise('incline_bench_press', 'Incline Bench Press',
      'Bench press na šikmé lavici', MuscleGroup.chest, Equipment.barbell,
      ExerciseType.weightReps, 6.0),
  SeedExercise('chest_press_machine', 'Chest Press Machine',
      'Tlaky na hrudním stroji', MuscleGroup.chest, Equipment.machine,
      ExerciseType.weightReps, 5.0),
  SeedExercise('pec_deck', 'Pec Deck', 'Butterfly na stroji',
      MuscleGroup.chest, Equipment.machine, ExerciseType.weightReps, 4.0),
  // Záda
  SeedExercise('seated_cable_row', 'Seated Cable Row',
      'Přítahy spodní kladky vsedě', MuscleGroup.back, Equipment.cable,
      ExerciseType.weightReps, 5.0),
  SeedExercise('one_arm_dumbbell_row', 'One-Arm Dumbbell Row',
      'Přítahy jednoručky v opoře', MuscleGroup.back, Equipment.dumbbell,
      ExerciseType.weightReps, 5.0),
  SeedExercise('chin_up', 'Chin-up', 'Shyb podhmatem', MuscleGroup.back,
      Equipment.bodyweight, ExerciseType.bodyweightReps, 6.0),
  // Ramena
  SeedExercise('dumbbell_shoulder_press', 'Dumbbell Shoulder Press',
      'Tlaky s jednoručkami nad hlavu', MuscleGroup.shoulders,
      Equipment.dumbbell, ExerciseType.weightReps, 5.0),
  SeedExercise('rear_delt_fly', 'Rear Delt Fly',
      'Zapažování v předklonu', MuscleGroup.shoulders, Equipment.dumbbell,
      ExerciseType.weightReps, 4.0),
  SeedExercise('face_pull', 'Face Pull', 'Přítahy lana k obličeji',
      MuscleGroup.shoulders, Equipment.cable, ExerciseType.weightReps, 4.0),
  // Biceps
  SeedExercise('barbell_curl', 'Barbell Curl', 'Bicepsový zdvih s velkou činkou',
      MuscleGroup.biceps, Equipment.barbell, ExerciseType.weightReps, 4.0),
  SeedExercise('hammer_curl', 'Hammer Curl', 'Kladivové zdvihy',
      MuscleGroup.biceps, Equipment.dumbbell, ExerciseType.weightReps, 4.0),
  SeedExercise('cable_curl', 'Cable Curl', 'Bicepsový zdvih na kladce',
      MuscleGroup.biceps, Equipment.cable, ExerciseType.weightReps, 4.0),
  // Triceps
  SeedExercise('skull_crusher', 'Skull Crusher', 'Francouzský tlak vleže',
      MuscleGroup.triceps, Equipment.barbell, ExerciseType.weightReps, 4.0),
  SeedExercise('overhead_triceps_extension', 'Overhead Triceps Extension',
      'Tricepsové tlaky za hlavou', MuscleGroup.triceps, Equipment.dumbbell,
      ExerciseType.weightReps, 4.0),
  SeedExercise('close_grip_bench_press', 'Close-Grip Bench Press',
      'Bench press úzkým úchopem', MuscleGroup.triceps, Equipment.barbell,
      ExerciseType.weightReps, 6.0),
  // Nohy
  SeedExercise('front_squat', 'Front Squat', 'Čelní dřep', MuscleGroup.legs,
      Equipment.barbell, ExerciseType.weightReps, 6.0),
  SeedExercise('goblet_squat', 'Goblet Squat', 'Goblet dřep',
      MuscleGroup.legs, Equipment.kettlebell, ExerciseType.weightReps, 5.0),
  SeedExercise('bulgarian_split_squat', 'Bulgarian Split Squat',
      'Bulharský dřep', MuscleGroup.legs, Equipment.dumbbell,
      ExerciseType.weightReps, 5.0),
  SeedExercise('leg_extension', 'Leg Extension', 'Předkopávání na stroji',
      MuscleGroup.legs, Equipment.machine, ExerciseType.weightReps, 4.0),
  SeedExercise('leg_curl', 'Leg Curl', 'Zakopávání na stroji',
      MuscleGroup.legs, Equipment.machine, ExerciseType.weightReps, 4.0),
  SeedExercise('calf_raise', 'Calf Raise', 'Výpony na lýtka',
      MuscleGroup.legs, Equipment.machine, ExerciseType.weightReps, 3.5),
  // Střed těla
  SeedExercise('hanging_leg_raise', 'Hanging Leg Raise', 'Zvedání nohou ve visu',
      MuscleGroup.core, Equipment.bodyweight, ExerciseType.bodyweightReps, 4.0),
  SeedExercise('cable_crunch', 'Cable Crunch', 'Zkracovačky na kladce',
      MuscleGroup.core, Equipment.cable, ExerciseType.weightReps, 4.0),
  SeedExercise('dead_bug', 'Dead Bug', 'Dead bug', MuscleGroup.core,
      Equipment.bodyweight, ExerciseType.bodyweightReps, 3.0),
  SeedExercise('side_plank', 'Side Plank', 'Boční plank', MuscleGroup.core,
      Equipment.bodyweight, ExerciseType.duration, 3.5),
  // Celé tělo
  SeedExercise('burpee', 'Burpee', 'Angličák', MuscleGroup.fullBody,
      Equipment.bodyweight, ExerciseType.bodyweightReps, 8.0),
  SeedExercise('kettlebell_swing', 'Kettlebell Swing', 'Švihy s kettlebellem',
      MuscleGroup.fullBody, Equipment.kettlebell, ExerciseType.weightReps, 8.0),
];

/// Každá rutina má 5 cviků × (45 s práce + 15 s pauza) = 5 minut.
const seedHomeRoutines = <SeedHomeRoutine>[
  SeedHomeRoutine('home_upper', 'Upper Body in 5 Minutes',
      'Horní polovina za 5 minut', MuscleGroup.chest,
      ['push_up', 'pike_push_up', 'plank', 'push_up', 'plank']),
  SeedHomeRoutine('home_lower', 'Lower Body in 5 Minutes',
      'Nohy za 5 minut', MuscleGroup.legs,
      ['bodyweight_squat', 'lunge', 'glute_bridge', 'bodyweight_squat',
        'lunge']),
  SeedHomeRoutine('home_full', 'Full Body in 5 Minutes',
      'Celé tělo za 5 minut', MuscleGroup.fullBody,
      ['jumping_jack', 'bodyweight_squat', 'push_up', 'mountain_climber',
        'plank']),
];
