import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auto_progression.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../premium/premium.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../data/units.dart';
import 'progression_format.dart';
import 'progression_queries.dart';
import 'progression_service.dart';

// ---------------------------------------------------------------------
// Štítek nepoužitého návrhu v editoru plánu
// ---------------------------------------------------------------------

/// „↑ +2,5 kg příště“ u cviku v editoru plánu, když čeká nepoužitý návrh.
/// Klepnutím se dá návrh použít nebo zahodit. Bez Premium
/// (autoProgression) se neukazuje.
class ProgressionPlanBadge extends ConsumerWidget {
  const ProgressionPlanBadge({
    super.key,
    required this.planId,
    required this.planExerciseId,
  });

  final int planId;
  final int planExerciseId;

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    ProgressionEvent event,
  ) async {
    final l10n = AppLocalizations.of(context);
    final db = ref.read(databaseProvider);
    final apply = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.progressionPendingTitle),
        content: Text(progressionEventText(context, event)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.progressionKeepCurrent),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.progressionApply),
          ),
        ],
      ),
    );
    if (apply == null) return;
    if (!apply) {
      await db.discardProgressionEvents([event.id]);
      return;
    }
    final ok = await db.applyProgressionEvent(event.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(ok ? l10n.progressionApplied : l10n.progressionStale),
        action: ok
            ? SnackBarAction(
                label: l10n.undo,
                onPressed: () => db.undoProgressionEvent(event.id),
              )
            : null,
      ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(premiumProvider
        .select((a) => a.isPremium(PremiumFeature.autoProgression)));
    if (!allowed) return const SizedBox.shrink();
    final event =
        ref.watch(pendingProgressionProvider(planId)).valueOrNull?[planExerciseId];
    if (event == null) return const SizedBox.shrink();
    ref.watch(unitSystemProvider); // překreslit po změně kg / lb
    final text = progressionBadgeText(context, event);
    if (text == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final down = event.kind == ProgressionKind.deload;
    final background = down ? scheme.secondaryContainer : scheme.primaryContainer;
    final foreground =
        down ? scheme.onSecondaryContainer : scheme.onPrimaryContainer;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _open(context, ref, event),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                text,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Nastavení progrese v editoru cviku plánu
// ---------------------------------------------------------------------

/// Stav polí nastavení progrese (drží ho editor cviku, ukládá se spolu
/// se sériemi).
class ProgressionItemSettings {
  ProgressionItemSettings.fromItem(PlanExercise item)
      : auto = item.autoProgression,
        customIncrement = item.progressionIncrementKg != null,
        repRangeMin = TextEditingController(text: item.repRangeMin?.toString()),
        repRangeMax = TextEditingController(text: item.repRangeMax?.toString()),
        increment = TextEditingController(
          text: weightInputText(item.progressionIncrementKg),
        );

  bool auto;
  bool customIncrement;
  final TextEditingController repRangeMin;
  final TextEditingController repRangeMax;

  /// Vlastní přírůstek v zobrazovaných jednotkách (kg / lb).
  final TextEditingController increment;

  /// Hodnoty k uložení, nebo null při neplatném vstupu.
  ProgressionItemSettingsValue? collect() {
    int? parse(TextEditingController c) {
      final t = c.text.trim();
      if (t.isEmpty) return null;
      return int.tryParse(t) ?? -1;
    }

    bool invalid(int? v) => v != null && (v < 1 || v > 100);
    final lo = parse(repRangeMin);
    final hi = parse(repRangeMax);
    if (invalid(lo) || invalid(hi)) return null;
    if (lo != null && hi != null && lo > hi) return null;
    double? incrementKg;
    if (customIncrement) {
      incrementKg = parseWeightInput(increment.text);
      if (incrementKg == null || incrementKg <= 0 || incrementKg > 50) {
        return null;
      }
    }
    return (
      auto: auto,
      repRangeMin: lo,
      repRangeMax: hi,
      incrementKg: incrementKg,
    );
  }

  void dispose() {
    repRangeMin.dispose();
    repRangeMax.dispose();
    increment.dispose();
  }
}

/// Sekce „Automatická progrese“ v editoru cviku plánu: přepínač, rozsah
/// opakování, přírůstek (automaticky / vlastní) a poslední změna.
/// Bez Premium (autoProgression) jen nadpis a zamčený řádek; uložené
/// hodnoty se nemění.
class ProgressionItemSettingsSection extends ConsumerStatefulWidget {
  const ProgressionItemSettingsSection({
    super.key,
    required this.settings,
    required this.exercise,
    required this.planExerciseId,
    required this.firstWorkingReps,
    required this.onChanged,
  });

  final ProgressionItemSettings settings;
  final Exercise exercise;
  final int planExerciseId;

  /// Cílová opakování první pracovní série (pro výchozí rozsah).
  final int? firstWorkingReps;
  final VoidCallback onChanged;

  @override
  ConsumerState<ProgressionItemSettingsSection> createState() =>
      _ProgressionItemSettingsSectionState();
}

class _ProgressionItemSettingsSectionState
    extends ConsumerState<ProgressionItemSettingsSection> {
  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final allowed = ref.watch(premiumProvider
        .select((a) => a.isPremium(PremiumFeature.autoProgression)));
    if (!allowed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Text(l10n.progressionSectionTitle,
                style: theme.textTheme.titleSmall),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: PremiumLockedPlaceholder(
              feature: PremiumFeature.autoProgression,
              compact: true,
            ),
          ),
        ],
      );
    }
    final s = widget.settings;
    final exercise = widget.exercise;
    final unit = ref.watch(unitSystemProvider);
    final last =
        ref.watch(lastProgressionEventProvider(widget.planExerciseId)).valueOrNull;
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final derived = defaultRepRange(widget.firstWorkingReps ?? 10);
    final autoIncrement = defaultIncrementKg(
      group: exercise.muscleGroup,
      equipment: exercise.equipment,
      slug: exercise.slug,
      unit: unit,
    );
    final locale = Localizations.localeOf(context).toString();

    Widget rangeField(TextEditingController c, String label, int hint) =>
        Expanded(
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              labelText: label,
              hintText: '$hint',
            ),
            onChanged: (_) => widget.onChanged(),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Text(l10n.progressionSectionTitle,
              style: theme.textTheme.titleSmall),
        ),
        SwitchListTile(
          title: Text(l10n.progressionAutoSwitch),
          subtitle: Text(l10n.progressionAutoSwitchHint),
          value: s.auto,
          onChanged: (v) => _update(() => s.auto = v),
        ),
        if (s.auto)
          switch (exercise.type) {
            ExerciseType.weightReps => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.progressionRepRange,
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        rangeField(s.repRangeMin, l10n.progressionRepRangeMin,
                            derived.min),
                        const SizedBox(width: 12),
                        rangeField(s.repRangeMax, l10n.progressionRepRangeMax,
                            derived.max),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.progressionRepRangeHint(derived.min, derived.max),
                      style: muted,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.progressionIncrementTitle,
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.progressionIncrementAuto(
                            formatWeightWithUnit(context, autoIncrement),
                          )),
                          selected: !s.customIncrement,
                          onSelected: (_) =>
                              _update(() => s.customIncrement = false),
                        ),
                        ChoiceChip(
                          label: Text(l10n.progressionIncrementCustom),
                          selected: s.customIncrement,
                          onSelected: (_) => _update(() {
                            s.customIncrement = true;
                            if (s.increment.text.trim().isEmpty) {
                              s.increment.text = weightInputText(autoIncrement);
                            }
                          }),
                        ),
                      ],
                    ),
                    if (s.customIncrement)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: TextField(
                          controller: s.increment,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]')),
                          ],
                          decoration: InputDecoration(
                            isDense: true,
                            labelText:
                                l10n.progressionIncrementLabel(weightUnit),
                          ),
                          onChanged: (_) => widget.onChanged(),
                        ),
                      ),
                  ],
                ),
              ),
            ExerciseType.bodyweightReps => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.progressionBodyweightHint, style: muted),
              ),
            ExerciseType.duration => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.progressionDurationHint(durationIncrementSeconds),
                  style: muted,
                ),
              ),
          },
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            last == null
                ? l10n.progressionNoChanges
                : l10n.progressionLastChange(
                    progressionEventText(context, last),
                    DateFormat.MMMd(locale).format(last.createdAt),
                  ),
            style: muted,
          ),
        ),
      ],
    );
  }
}
