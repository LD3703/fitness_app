import 'package:flutter/widgets.dart';

import '../core/formulas.dart';
import '../data/database.dart';
import '../l10n/app_localizations.dart';
import 'format.dart';

/// Stručný popis sérií plánu: „R 15 @ 40 kg · 3 × 10 @ 60 kg“ (nebo lb).
String describePlanSets(
  BuildContext context,
  Iterable<({int reps, double? weightKg, bool isWarmup})> sets, {
  required bool isDuration,
}) {
  final l10n = AppLocalizations.of(context);
  final parts = <String>[];
  for (final g in groupSets(sets)) {
    final value = isDuration ? '${g.reps} s' : '${g.reps}';
    final base = g.count > 1 ? '${g.count} × $value' : value;
    final weight = g.weightKg == null || isDuration
        ? ''
        : ' @ ${formatWeightWithUnit(context, g.weightKg!)}';
    final prefix = g.isWarmup ? '${l10n.setWarmupShort} ' : '';
    parts.add('$prefix$base$weight');
  }
  return parts.join(' · ');
}

/// Popis série z tréninku: „60 × 10“, „10×“ (bez váhy), „30 s“.
String describeDoneSet(BuildContext context, SetEntry s) {
  if (s.durationSeconds != null) return '${s.durationSeconds} s';
  final w = s.weightKg;
  final reps = s.reps ?? 0;
  return w == null ? '$reps×' : '${formatWeight(context, w)} × $reps';
}

/// „Rekord: 1RM ≈ 85 kg (75 kg × 5)“.
String describeRecord(BuildContext context, ExerciseRecord r) {
  final l10n = AppLocalizations.of(context);
  return l10n.dataRecordLine(
    formatWeightWithUnit(context, r.oneRepMax, rounded: true),
    formatWeightWithUnit(context, r.weightKg),
    r.reps,
  );
}

/// „Minule: 40 × 15 · 60 × 10“.
String describeLastSets(BuildContext context, List<SetEntry> sets) {
  final l10n = AppLocalizations.of(context);
  return l10n.lastTimeLine(
    sets.map((s) => describeDoneSet(context, s)).join(' · '),
  );
}
