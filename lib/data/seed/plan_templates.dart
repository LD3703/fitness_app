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
    this.goal,
  });

  final String slug;
  final String nameEn;
  final String nameCs;
  final String descriptionEn;
  final String descriptionCs;
  final List<TemplatePlan> plans;

  /// Pevný cíl programu (null = vybere se při přidání).
  final TrainingFocus? goal;
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
List<TemplateSet> templateSetsFor(
  TemplateItem item,
  TrainingFocus goal, {
  TemplateProgram? program,
  bool isDuration = false,
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

const _mon = 1, _tue = 2, _wed = 4, _thu = 8, _fri = 16;

const _main = TemplateRole.main;
const _hinge = TemplateRole.hinge;
const _sec = TemplateRole.secondary;
const _acc = TemplateRole.accessory;
const _bw = TemplateRole.bodyweight;

/// Pořadí je důležité: po spuštění Premium jsou zdarma první programy
/// (kFreeTemplatePrograms v premium_rules.dart).
const templatePrograms = <TemplateProgram>[
  TemplateProgram(
    slug: 'full_body',
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
    nameEn: 'Push / Pull / Legs',
    nameCs: 'Push / Pull / Nohy',
    descriptionEn: '3× per week: push Mon, pull Wed, legs Fri.',
    descriptionCs: '3× týdně: tlaky Po, přítahy St, nohy Pá.',
    plans: [
      TemplatePlan('Push', 'Push (tlaky)', _mon, [
        TemplateItem('bench_press', _main, 4, 8, warmup: true),
        TemplateItem('dumbbell_shoulder_press', _sec, 3, 10),
        TemplateItem('incline_dumbbell_press', _sec, 3, 10),
        TemplateItem('lateral_raise', _acc, 3, 12),
        TemplateItem('triceps_pushdown', _acc, 3, 12),
      ]),
      TemplatePlan('Pull', 'Pull (přítahy)', _wed, [
        TemplateItem('deadlift', _hinge, 3, 5, warmup: true),
        TemplateItem('pull_up', _bw, 3, 8),
        TemplateItem('seated_cable_row', _sec, 3, 10),
        TemplateItem('face_pull', _acc, 3, 15),
        TemplateItem('barbell_curl', _acc, 3, 10),
      ]),
      TemplatePlan('Legs', 'Nohy', _fri, [
        TemplateItem('back_squat', _main, 4, 8, warmup: true),
        TemplateItem('romanian_deadlift', _hinge, 3, 10),
        TemplateItem('leg_extension', _acc, 3, 12),
        TemplateItem('leg_curl', _acc, 3, 12),
        TemplateItem('calf_raise', _acc, 4, 15),
      ]),
    ],
  ),
  TemplateProgram(
    slug: 'full_body_2x',
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
];
