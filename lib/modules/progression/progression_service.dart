import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auto_progression.dart';
import '../../data/database.dart';
import '../../features/workout/workout_service.dart';
import '../../premium/premium.dart';
import '../../providers.dart';
import 'progression_queries.dart';

/// Návrhy z posledního dokončeného tréninku (pro souhrn).
/// [autoApplied] = změny už jsou v plánu (režim „použít automaticky“).
typedef ProgressionSummaryState = ({
  int sessionId,
  bool autoApplied,
  List<ProgressionEntry> entries,
});

final progressionSummaryProvider =
    StateProvider<ProgressionSummaryState?>((ref) => null);

/// Nepoužité návrhy cviků plánu (podle ID cviku v plánu).
final pendingProgressionProvider = StreamProvider.autoDispose
    .family<Map<int, ProgressionEvent>, int>(
  (ref, planId) =>
      ref.watch(databaseProvider).watchPendingProgression(planId),
);

/// Poslední použitá změna cviku v plánu (editor cviku).
final lastProgressionEventProvider =
    StreamProvider.autoDispose.family<ProgressionEvent?, int>(
  (ref, planExerciseId) =>
      ref.watch(databaseProvider).watchLastProgressionEvent(planExerciseId),
);

/// Co teď brání zvyšování (nemoc, zotavování, zranění partie, dieta).
/// Když uživatel období nesleduje, nic.
ProgressionBlockers progressionBlockersOf(
  UserProfile profile,
  List<Period> periods,
  DateTime now,
) {
  if (!profile.trackPeriods) return ProgressionBlockers.none;
  return progressionBlockersFrom(
    periods.map((p) => (
          type: p.type,
          start: p.startDate,
          end: p.endDate,
          groups: p.injuredGroups,
        )),
    now,
  );
}

/// Háček po tréninku (progression:finished): navrhne nové cíle cviků plánu
/// (v režimu „použít automaticky“ je rovnou zapíše) a předá je souhrnu.
/// Premium (autoProgression): bez předplatného se nic nenavrhuje – souhrn
/// pak ukáže jen zamčenou upoutávku.
Future<void> progressionWorkoutFinished(
  WidgetRef ref,
  WorkoutSummary summary,
) async {
  final notifier = ref.read(progressionSummaryProvider.notifier);
  notifier.state = null;
  if (!ref.read(premiumProvider).isPremium(PremiumFeature.autoProgression)) {
    return;
  }
  final db = ref.read(databaseProvider);
  final profile = await db.watchProfile().first;
  final mode = progressionModeOf(profile.progressionMode);
  if (mode == ProgressionMode.off) return;
  final session = await db.getSession(summary.sessionId);
  final planId = session.planId;
  if (planId == null || session.kind != SessionKind.full) return;
  final periods = await db.watchPeriods().first;
  final entries = await db.runAutoProgression(
    summary.sessionId,
    planId,
    unit: profile.unitSystem,
    blockers: progressionBlockersOf(profile, periods, DateTime.now()),
    apply: mode == ProgressionMode.auto,
  );
  if (entries.isEmpty) return;
  notifier.state = (
    sessionId: summary.sessionId,
    autoApplied: mode == ProgressionMode.auto,
    entries: entries,
  );
}
