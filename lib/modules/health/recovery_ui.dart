// Obrazovky regenerace z hodinek a prstenů: karta Připravenost na Dnes,
// detail (/readiness), dialog před tréninkem a tep v souhrnu tréninku.
// Vyhodnocení: core/readiness.dart, data: recovery.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/readiness.dart';
import '../../data/database.dart';
import '../../features/workout/start_workout.dart';
import '../../features/workout/workout_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/weekdays.dart';
import 'health_service.dart';
import 'recovery.dart';

GoRoute readinessRoute() => GoRoute(
      path: '/readiness',
      builder: (context, state) => const ReadinessScreen(),
    );

/// „7 h 20 min“.
String formatSleep(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}

String readinessLevelText(AppLocalizations l10n, ReadinessLevel level) =>
    switch (level) {
      ReadinessLevel.good => l10n.readinessGood,
      ReadinessLevel.caution => l10n.readinessCaution,
      ReadinessLevel.low => l10n.readinessLow,
    };

Color readinessColor(ThemeData theme, ReadinessLevel level) => switch (level) {
      ReadinessLevel.good => Colors.green.shade600,
      ReadinessLevel.caution => Colors.orange.shade700,
      ReadinessLevel.low => theme.colorScheme.error,
    };

IconData readinessIcon(ReadinessLevel level) => switch (level) {
      ReadinessLevel.good => Icons.battery_full,
      ReadinessLevel.caution => Icons.battery_4_bar,
      ReadinessLevel.low => Icons.battery_1_bar,
    };

/// Texty důvodů (co připravenost snižuje).
List<String> readinessReasons(AppLocalizations l10n, ReadinessReport r) {
  String ms(double v) => '${v.round()}';
  final reasons = <String>[];
  for (final f in r.factors) {
    switch (f) {
      case ReadinessFactor.hrvLow:
        final n = r.hrvNormalMs;
        reasons.add(l10n.readinessHrvLow(
          ms(r.hrv7DayMs ?? 0),
          n == null ? '' : ms(n.low),
          n == null ? '' : ms(n.high),
        ));
      case ReadinessFactor.hrvDrop:
        reasons.add(l10n.readinessHrvDrop(ms(r.hrvTodayMs ?? 0)));
      case ReadinessFactor.restingHrHigh || ReadinessFactor.restingHrElevated:
        final today = r.restingHrToday ?? 0;
        final base = r.restingHrBaseline ?? today;
        reasons.add(l10n.readinessRhrUp(
            today.round(), (today - base).round(), base.round()));
      case ReadinessFactor.restingHrSustained:
        reasons.add(l10n.readinessRhrSustained);
      case ReadinessFactor.sleepVeryShort:
        reasons.add(l10n.readinessSleepVeryShort(formatSleep(r.sleepMinutes!)));
      case ReadinessFactor.sleepShort:
        reasons.add(l10n.readinessSleepShort(formatSleep(r.sleepMinutes!)));
      case ReadinessFactor.sleepBelow:
        reasons.add(l10n.readinessSleepBelow(formatSleep(r.sleepMinutes!)));
      case ReadinessFactor.sleepDebt:
        reasons.add(l10n.readinessSleepDebt(formatSleep(r.sleepDebtMinutes)));
    }
  }
  return reasons;
}

String readinessAdviceText(AppLocalizations l10n, ReadinessAdvice a) =>
    switch (a) {
      ReadinessAdvice.train => l10n.readinessAdviceTrain,
      ReadinessAdvice.trainEasy => l10n.readinessAdviceEasy,
      ReadinessAdvice.lighter => l10n.readinessAdviceLighter,
      ReadinessAdvice.rest => l10n.readinessAdviceRest,
    };

/// Tipy na regeneraci podle důvodů.
List<String> readinessTips(AppLocalizations l10n, ReadinessReport r) {
  final f = r.factors.toSet();
  final sleep = f.contains(ReadinessFactor.sleepVeryShort) ||
      f.contains(ReadinessFactor.sleepShort) ||
      f.contains(ReadinessFactor.sleepDebt);
  return [
    if (sleep) l10n.readinessTipShortSleep,
    if (sleep || f.contains(ReadinessFactor.sleepBelow)) l10n.readinessTipSleep,
    if (r.level == ReadinessLevel.low) l10n.readinessTipRecovery,
  ];
}

/// Dnešní plány, které ještě nejsou odcvičené (pro „Lehčí trénink“).
int? _todayPlanId(WidgetRef ref) {
  final plans = ref.watch(plansProvider).valueOrNull ?? const <WorkoutPlan>[];
  final scheduled = ref.watch(scheduledTodayProvider).valueOrNull ??
      const <ScheduledWorkout>[];
  final finished =
      ref.watch(finishedPlanIdsTodayProvider).valueOrNull ?? const <int>{};
  final todayIndex = dayIndexOf(DateTime.now());
  final here = {
    for (final s in scheduled)
      if (s.status == ScheduleStatus.planned) s.planId,
  };
  final removed = {
    for (final s in scheduled)
      if (s.status == ScheduleStatus.moved ||
          s.status == ScheduleStatus.skipped)
        s.planId,
  };
  for (final p in plans) {
    if ((isWeekdayInMask(p.weekdaysMask, todayIndex) || here.contains(p.id)) &&
        !removed.contains(p.id) &&
        !finished.contains(p.id)) {
      return p.id;
    }
  }
  return null;
}

/// Karta na Dnes: připravenost, důvody a doporučení. Při otevření načte
/// nová data z Health (nejvýš jednou za 15 minut).
class ReadinessTodayCard extends ConsumerStatefulWidget {
  const ReadinessTodayCard({super.key});

  @override
  ConsumerState<ReadinessTodayCard> createState() => _ReadinessTodayCardState();
}

class _ReadinessTodayCardState extends ConsumerState<ReadinessTodayCard> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _refresh();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  void _refresh() => RecoverySync.instance.refresh(ref.read(databaseProvider));

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    if (profile == null || !profile.healthReadEnabled) {
      return const SizedBox.shrink();
    }
    final report = ref.watch(readinessProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    if (report == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.watch_outlined),
          title: Text(l10n.readinessTitle),
          subtitle: Text(l10n.readinessNoData),
          onTap: () => context.push('/readiness'),
        ),
      );
    }

    final color = readinessColor(theme, report.level);
    final reasons = readinessReasons(l10n, report);
    final planId =
        report.level == ReadinessLevel.low ? _todayPlanId(ref) : null;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/readiness'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(readinessIcon(report.level), color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.readinessTitle,
                        style: theme.textTheme.titleMedium),
                  ),
                  Text(
                    readinessLevelText(l10n, report.level),
                    style: theme.textTheme.labelLarge?.copyWith(color: color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (reasons.isEmpty && !report.learning)
                Text(l10n.readinessAllGood, style: muted),
              for (final r in reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('• $r', style: muted),
                ),
              if (report.learning)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.readinessLearning(
                        report.baselineDays, kReadinessMinBaselineDays),
                    style: muted,
                  ),
                ),
              const SizedBox(height: 8),
              Text(readinessAdviceText(l10n, report.advice)),
              if (planId != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => startWorkout(context, ref,
                          planId: planId, light: true),
                      icon: const Icon(Icons.spa_outlined),
                      label: Text(l10n.readinessLightButton),
                    ),
                    TextButton(
                      onPressed: () => context.push('/planb?planId=$planId'),
                      child: Text(l10n.fatiguePlanB),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Před tréninkem podle plánu: při slabší regeneraci nabídne lehčí
/// trénink nebo Plán B (module_hub: health:start).
Future<WorkoutStartDecision> readinessStartCheck(
  BuildContext context,
  WidgetRef ref,
  int planId,
) async {
  final report = ref.read(readinessProvider);
  if (report == null || report.level != ReadinessLevel.low) {
    return WorkoutStartDecision.proceed;
  }
  final l10n = AppLocalizations.of(context);
  final reasons = readinessReasons(l10n, report);
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.battery_1_bar),
      title: Text(l10n.readinessLow),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in reasons) Text('• $r'),
            const SizedBox(height: 12),
            Text(readinessAdviceText(l10n, report.advice)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('planB'),
          child: Text(l10n.fatiguePlanB),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop('plan'),
          child: Text(l10n.readinessTrainAsPlanned),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop('light'),
          child: Text(l10n.readinessLightButton),
        ),
      ],
    ),
  );
  switch (choice) {
    case 'light':
      return WorkoutStartDecision.light;
    case 'plan':
      return WorkoutStartDecision.proceed;
    case 'planB':
      if (context.mounted) context.push('/planb?planId=$planId');
      return WorkoutStartDecision.cancel;
    default:
      return WorkoutStartDecision.cancel;
  }
}

/// Detail regenerace: dnešní hodnocení, posledních 14 dní a jak se
/// hodnotí.
class ReadinessScreen extends ConsumerWidget {
  const ReadinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final report = ref.watch(readinessProvider);
    final days = ref.watch(recoveryDaysProvider).valueOrNull ?? const [];
    final last = days.reversed.take(14).toList();
    final source = HealthService.instance.isIOS
        ? l10n.healthSyncIos
        : l10n.healthSyncAndroid;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.readinessScreenTitle)),
      body: RefreshIndicator(
        onRefresh: () => RecoverySync.instance
            .refresh(ref.read(databaseProvider), force: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (report == null)
              Text(l10n.readinessNoData)
            else ...[
              Row(
                children: [
                  Icon(readinessIcon(report.level),
                      color: readinessColor(theme, report.level), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(readinessLevelText(l10n, report.level),
                        style: theme.textTheme.headlineSmall),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final r in readinessReasons(l10n, report)) Text('• $r'),
              if (report.factors.isEmpty && !report.learning)
                Text(l10n.readinessAllGood),
              if (report.learning) ...[
                const SizedBox(height: 4),
                Text(
                    l10n.readinessLearning(
                        report.baselineDays, kReadinessMinBaselineDays),
                    style: muted),
              ],
              const SizedBox(height: 12),
              Text(readinessAdviceText(l10n, report.advice),
                  style: theme.textTheme.bodyLarge),
              for (final tip in readinessTips(l10n, report)) ...[
                const SizedBox(height: 6),
                Text('💡 $tip'),
              ],
              const SizedBox(height: 16),
              _MetricRow(
                label: l10n.readinessHrv,
                value: report.hrv7DayMs == null
                    ? '–'
                    : '${report.hrv7DayMs!.round()} ms',
                normal: report.hrvNormalMs == null
                    ? null
                    : l10n.readinessNormal('${report.hrvNormalMs!.low.round()}–'
                        '${report.hrvNormalMs!.high.round()} ms'),
              ),
              _MetricRow(
                label: l10n.readinessRestingHr,
                value: report.restingHrToday == null
                    ? '–'
                    : '${report.restingHrToday!.round()}',
                normal: report.restingHrBaseline == null
                    ? null
                    : l10n.readinessNormal(
                        '${report.restingHrBaseline!.round()}'),
              ),
              _MetricRow(
                label: l10n.readinessSleep,
                value: report.sleepMinutes == null
                    ? '–'
                    : formatSleep(report.sleepMinutes!),
                normal: l10n.readinessNormal('7+ h'),
              ),
            ],
            const Divider(height: 32),
            Text(l10n.readinessDaysTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {0: FlexColumnWidth(1.4)},
              children: [
                TableRow(children: [
                  const SizedBox.shrink(),
                  Text(l10n.readinessSleep, style: muted),
                  Text(l10n.readinessHrv, style: muted),
                  Text(l10n.readinessRestingHr, style: muted),
                ]),
                for (final d in last)
                  TableRow(children: [
                    Text(MaterialLocalizations.of(context)
                        .formatShortMonthDay(d.day)),
                    Text(d.sleepMinutes == null
                        ? '–'
                        : formatSleep(d.sleepMinutes!)),
                    Text(d.hrvMs == null ? '–' : '${d.hrvMs!.round()}'),
                    Text(d.restingHr == null ? '–' : '${d.restingHr!.round()}'),
                  ]),
              ],
            ),
            const Divider(height: 32),
            Text(l10n.readinessHowTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(l10n.readinessHowBody),
            const SizedBox(height: 12),
            Text(l10n.readinessSourceNote(source), style: muted),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value, this.normal});

  final String label;
  final String value;
  final String? normal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: normal == null ? null : Text(normal!),
      trailing: Text(value, style: theme.textTheme.titleMedium),
    );
  }
}

/// Tep tréninku v souhrnu (průměr, maximum, zóny, energie podle tepu).
class HeartRateSummarySection extends ConsumerWidget {
  const HeartRateSummarySection({super.key, required this.summary});

  final WorkoutSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final session = ref.watch(_sessionProvider(summary.sessionId)).valueOrNull;
    if (session == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final avg = session.avgHeartRate;
    final max = session.maxHeartRate;
    if (avg == null || max == null) {
      // Hodinky do Health zapisují se zpožděním – doplní se při další
      // synchronizaci (karta na Dnes, detail regenerace).
      if (!(profile?.healthReadEnabled ?? false)) {
        return const SizedBox.shrink();
      }
      return ListTile(
        leading: const Icon(Icons.favorite_border),
        title: Text(l10n.hrSummaryTitle),
        subtitle: Text(l10n.hrWaiting),
      );
    }
    final zones = HeartRateSummary.zonesFromText(session.heartRateZones);
    final total = zones.fold(0, (a, b) => a + b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.favorite, color: Colors.redAccent),
          title: Text(l10n.hrSummaryTitle),
          subtitle: Text([
            l10n.hrAvgMax(avg, max),
            if (session.heartRateKcal case final kcal?)
              l10n.hrKcal(formatInt(context, kcal)),
          ].join(' · ')),
        ),
        if (total > 0 && zones.length == 6)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                for (var z = 1; z <= 5; z++)
                  Expanded(
                    child: Column(
                      children: [
                        Text('Z$z', style: theme.textTheme.labelSmall),
                        Text(formatDuration(Duration(seconds: zones[z])),
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

final _sessionProvider =
    StreamProvider.autoDispose.family<WorkoutSession?, int>(
  (ref, id) => ref.watch(databaseProvider).watchSession(id),
);
