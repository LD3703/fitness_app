import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coach_tone.dart';
import '../../core/progressive_overload.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../modules/data/units.dart';
import '../../modules/stats/stats_providers.dart';
import '../../modules/stats/widgets/stats_card.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/labels.dart';
import '../fatigue/fatigue_providers.dart';
import 'overload_providers.dart';

/// Ikona stavu (stav se vždy ukazuje i slovem, nikdy jen barvou).
IconData overloadStatusIcon(OverloadStatus s) => switch (s) {
      OverloadStatus.progressing => Icons.trending_up,
      OverloadStatus.holding => Icons.shield_outlined,
      OverloadStatus.stagnating => Icons.trending_flat,
      OverloadStatus.declining => Icons.trending_down,
      OverloadStatus.insufficientData => Icons.more_horiz,
    };

Color overloadStatusColor(ColorScheme scheme, OverloadStatus s) => switch (s) {
      OverloadStatus.progressing => scheme.primary,
      OverloadStatus.holding => scheme.secondary,
      OverloadStatus.stagnating => scheme.onSurfaceVariant,
      OverloadStatus.declining => scheme.error,
      OverloadStatus.insufficientData => scheme.outline,
    };

String overloadStatusLabel(AppLocalizations l10n, OverloadStatus s) =>
    switch (s) {
      OverloadStatus.progressing => l10n.overloadStatusProgressing,
      OverloadStatus.holding => l10n.overloadStatusHolding,
      OverloadStatus.stagnating => l10n.overloadStatusStagnating,
      OverloadStatus.declining => l10n.overloadStatusDeclining,
      OverloadStatus.insufficientData => l10n.overloadStatusInsufficient,
    };

/// „+8“, „−12“, „0“ (procenta bez znaku %; ten je v překladu).
String formatSignedPercent(BuildContext context, double percent) {
  final rounded = percent.abs() < 1
      ? (percent * 10).round() / 10
      : percent.roundToDouble();
  if (rounded == 0) return formatDecimal(context, 0);
  final text = formatDecimal(context, rounded.abs(), maxDecimals: 1);
  return rounded > 0 ? '+$text' : '−$text';
}

/// „Bench press: 1RM +3 %“ / „Objem +8 %“.
String overloadReasonText(
  BuildContext context,
  OverloadReason reason,
  Map<int, Exercise> exercises,
) {
  final l10n = AppLocalizations.of(context);
  final change = formatSignedPercent(context, reason.percent);
  switch (reason.kind) {
    case OverloadReasonKind.oneRepMax:
      final exercise = exercises[reason.exerciseId];
      return l10n.overloadReasonOneRepMax(
        exercise?.localizedName(context) ?? l10n.statsUnknownExercise,
        change,
      );
    case OverloadReasonKind.volume:
      return l10n.overloadReasonVolume(change);
  }
}

/// Text tipu při stagnaci (váha podle jednotek: 2,5 kg / 5 lb).
/// [strict] = přísný trenér (jen když je dovolený, viz core/coach_tone.dart).
String overloadTipText(
  BuildContext context,
  OverloadTip tip, {
  bool strict = false,
}) {
  final l10n = AppLocalizations.of(context);
  final weight =
      '${formatDecimal(context, weightDisplayStep, maxDecimals: 1)} $weightUnit';
  if (strict) {
    return switch (tip) {
      OverloadTip.addReps => l10n.coachTipAddReps,
      OverloadTip.addSet => l10n.coachTipAddSet,
      OverloadTip.addWeight => l10n.coachTipAddWeight(weight),
    };
  }
  return switch (tip) {
    OverloadTip.addReps => l10n.overloadTipAddReps,
    OverloadTip.addSet => l10n.overloadTipAddSet,
    OverloadTip.addWeight => l10n.overloadTipAddWeight(weight),
  };
}

/// Karta „Progresivní přetížení“ na obrazovce Pokrok (overload:progress).
class OverloadProgressCard extends ConsumerWidget {
  const OverloadProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(overloadHistoryProvider);
    if (history == null) return const SizedBox.shrink();
    ref.watch(unitSystemProvider); // překreslit po změně kg / lb
    final exercises =
        ref.watch(statsExerciseMapProvider).valueOrNull ?? const <int, Exercise>{};
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final current = currentOverload(history);
    final rated = [
      for (final g in current)
        if (!g.excused && g.status != OverloadStatus.insufficientData) g,
    ];
    final waiting = [
      for (final g in current)
        if (!g.excused && g.status == OverloadStatus.insufficientData)
          l10n.muscleGroup(g.group),
    ];
    final excused = [
      for (final g in current)
        if (g.excused) l10n.muscleGroup(g.group),
    ];
    final tips = [
      for (final g in rated)
        if (g.tip != null) g,
    ];
    // Přísný tón tipů jen ve zdravé situaci a bez velké únavy (dokud se
    // únava nenačte, přátelský).
    final fatigue = tips.isEmpty ? null : ref.watch(fatigueProvider).valueOrNull;
    final strictTips = fatigue != null &&
        effectiveCoachTone(
              coachToneOf(ref.watch(profileProvider).valueOrNull?.coachTone),
              ref.watch(situationProvider),
              maxFatigue: maxFatiguePercent(fatigue),
            ) ==
            CoachTone.strict;

    return StatsCard(
      title: l10n.overloadTitle,
      subtitle: l10n.overloadHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rated.isEmpty)
            StatsEmpty(l10n.overloadNoData)
          else
            for (final g in rated)
              _GroupRow(result: g, exercises: exercises),
          if (tips.isNotEmpty) ...[
            StatsSubheading(l10n.overloadTipsTitle),
            for (final g in tips) _TipRow(result: g, strict: strictTips),
          ],
          if (waiting.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l10n.overloadWaitingGroups(waiting.join(', ')), style: muted),
          ],
          if (excused.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(l10n.overloadExcusedGroups(excused.join(', ')), style: muted),
          ],
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.result, required this.exercises});

  final GroupOverload result;
  final Map<int, Exercise> exercises;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = overloadStatusColor(theme.colorScheme, result.status);
    final reasons = [
      for (final r in result.reasons) overloadReasonText(context, r, exercises),
      if (result.status == OverloadStatus.holding) l10n.overloadHoldingCut,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(overloadStatusIcon(result.status), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.muscleGroup(result.group),
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        overloadStatusLabel(l10n, result.status),
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: color),
                      ),
                    ),
                  ],
                ),
                if (reasons.isNotEmpty)
                  Text(
                    reasons.join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.result, this.strict = false});

  final GroupOverload result;
  final bool strict;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tip = result.tip;
    if (tip == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: theme.colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.overloadStagnantFor(
                    l10n.muscleGroup(result.group),
                    result.stagnantWeeks,
                  ),
                  style: theme.textTheme.titleSmall,
                ),
                Text(overloadTipText(context, tip, strict: strict)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
