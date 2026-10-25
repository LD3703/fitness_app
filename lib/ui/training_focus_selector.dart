import 'package:flutter/material.dart';

import '../data/enums.dart';
import '../l10n/app_localizations.dart';
import 'labels.dart';

/// Volba cíle / zaměření tréninku: síla / svaly / výdrž, pod ní krátké
/// vysvětlení. Obrazovka tréninku, úvod, profil, editor plánu a přidání
/// programu.
class TrainingFocusSelector extends StatelessWidget {
  const TrainingFocusSelector({
    super.key,
    required this.focus,
    required this.onChanged,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 4),
    this.goalHints = false,
  });

  final TrainingFocus focus;
  final ValueChanged<TrainingFocus> onChanged;
  final EdgeInsetsGeometry padding;

  /// Vysvětlení cíle (co se podle něj nastaví) místo vysvětlení pauz.
  final bool goalHints;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<TrainingFocus>(
            showSelectedIcon: false,
            segments: [
              for (final f in TrainingFocus.values)
                ButtonSegment(
                  value: f,
                  label: Text(
                    l10n.trainingFocus(f),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            selected: {focus},
            onSelectionChanged: (v) => onChanged(v.first),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              goalHints
                  ? l10n.trainingGoalHint(focus)
                  : l10n.trainingFocusHint(focus),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
