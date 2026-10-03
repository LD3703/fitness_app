import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/charts.dart';
import '../../../ui/format.dart';
import '../../../ui/labels.dart';
import '../../data/units.dart';
import '../stats_math.dart';
import '../stats_providers.dart';
import 'stats_card.dart';

/// Objem: zvednutá váha po týdnech a po partiích.
class StatsVolumeCard extends ConsumerWidget {
  const StatsVolumeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    ref.watch(unitSystemProvider); // překreslit po změně kg / lb
    final sessions = ref.watch(statsSessionVolumesProvider).valueOrNull ??
        const <({DateTime x, double y})>[];
    final groups = ref.watch(statsGroupStatsProvider).valueOrNull ?? const [];
    final weeks =
        weeklySums(sessions, DateTime.now(), weeks: statsVolumeWeeks);
    final total = weeks.fold<double>(0, (a, w) => a + w.total);
    final fmt = DateFormat.MMMd(Localizations.localeOf(context).toString());

    final byGroup = [
      for (final g in groups)
        if (g.volumeKg > 0) g,
    ]..sort((a, b) => b.volumeKg.compareTo(a.volumeKg));

    return StatsCard(
      title: l10n.statsVolumeTitle,
      subtitle: l10n.statsVolumeSubtitle(statsVolumeWeeks),
      child: total <= 0
          ? StatsEmpty(l10n.statsVolumeEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WeeklyBarChart(
                  values: [for (final w in weeks) w.total.round()],
                  labels: [for (final w in weeks) fmt.format(w.weekStart)],
                  color: theme.colorScheme.primary,
                  tooltip: (i) => l10n.statsVolumeTooltip(
                    fmt.format(weeks[i].weekStart),
                    formatWeightTotal(context, weeks[i].total),
                  ),
                ),
                if (byGroup.isNotEmpty) ...[
                  StatsSubheading(l10n.statsVolumeByGroup(statsGroupDays)),
                  HorizontalBars(
                    items: [
                      for (final g in byGroup)
                        (
                          label: l10n.muscleGroup(g.group),
                          value: g.volumeKg,
                          valueText: l10n.statsKg(formatWeightTotal(context, g.volumeKg)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
