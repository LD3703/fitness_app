import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/date_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/labels.dart';
import '../stats_math.dart';
import '../stats_providers.dart';
import 'stats_card.dart';

/// Frekvence: kalendář aktivity a jak často se trénuje která partie.
class StatsFrequencyCard extends ConsumerWidget {
  const StatsFrequencyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dates =
        ref.watch(statsWorkoutDatesProvider).valueOrNull ?? const <DateTime>[];
    final groups = ref.watch(statsGroupStatsProvider).valueOrNull ?? const [];
    final byGroup = [
      for (final g in groups)
        if (g.sessions > 0) g,
    ]..sort((a, b) => b.sessions.compareTo(a.sessions));

    return StatsCard(
      title: l10n.statsActivityTitle,
      subtitle: l10n.statsActivitySubtitle(statsHeatmapWeeks),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ActivityHeatmap(dates: dates, weeks: statsHeatmapWeeks),
          StatsSubheading(l10n.statsActivityByGroup(statsGroupDays)),
          if (byGroup.isEmpty)
            StatsEmpty(l10n.statsActivityByGroupEmpty)
          else
            HorizontalBars(
              items: [
                for (final g in byGroup)
                  (
                    label: l10n.muscleGroup(g.group),
                    value: g.sessions.toDouble(),
                    valueText: l10n.statsTimes(g.sessions),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Kalendář aktivity: 7 řádků (po–ne), sloupec = týden, nejnovější vpravo.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({super.key, required this.dates, this.weeks = 16});

  final List<DateTime> dates;
  final int weeks;

  static const _gap = 3.0;
  static const _labelWidth = 28.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dayFmt = DateFormat.MMMEd(locale);
    final weekdayFmt = DateFormat.E(locale);
    final monthFmt = DateFormat.MMM(locale);
    final counts = dailyCounts(dates);
    final today = startOfDay(DateTime.now());
    final firstMonday = addDays(weekStartOf(today), -7 * (weeks - 1));
    final empty = theme.colorScheme.surfaceContainerHighest;
    final primary = theme.colorScheme.primary;

    Color colorFor(int count) => switch (count) {
          0 => empty,
          1 => primary.withValues(alpha: 0.6),
          _ => primary,
        };

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - _labelWidth;
        final cell = math
            .min(20.0, (available - _gap * (weeks - 1)) / weeks)
            .clamp(4.0, 20.0);
        Widget legendBox(Color c) => Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(2),
              ),
            );
        final labelStyle = theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Měsíce nad sloupci (u týdne, ve kterém měsíc začíná).
            Padding(
              padding: const EdgeInsets.only(left: _labelWidth),
              child: SizedBox(
                height: 16,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var w = 0; w < weeks; w++)
                      if (_monthLabelAt(firstMonday, w))
                        Positioned(
                          left: w * (cell + _gap),
                          child: Text(
                            monthFmt.format(addDays(firstMonday, 7 * w)),
                            style: labelStyle,
                          ),
                        ),
                  ],
                ),
              ),
            ),
            for (var d = 0; d < 7; d++)
              Padding(
                padding: EdgeInsets.only(bottom: d == 6 ? 0 : _gap),
                child: Row(
                  children: [
                    SizedBox(
                      width: _labelWidth,
                      child: d.isEven
                          ? Text(
                              weekdayFmt.format(addDays(firstMonday, d)),
                              style: labelStyle,
                            )
                          : null,
                    ),
                    for (var w = 0; w < weeks; w++)
                      Padding(
                        padding:
                            EdgeInsets.only(right: w == weeks - 1 ? 0 : _gap),
                        child: _cell(
                          day: addDays(firstMonday, 7 * w + d),
                          today: today,
                          size: cell,
                          counts: counts,
                          colorFor: colorFor,
                          label: (day, count) => l10n.statsActivityDay(
                            dayFmt.format(day),
                            count,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(l10n.statsActivityLess, style: labelStyle),
                const SizedBox(width: 4),
                legendBox(colorFor(0)),
                legendBox(colorFor(1)),
                legendBox(colorFor(2)),
                const SizedBox(width: 4),
                Text(l10n.statsActivityMore, style: labelStyle),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Popisek měsíce patří nad týden, ve kterém měsíc začíná. U prvního
  /// sloupce jen tehdy, když se nepřekryje s popiskem dalšího měsíce.
  bool _monthLabelAt(DateTime firstMonday, int w) {
    int monthOf(int week) => addDays(firstMonday, 7 * week).month;
    if (w > 0) return monthOf(w) != monthOf(w - 1);
    for (var next = 1; next < 3 && next < weeks; next++) {
      if (monthOf(next) != monthOf(0)) return false;
    }
    return true;
  }

  Widget _cell({
    required DateTime day,
    required DateTime today,
    required double size,
    required Map<DateTime, int> counts,
    required Color Function(int) colorFor,
    required String Function(DateTime, int) label,
  }) {
    if (day.isAfter(today)) return SizedBox(width: size, height: size);
    final count = counts[day] ?? 0;
    final isToday = day == today;
    return Tooltip(
      message: label(day, count),
      triggerMode: TooltipTriggerMode.tap,
      child: Builder(
        builder: (context) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorFor(count),
            borderRadius: BorderRadius.circular(3),
            border: isToday
                ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 1.5,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
