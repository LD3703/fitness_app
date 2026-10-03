import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/database.dart';
import '../../../features/progress/progress_screen.dart' show periodBands;
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../../../ui/charts.dart';
import '../../../ui/format.dart';
import '../../data/units.dart';
import '../stats_providers.dart';
import '../stats_queries.dart';

/// Sekce v detailu cviku: graf odhadu 1RM a posledních 5 tréninků.
/// Když uživatel cvik ještě nedělal, nic nezobrazí.
class ExerciseStatsSection extends ConsumerWidget {
  const ExerciseStatsSection({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions =
        ref.watch(statsRecentExerciseSessionsProvider(exercise.id)).valueOrNull;
    if (sessions == null || sessions.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    ref.watch(unitSystemProvider); // překreslit po změně kg / lb
    final points = ref.watch(oneRepMaxSeriesProvider(exercise.id)).valueOrNull ??
        const <SeriesPoint>[];
    final trackPeriods =
        ref.watch(profileProvider).valueOrNull?.trackPeriods ?? true;
    final periods = trackPeriods
        ? ref.watch(periodsProvider).valueOrNull ?? const <Period>[]
        : const <Period>[];
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.yMMMEd(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(l10n.statsExerciseTitle, style: theme.textTheme.titleMedium),
        if (points.length >= 2) ...[
          Text(
            l10n.statsExerciseChartSubtitle,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          TimeSeriesChart(
            series: [
              ChartSeries(points: points, color: theme.colorScheme.primary),
            ],
            bands: periodBands(periods, exercise.muscleGroup),
            formatY: (v) =>
                l10n.statsKg(formatWeightWithUnit(context, v, rounded: true)),
          ),
        ],
        const SizedBox(height: 16),
        Text(l10n.statsExerciseRecent, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        for (final s in sessions)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(dateFmt.format(s.date)),
            subtitle: Text(_describeSets(context, l10n, s)),
          ),
      ],
    );
  }

  /// „80 kg × 8, 80 × 8, 85 × 6“ – jednotka jen u první série s vahou.
  /// Rozcvičkové série se vynechají (když jsou jen ony, ukážou se).
  static String _describeSets(
    BuildContext context,
    AppLocalizations l10n,
    ExerciseSessionSets session,
  ) {
    final working = session.sets.where((s) => !s.isWarmup).toList();
    final sets = working.isEmpty ? session.sets : working;
    var unitShown = false;
    final parts = <String>[];
    for (final s in sets) {
      final w = s.weightKg;
      final r = s.reps;
      final d = s.durationSeconds;
      if (w != null && w > 0 && r != null) {
        parts.add(unitShown
            ? l10n.statsSetWeightRepsShort(formatWeight(context, w), r)
            : l10n.statsSetWeightReps(formatWeightWithUnit(context, w), r));
        unitShown = true;
      } else if (r != null) {
        parts.add(l10n.statsSetReps(r));
      } else if (d != null) {
        parts.add(formatDuration(Duration(seconds: d)));
      }
    }
    return parts.join(', ');
  }
}
