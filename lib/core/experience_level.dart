/// Úroveň pokročilosti a její vývoj podle historie tréninků.
///
/// Úroveň zadá uživatel v úvodu (a kdykoli v profilu). Aplikace pak
/// z dokončených tréninků navrhne změnu – nikdy ji nemění sama, uživatel ji
/// na kartě Dnes potvrdí, nebo odmítne (další návrh nejdřív za 30 dní).
///
/// Prahy vycházejí z doporučení ACSM (Progression Models in Resistance
/// Training, 2009): začátečník = bez zkušeností nebo po několikaleté
/// pauze, mírně pokročilý ≈ 6 měsíců pravidelného tréninku (3–4× týdně),
/// pokročilý = roky tréninku (4–5× týdně). Pravidelnost se hlídá za
/// posledních 12 týdnů, aby nestačil starý „nápor“.
///
/// Návrat o úroveň níž: po 12 týdnech bez tréninku. Síla se při pauze do
/// ~4 týdnů skoro nemění, výrazně klesá zhruba po 8–12 týdnech (Mujika
/// a Padilla 2001; McMaster a kol. 2013) – po takové pauze je rozumné
/// začít s menším objemem a postupně se vrátit.
library;

import '../data/enums.dart';

/// Proč aplikace navrhuje změnu úrovně.
enum LevelChangeReason {
  /// Dost dlouho a pravidelně trénuje → o úroveň výš.
  progress,

  /// Dlouhá pauza → o úroveň níž.
  longBreak,
}

typedef LevelSuggestion = ({ExperienceLevel level, LevelChangeReason reason});

/// Podmínky postupu z jedné úrovně na další.
class LevelRequirement {
  const LevelRequirement({
    required this.weeks,
    required this.workouts,
    required this.recentWorkouts,
  });

  /// Nejméně týdnů na současné úrovni.
  final int weeks;

  /// Nejméně dokončených tréninků od začátku současné úrovně.
  final int workouts;

  /// Nejméně tréninků za posledních [kRecentWeeks] týdnů (pravidelnost).
  final int recentWorkouts;
}

/// Okno pro pravidelnost.
const kRecentWeeks = 12;

/// Pauza (týdny bez tréninku), po které se navrhne nižší úroveň.
const kLongBreakWeeks = 12;

/// Odmítnutý návrh se znovu ukáže nejdřív po tolika dnech.
const kLevelPromptCooldownDays = 30;

/// Postup na další úroveň (klíč = současná úroveň).
/// Začátečník → mírně pokročilý: půl roku, ~2 tréninky týdně (48),
/// posledních 12 týdnů aspoň 1,5× týdně (18).
/// Mírně pokročilý → pokročilý: rok a půl, ~2,5 tréninku týdně (180),
/// posledních 12 týdnů aspoň 2,5× týdně (30).
const levelRequirements = <ExperienceLevel, LevelRequirement>{
  ExperienceLevel.beginner:
      LevelRequirement(weeks: 26, workouts: 48, recentWorkouts: 18),
  ExperienceLevel.intermediate:
      LevelRequirement(weeks: 78, workouts: 180, recentWorkouts: 30),
};

ExperienceLevel experienceLevelOf(int? value) =>
    value != null && value >= 0 && value < ExperienceLevel.values.length
        ? ExperienceLevel.values[value]
        : ExperienceLevel.beginner;

/// Plnění podmínek pro další úroveň.
typedef LevelProgress = ({
  ExperienceLevel next,
  LevelRequirement requirement,
  int weeks,
  int workouts,
  int recentWorkouts,
});

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Celé dny mezi dvěma daty podle kalendáře (bez vlivu změny času).
int _daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

/// Začátek současné úrovně: [since], jinak první trénink, jinak dnes.
DateTime _levelStart(DateTime? since, List<DateTime> workouts, DateTime now) {
  if (since != null) return _day(since);
  if (workouts.isEmpty) return _day(now);
  return _day(workouts.reduce((a, b) => a.isBefore(b) ? a : b));
}

/// Jak daleko je uživatel od další úrovně (null = už je pokročilý).
/// [workouts] = začátky dokončených tréninků (stačí od [since]).
LevelProgress? levelProgress({
  required ExperienceLevel current,
  required DateTime? since,
  required List<DateTime> workouts,
  required DateTime now,
}) {
  final requirement = levelRequirements[current];
  if (requirement == null) return null;
  final start = _levelStart(since, workouts, now);
  final recentFrom = _day(now).subtract(const Duration(days: 7 * kRecentWeeks));
  var total = 0;
  var recent = 0;
  for (final w in workouts) {
    final d = _day(w);
    if (d.isBefore(start)) continue;
    total++;
    if (!d.isBefore(recentFrom)) recent++;
  }
  return (
    next: ExperienceLevel.values[current.index + 1],
    requirement: requirement,
    weeks: _daysBetween(start, now) ~/ 7,
    workouts: total,
    recentWorkouts: recent,
  );
}

/// Návrh změny úrovně, nebo null. [promptAt] = kdy uživatel naposledy
/// návrh odmítl.
LevelSuggestion? suggestLevelChange({
  required ExperienceLevel current,
  required DateTime? since,
  required List<DateTime> workouts,
  required DateTime now,
  DateTime? promptAt,
}) {
  if (promptAt != null &&
      _daysBetween(promptAt, now) < kLevelPromptCooldownDays) {
    return null;
  }

  // Dlouhá pauza: poslední trénink před 12+ týdny (a na úrovni je
  // uživatel aspoň tak dlouho – čerstvě zvolenou úroveň nezpochybňujeme).
  if (current != ExperienceLevel.beginner && workouts.isNotEmpty) {
    final last = workouts.reduce((a, b) => a.isAfter(b) ? a : b);
    final start = _levelStart(since, workouts, now);
    final breakDays = 7 * kLongBreakWeeks;
    if (_daysBetween(last, now) >= breakDays &&
        _daysBetween(start, now) >= breakDays) {
      return (
        level: ExperienceLevel.values[current.index - 1],
        reason: LevelChangeReason.longBreak,
      );
    }
  }

  final p = levelProgress(
      current: current, since: since, workouts: workouts, now: now);
  if (p == null) return null;
  final r = p.requirement;
  if (p.weeks >= r.weeks &&
      p.workouts >= r.workouts &&
      p.recentWorkouts >= r.recentWorkouts) {
    return (level: p.next, reason: LevelChangeReason.progress);
  }
  return null;
}
