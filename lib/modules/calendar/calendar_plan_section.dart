import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/weekdays.dart';
import 'calendar_providers.dart';

/// Sekce v editoru plánu: „Navrhnout čas“ podle volných oken v kalendáři.
class CalendarPlanSection extends ConsumerWidget {
  const CalendarPlanSection({super.key, required this.planId});

  final int planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(calendarReadEnabledProvider)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _SuggestSheet(planId: planId),
        ),
        icon: const Icon(Icons.event_available_outlined),
        label: Text(l10n.calSuggestTime),
      ),
    );
  }
}

class _SuggestSheet extends ConsumerWidget {
  const _SuggestSheet({required this.planId});

  final int planId;

  Future<void> _choose(BuildContext context, WidgetRef ref, int minutes) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final time = formatMinutesOfDay(context, minutes);
    await ref.read(databaseProvider).setPlanTime(planId, minutes);
    if (context.mounted) Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.calSuggestSaved(time))));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plan = ref.watch(planProvider(planId)).valueOrNull;
    final data = ref.watch(planTimeSuggestionsProvider(planId));
    final dayFormat =
        DateFormat.MMMEd(Localizations.localeOf(context).toString());

    Widget body;
    if (plan != null && plan.weekdaysMask == 0) {
      body = Text(l10n.calSuggestNoDays);
    } else {
      body = data.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Text(l10n.calSuggestNoSlots),
        data: (s) {
          if (s.common.isEmpty && s.perDay.every((d) => d.slots.isEmpty)) {
            return Text(l10n.calSuggestNoSlots);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s.common.isNotEmpty) ...[
                Text(l10n.calSuggestAllDays, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in s.common)
                      ActionChip(
                        avatar: const Icon(Icons.star_outline, size: 18),
                        label: Text(formatMinutesOfDay(context, c.minutes)),
                        onPressed: () => _choose(context, ref, c.minutes),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              for (final d in s.perDay) ...[
                Text(dayFormat.format(d.day), style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                if (d.slots.isEmpty)
                  Text(
                    l10n.calSuggestDayBusy,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final slot in d.slots)
                        ActionChip(
                          label: Text(formatMinutesOfDay(
                            context,
                            slot.start.hour * 60 + slot.start.minute,
                          )),
                          onPressed: () => _choose(
                            context,
                            ref,
                            slot.start.hour * 60 + slot.start.minute,
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.calSuggestTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l10n.calSuggestHint,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            body,
          ],
        ),
      ),
    );
  }
}
