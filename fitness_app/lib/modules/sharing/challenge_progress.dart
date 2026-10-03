// Čistá logika výzev: stav, časová okna a průběh. Bez Flutteru a databáze,
// aby šla testovat (test/sharing_challenge_progress_test.dart).

import '../../core/date_utils.dart';
import '../../data/enums.dart';

/// Stav výzvy v daném okamžiku.
enum ChallengeState { active, completed, expired, dismissed }

/// Stav výzvy: skrytá > splněná > propadlá > aktivní.
/// Termín [deadline] platí celý den (propadne až o půlnoci po něm).
ChallengeState challengeState({
  DateTime? completedAt,
  DateTime? dismissedAt,
  DateTime? deadline,
  required DateTime now,
}) {
  if (dismissedAt != null) return ChallengeState.dismissed;
  if (completedAt != null) return ChallengeState.completed;
  if (deadline != null && !now.isBefore(endOfDayExclusive(deadline))) {
    return ChallengeState.expired;
  }
  return ChallengeState.active;
}

/// Počet dní do termínu (0 = končí dnes, záporné = po termínu).
/// Počítá kalendářní dny, takže nevadí přechod na letní čas.
int? daysLeft(DateTime? deadline, DateTime now) {
  if (deadline == null) return null;
  final a = DateTime.utc(now.year, now.month, now.day);
  final b = DateTime.utc(deadline.year, deadline.month, deadline.day);
  return b.difference(a).inDays;
}

/// Pondělí 00:00 týdne, do kterého patří [now].
DateTime weekStart(DateTime now) =>
    DateTime(now.year, now.month, now.day - (now.weekday - 1));

/// Pondělí 00:00 následujícího týdne.
DateTime weekEndExclusive(DateTime now) =>
    DateTime(now.year, now.month, now.day - (now.weekday - 1) + 7);

/// První den měsíce 00:00.
DateTime monthStart(DateTime now) => DateTime(now.year, now.month);

/// První den následujícího měsíce 00:00.
DateTime monthEndExclusive(DateTime now) => DateTime(now.year, now.month + 1);

/// Zaokrouhlí na nejbližší půlku (116,67 → 116,5).
double roundToHalf(double v) => (v * 2).round() / 2;

/// Průběh výzvy: aktuální hodnota proti cíli.
class ChallengeProgress {
  const ChallengeProgress({
    required this.kind,
    required this.current,
    required this.target,
  });

  final ChallengeKind kind;
  final double current;
  final double target;

  /// 0–1 pro ukazatel průběhu.
  double get fraction {
    if (target <= 0) return 1;
    final f = current / target;
    return f < 0 ? 0 : (f > 1 ? 1 : f);
  }

  /// Je cíl splněn? Rekord je potřeba překonat (víc než cíl),
  /// u počtu tréninků a vody stačí cíle dosáhnout.
  bool get reached {
    if (target <= 0) return true;
    return switch (kind) {
      ChallengeKind.beatRecord => current > target + 1e-9,
      ChallengeKind.workoutsInMonth ||
      ChallengeKind.weeklyWater =>
        current >= target - 1e-9,
    };
  }
}

/// Průběh výzvy podle naměřených hodnot. Hodnoty, které se druhu
/// výzvy netýkají, se ignorují.
///
/// - beatRecord: nejlepší odhad 1RM v cviku (null = bez rekordu → 0),
/// - workoutsInMonth: dokončené tréninky v aktuálním měsíci,
/// - weeklyWater: ml vody v aktuálním týdnu (po–ne).
ChallengeProgress challengeProgress(
  ChallengeKind kind,
  double target, {
  double? bestOneRepMax,
  int workoutsThisMonth = 0,
  int waterMlThisWeek = 0,
}) =>
    ChallengeProgress(
      kind: kind,
      target: target,
      current: switch (kind) {
        ChallengeKind.beatRecord => bestOneRepMax ?? 0,
        ChallengeKind.workoutsInMonth => workoutsThisMonth.toDouble(),
        ChallengeKind.weeklyWater => waterMlThisWeek.toDouble(),
      },
    );

/// Slug cviku pro lidi: 'bench_press' → 'Bench press'.
String humanizeSlug(String slug) {
  final s = slug.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
