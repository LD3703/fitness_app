/// Hotové tréninkové programy pro začátečníky. Po přidání se z nich
/// vytvoří běžné (upravitelné) plány uživatele.
library;

typedef TemplateSet = ({
  int reps,
  double? weightKg,
  bool isWarmup,
  bool isDrop,
});

/// Pauza se u cviků z programu počítá automaticky (core/rest_time.dart).
class TemplateItem {
  const TemplateItem(this.slug, this.sets);

  final String slug;
  final List<TemplateSet> sets;
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
  });

  final String slug;
  final String nameEn;
  final String nameCs;
  final String descriptionEn;
  final String descriptionCs;
  final List<TemplatePlan> plans;
}

const _mon = 1, _tue = 2, _wed = 4, _thu = 8, _fri = 16;

/// [count] stejných pracovních sérií, volitelně s jednou rozcvičkou navíc.
List<TemplateSet> _sets(int count, int reps, {bool warmup = false}) => [
      if (warmup) (reps: 12, weightKg: null, isWarmup: true, isDrop: false),
      for (var i = 0; i < count; i++)
        (reps: reps, weightKg: null, isWarmup: false, isDrop: false),
    ];

final templatePrograms = <TemplateProgram>[
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
        TemplateItem('back_squat', _sets(3, 8, warmup: true)),
        TemplateItem('bench_press', _sets(3, 8, warmup: true)),
        TemplateItem('barbell_row', _sets(3, 8)),
        TemplateItem('overhead_press', _sets(2, 10)),
        TemplateItem('plank', _sets(3, 30)),
      ]),
      TemplatePlan('Full body B', 'Celé tělo B', _wed, [
        TemplateItem('deadlift', _sets(3, 5, warmup: true)),
        TemplateItem('incline_dumbbell_press', _sets(3, 10)),
        TemplateItem('lat_pulldown', _sets(3, 10)),
        TemplateItem('lunge', _sets(2, 10)),
        TemplateItem('cable_crunch', _sets(3, 12)),
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
        TemplateItem('bench_press', _sets(4, 6, warmup: true)),
        TemplateItem('barbell_row', _sets(4, 6)),
        TemplateItem('dumbbell_shoulder_press', _sets(3, 10)),
        TemplateItem('lat_pulldown', _sets(3, 10)),
        TemplateItem('dumbbell_curl', _sets(2, 12)),
        TemplateItem('triceps_pushdown', _sets(2, 12)),
      ]),
      TemplatePlan('Lower body', 'Dolní polovina', _tue | _fri, [
        TemplateItem('back_squat', _sets(4, 6, warmup: true)),
        TemplateItem('romanian_deadlift', _sets(3, 8)),
        TemplateItem('leg_press', _sets(3, 10)),
        TemplateItem('leg_curl', _sets(3, 12)),
        TemplateItem('calf_raise', _sets(3, 15)),
        TemplateItem('hanging_leg_raise', _sets(3, 10)),
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
        TemplateItem('bench_press', _sets(4, 8, warmup: true)),
        TemplateItem('dumbbell_shoulder_press', _sets(3, 10)),
        TemplateItem('incline_dumbbell_press', _sets(3, 10)),
        TemplateItem('lateral_raise', _sets(3, 12)),
        TemplateItem('triceps_pushdown', _sets(3, 12)),
      ]),
      TemplatePlan('Pull', 'Pull (přítahy)', _wed, [
        TemplateItem('deadlift', _sets(3, 5, warmup: true)),
        TemplateItem('pull_up', _sets(3, 8)),
        TemplateItem('seated_cable_row', _sets(3, 10)),
        TemplateItem('face_pull', _sets(3, 15)),
        TemplateItem('barbell_curl', _sets(3, 10)),
      ]),
      TemplatePlan('Legs', 'Nohy', _fri, [
        TemplateItem('back_squat', _sets(4, 8, warmup: true)),
        TemplateItem('romanian_deadlift', _sets(3, 10)),
        TemplateItem('leg_extension', _sets(3, 12)),
        TemplateItem('leg_curl', _sets(3, 12)),
        TemplateItem('calf_raise', _sets(4, 15)),
      ]),
    ],
  ),
];
