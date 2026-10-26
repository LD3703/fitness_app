/// Hotové tréninkové programy. Po přidání se z nich vytvoří běžné
/// (upravitelné) plány uživatele.
///
/// Většina programů jde přidat ve třech variantách podle cíle (síla /
/// svaly / výdrž, [TrainingFocus]): cvik má v programu roli
/// ([TemplateRole]) a podle ní a cíle se nastaví série, opakování
/// a rozsah opakování pro automatickou progresi ([templateSetsFor],
/// [templateRangeFor]). Hodnoty u cviku platí pro „svaly“. Programy
/// s pevným cílem ([TemplateProgram.goal], např. 5×5 nebo kruhový trénink)
/// mají hodnoty přesně dané.
///
/// Každý program je sestavený pro jednu úroveň pokročilosti
/// ([TemplateProgram.level], [ExperienceLevel]); pro jinou úroveň se upraví
/// počet sérií ([levelAdjustedSets]). Obměny ([TemplateProgram.variationOf])
/// mají stejnou stavbu s jinými cviky – na střídání po 6–8 týdnech.
/// Zdroje a pravidla: docs/programs.md.
library;

import '../enums.dart';

typedef TemplateSet = ({
  int reps,
  double? weightKg,
  bool isWarmup,
  bool isDrop,
});

/// Rozsah opakování pro automatickou progresi (u cviků na čas sekund).
typedef TemplateRange = ({int min, int max});

/// Role cviku v programu.
enum TemplateRole {
  /// Hlavní cvik s velkou činkou (dřep, bench, tlaky, přítahy).
  main,

  /// Mrtvý tah a podobné – na výdrž méně opakování než ostatní hlavní cviky.
  hinge,

  /// Vícekloubový doplňkový cvik (jednoručky, stroj, kladka).
  secondary,

  /// Izolovaný cvik (bicepsy, upažování, zakopávání…).
  accessory,

  /// Cvik s vlastní vahou, střed těla nebo kardio (opakování / sekundy):
  /// na sílu beze změny, na výdrž o polovinu víc.
  bodyweight,
}

/// Pauza se u cviků z programu počítá automaticky (core/rest_time.dart).
class TemplateItem {
  const TemplateItem(
    this.slug,
    this.role,
    this.sets,
    this.reps, {
    this.warmup = false,
    this.range,
    this.superset,
  });

  final String slug;
  final TemplateRole role;

  /// Pracovní série a opakování (u cviků na čas sekundy) pro „svaly“,
  /// u programu s pevným cílem pro jeho cíl.
  final int sets;
  final int reps;

  /// Jedna rozcvičková série před pracovními.
  final bool warmup;

  /// Rozsah pro progresi u programu s pevným cílem (null = odvodí se).
  final TemplateRange? range;

  /// Supersérie: po sobě jdoucí cviky se stejným číslem (kruhový trénink).
  final int? superset;
}

class TemplatePlan {
  const TemplatePlan(this.nameEn, this.nameCs, this.weekdaysMask, this.items);

  final String nameEn;
  final String nameCs;

  /// Bit 0 = pondělí … bit 6 = neděle.
  final int weekdaysMask;
  final List<TemplateItem> items;
}

class TemplateProgram {
  const TemplateProgram({
    required this.slug,
    required this.nameEn,
    required this.nameCs,
    required this.descriptionEn,
    required this.descriptionCs,
    required this.plans,
    required this.level,
    this.goal,
    this.variationOf,
  });

  final String slug;
  final String nameEn;
  final String nameCs;
  final String descriptionEn;
  final String descriptionCs;
  final List<TemplatePlan> plans;

  /// Pevný cíl programu (null = vybere se při přidání).
  final TrainingFocus? goal;

  /// Úroveň, pro kterou je program sestavený.
  final ExperienceLevel level;

  /// Obměna programu s tímto slugem (stejná stavba, jiné cviky).
  final String? variationOf;
}

/// Počet pracovních sérií cviku s rolí [role] pro uživatele o [delta]
/// úrovní nad (kladné) / pod (záporné) úrovní programu. Začátečník má
/// u každého cviku o sérii míň (nejméně 2), pokročilý o sérii víc
/// u vícekloubových cviků (nejvýš 5) – podle ACSM 1–3 série pro
/// začátečníky, 3–6 pro pokročilé. Cvik s jedinou sérií (mrtvý tah 1×5,
/// veslování 5 min) se nemění.
int levelAdjustedSets(int sets, TemplateRole role, int delta) {
  if (sets <= 1 || delta == 0) return sets;
  if (delta < 0) return (sets + delta).clamp(2, sets);
  if (role == TemplateRole.main || role == TemplateRole.secondary) {
    return (sets + delta).clamp(sets, 5);
  }
  return sets;
}

/// Série, opakování a rozsah jedné role pro cíl.
typedef _Prescription = ({int sets, int reps, int max});

/// Síla: méně opakování, víc sérií u hlavních cviků, úzký rozsah (váha
/// roste často). Výdrž: hodně opakování, široký rozsah (nejdřív se
/// přidávají opakování, váha až potom).
const _strength = <TemplateRole, _Prescription>{
  TemplateRole.main: (sets: 4, reps: 5, max: 6),
  TemplateRole.hinge: (sets: 3, reps: 5, max: 6),
  TemplateRole.secondary: (sets: 3, reps: 6, max: 8),
  TemplateRole.accessory: (sets: 3, reps: 8, max: 10),
};

const _endurance = <TemplateRole, _Prescription>{
  TemplateRole.main: (sets: 3, reps: 12, max: 16),
  TemplateRole.hinge: (sets: 3, reps: 10, max: 12),
  TemplateRole.secondary: (sets: 3, reps: 15, max: 20),
  TemplateRole.accessory: (sets: 3, reps: 15, max: 20),
};

/// Rozcvičková série (lehká váha, 12 opakování).
const TemplateSet _warmupSet =
    (reps: 12, weightKg: null, isWarmup: true, isDrop: false);

/// Opakování / sekundy cviku s vlastní vahou na výdrž: +50 %, sekundy
/// zaokrouhlené na 5.
int _enduranceBodyweight(int reps, {required bool seconds}) {
  final v = reps * 1.5;
  return seconds ? ((v / 5).round() * 5) : v.round();
}

/// Cíl, se kterým se program přidá: pevný cíl programu, jinak [goal].
TrainingFocus programGoal(TemplateProgram program, TrainingFocus goal) =>
    program.goal ?? goal;

/// Cílové série cviku z programu pro cíl [goal]. [isDuration] = cvik na
/// čas (u role bodyweight se pak zaokrouhluje na 5 s).
///
/// [level] = úroveň uživatele; u programu bez pevného cíle se podle ní
/// upraví počet sérií ([levelAdjustedSets]).
List<TemplateSet> templateSetsFor(
  TemplateItem item,
  TrainingFocus goal, {
  TemplateProgram? program,
  bool isDuration = false,
  ExperienceLevel? level,
}) {
  var sets = item.sets;
  var reps = item.reps;
  final fixed = program?.goal != null;
  if (!fixed && goal != TrainingFocus.muscle) {
    if (item.role == TemplateRole.bodyweight) {
      if (goal == TrainingFocus.conditioning) {
        reps = _enduranceBodyweight(reps, seconds: isDuration);
      }
    } else {
      final p =
          (goal == TrainingFocus.strength ? _strength : _endurance)[item.role]!;
      sets = p.sets;
      reps = p.reps;
    }
  }
  if (!fixed && program != null && level != null) {
    sets = levelAdjustedSets(sets, item.role, level.index - program.level.index);
  }
  return [
    if (item.warmup) _warmupSet,
    for (var i = 0; i < sets; i++)
      (reps: reps, weightKg: null, isWarmup: false, isDrop: false),
  ];
}

/// Rozsah opakování pro progresi (null = odvodí se z cílových opakování,
/// core/auto_progression.dart).
TemplateRange? templateRangeFor(
  TemplateItem item,
  TrainingFocus goal, {
  TemplateProgram? program,
}) {
  if (program?.goal != null) return item.range;
  if (goal == TrainingFocus.muscle || item.role == TemplateRole.bodyweight) {
    return null;
  }
  final p =
      (goal == TrainingFocus.strength ? _strength : _endurance)[item.role]!;
  return (min: p.reps, max: p.max);
}

const _mon = 1, _tue = 2, _wed = 4, _thu = 8, _fri = 16, _sat = 32;

const _main = TemplateRole.main;
const _hinge = TemplateRole.hinge;
const _sec = TemplateRole.secondary;
const _acc = TemplateRole.accessory;
const _bw = TemplateRole.bodyweight;

const _beginner = ExperienceLevel.beginner;
const _intermediate = ExperienceLevel.intermediate;
const _advanced = ExperienceLevel.advanced;

// Tréninky Push / Pull / Nohy A a B – sdílí je program „ppl“, jeho obměna
// a „PPL 6× týdně“ (stejný název = stejný trénink).
const _pushA = [
  TemplateItem('bench_press', _main, 4, 8, warmup: true),
  TemplateItem('dumbbell_shoulder_press', _sec, 3, 10),
  TemplateItem('incline_dumbbell_press', _sec, 3, 10),
  TemplateItem('lateral_raise', _acc, 3, 12),
  TemplateItem('triceps_pushdown', _acc, 3, 12),
];
const _pullA = [
  TemplateItem('deadlift', _hinge, 3, 5, warmup: true),
  TemplateItem('pull_up', _bw, 3, 8),
  TemplateItem('seated_cable_row', _sec, 3, 10),
  TemplateItem('face_pull', _acc, 3, 15),
  TemplateItem('barbell_curl', _acc, 3, 10),
];
const _legsA = [
  TemplateItem('back_squat', _main, 4, 8, warmup: true),
  TemplateItem('romanian_deadlift', _hinge, 3, 10),
  TemplateItem('leg_extension', _acc, 3, 12),
  TemplateItem('leg_curl', _acc, 3, 12),
  TemplateItem('calf_raise', _acc, 4, 15),
];
const _pushB = [
  TemplateItem('overhead_press', _main, 4, 6, warmup: true),
  TemplateItem('incline_dumbbell_press', _sec, 3, 10),
  TemplateItem('chest_dips', _bw, 3, 10),
  TemplateItem('cable_fly', _acc, 3, 12),
  TemplateItem('cable_lateral_raise', _acc, 3, 15),
  TemplateItem('skull_crusher', _acc, 3, 10),
];
const _pullB = [
  TemplateItem('barbell_row', _main, 4, 8, warmup: true),
  TemplateItem('chin_up', _bw, 3, 8),
  TemplateItem('single_arm_cable_row', _sec, 3, 12),
  TemplateItem('rear_delt_fly', _acc, 3, 15),
  TemplateItem('hammer_curl', _acc, 3, 12),
  TemplateItem('dumbbell_shrug', _acc, 3, 12),
];
const _legsB = [
  TemplateItem('hack_squat', _main, 4, 8, warmup: true),
  TemplateItem('stiff_leg_deadlift', _hinge, 3, 10),
  TemplateItem('walking_lunge', _sec, 3, 12),
  TemplateItem('seated_leg_curl', _acc, 3, 12),
  TemplateItem('single_leg_calf_raise', _bw, 3, 12),
  TemplateItem('hanging_leg_raise', _bw, 3, 10),
];

/// Pořadí je důležité: po spuštění Premium jsou zdarma první programy
/// (kFreeTemplatePrograms v premium_rules.dart).
const templatePrograms = <TemplateProgram>[
  TemplateProgram(
    slug: 'full_body',
    level: _beginner,
    nameEn: 'Full body (beginner)',
    nameCs: 'Celé tělo (začátečník)',
    descriptionEn:
        '3× per week, alternating workouts A and B. Ideal for the first months.',
    descriptionCs:
        '3× týdně, střídání tréninků A a B. Ideální na první měsíce.',
    plans: [
      TemplatePlan('Full body A', 'Celé tělo A', _mon | _fri, [
        TemplateItem('back_squat', _main, 3, 8, warmup: true),
        TemplateItem('bench_press', _main, 3, 8, warmup: true),
        TemplateItem('barbell_row', _main, 3, 8),
        TemplateItem('overhead_press', _sec, 2, 10),
        TemplateItem('plank', _bw, 3, 30),
      ]),
      TemplatePlan('Full body B', 'Celé tělo B', _wed, [
        TemplateItem('deadlift', _hinge, 3, 5, warmup: true),
        TemplateItem('incline_dumbbell_press', _sec, 3, 10),
        TemplateItem('lat_pulldown', _sec, 3, 10),
        TemplateItem('lunge', _bw, 2, 10),
        TemplateItem('cable_crunch', _acc, 3, 12),
      ]),
    ],
  ),
  TemplateProgram(
    slug: 'upper_lower',
    level: _intermediate,
    nameEn: 'Upper / Lower',
    nameCs: 'Horní / dolní polovina',
    descriptionEn: '4× per week: upper body Mon + Thu, lower body Tue + Fri.',
    descriptionCs: '4× týdně: horní polovina Po + Čt, dolní Út + Pá.',
    plans: [
      TemplatePlan('Upper body', 'Horní polovina', _mon | _thu, [
        TemplateItem('bench_press', _main, 4, 6, warmup: true),
        TemplateItem('barbell_row', _main, 4, 6),
        TemplateItem('dumbbell_shoulder_press', _sec, 3, 10),
        TemplateItem('lat_pulldown', _sec, 3, 10),
        TemplateItem('dumbbell_curl', _acc, 2, 12),
        TemplateItem('triceps_pushdown', _acc, 2, 12),
      ]),
      TemplatePlan('Lower body', 'Dolní polovina', _tue | _fri, [
        TemplateItem('back_squat', _main, 4, 6, warmup: true),
        TemplateItem('romanian_deadlift', _hinge, 3, 8),
        TemplateItem('leg_press', _sec, 3, 10),
        TemplateItem('leg_curl', _acc, 3, 12),
        TemplateItem('calf_raise', _acc, 3, 15),
        TemplateItem('hanging_leg_raise', _bw, 3, 10),
      ]),
    ],
  ),
  TemplateProgram(
    slug: 'ppl',
    level: _intermediate,
    nameEn: 'Push / Pull / Legs',
    nameCs: 'Push / Pull / Nohy',
    descriptionEn: '3× per week: push Mon, pull Wed, legs Fri.',
    descriptionCs: '3× týdně: tlaky Po, přítahy St, nohy Pá.',
    plans: [
      TemplatePlan('Push', 'Push (tlaky)', _mon, _pushA),
      TemplatePlan('Pull', 'Pull (přítahy)', _wed, _pullA),
      TemplatePlan('Legs', 'Nohy', _fri, _legsA),
    ],
  ),
  TemplateProgram(
    slug: 'full_body_2x',
    level: _beginner,
    nameEn: 'Full body 2× per week',
    nameCs: 'Celé tělo 2× týdně',
    descriptionEn:
        'For busy weeks: 2 workouts of about an hour, Mon + Thu. Every muscle twice a week.',
    descriptionCs:
        'Na nabité týdny: 2 tréninky zhruba na hodinu, Po + Čt. Každá partie 2× týdně.',
    plans: [
      TemplatePlan('Full body 2× A', 'Celé tělo 2× A', _mon, [
        TemplateItem('back_squat', _main, 3, 8, warmup: true),
        TemplateItem('bench_press', _main, 3, 8, warmup: true),
        TemplateItem('lat_pulldown', _sec, 3, 10),
        TemplateItem('romanian_deadlift', _hinge, 3, 10),
        TemplateItem('dumbbell_shoulder_press', _sec, 2, 12),
        TemplateItem('plank', _bw, 3, 30),
      ]),
      TemplatePlan('Full body 2× B', 'Celé tělo 2× B', _thu, [
        TemplateItem('deadlift', _hinge, 3, 5, warmup: true),
        TemplateItem('incline_dumbbell_press', _sec, 3, 10),
        TemplateItem('seated_cable_row', _sec, 3, 10),
        TemplateItem('leg_press', _sec, 3, 12),
        TemplateItem('lateral_raise', _acc, 3, 12),
        TemplateItem('hanging_leg_raise', _bw, 3, 10),
      ]),
    ],
  ),
  TemplateProgram(
    slug: 'dumbbell_home',
    level: _beginner,
    nameEn: 'Dumbbells at home',
    nameCs: 'Jednoručky doma',
    descriptionEn:
        '3× per week with a pair of dumbbells and a mat, alternating A and B. No gym needed.',
    descriptionCs:
        '3× týdně s párem jednoruček a podložkou, střídání A a B. Bez posilovny.',
    plans: [
      TemplatePlan('Dumbbells A', 'Jednoručky A', _mon | _fri, [
        TemplateItem('goblet_squat', _main, 3, 10),
        TemplateItem('dumbbell_floor_press', _main, 3, 10),
        TemplateItem('one_arm_dumbbell_row', _sec, 3, 10),
        TemplateItem('dumbbell_shoulder_press', _sec, 3, 10),
        TemplateItem('dumbbell_curl', _acc, 2, 12),
        TemplateItem('plank', _bw, 3, 30),
      ]),
      TemplatePlan('Dumbbells B', 'Jednoručky B', _wed, [
        TemplateItem('dumbbell_romanian_deadlift', _hinge, 3, 10),
        TemplateItem('reverse_lunge', _sec, 3, 10),
        TemplateItem('push_up', _bw, 3, 12),
        TemplateItem('renegade_row', _sec, 3, 8),
        TemplateItem('lateral_raise', _acc, 3, 12),
        TemplateItem('dead_bug', _bw, 3, 10),
      ]),
    ],
  ),
  TemplateProgram(
    slug: 'strength_5x5',
    level: _beginner,
    nameEn: 'Strength 5×5',
    nameCs: 'Síla 5×5',
    descriptionEn:
        '3× per week, alternating A and B: 5 sets of 5 on the big lifts. When all sets hit 5 reps, the weight goes up.',
    descriptionCs:
        '3× týdně, střídání A a B: 5 sérií po 5 u velkých cviků. Když dáš všechny série po 5, váha jde nahoru.',
    goal: TrainingFocus.strength,
    plans: [
      TemplatePlan('5×5 A', '5×5 A', _mon | _fri, [
        TemplateItem('back_squat', _main, 5, 5,
            warmup: true, range: (min: 5, max: 5)),
        TemplateItem('bench_press', _main, 5, 5,
            warmup: true, range: (min: 5, max: 5)),
        TemplateItem('barbell_row', _main, 5, 5, range: (min: 5, max: 5)),
      ]),
      TemplatePlan('5×5 B', '5×5 B', _wed, [
        TemplateItem('back_squat', _main, 5, 5,
            warmup: true, range: (min: 5, max: 5)),
        TemplateItem('overhead_press', _main, 5, 5,
            warmup: true, range: (min: 5, max: 5)),
        TemplateItem('deadlift', _hinge, 1, 5,
            warmup: true, range: (min: 5, max: 5)),
      ]),
    ],
  ),
  TemplateProgram(
    slug: 'circuit',
    level: _beginner,
    nameEn: 'Circuit training (endurance)',
    nameCs: 'Kruhový trénink (výdrž)',
    descriptionEn:
        '3× per week, alternating A and B: exercises in circuits back to back, short rests, lots of reps. For stamina and fitness.',
    descriptionCs:
        '3× týdně, střídání A a B: cviky v kruhu za sebou, krátké pauzy, hodně opakování. Na výdrž a kondici.',
    goal: TrainingFocus.conditioning,
    plans: [
      TemplatePlan('Circuit A', 'Kruh A', _mon | _fri, [
        TemplateItem('goblet_squat', _main, 3, 15,
            range: (min: 15, max: 20), superset: 1),
        TemplateItem('push_up', _bw, 3, 12, superset: 1),
        TemplateItem('one_arm_dumbbell_row', _sec, 3, 15,
            range: (min: 15, max: 20), superset: 1),
        TemplateItem('dumbbell_romanian_deadlift', _hinge, 3, 15,
            range: (min: 15, max: 20), superset: 2),
        TemplateItem('dumbbell_shoulder_press', _sec, 3, 15,
            range: (min: 15, max: 20), superset: 2),
        TemplateItem('mountain_climber', _bw, 3, 30, superset: 2),
        TemplateItem('plank', _bw, 3, 45),
      ]),
      TemplatePlan('Circuit B', 'Kruh B', _wed, [
        TemplateItem('kettlebell_swing', _main, 3, 20,
            range: (min: 20, max: 25), superset: 1),
        TemplateItem('reverse_lunge', _sec, 3, 12,
            range: (min: 12, max: 16), superset: 1),
        TemplateItem('dumbbell_bench_press', _sec, 3, 15,
            range: (min: 15, max: 20), superset: 1),
        TemplateItem('lat_pulldown', _sec, 3, 15,
            range: (min: 15, max: 20), superset: 2),
        TemplateItem('step_up', _sec, 3, 12,
            range: (min: 12, max: 16), superset: 2),
        TemplateItem('jumping_jack', _bw, 3, 45, superset: 2),
        TemplateItem('rowing_machine', _bw, 1, 300),
      ]),
    ],
  ),
  // ----- Začátečník -------------------------------------------------------
  TemplateProgram(
    slug: 'full_body_variation',
    level: _beginner,
    variationOf: 'full_body',
    nameEn: 'Full body – variation',
    nameCs: 'Celé tělo – obměna',
    descriptionEn:
        '3× per week, alternating C and D. Same structure as Full body (beginner) with different exercises – switch every 6–8 weeks.',
    descriptionCs:
        '3× týdně, střídání C a D. Stejná stavba jako Celé tělo (začátečník), jiné cviky – střídej po 6–8 týdnech.',
    plans: [
      TemplatePlan('Full body C', 'Celé tělo C', _mon | _fri, [
        TemplateItem('goblet_squat', _main, 3, 10, warmup: true),
        TemplateItem('dumbbell_bench_press', _main, 3, 10),
        TemplateItem('seated_cable_row', _sec, 3, 10),
        TemplateItem('dumbbell_romanian_deadlift', _hinge, 3, 10),
        TemplateItem('lateral_raise', _acc, 2, 12),
        TemplateItem('dead_bug', _bw, 3, 10),
      ]),
      TemplatePlan('Full body D', 'Celé tělo D', _wed, [
        TemplateItem('trap_bar_deadlift', _hinge, 3, 6, warmup: true),
        TemplateItem('chest_press_machine', _sec, 3, 10),
        TemplateItem('band_assisted_pull_up', _bw, 3, 6),
        TemplateItem('leg_press', _sec, 3, 12),
        TemplateItem('hammer_curl', _acc, 2, 12),
        TemplateItem('side_plank', _bw, 2, 30),
      ]),
    ],
  ),
  TemplateProgram(
    slug: 'bodyweight_home',
    level: _beginner,
    nameEn: 'Bodyweight at home',
    nameCs: 'Vlastní váha doma',
    descriptionEn:
        '3× per week, alternating A and B, no equipment – just a mat (and a sturdy table for rows). Great for a start or for travel.',
    descriptionCs:
        '3× týdně, střídání A a B, bez vybavení – stačí podložka (a pevný stůl na přítahy). Na začátek i na cesty.',
    plans: [
      TemplatePlan('Bodyweight A', 'Vlastní váha A', _mon | _fri, [
        TemplateItem('bodyweight_squat', _bw, 3, 15),
        TemplateItem('push_up', _bw, 3, 10),
        TemplateItem('glute_bridge', _bw, 3, 15),
        TemplateItem('superman', _bw, 3, 12),
        TemplateItem('plank', _bw, 3, 30),
        TemplateItem('jumping_jack', _bw, 2, 45),
      ]),
      TemplatePlan('Bodyweight B', 'Vlastní váha B', _wed, [
        TemplateItem('lunge', _bw, 3, 10),
        TemplateItem('pike_push_up', _bw, 3, 8),
        TemplateItem('inverted_row', _bw, 3, 8),
        TemplateItem('single_leg_glute_bridge', _bw, 3, 10),
        TemplateItem('bird_dog', _bw, 3, 10),
        TemplateItem('mountain_climber', _bw, 3, 30),
      ]),
    ],
  ),
  TemplateProgram(
    slug: 'machines',
    level: _beginner,
    nameEn: 'Machines (beginner)',
    nameCs: 'Stroje (začátečník)',
    descriptionEn:
        '3× per week, alternating A and B, on gym machines: easy to learn, safe without a spotter. A good first step before free weights.',
    descriptionCs:
        '3× týdně, střídání A a B, na strojích v posilovně: snadno se naučíš, bezpečné i bez jištění. Dobrý první krok před volnými vahami.',
    plans: [
      TemplatePlan('Machines A', 'Stroje A', _mon | _fri, [
        TemplateItem('leg_press', _sec, 3, 10, warmup: true),
        TemplateItem('chest_press_machine', _sec, 3, 10),
        TemplateItem('lat_pulldown', _sec, 3, 10),
        TemplateItem('seated_leg_curl', _acc, 3, 12),
        TemplateItem('shoulder_press_machine', _sec, 2, 10),
        TemplateItem('cable_crunch', _acc, 3, 12),
      ]),
      TemplatePlan('Machines B', 'Stroje B', _wed, [
        TemplateItem('hack_squat', _sec, 3, 10, warmup: true),
        TemplateItem('machine_row', _sec, 3, 10),
        TemplateItem('incline_chest_press_machine', _sec, 3, 10),
        TemplateItem('machine_hip_thrust', _sec, 3, 10),
        TemplateItem('reverse_pec_deck', _acc, 2, 15),
        TemplateItem('leg_press_calf_raise', _acc, 3, 15),
        TemplateItem('plank', _bw, 3, 30),
      ]),
    ],
  ),
  // ----- Mírně pokročilý --------------------------------------------------
  TemplateProgram(
    slug: 'upper_lower_variation',
    level: _intermediate,
    variationOf: 'upper_lower',
    nameEn: 'Upper / Lower – variation',
    nameCs: 'Horní / dolní – obměna',
    descriptionEn:
        '4× per week like Upper / Lower, with different exercises (incline bench, front squat, hip thrust). Switch every 6–8 weeks.',
    descriptionCs:
        '4× týdně jako Horní / dolní polovina, s jinými cviky (šikmý bench, přední dřep, hip thrust). Střídej po 6–8 týdnech.',
    plans: [
      TemplatePlan('Upper body B', 'Horní polovina B', _mon | _thu, [
        TemplateItem('incline_bench_press', _main, 4, 8, warmup: true),
        TemplateItem('chest_supported_row', _sec, 3, 10),
        TemplateItem('arnold_press', _sec, 3, 10),
        TemplateItem('neutral_grip_pull_up', _bw, 3, 8),
        TemplateItem('cable_lateral_raise', _acc, 3, 15),
        TemplateItem('ez_bar_curl', _acc, 2, 12),
        TemplateItem('overhead_cable_extension', _acc, 2, 12),
      ]),
      TemplatePlan('Lower body B', 'Dolní polovina B', _tue | _fri, [
        TemplateItem('front_squat', _main, 4, 6, warmup: true),
        TemplateItem('hip_thrust', _main, 3, 10),
        TemplateItem('bulgarian_split_squat', _sec, 3, 10),
        TemplateItem('seated_leg_curl', _acc, 3, 12),
        TemplateItem('seated_calf_raise', _acc, 3, 15),
        TemplateItem('ab_wheel_rollout', _bw, 3, 10),
      ]),
    ],
  ),
  TemplateProgram(
    slug: 'ppl_variation',
    level: _intermediate,
    variationOf: 'ppl',
    nameEn: 'Push / Pull / Legs – variation',
    nameCs: 'Push / Pull / Nohy – obměna',
    descriptionEn:
        '3× per week like Push / Pull / Legs, with different exercises (overhead press first, rows, hack squat). Switch every 6–8 weeks.',
    descriptionCs:
        '3× týdně jako Push / Pull / Nohy, s jinými cviky (nejdřív tlaky nad hlavu, přítahy v předklonu, hack dřep). Střídej po 6–8 týdnech.',
    plans: [
      TemplatePlan('Push B', 'Push B (tlaky)', _mon, _pushB),
      TemplatePlan('Pull B', 'Pull B (přítahy)', _wed, _pullB),
      TemplatePlan('Legs B', 'Nohy B', _fri, _legsB),
    ],
  ),
  TemplateProgram(
    slug: 'strength_dup',
    level: _intermediate,
    goal: TrainingFocus.strength,
    nameEn: 'Strength – weekly waves',
    nameCs: 'Síla – týdenní vlny',
    descriptionEn:
        '3× per week: heavy day (sets of 3), volume day (6–8 reps) and medium day (sets of 5). Changing the load within the week keeps strength growing after the first year.',
    descriptionCs:
        '3× týdně: těžký den (série po 3), objemový den (6–8 opakování) a střední den (série po 5). Střídání zátěže v týdnu udrží růst síly i po prvním roce.',
    plans: [
      TemplatePlan('Strength: heavy day', 'Síla: těžký den', _mon, [
        TemplateItem('back_squat', _main, 5, 3,
            warmup: true, range: (min: 3, max: 4)),
        TemplateItem('bench_press', _main, 5, 3,
            warmup: true, range: (min: 3, max: 4)),
        TemplateItem('barbell_row', _main, 4, 5, range: (min: 5, max: 6)),
        TemplateItem('plank', _bw, 3, 30),
      ]),
      TemplatePlan('Strength: volume day', 'Síla: objemový den', _wed, [
        TemplateItem('back_squat', _main, 3, 8,
            warmup: true, range: (min: 8, max: 10)),
        TemplateItem('overhead_press', _main, 4, 6,
            warmup: true, range: (min: 6, max: 8)),
        TemplateItem('romanian_deadlift', _hinge, 3, 8,
            range: (min: 8, max: 10)),
        TemplateItem('pull_up', _bw, 3, 8),
      ]),
      TemplatePlan('Strength: medium day', 'Síla: střední den', _fri, [
        TemplateItem('deadlift', _hinge, 3, 5,
            warmup: true, range: (min: 5, max: 6)),
        TemplateItem('bench_press', _main, 4, 5,
            warmup: true, range: (min: 5, max: 6)),
        TemplateItem('front_squat', _main, 3, 5, range: (min: 5, max: 6)),
        TemplateItem('chin_up', _bw, 3, 6),
      ]),
    ],
  ),
  TemplateProgram(
    slug: 'conditioning_intervals',
    level: _intermediate,
    goal: TrainingFocus.conditioning,
    nameEn: 'Conditioning – intervals',
    nameCs: 'Kondice – intervaly',
    descriptionEn:
        '3× per week, alternating A and B: pairs of a strength and a cardio exercise back to back, finished with a steady cardio block. For fitness, stamina and fat loss.',
    descriptionCs:
        '3× týdně, střídání A a B: dvojice silového a kardio cviku hned po sobě, na konci souvislé kardio. Na kondici, výdrž a hubnutí.',
    plans: [
      TemplatePlan('Intervals A', 'Intervaly A', _mon | _fri, [
        TemplateItem('thruster', _main, 4, 12,
            warmup: true, range: (min: 12, max: 15), superset: 1),
        TemplateItem('burpee', _bw, 4, 10, superset: 1),
        TemplateItem('kettlebell_swing', _main, 4, 20,
            range: (min: 20, max: 25), superset: 2),
        TemplateItem('air_bike', _bw, 4, 30, superset: 2),
        TemplateItem('plank_shoulder_tap', _bw, 3, 20),
        TemplateItem('rowing_machine', _bw, 1, 600),
      ]),
      TemplatePlan('Intervals B', 'Intervaly B', _wed, [
        TemplateItem('walking_lunge', _sec, 4, 12,
            range: (min: 12, max: 16), superset: 1),
        TemplateItem('push_up', _bw, 4, 15, superset: 1),
        TemplateItem('renegade_row', _sec, 3, 10,
            range: (min: 10, max: 12), superset: 2),
        TemplateItem('box_jump', _bw, 3, 10, superset: 2),
        TemplateItem('jump_rope', _bw, 3, 60),
        TemplateItem('stationary_bike', _bw, 1, 600),
      ]),
    ],
  ),
  // ----- Pokročilý --------------------------------------------------------
  TemplateProgram(
    slug: 'phul',
    level: _advanced,
    goal: TrainingFocus.muscle,
    nameEn: 'Power + hypertrophy (PHUL)',
    nameCs: 'Síla + objem (PHUL)',
    descriptionEn:
        '4× per week: heavy upper and lower days for strength (Mon, Tue), higher-rep days for muscle (Thu, Fri). About 12–16 sets per muscle per week.',
    descriptionCs:
        '4× týdně: těžké dny horní a dolní poloviny na sílu (Po, Út), dny s více opakováními na svaly (Čt, Pá). Zhruba 12–16 sérií na partii týdně.',
    plans: [
      TemplatePlan('Upper power', 'Horní – síla', _mon, [
        TemplateItem('bench_press', _main, 4, 5,
            warmup: true, range: (min: 5, max: 6)),
        TemplateItem('barbell_row', _main, 4, 5, range: (min: 5, max: 6)),
        TemplateItem('overhead_press', _main, 3, 6, range: (min: 6, max: 8)),
        TemplateItem('weighted_pull_up', _sec, 3, 6, range: (min: 6, max: 8)),
        TemplateItem('barbell_curl', _acc, 2, 8, range: (min: 8, max: 10)),
        TemplateItem('skull_crusher', _acc, 2, 8, range: (min: 8, max: 10)),
      ]),
      TemplatePlan('Lower power', 'Dolní – síla', _tue, [
        TemplateItem('back_squat', _main, 4, 5,
            warmup: true, range: (min: 5, max: 6)),
        TemplateItem('deadlift', _hinge, 3, 5,
            warmup: true, range: (min: 5, max: 6)),
        TemplateItem('leg_press', _sec, 3, 10, range: (min: 10, max: 12)),
        TemplateItem('leg_curl', _acc, 3, 8, range: (min: 8, max: 10)),
        TemplateItem('calf_raise', _acc, 4, 10, range: (min: 10, max: 12)),
      ]),
      TemplatePlan('Upper hypertrophy', 'Horní – objem', _thu, [
        TemplateItem('incline_dumbbell_press', _sec, 4, 10,
            warmup: true, range: (min: 10, max: 12)),
        TemplateItem('seated_cable_row', _sec, 4, 10,
            range: (min: 10, max: 12)),
        TemplateItem('pec_deck', _acc, 3, 12, range: (min: 12, max: 15)),
        TemplateItem('lat_pulldown', _sec, 3, 12, range: (min: 12, max: 15)),
        TemplateItem('cable_lateral_raise', _acc, 4, 15,
            range: (min: 15, max: 20)),
        TemplateItem('incline_dumbbell_curl', _acc, 3, 12,
            range: (min: 12, max: 15)),
        TemplateItem('rope_pushdown', _acc, 3, 12, range: (min: 12, max: 15)),
      ]),
      TemplatePlan('Lower hypertrophy', 'Dolní – objem', _fri, [
        TemplateItem('front_squat', _main, 4, 8,
            warmup: true, range: (min: 8, max: 10)),
        TemplateItem('hip_thrust', _main, 3, 10, range: (min: 10, max: 12)),
        TemplateItem('bulgarian_split_squat', _sec, 3, 10,
            range: (min: 10, max: 12)),
        TemplateItem('seated_leg_curl', _acc, 3, 12,
            range: (min: 12, max: 15)),
        TemplateItem('leg_extension', _acc, 3, 15, range: (min: 15, max: 20)),
        TemplateItem('seated_calf_raise', _acc, 4, 15,
            range: (min: 15, max: 20)),
        TemplateItem('cable_crunch', _acc, 3, 15, range: (min: 15, max: 20)),
      ]),
    ],
  ),
  TemplateProgram(
    slug: 'strength_advanced',
    level: _advanced,
    goal: TrainingFocus.strength,
    nameEn: 'Strength – 4 days (advanced)',
    nameCs: 'Síla – 4 dny (pokročilý)',
    descriptionEn:
        '4× per week, one big lift per day (squat, bench, deadlift, overhead press): heavy sets of 3, a related variation and accessories for weak points.',
    descriptionCs:
        '4× týdně, každý den jeden velký cvik (dřep, bench, mrtvý tah, tlak nad hlavu): těžké série po 3, příbuzná varianta a doplňky na slabá místa.',
    plans: [
      TemplatePlan('Strength: squat', 'Síla: dřep', _mon, [
        TemplateItem('back_squat', _main, 5, 3,
            warmup: true, range: (min: 3, max: 4)),
        TemplateItem('front_squat', _main, 3, 5, range: (min: 5, max: 6)),
        TemplateItem('good_morning', _hinge, 3, 8, range: (min: 8, max: 10)),
        TemplateItem('hanging_leg_raise', _bw, 3, 10),
      ]),
      TemplatePlan('Strength: bench', 'Síla: bench', _tue, [
        TemplateItem('bench_press', _main, 5, 3,
            warmup: true, range: (min: 3, max: 4)),
        TemplateItem('close_grip_bench_press', _main, 3, 6,
            range: (min: 6, max: 8)),
        TemplateItem('pendlay_row', _main, 4, 6, range: (min: 6, max: 8)),
        TemplateItem('face_pull', _acc, 3, 15, range: (min: 15, max: 20)),
      ]),
      TemplatePlan('Strength: deadlift', 'Síla: mrtvý tah', _thu, [
        TemplateItem('deadlift', _hinge, 4, 3,
            warmup: true, range: (min: 3, max: 4)),
        TemplateItem('romanian_deadlift', _hinge, 3, 6,
            range: (min: 6, max: 8)),
        TemplateItem('bulgarian_split_squat', _sec, 3, 8,
            range: (min: 8, max: 10)),
        TemplateItem('weighted_pull_up', _sec, 4, 5, range: (min: 5, max: 6)),
        TemplateItem('ab_wheel_rollout', _bw, 3, 10),
      ]),
      TemplatePlan('Strength: overhead press', 'Síla: tlak nad hlavu', _fri, [
        TemplateItem('overhead_press', _main, 5, 3,
            warmup: true, range: (min: 3, max: 4)),
        TemplateItem('incline_bench_press', _main, 4, 6,
            range: (min: 6, max: 8)),
        TemplateItem('weighted_dips', _sec, 3, 8, range: (min: 8, max: 10)),
        TemplateItem('chest_supported_row', _sec, 4, 8,
            range: (min: 8, max: 10)),
        TemplateItem('barbell_curl', _acc, 3, 8, range: (min: 8, max: 10)),
      ]),
    ],
  ),
  TemplateProgram(
    slug: 'ppl_6x',
    level: _advanced,
    nameEn: 'Push / Pull / Legs 6× per week',
    nameCs: 'Push / Pull / Nohy 6× týdně',
    descriptionEn:
        'Mon–Sat: Push, Pull, Legs, then Push B, Pull B, Legs B. Every muscle twice a week with high volume – for experienced lifters with good recovery.',
    descriptionCs:
        'Po–So: Push, Pull, Nohy, pak Push B, Pull B, Nohy B. Každá partie 2× týdně s vysokým objemem – pro zkušené s dobrou regenerací.',
    plans: [
      TemplatePlan('Push', 'Push (tlaky)', _mon, _pushA),
      TemplatePlan('Pull', 'Pull (přítahy)', _tue, _pullA),
      TemplatePlan('Legs', 'Nohy', _wed, _legsA),
      TemplatePlan('Push B', 'Push B (tlaky)', _thu, _pushB),
      TemplatePlan('Pull B', 'Pull B (přítahy)', _fri, _pullB),
      TemplatePlan('Legs B', 'Nohy B', _sat, _legsB),
    ],
  ),
];
