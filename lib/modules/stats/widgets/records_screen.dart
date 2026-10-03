import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/format.dart';
import '../../../ui/labels.dart';
import '../../data/units.dart';
import '../stats_providers.dart';
import '../stats_queries.dart';

/// Obrazovka osobních rekordů (route /records).
class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final records = ref.watch(statsRecordsProvider);
    ref.watch(unitSystemProvider); // překreslit po změně kg / lb
    final exercises = ref.watch(statsExerciseMapProvider).valueOrNull;
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.yMMMd(locale);

    Widget body;
    if (records == null || exercises == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final rows = [
        for (final r in records)
          if (exercises[r.exerciseId] case final e?) (record: r, exercise: e),
      ];
      final names = {
        for (final row in rows) row.exercise.id: row.exercise.localizedName(context),
      };
      rows.sort((a, b) => names[a.exercise.id]!
          .toLowerCase()
          .compareTo(names[b.exercise.id]!.toLowerCase()));
      body = rows.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.statsRecordsEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: rows.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final SessionBest r = rows[i].record;
                final Exercise e = rows[i].exercise;
                return ListTile(
                  title: Text(names[e.id]!),
                  subtitle: Text(
                    '${l10n.statsSetWeightReps(formatWeightWithUnit(context, r.weightKg), r.reps)}'
                    ' · ${dateFmt.format(r.date)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.statsKg(formatWeightWithUnit(
                          context,
                          (r.oneRepMax * 10).round() / 10,
                        )),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        l10n.statsE1rmLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => context.push('/exercises/${e.id}'),
                );
              },
            );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsRecordsTitle)),
      body: body,
    );
  }
}

/// Vstup na obrazovku rekordů z obrazovky Pokrok.
class StatsRecordsEntryCard extends ConsumerWidget {
  const StatsRecordsEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final count = ref.watch(statsRecordsProvider)?.length ?? 0;
    return Card(
      child: ListTile(
        leading: Icon(Icons.emoji_events_outlined,
            color: theme.colorScheme.primary),
        title: Text(l10n.statsRecordsTitle),
        subtitle: Text(count == 0
            ? l10n.statsRecordsEmptyShort
            : l10n.statsRecordsCount(count)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/records'),
      ),
    );
  }
}
