import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../l10n/app_localizations.dart';
import 'body_map.dart';
import 'labels.dart';

/// Vodorovný pruh partií s postavičkou a zvýrazněnou partií (knihovna
/// cviků, výběr cviku). První dlaždice „Vše“ filtr zruší.
class MuscleGroupStrip extends StatelessWidget {
  const MuscleGroupStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// Vybraná partie (null = vše).
  final MuscleGroup? selected;
  final ValueChanged<MuscleGroup?> onSelected;

  static const _tile = 64.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: _tile + 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _GroupTile(
            label: l10n.filterAll,
            selected: selected == null,
            onTap: () => onSelected(null),
            icon: const MuscleIcon(
              focus: MuscleGroup.fullBody,
              sets: (primary: <MuscleGroup>{}, secondary: <MuscleGroup>{}),
              size: _tile,
            ),
          ),
          for (final g in muscleGroupsUiOrder)
            _GroupTile(
              label: l10n.muscleGroup(g),
              selected: selected == g,
              // Druhé klepnutí na vybranou partii filtr zruší.
              onTap: () => onSelected(selected == g ? null : g),
              icon: MuscleIcon(
                focus: g,
                sets: muscleGroupHighlight(g),
                size: _tile,
              ),
            ),
        ],
      ),
    );
  }
}

/// Zvýraznění partie na postavičce: souhrnná partie (nohy) i s dílčími,
/// celé tělo vším.
MuscleSets muscleGroupHighlight(MuscleGroup g) => (
      primary: g == MuscleGroup.fullBody
          ? MuscleGroup.values.toSet()
          : {g, ...g.specific},
      secondary: <MuscleGroup>{},
    );

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: SizedBox(
            width: MuscleGroupStrip._tile + 8,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: selected ? scheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: icon,
                ),
                const SizedBox(height: 4),
                ExcludeSemantics(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected ? scheme.primary : null,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Položka seznamu cviků rozděleného podle partií: nadpis partie, nebo cvik.
typedef ExerciseListEntry = ({MuscleGroup? header, Exercise? exercise});

/// Cviky seřazené podle partií (pořadí jako v pruhu) a uvnitř podle názvu;
/// s nadpisem před každou partií, když [withHeaders].
List<ExerciseListEntry> exerciseListEntries(
  BuildContext context,
  List<Exercise> list, {
  required bool withHeaders,
}) {
  int order(MuscleGroup g) {
    final i = muscleGroupsUiOrder.indexOf(g);
    return i < 0 ? muscleGroupsUiOrder.length : i;
  }

  String name(Exercise e) => e.localizedName(context).toLowerCase();
  final sorted = [...list]..sort((a, b) {
      if (withHeaders) {
        final c = order(a.muscleGroup).compareTo(order(b.muscleGroup));
        if (c != 0) return c;
      }
      return name(a).compareTo(name(b));
    });
  final result = <ExerciseListEntry>[];
  MuscleGroup? current;
  for (final e in sorted) {
    if (withHeaders && (result.isEmpty || e.muscleGroup != current)) {
      current = e.muscleGroup;
      result.add((header: current, exercise: null));
    }
    result.add((header: null, exercise: e));
  }
  return result;
}

/// Nadpis partie v seznamu cviků.
class ExerciseGroupHeader extends StatelessWidget {
  const ExerciseGroupHeader({super.key, required this.group});

  final MuscleGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        AppLocalizations.of(context).muscleGroup(group),
        style: theme.textTheme.titleSmall
            ?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}
