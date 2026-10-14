// Automatické pauzy mezi sériemi (čistý Dart, testy: test/rest_time_test.dart).
//
// Délka pauzy se odvíjí od:
//  - náročnosti cviku (těžký vícekloubový cvik jako dřep potřebuje víc
//    odpočinku než izolovaný cvik nebo sklapovačky),
//  - zaměření tréninku (síla = dlouhé pauzy, svaly = střední,
//    kondice = krátké pauzy a vyšší tep),
//  - pohlaví, je-li v profilu: ženy se mezi sériemi v průměru zotavují
//    rychleji, proto mají pauzu o 15 % kratší.
// Pauza nastavená ručně u cviku v plánu má vždy přednost.

import '../data/enums.dart';

/// Náročnost cviku pro délku pauzy.
enum RestTier {
  /// Těžký vícekloubový cvik s velkou činkou (dřep, mrtvý tah, bench).
  heavy,

  /// Vícekloubový cvik s jednoručkami, na stroji nebo s vlastní vahou.
  compound,

  /// Izolovaný cvik (bicepsový zdvih, upažování, výpony).
  isolation,

  /// Střed těla a výdrže (plank, sklapovačky).
  core,

  /// Kondiční cvik (angličák, skákací panák).
  conditioning,
}

/// Pauza v sekundách: (síla, svaly, kondice).
const restTable = <RestTier, (int, int, int)>{
  RestTier.heavy: (180, 150, 75),
  RestTier.compound: (150, 90, 45),
  RestTier.isolation: (90, 60, 30),
  RestTier.core: (60, 45, 30),
  RestTier.conditioning: (45, 30, 15),
};

/// Ženy: pauza krát tento koeficient.
const femaleRestFactor = 0.85;

/// Zařazení vestavěných cviků (podle slugu). Test hlídá, že je tu každý
/// cvik ze seed_data.dart.
const exerciseRestTiers = <String, RestTier>{
  // Těžké vícekloubové
  'back_squat': RestTier.heavy,
  'front_squat': RestTier.heavy,
  'deadlift': RestTier.heavy,
  'romanian_deadlift': RestTier.heavy,
  'bench_press': RestTier.heavy,
  'incline_bench_press': RestTier.heavy,
  'overhead_press': RestTier.heavy,
  'barbell_row': RestTier.heavy,
  'leg_press': RestTier.heavy,
  'hip_thrust': RestTier.heavy,
  'good_morning': RestTier.heavy,
  'weighted_pull_up': RestTier.heavy,
  'weighted_dips': RestTier.heavy,
  // Vícekloubové
  'incline_dumbbell_press': RestTier.compound,
  'dumbbell_bench_press': RestTier.compound,
  'chest_press_machine': RestTier.compound,
  'close_grip_bench_press': RestTier.compound,
  'push_up': RestTier.compound,
  'pull_up': RestTier.compound,
  'chin_up': RestTier.compound,
  'lat_pulldown': RestTier.compound,
  'seated_cable_row': RestTier.compound,
  'one_arm_dumbbell_row': RestTier.compound,
  'dips': RestTier.compound,
  'dumbbell_shoulder_press': RestTier.compound,
  'pike_push_up': RestTier.compound,
  'lunge': RestTier.compound,
  'bulgarian_split_squat': RestTier.compound,
  'goblet_squat': RestTier.compound,
  'back_extension': RestTier.compound,
  'barbell_shrug': RestTier.compound,
  'kettlebell_swing': RestTier.compound,
  // Izolované
  'cable_fly': RestTier.isolation,
  'pec_deck': RestTier.isolation,
  'lateral_raise': RestTier.isolation,
  'rear_delt_fly': RestTier.isolation,
  'face_pull': RestTier.isolation,
  'dumbbell_curl': RestTier.isolation,
  'barbell_curl': RestTier.isolation,
  'hammer_curl': RestTier.isolation,
  'cable_curl': RestTier.isolation,
  'reverse_curl': RestTier.isolation,
  'triceps_pushdown': RestTier.isolation,
  'skull_crusher': RestTier.isolation,
  'overhead_triceps_extension': RestTier.isolation,
  'leg_extension': RestTier.isolation,
  'leg_curl': RestTier.isolation,
  'calf_raise': RestTier.isolation,
  'dumbbell_shrug': RestTier.isolation,
  'wrist_curl': RestTier.isolation,
  'bodyweight_squat': RestTier.isolation,
  'glute_bridge': RestTier.isolation,
  // Střed těla a výdrže
  'plank': RestTier.core,
  'side_plank': RestTier.core,
  'crunch': RestTier.core,
  'cable_crunch': RestTier.core,
  'hanging_leg_raise': RestTier.core,
  'dead_bug': RestTier.core,
  'superman': RestTier.core,
  'dead_hang': RestTier.core,
  // Kondiční
  'mountain_climber': RestTier.conditioning,
  'jumping_jack': RestTier.conditioning,
  'burpee': RestTier.conditioning,
  // Rozšíření knihovny (v15)
  'decline_bench_press': RestTier.heavy,
  'smith_bench_press': RestTier.compound,
  'dumbbell_fly': RestTier.isolation,
  'incline_dumbbell_fly': RestTier.isolation,
  'low_to_high_cable_fly': RestTier.isolation,
  'incline_chest_press_machine': RestTier.compound,
  'chest_dips': RestTier.compound,
  'incline_push_up': RestTier.compound,
  'decline_push_up': RestTier.compound,
  'dumbbell_floor_press': RestTier.compound,
  't_bar_row': RestTier.heavy,
  'pendlay_row': RestTier.heavy,
  'machine_row': RestTier.compound,
  'chest_supported_row': RestTier.compound,
  'close_grip_lat_pulldown': RestTier.compound,
  'straight_arm_pulldown': RestTier.isolation,
  'band_assisted_pull_up': RestTier.compound,
  'inverted_row': RestTier.compound,
  'neutral_grip_pull_up': RestTier.compound,
  'rack_pull': RestTier.heavy,
  'trap_bar_deadlift': RestTier.heavy,
  'single_arm_cable_row': RestTier.compound,
  'dumbbell_pullover': RestTier.isolation,
  'renegade_row': RestTier.compound,
  'arnold_press': RestTier.compound,
  'shoulder_press_machine': RestTier.compound,
  'push_press': RestTier.heavy,
  'cable_lateral_raise': RestTier.isolation,
  'machine_lateral_raise': RestTier.isolation,
  'front_raise': RestTier.isolation,
  'upright_row': RestTier.compound,
  'reverse_pec_deck': RestTier.isolation,
  'band_pull_apart': RestTier.isolation,
  'handstand_push_up': RestTier.compound,
  'landmine_press': RestTier.compound,
  'preacher_curl': RestTier.isolation,
  'concentration_curl': RestTier.isolation,
  'incline_dumbbell_curl': RestTier.isolation,
  'ez_bar_curl': RestTier.isolation,
  'rope_hammer_curl': RestTier.isolation,
  'machine_biceps_curl': RestTier.isolation,
  'band_curl': RestTier.isolation,
  'rope_pushdown': RestTier.isolation,
  'overhead_cable_extension': RestTier.isolation,
  'triceps_kickback': RestTier.isolation,
  'bench_dips': RestTier.compound,
  'machine_triceps_dip': RestTier.compound,
  'single_arm_pushdown': RestTier.isolation,
  'diamond_push_up': RestTier.compound,
  'reverse_wrist_curl': RestTier.isolation,
  'hack_squat': RestTier.heavy,
  'smith_squat': RestTier.heavy,
  'walking_lunge': RestTier.compound,
  'reverse_lunge': RestTier.compound,
  'step_up': RestTier.compound,
  'split_squat': RestTier.compound,
  'sumo_squat': RestTier.compound,
  'pistol_squat': RestTier.compound,
  'single_leg_press': RestTier.compound,
  'hip_adduction_machine': RestTier.isolation,
  'wall_sit': RestTier.core,
  'jump_squat': RestTier.conditioning,
  'box_jump': RestTier.conditioning,
  'seated_leg_curl': RestTier.isolation,
  'nordic_curl': RestTier.compound,
  'single_leg_rdl': RestTier.compound,
  'dumbbell_romanian_deadlift': RestTier.compound,
  'stiff_leg_deadlift': RestTier.heavy,
  'stability_ball_leg_curl': RestTier.isolation,
  'sumo_deadlift': RestTier.heavy,
  'cable_glute_kickback': RestTier.isolation,
  'hip_abduction_machine': RestTier.isolation,
  'machine_hip_thrust': RestTier.compound,
  'single_leg_glute_bridge': RestTier.isolation,
  'donkey_kick': RestTier.isolation,
  'fire_hydrant': RestTier.isolation,
  'banded_lateral_walk': RestTier.isolation,
  'cable_pull_through': RestTier.compound,
  'seated_calf_raise': RestTier.isolation,
  'single_leg_calf_raise': RestTier.isolation,
  'leg_press_calf_raise': RestTier.isolation,
  'sit_up': RestTier.core,
  'decline_sit_up': RestTier.core,
  'bicycle_crunch': RestTier.core,
  'reverse_crunch': RestTier.core,
  'lying_leg_raise': RestTier.core,
  'captains_chair_knee_raise': RestTier.core,
  'ab_wheel_rollout': RestTier.core,
  'russian_twist': RestTier.core,
  'v_up': RestTier.core,
  'hollow_hold': RestTier.core,
  'pallof_press': RestTier.core,
  'cable_woodchopper': RestTier.core,
  'plank_shoulder_tap': RestTier.core,
  'bird_dog': RestTier.core,
  'power_clean': RestTier.heavy,
  'thruster': RestTier.compound,
  'turkish_get_up': RestTier.compound,
  'bear_crawl': RestTier.conditioning,
  'high_knees': RestTier.conditioning,
  'jump_rope': RestTier.conditioning,
  'rowing_machine': RestTier.conditioning,
  'stationary_bike': RestTier.conditioning,
  'treadmill_run': RestTier.conditioning,
  'elliptical': RestTier.conditioning,
  'stair_climber': RestTier.conditioning,
  'air_bike': RestTier.conditioning,
};

const _bigGroups = {
  MuscleGroup.chest,
  MuscleGroup.back,
  MuscleGroup.legs,
  MuscleGroup.quads,
  MuscleGroup.hamstrings,
  MuscleGroup.glutes,
  MuscleGroup.lowerBack,
};

/// Náročnost cviku: vestavěný podle tabulky, vlastní odhadem z partie,
/// vybavení a typu.
RestTier restTierOf({
  String? slug,
  required MuscleGroup group,
  required Equipment equipment,
  required ExerciseType type,
}) {
  final known = slug == null ? null : exerciseRestTiers[slug];
  if (known != null) return known;
  if (group == MuscleGroup.fullBody) {
    return type == ExerciseType.duration
        ? RestTier.conditioning
        : RestTier.compound;
  }
  if (type == ExerciseType.duration || group == MuscleGroup.core) {
    return RestTier.core;
  }
  if (_bigGroups.contains(group)) {
    return equipment == Equipment.barbell ? RestTier.heavy : RestTier.compound;
  }
  if (group == MuscleGroup.shoulders) {
    return switch (equipment) {
      Equipment.barbell => RestTier.heavy,
      Equipment.dumbbell || Equipment.machine => RestTier.compound,
      _ => RestTier.isolation,
    };
  }
  // Biceps, triceps, předloktí, lýtka, trapézy.
  return RestTier.isolation;
}

/// Doporučená pauza v sekundách (zaokrouhlená na 5 s).
int recommendedRestSeconds(
  RestTier tier,
  TrainingFocus focus, {
  Sex? sex,
}) {
  final row = restTable[tier]!;
  final base = switch (focus) {
    TrainingFocus.strength => row.$1,
    TrainingFocus.muscle => row.$2,
    TrainingFocus.conditioning => row.$3,
  };
  final seconds = sex == Sex.female ? base * femaleRestFactor : base.toDouble();
  final rounded = (seconds / 5).round() * 5;
  return rounded < 10 ? 10 : rounded;
}

/// Zaměření z hodnoty v databázi (výchozí = svaly).
TrainingFocus trainingFocusOf(int? value) =>
    value != null && value >= 0 && value < TrainingFocus.values.length
        ? TrainingFocus.values[value]
        : TrainingFocus.muscle;

/// Pohlaví z hodnoty v databázi (null = neuvedeno).
Sex? sexOf(int? value) =>
    value != null && value >= 0 && value < Sex.values.length
        ? Sex.values[value]
        : null;
