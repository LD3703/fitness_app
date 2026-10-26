/// Jak hotový program sedí do týdne uživatele: kolikrát týdně se trénuje,
/// odhad délky tréninku, zkrácení na zvolený čas a pořadí doporučení.
///
/// Délka tréninku se odhaduje z pracovních sérií, pauz podle náročnosti
/// cviku a zaměření (core/rest_time.dart) a času na přípravu cviku.
/// Delší trénink se při přidání programu zkrátí: nejdřív ubývají série
/// izolovaných cviků a cviků s vlastní vahou, pak vícekloubových doplňků,
/// hlavní cviky nejpozději (nejméně 2 série) – a když to nestačí, vypadnou
/// poslední doplňkové cviky (nejméně 3 cviky zůstanou). Viz docs/programs.md.
library;

import '../../core/rest_time.dart';
import '../enums.dart';
import 'plan_templates.dart';
import 'seed_data.dart';

/// Cvik programu s výslednými sériemi (po úpravě podle cíle a úrovně).
typedef PlannedItem = ({TemplateItem item, List<TemplateSet> sets});

/// Volby délky tréninku (minuty) a počtu tréninků týdně.
const kSessionMinuteOptions = [30, 45, 60, 75, 90];
const kDaysPerWeekOptions = [2, 3, 4, 5, 6];

/// Obecné rozcvičení na začátku tréninku.
const _warmupSeconds = 5 * 60;

/// Příprava cviku (přechod, nastavení stroje / činky); v supersérii půl.
const _setupSeconds = 60;

/// Jedno opakování (tempo zhruba 1 s nahoru, 2 s dolů).
const _secondsPerRep = 3;

/// Přechod mezi cviky supersérie a pauza po rozcvičkové sérii.
const _supersetTransition = 15;
const _warmupSetRest = 60;

final _seedBySlug = {for (final e in seedExercises) e.slug: e};

bool _isDuration(String slug) =>
    _seedBySlug[slug]?.type == ExerciseType.duration;

/// Cviky plánu se sériemi pro cíl a úroveň.
List<PlannedItem> plannedItems(
  TemplatePlan plan,
  TrainingFocus goal, {
  TemplateProgram? program,
  ExperienceLevel? level,
}) =>
    [
      for (final item in plan.items)
        (
          item: item,
          sets: templateSetsFor(item, goal,
              program: program,
              level: level,
              isDuration: _isDuration(item.slug)),
        ),
    ];

/// Odhad délky tréninku v sekundách. [focus] = zaměření (pauzy).
int estimateSeconds(List<PlannedItem> items, TrainingFocus focus) {
  var total = _warmupSeconds;
  for (var i = 0; i < items.length; i++) {
    final (:item, :sets) = items[i];
    final group = item.superset;
    final lastInGroup = group == null ||
        i == items.length - 1 ||
        items[i + 1].item.superset != group;
    final rest = lastInGroup
        ? recommendedRestSeconds(
            exerciseRestTiers[item.slug] ?? RestTier.compound, focus)
        : _supersetTransition;
    total += group == null ? _setupSeconds : _setupSeconds ~/ 2;
    for (final s in sets) {
      final work = _isDuration(item.slug)
          ? s.reps
          : (s.reps * _secondsPerRep).clamp(15, 120);
      total += work + (s.isWarmup ? _warmupSetRest : rest);
    }
  }
  return total;
}

/// Odhad v minutách zaokrouhlený na 5.
int roundMinutes(int seconds) => ((seconds / 60) / 5).round() * 5;

/// Pořadí, ve kterém se při zkracování berou série.
const _trimOrder = [
  TemplateRole.accessory,
  TemplateRole.bodyweight,
  TemplateRole.secondary,
  TemplateRole.hinge,
  TemplateRole.main,
];

/// Zkrátí trénink na [maxMinutes] (viz popis knihovny). Vrací nový seznam.
List<PlannedItem> fitToMinutes(
  List<PlannedItem> items,
  TrainingFocus focus,
  int maxMinutes,
) {
  final result = [...items];
  final limit = maxMinutes * 60;
  int working(List<TemplateSet> sets) => sets.where((s) => !s.isWarmup).length;

  while (estimateSeconds(result, focus) > limit) {
    // 1) O sérii míň – poslední cvik s nejméně důležitou rolí, který má
    //    víc než 2 pracovní série.
    int? pick;
    for (final role in _trimOrder) {
      for (var i = result.length - 1; i >= 0; i--) {
        if (result[i].item.role == role && working(result[i].sets) > 2) {
          pick = i;
          break;
        }
      }
      if (pick != null) break;
    }
    if (pick != null) {
      final sets = [...result[pick].sets]..removeLast();
      result[pick] = (item: result[pick].item, sets: sets);
      continue;
    }
    // 2) Vynechat poslední doplňkový cvik (hlavní zůstávají, aspoň 3 cviky).
    if (result.length <= 3) break;
    final drop = result.lastIndexWhere((p) =>
        p.item.role != TemplateRole.main && p.item.role != TemplateRole.hinge);
    if (drop < 0) break;
    result.removeAt(drop);
  }
  return result;
}

/// Kolik dní v týdnu program zabere (sjednocení dnů všech plánů).
int programDaysPerWeek(TemplateProgram program) {
  var mask = 0;
  for (final p in program.plans) {
    mask |= p.weekdaysMask;
  }
  var count = 0;
  for (var m = mask; m != 0; m >>= 1) {
    count += m & 1;
  }
  return count;
}

/// Průměrná odhadovaná délka tréninku programu v minutách (bez zkrácení).
int programMinutes(
  TemplateProgram program,
  TrainingFocus goal, {
  ExperienceLevel? level,
}) {
  final focus = programGoal(program, goal);
  var total = 0;
  for (final plan in program.plans) {
    total += estimateSeconds(
        plannedItems(plan, goal, program: program, level: level), focus);
  }
  return roundMinutes(total ~/ program.plans.length);
}

/// Jak program sedí uživateli.
typedef ProgramFit = ({
  TemplateProgram program,
  int days,
  int minutes,

  /// Stejný počet tréninků týdně, jaký uživatel chce.
  bool fitsDays,

  /// Tréninky se při přidání zkrátí na zvolený čas.
  bool shortened,
});

ProgramFit programFit(
  TemplateProgram program, {
  required TrainingFocus goal,
  required ExperienceLevel level,
  required int daysPerWeek,
  required int sessionMinutes,
}) {
  final days = programDaysPerWeek(program);
  final minutes = programMinutes(program, goal, level: level);
  return (
    program: program,
    days: days,
    minutes: minutes,
    fitsDays: days == daysPerWeek,
    shortened: minutes > sessionMinutes,
  );
}

/// Doporučené programy seřazené podle toho, jak sedí: programy pro
/// úroveň uživatele a k nim programy sousední úrovně se stejným počtem
/// tréninků týdně (např. začátečník, který chce 4× týdně, dostane
/// i Horní / dolní). Nejvýš sedí stejný počet dní, pak délka (méně
/// zkracování), pevný cíl shodný s cílem uživatele a základní program
/// před obměnou.
List<ProgramFit> recommendPrograms({
  required ExperienceLevel level,
  required TrainingFocus goal,
  required int daysPerWeek,
  required int sessionMinutes,
}) {
  final fits = [
    for (final p in templatePrograms)
      if (p.level == level ||
          ((p.level.index - level.index).abs() == 1 &&
              programDaysPerWeek(p) == daysPerWeek))
        programFit(p,
            goal: goal,
            level: level,
            daysPerWeek: daysPerWeek,
            sessionMinutes: sessionMinutes),
  ];
  int score(ProgramFit f) {
    var s = (f.days - daysPerWeek).abs() * 20;
    if (f.minutes > sessionMinutes) s += (f.minutes - sessionMinutes) ~/ 5;
    if (f.program.level != level) s += 4;
    final fixed = f.program.goal;
    if (fixed != null) s += fixed == goal ? -2 : 6;
    if (f.program.variationOf != null) s += 1;
    return s;
  }

  final order = {for (final (i, p) in templatePrograms.indexed) p: i};
  return fits
    ..sort((a, b) {
      final c = score(a).compareTo(score(b));
      return c != 0 ? c : order[a.program]!.compareTo(order[b.program]!);
    });
}
