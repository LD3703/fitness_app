import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/format.dart';
import '../../../ui/labels.dart';
import '../../data/units.dart';
import '../insights.dart';
import '../stats_providers.dart';
import 'stats_card.dart';

/// Karta „Postřehy“ na obrazovce Pokrok.
class StatsInsightsCard extends ConsumerWidget {
  const StatsInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final insights = ref.watch(statsInsightsProvider);
    ref.watch(unitSystemProvider); // překreslit po změně kg / lb
    final exercises =
        ref.watch(statsExerciseMapProvider).valueOrNull ?? const <int, Exercise>{};
    if (insights == null) return const SizedBox.shrink();

    return StatsCard(
      title: l10n.statsInsightsTitle,
      child: insights.isEmpty
          ? StatsEmpty(l10n.statsInsightsEmpty)
          : Column(
              children: [
                for (final i in insights)
                  _InsightTile(insight: i, exercises: exercises),
              ],
            ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight, required this.exercises});

  final Insight insight;
  final Map<int, Exercise> exercises;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    String pct(double v) => NumberFormat('0', locale).format(v);
    String sign(double v) => v < 0 ? '−' : '+';
    String signedPct(double v) =>
        '${sign(v.round().toDouble())}${pct(v.abs())}';
    String signedKg(double v) {
      final rounded = (kgToDisplay(v) * 10).round() / 10;
      return '${sign(rounded)}${NumberFormat('0.0', locale).format(rounded.abs())} $weightUnit';
    }
    String name(int id) =>
        exercises[id]?.localizedName(context) ?? l10n.statsUnknownExercise;

    final (IconData icon, Color color, String title, List<String> lines) =
        switch (insight) {
      WeightDropInsight(:final percentPerWeek) => (
          Icons.trending_down,
          theme.colorScheme.error,
          l10n.statsInsightWeightDropTitle,
          [
            l10n.statsInsightWeightDropBody(
              NumberFormat('0.0', locale).format(percentPerWeek),
            ),
          ],
        ),
      IllnessRecoveryInsight(:final lifts) => (
          Icons.healing_outlined,
          theme.colorScheme.primary,
          l10n.statsInsightIllnessTitle,
          [
            for (final lift in lifts)
              if (lift.daysToRecover case final days?)
                l10n.statsInsightIllnessRecovered(name(lift.exerciseId), days)
              else
                l10n.statsInsightIllnessBelow(
                  name(lift.exerciseId),
                  pct(lift.percentBelow ?? 0.0),
                ),
          ],
        ),
      CutSummaryInsight(
        :final ongoing,
        :final weightChangeKg,
        :final strengthKeptPercent,
      ) =>
        (
          Icons.local_fire_department_outlined,
          theme.colorScheme.primary,
          ongoing ? l10n.statsInsightCutOngoing : l10n.statsInsightCutDone,
          [
            if (weightChangeKg != null)
              l10n.statsInsightWeightChange(signedKg(weightChangeKg)),
            if (strengthKeptPercent != null)
              l10n.statsInsightStrengthKept(pct(strengthKeptPercent)),
          ],
        ),
      BulkSummaryInsight(
        :final ongoing,
        :final weightChangeKg,
        :final strengthChangePercent,
      ) =>
        (
          Icons.restaurant_outlined,
          theme.colorScheme.primary,
          ongoing ? l10n.statsInsightBulkOngoing : l10n.statsInsightBulkDone,
          [
            if (weightChangeKg != null)
              l10n.statsInsightWeightChange(signedKg(weightChangeKg)),
            if (strengthChangePercent != null)
              l10n.statsInsightStrengthChange(signedPct(strengthChangePercent)),
          ],
        ),
      MonthRecordsInsight(
        :final count,
        :final bestExerciseId,
        :final bestOneRepMax,
        :final bestGainPercent,
      ) =>
        (
          Icons.emoji_events_outlined,
          theme.colorScheme.tertiary,
          l10n.statsInsightRecordsTitle(count),
          [
            l10n.statsInsightRecordsBest(
              name(bestExerciseId),
              formatWeightWithUnit(context, bestOneRepMax, rounded: true),
              signedPct(bestGainPercent),
            ),
          ],
        ),
      NeglectedGroupInsight(:final group, :final daysSince) => (
          Icons.hourglass_bottom,
          theme.colorScheme.secondary,
          l10n.statsInsightNeglectedTitle,
          [l10n.statsInsightNeglectedBody(l10n.muscleGroup(group), daysSince)],
        ),
      final ConsistencyInsight c => (
          Icons.event_available_outlined,
          theme.colorScheme.primary,
          l10n.statsInsightConsistencyTitle,
          [
            if (c.plannedPerWeek > 0)
              l10n.statsInsightConsistencyPlanned(
                NumberFormat('0.#', locale).format(c.averagePerWeek),
                c.plannedPerWeek,
              )
            else
              l10n.statsInsightConsistencyNoPlan(
                NumberFormat('0.#', locale).format(c.averagePerWeek),
              ),
            if (c.plannedPerWeek > 0)
              c.onTrack
                  ? l10n.statsInsightConsistencyOnTrack
                  : l10n.statsInsightConsistencyBehind,
          ],
        ),
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: lines.isEmpty ? null : Text(lines.join('\n')),
    );
  }
}
