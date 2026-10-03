import '../enums.dart';

/// Vedlejší partie vestavěných cviků (podle slugu) pro model únavy svalů
/// (core/fatigue.dart). Hlavní partie je u cviku v databázi; tady jsou jen
/// partie, které cvik zapojuje výrazně navíc. Vlastní cviky vedlejší partie
/// nemají. Test hlídá, že je tu každý cvik ze seed_data.dart.
const exerciseSecondaryMuscles = <String, Set<MuscleGroup>>{
  // Hrudník
  'bench_press': {MuscleGroup.triceps, MuscleGroup.shoulders},
  'incline_dumbbell_press': {MuscleGroup.shoulders, MuscleGroup.triceps},
  'cable_fly': {MuscleGroup.shoulders},
  'push_up': {MuscleGroup.triceps, MuscleGroup.shoulders, MuscleGroup.core},
  'dumbbell_bench_press': {MuscleGroup.triceps, MuscleGroup.shoulders},
  'incline_bench_press': {MuscleGroup.shoulders, MuscleGroup.triceps},
  'chest_press_machine': {MuscleGroup.triceps, MuscleGroup.shoulders},
  'pec_deck': {MuscleGroup.shoulders},
  // Záda
  'deadlift': {MuscleGroup.legs, MuscleGroup.glutes, MuscleGroup.core},
  'barbell_row': {MuscleGroup.biceps, MuscleGroup.shoulders},
  'lat_pulldown': {MuscleGroup.biceps},
  'pull_up': {MuscleGroup.biceps},
  'seated_cable_row': {MuscleGroup.biceps},
  'one_arm_dumbbell_row': {MuscleGroup.biceps},
  'chin_up': {MuscleGroup.biceps},
  'weighted_pull_up': {MuscleGroup.biceps},
  // Ramena
  'overhead_press': {MuscleGroup.triceps, MuscleGroup.core},
  'lateral_raise': {},
  'pike_push_up': {MuscleGroup.triceps},
  'dumbbell_shoulder_press': {MuscleGroup.triceps},
  'rear_delt_fly': {MuscleGroup.back},
  'face_pull': {MuscleGroup.back},
  // Paže
  'dumbbell_curl': {},
  'barbell_curl': {},
  'hammer_curl': {},
  'cable_curl': {},
  'triceps_pushdown': {},
  'skull_crusher': {},
  'overhead_triceps_extension': {},
  'dips': {MuscleGroup.chest, MuscleGroup.shoulders},
  'weighted_dips': {MuscleGroup.chest, MuscleGroup.shoulders},
  'close_grip_bench_press': {MuscleGroup.chest, MuscleGroup.shoulders},
  // Nohy a hýždě
  'back_squat': {MuscleGroup.glutes, MuscleGroup.core},
  'front_squat': {MuscleGroup.glutes, MuscleGroup.core},
  'goblet_squat': {MuscleGroup.glutes, MuscleGroup.core},
  'leg_press': {MuscleGroup.glutes},
  'romanian_deadlift': {MuscleGroup.glutes, MuscleGroup.back},
  'bodyweight_squat': {MuscleGroup.glutes},
  'lunge': {MuscleGroup.glutes},
  'bulgarian_split_squat': {MuscleGroup.glutes},
  'leg_extension': {},
  'leg_curl': {},
  'calf_raise': {},
  'hip_thrust': {MuscleGroup.legs},
  'glute_bridge': {MuscleGroup.legs},
  // Střed těla
  'plank': {},
  'side_plank': {},
  'crunch': {},
  'cable_crunch': {},
  'hanging_leg_raise': {},
  'dead_bug': {},
  // Celé tělo (hlavní partie se rozkládá do všech partií)
  'mountain_climber': {},
  'jumping_jack': {},
  'burpee': {},
  'kettlebell_swing': {MuscleGroup.glutes, MuscleGroup.legs},
};

/// Vedlejší partie cviku (prázdné u vlastních a neznámých cviků).
Set<MuscleGroup> secondaryMusclesOf(String? slug) =>
    slug == null ? const {} : exerciseSecondaryMuscles[slug] ?? const {};
