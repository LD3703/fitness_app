import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../features/workout/workout_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/labels.dart';
import '../data/units.dart';
import '../links/deep_links.dart';
import 'challenge_link.dart';
import 'challenge_progress.dart';
import 'share_cards.dart';
import 'share_service.dart';
import 'sharing_queries.dart';

/// Kolik dní má kamarád na překonání výzvy.
const kChallengeDefaultDays = 30;

void _showError(BuildContext context) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).shareFailed)),
  );
}

/// Sdílí kartu osobního rekordu cviku (náhled → obrázek + text).
Future<void> shareRecord(
  BuildContext context,
  WidgetRef ref,
  Exercise exercise,
) async {
  final db = ref.read(databaseProvider);
  final record = await db.exerciseRecord(exercise.id);
  if (!context.mounted) return;
  if (record == null) {
    _showError(context);
    return;
  }
  final l10n = AppLocalizations.of(context);
  final name = exercise.localizedName(context);
  final data = RecordCardData(
    exerciseName: name,
    weightKg: record.weightKg,
    reps: record.reps,
    oneRepMax: record.oneRepMax,
    date: record.date,
  );
  await showShareCardPreview(
    context,
    card: RecordShareCard(data: data),
    fileName: 'record_${exercise.id}',
    text: l10n.shareRecordText(
      name,
      formatWeightWithUnit(context, record.weightKg),
      record.reps,
      formatWeightWithUnit(context, record.oneRepMax),
      kWebBaseUrl,
    ),
  );
}

/// Sdílí kartu dokončeného tréninku.
Future<void> shareWorkout(
  BuildContext context,
  WidgetRef ref,
  WorkoutSummary summary,
) async {
  final db = ref.read(databaseProvider);
  final exercises = await db.sessionExercises(summary.sessionId);
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final data = WorkoutCardData(
    date: summary.startedAt,
    duration: summary.duration,
    setCount: summary.setCount,
    volumeKg: summary.volumeKg,
    recordCount: summary.records.length,
    exerciseNames: [for (final e in exercises) e.localizedName(context)],
  );
  await showShareCardPreview(
    context,
    card: WorkoutShareCard(data: data),
    fileName: 'workout_${summary.sessionId}',
    text: l10n.shareWorkoutText(
      summary.setCount,
      formatWeightTotal(context, summary.volumeKg),
      formatDuration(summary.duration),
      kWebBaseUrl,
    ),
  );
}

/// Pošle výzvu odkazem: „Dal jsem 100 kg na bench. Překonáš mě?“
Future<void> challengeFriend(
  BuildContext context,
  WidgetRef ref,
  Exercise exercise,
) async {
  final db = ref.read(databaseProvider);
  final record = await db.exerciseRecord(exercise.id);
  final profile = await ref.read(profileProvider.future);
  if (!context.mounted) return;
  if (record == null) {
    _showError(context);
    return;
  }
  final l10n = AppLocalizations.of(context);
  final name = exercise.localizedName(context);
  final now = DateTime.now();
  final deadline =
      DateTime(now.year, now.month, now.day + kChallengeDefaultDays);
  final slug = exercise.slug;
  final link = ChallengeLink(
    exercise: slug ?? '${exercise.id}',
    exerciseName: slug == null ? name : null,
    value: roundToHalf(record.oneRepMax),
    fromName: profile.name?.trim(),
    deadline: deadline,
  );
  final locale = Localizations.localeOf(context).toString();
  await shareText(
    context,
    l10n.shareChallengeText(
      name,
      formatWeightWithUnit(context, record.weightKg),
      record.reps,
      formatWeightWithUnit(context, link.value),
      DateFormat.yMMMd(locale).format(deadline),
      link.toWebUrl(kWebBaseUrl),
    ),
  );
}

/// Dvojice tlačítek „Sdílet rekord“ + „Vyzvat kamaráda“.
class RecordShareButtons extends ConsumerWidget {
  const RecordShareButtons({
    super.key,
    required this.exercise,
    this.shareLabel,
  });

  final Exercise exercise;

  /// Popisek tlačítka sdílení (výchozí „Sdílet rekord“).
  final String? shareLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        OutlinedButton.icon(
          onPressed: () => shareRecord(context, ref, exercise),
          icon: const Icon(Icons.ios_share, size: 18),
          label: Text(shareLabel ?? l10n.shareRecordButton),
        ),
        Builder(
          builder: (buttonContext) => TextButton.icon(
            onPressed: () => challengeFriend(buttonContext, ref, exercise),
            icon: const Icon(Icons.sports_kabaddi, size: 18),
            label: Text(l10n.shareChallengeButton),
          ),
        ),
      ],
    );
  }
}

/// Tlačítka sdílení v souhrnu po tréninku (sharing:summary).
class SharingSummaryActions extends ConsumerWidget {
  const SharingSummaryActions({super.key, required this.summary});

  final WorkoutSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (summary.setCount > 0)
            FilledButton.tonalIcon(
              onPressed: () => shareWorkout(context, ref, summary),
              icon: const Icon(Icons.ios_share),
              label: Text(l10n.shareWorkoutButton),
            ),
          for (final r in summary.records) ...[
            const SizedBox(height: 8),
            Text(
              r.exercise.localizedName(context),
              style: theme.textTheme.labelLarge,
            ),
            RecordShareButtons(exercise: r.exercise),
          ],
        ],
      ),
    );
  }
}

/// Sekce v detailu cviku: můj rekord + sdílení a výzva (sharing:exercise).
class ExerciseShareSection extends ConsumerWidget {
  const ExerciseShareSection({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record =
        ref.watch(exerciseStatsProvider(exercise.id)).valueOrNull?.record;
    if (record == null) return const SizedBox.shrink();
    ref.watch(unitSystemProvider); // překreslit po změně kg / lb
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.shareMyRecordTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.emoji_events, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.shareRecordValue(
                  formatWeightWithUnit(context, record.weightKg),
                  record.reps,
                  formatWeightWithUnit(context, record.oneRepMax),
                )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RecordShareButtons(
            exercise: exercise,
            shareLabel: l10n.shareMyRecordButton,
          ),
        ],
      ),
    );
  }
}
