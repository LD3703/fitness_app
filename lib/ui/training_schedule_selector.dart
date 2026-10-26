import 'package:flutter/material.dart';

import '../data/seed/program_fit.dart';
import '../l10n/app_localizations.dart';

/// Kolikrát týdně a jak dlouho trénovat (úvod a profil). Podle toho se
/// doporučují a zkracují hotové programy (data/seed/program_fit.dart).
class TrainingScheduleSelector extends StatelessWidget {
  const TrainingScheduleSelector({
    super.key,
    required this.daysPerWeek,
    required this.minutes,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  final int daysPerWeek;
  final int minutes;
  final void Function(int daysPerWeek, int minutes) onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.scheduleDaysTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in kDaysPerWeekOptions)
                ChoiceChip(
                  label: Text('$d×'),
                  selected: daysPerWeek == d,
                  onSelected: (_) => onChanged(d, minutes),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.scheduleDaysHint,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(l10n.scheduleMinutesTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in kSessionMinuteOptions)
                ChoiceChip(
                  label: Text(l10n.calMinutes(m)),
                  selected: minutes == m,
                  onSelected: (_) => onChanged(daysPerWeek, m),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
