import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../stats_providers.dart';

/// Karta Dnes: kolik týdnů v řadě uživatel splnil svůj plán.
class StatsStreakTodayCard extends ConsumerWidget {
  const StatsStreakTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final streak = ref.watch(statsStreakProvider);
    if (streak == null || (streak.weeks == 0 && streak.doneThisWeek == 0)) {
      return const SizedBox.shrink();
    }
    final done = streak.doneThisWeek.clamp(0, streak.goal);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: streak.weeks > 0
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    streak.weeks > 0
                        ? l10n.statsStreakWeeks(streak.weeks)
                        : l10n.statsStreakStart,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.statsStreakThisWeek(streak.doneThisWeek, streak.goal)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: done / streak.goal,
              minHeight: 6,
              semanticsLabel:
                  l10n.statsStreakThisWeek(streak.doneThisWeek, streak.goal),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.statsStreakHint,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Karta Dnes: jemné upozornění, když váha klesá rychleji než ~1 % týdně.
class StatsWeightDropTodayCard extends ConsumerWidget {
  const StatsWeightDropTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rate = ref.watch(statsFastWeightLossProvider);
    if (rate == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          Icons.trending_down,
          color: theme.colorScheme.onSecondaryContainer,
        ),
        title: Text(
          l10n.statsTodayWeightDropTitle,
          style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
        ),
        subtitle: Text(
          l10n.statsTodayWeightDropBody(NumberFormat('0.0', locale).format(rate)),
          style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
        ),
      ),
    );
  }
}
