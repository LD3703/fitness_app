import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/weekdays.dart';
import 'calendar_providers.dart';

/// Karta na obrazovce Dnes: upozorní, když se dnešní trénink kryje
/// s událostí v kalendáři, a navrhne nejbližší volný čas. Bez kolize
/// se nezobrazí.
class CalendarTodayCard extends ConsumerStatefulWidget {
  const CalendarTodayCard({super.key});

  @override
  ConsumerState<CalendarTodayCard> createState() => _CalendarTodayCardState();
}

class _CalendarTodayCardState extends ConsumerState<CalendarTodayCard> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Kalendář se mohl mezitím změnit v jiné aplikaci.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(calendarTodayConflictsProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  int _minutesOf(DateTime t) => t.hour * 60 + t.minute;

  @override
  Widget build(BuildContext context) {
    final conflicts =
        ref.watch(calendarTodayConflictsProvider).valueOrNull ?? const [];
    if (conflicts.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final children = <Widget>[
      Row(
        children: [
          Icon(Icons.event_busy_outlined, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l10n.calTodayTitle, style: theme.textTheme.titleMedium),
          ),
        ],
      ),
      const SizedBox(height: 8),
    ];

    for (final c in conflicts) {
      final eventTime = formatMinutesOfDay(context, _minutesOf(c.event.start));
      final workoutTime =
          formatMinutesOfDay(context, c.plan.plannedTimeMinutes ?? 0);
      children.add(Text(l10n.calTodayCollision(
        eventTime,
        c.event.title,
        c.plan.name,
        workoutTime,
      )));
      final freeAt = c.freeAt;
      if (freeAt != null) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            l10n.calTodayFreeAt(formatMinutesOfDay(context, _minutesOf(freeAt))),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ));
      } else {
        children.addAll([
          const SizedBox(height: 4),
          Text(
            l10n.calTodayNoFreeTime,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final text = l10n.calMovedTomorrow(c.plan.name);
                await ref
                    .read(databaseProvider)
                    .postponePlan(c.plan.id, startOfDay(DateTime.now()));
                messenger.showSnackBar(SnackBar(content: Text(text)));
              },
              icon: const Icon(Icons.redo),
              label: Text(l10n.calMoveTomorrow),
            ),
          ),
        ]);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
