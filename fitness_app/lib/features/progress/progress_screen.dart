import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/formulas.dart';
import '../../core/injury.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../modules/module_hub.dart';
import '../../premium/premium.dart';
import '../../providers.dart';
import '../../ui/charts.dart';
import '../../ui/format.dart';
import '../../ui/labels.dart';
import '../periods/periods_screen.dart';

/// Barva pruhu období v grafech (průhledná, text nese vždy i legenda).
Color periodBandColor(PeriodType t) => switch (t) {
      PeriodType.illness => const Color(0x33D9534F),
      PeriodType.injury => const Color(0x33E8912D),
      PeriodType.cut => const Color(0x332B7BD6),
      PeriodType.bulk => const Color(0x332E9E5B),
      PeriodType.maintenance => const Color(0x33888888),
      PeriodType.pause => const Color(0x338E5BC7),
    };

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider).valueOrNull;
    final showPeriods = profile?.trackPeriods ?? true;
    final periods = showPeriods
        ? ref.watch(periodsProvider).valueOrNull ?? const <Period>[]
        : const <Period>[];
    // Premium: pruhy období v grafech (zdarma bez nich).
    final bandsAllowed =
        ref.watch(premiumProvider).isPremium(PremiumFeature.periodBands);
    final bandPeriods = bandsAllowed ? periods : const <Period>[];
    final history = ref.watch(sessionHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProgress)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (profile?.trackWeight ?? true)
            _WeightChartCard(periods: bandPeriods),
          _StrengthChartCard(periods: bandPeriods),
          const _FrequencyCard(),
          ...moduleProgressCards(),
          if (periods.isNotEmpty)
            bandsAllowed
                ? _PeriodLegend(periods: periods)
                : const Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: PremiumLockedPlaceholder(
                      feature: PremiumFeature.periodBands,
                      compact: true,
                    ),
                  ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(l10n.historyTitle,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          ...history.when<List<Widget>>(
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (e, _) => [Center(child: Text(l10n.errorGeneric))],
            data: (sessions) => sessions.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.historyEmpty),
                    ),
                  ]
                : [for (final s in sessions) _HistoryTile(session: s)],
          ),
        ],
      ),
    );
  }
}

/// Pruhy období pro graf. Zranění s partií se ukáže jen u grafu cviku
/// na tuto partii ([group]); u grafů bez partie (váha) se vynechá.
List<ChartBand> periodBands(List<Period> periods, MuscleGroup? group) {
  final now = DateTime.now();
  return [
    for (final p in periods)
      if (periodAppliesTo(p.type, p.injuredGroups, group))
        ChartBand(p.startDate, p.endDate ?? now, periodBandColor(p.type)),
  ];
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 80,
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
}

class _WeightChartCard extends ConsumerWidget {
  const _WeightChartCard({required this.periods});

  final List<Period> periods;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Premium: celá historie; zdarma posledních 30 dní.
    final fullHistory =
        ref.watch(premiumProvider).isPremium(PremiumFeature.fullHistory);
    final allEntries =
        ref.watch(weightHistoryProvider).valueOrNull ?? const <BodyWeightEntry>[];
    final entries = pointsSince(
      allEntries,
      (BodyWeightEntry e) => e.day,
      chartHistoryStart(DateTime.now(), fullHistory: fullHistory),
    );
    // Grafy kreslí hodnoty rovnou ve zvolených jednotkách (kg / lb).
    final raw = [for (final e in entries) (x: e.day, y: kgToDisplay(e.weightKg))];
    final avg = movingAverage(raw);

    return _ChartCard(
      title: l10n.chartWeightTitle,
      subtitle: l10n.chartLastDays(fullHistory ? chartDays : kFreeChartDays),
      child: raw.length < 2
          ? _EmptyChart(l10n.chartWeightEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (allEntries.length > entries.length)
                  const _HistoryLimitHint(),
                TimeSeriesChart(
                  series: [
                    ChartSeries(
                      points: avg,
                      color: theme.colorScheme.primary,
                      showDots: false,
                    ),
                    ChartSeries(
                      points: raw,
                      color: theme.colorScheme.outline,
                      showLine: false,
                    ),
                  ],
                  bands: periodBands(periods, null),
                  formatY: (v) =>
                      '${formatDecimal(context, v, maxDecimals: 1)} $weightUnit',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  children: [
                    _LegendItem(
                      color: theme.colorScheme.primary,
                      label: l10n.chartWeightAverage,
                      line: true,
                    ),
                    _LegendItem(
                      color: theme.colorScheme.outline,
                      label: l10n.chartWeightDaily,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _StrengthChartCard extends ConsumerWidget {
  const _StrengthChartCard({required this.periods});

  final List<Period> periods;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final exercises =
        ref.watch(exercisesWithHistoryProvider).valueOrNull ?? const <Exercise>[];
    final chosenId = ref.watch(chartExerciseProvider);
    final exercise = exercises.where((e) => e.id == chosenId).firstOrNull ??
        exercises.firstOrNull;
    final fullHistory =
        ref.watch(premiumProvider).isPremium(PremiumFeature.fullHistory);
    final allPoints = exercise == null
        ? const <SeriesPoint>[]
        : ref.watch(oneRepMaxSeriesProvider(exercise.id)).valueOrNull ??
            const <SeriesPoint>[];
    final points = pointsSince(
      allPoints,
      (SeriesPoint p) => p.x,
      chartHistoryStart(DateTime.now(), fullHistory: fullHistory),
    );

    return _ChartCard(
      title: l10n.chartStrengthTitle,
      subtitle: l10n.chartStrengthSubtitle,
      trailing: exercises.isEmpty
          ? null
          : DropdownButton<int>(
              value: exercise?.id,
              underline: const SizedBox.shrink(),
              items: [
                for (final e in exercises)
                  DropdownMenuItem(
                    value: e.id,
                    child: Text(e.localizedName(context)),
                  ),
              ],
              onChanged: (id) =>
                  ref.read(chartExerciseProvider.notifier).state = id,
            ),
      child: points.length < 2
          ? (allPoints.length > points.length
              ? const _HistoryLimitHint()
              : _EmptyChart(l10n.chartStrengthEmpty))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (allPoints.length > points.length)
                  const _HistoryLimitHint(),
                TimeSeriesChart(
                  series: [
                    ChartSeries(
                      points: [
                        for (final p in points) (x: p.x, y: kgToDisplay(p.y)),
                      ],
                      color: theme.colorScheme.primary,
                    ),
                  ],
                  bands: periodBands(periods, exercise!.muscleGroup),
                  formatY: (v) =>
                      '${formatDecimal(context, roundToStep(v, step: isImperial ? 1 : 0.5))} '
                      '$weightUnit',
                ),
              ],
            ),
    );
  }
}

class _FrequencyCard extends ConsumerWidget {
  const _FrequencyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dates = ref.watch(workoutDatesProvider).valueOrNull ?? const [];
    final allWeeks = weeklyCounts(dates, DateTime.now());
    // Premium: zdarma jen posledních 5 týdnů (≈ 30 dní).
    final fullHistory =
        ref.watch(premiumProvider).isPremium(PremiumFeature.fullHistory);
    final weeks = allWeeks.sublist(
      allWeeks.length - visibleWeekCount(allWeeks.length, fullHistory: fullHistory),
    );
    final fmt = DateFormat.MMMd(Localizations.localeOf(context).toString());
    final total = weeks.fold<int>(0, (a, w) => a + w.count);

    return _ChartCard(
      title: l10n.chartFrequencyTitle,
      subtitle: weeks.length < allWeeks.length
          ? l10n.premiumFrequencyLimited(weeks.length)
          : l10n.chartFrequencySubtitle,
      child: total == 0
          ? _EmptyChart(l10n.chartFrequencyEmpty)
          : WeeklyBarChart(
              values: [for (final w in weeks) w.count],
              labels: [for (final w in weeks) fmt.format(w.weekStart)],
              color: theme.colorScheme.primary,
              tooltip: (i) => l10n.chartFrequencyTooltip(
                fmt.format(weeks[i].weekStart),
                weeks[i].count,
              ),
            ),
    );
  }
}

/// Zdarma grafy ukazují jen posledních 30 dní – odkaz na Premium.
class _HistoryLimitHint extends StatelessWidget {
  const _HistoryLimitHint();

  @override
  Widget build(BuildContext context) => PremiumLockedPlaceholder(
        feature: PremiumFeature.fullHistory,
        compact: true,
        text: AppLocalizations.of(context).premiumChartLimited(kFreeChartDays),
      );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.line = false,
  });

  final Color color;
  final String label;
  final bool line;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: line ? 16 : 8,
          height: line ? 2 : 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(line ? 1 : 4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _PeriodLegend extends StatelessWidget {
  const _PeriodLegend({required this.periods});

  final List<Period> periods;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final types = {for (final p in periods) p.type}.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final injured = {
      for (final p in periods)
        if (p.type == PeriodType.injury) ...p.injuredGroups,
    }.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    String label(PeriodType t) => t == PeriodType.injury && injured.isNotEmpty
        ? '${l10n.periodType(t)} (${injured.map(l10n.muscleGroup).join(', ')})'
        : l10n.periodType(t);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(l10n.chartPeriodsLegend,
              style: Theme.of(context).textTheme.labelSmall),
          for (final t in types)
            Chip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(periodIcon(t), size: 16),
              backgroundColor: periodBandColor(t),
              label: Text(label(t)),
            ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.session});

  final SessionSummary session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMEd(locale).format(session.startedAt);
    final end = session.endedAt;
    final parts = [
      l10n.historySets(session.setCount),
      if (session.volumeKg > 0) formatWeightTotal(context, session.volumeKg),
      if (end != null) formatDuration(end.difference(session.startedAt)),
    ];
    final title = session.kind == SessionKind.planB
        ? l10n.planBHistoryTitle
        : (session.planName ?? l10n.workoutFree);

    return ListTile(
      leading: Icon(session.kind == SessionKind.planB
          ? Icons.home_outlined
          : Icons.fitness_center),
      title: Text(title),
      subtitle: Text('$date\n${parts.join(' · ')}'),
      isThreeLine: true,
    );
  }
}
