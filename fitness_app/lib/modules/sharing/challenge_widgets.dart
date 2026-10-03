import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../features/workout/workout_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/labels.dart';
import '../data/units.dart';
import '../links/deep_links.dart';
import 'challenge_progress.dart';
import 'challenge_service.dart';
import 'share_service.dart';

/// Název cíle výzvy (cvik / počet tréninků / voda).
String challengeTitle(BuildContext context, ChallengeView v) {
  final l10n = AppLocalizations.of(context);
  final c = v.challenge;
  return switch (c.kind) {
    ChallengeKind.beatRecord => v.exercise?.localizedName(context) ??
        (c.exerciseSlug != null && c.exerciseSlug!.isNotEmpty
            ? humanizeSlug(c.exerciseSlug!)
            : l10n.shareUnknownExercise),
    ChallengeKind.workoutsInMonth => l10n.shareKindWorkouts,
    ChallengeKind.weeklyWater => l10n.shareKindWater,
  };
}

/// „80 / 100 kg“, „5 / 12“, „6 500 / 14 000 ml“.
String challengeProgressText(BuildContext context, ChallengeView v) {
  final l10n = AppLocalizations.of(context);
  final p = v.progress;
  return switch (v.challenge.kind) {
    ChallengeKind.beatRecord => l10n.shareProgressKg(
        formatWeightWithUnit(context, p.current), formatWeightWithUnit(context, p.target)),
    ChallengeKind.workoutsInMonth => l10n.shareProgressCount(
        formatInt(context, p.current), formatInt(context, p.target)),
    ChallengeKind.weeklyWater => l10n.shareProgressMl(
        formatVolume(context, p.current), formatVolume(context, p.target)),
  };
}

/// Text ke sdílení splněné výzvy. Voda se nesdílí (soukromí) → null.
String? completedShareText(BuildContext context, ChallengeView v) {
  final l10n = AppLocalizations.of(context);
  final c = v.challenge;
  final from = c.fromName;
  return switch (c.kind) {
    ChallengeKind.beatRecord => from == null || from.isEmpty
        ? l10n.shareCompletedRecord(challengeTitle(context, v),
            formatWeightWithUnit(context, v.progress.current), kWebBaseUrl)
        : l10n.shareCompletedRecordFrom(from, challengeTitle(context, v),
            formatWeightWithUnit(context, v.progress.current), kWebBaseUrl),
    ChallengeKind.workoutsInMonth =>
      l10n.shareCompletedWorkouts(v.progress.current.round(), kWebBaseUrl),
    ChallengeKind.weeklyWater => null,
  };
}

/// Karta výzev na obrazovce Dnes (sharing:today).
class ChallengesTodayCard extends ConsumerWidget {
  const ChallengesTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(todayChallengesProvider).valueOrNull ??
        const <ChallengeView>[];
    if (items.isEmpty) return const SizedBox.shrink();
    ref.watch(unitSystemProvider); // překreslit po změně kg / lb
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_kabaddi, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.shareChallengesTitle,
                    style: theme.textTheme.titleMedium),
              ],
            ),
            for (final v in items) _ChallengeTile(view: v),
          ],
        ),
      ),
    );
  }
}

enum _TileAction { share, hide }

class _ChallengeTile extends ConsumerWidget {
  const _ChallengeTile({required this.view});

  final ChallengeView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = view.challenge;
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final status = switch (view.state) {
      ChallengeState.completed => l10n.shareStatusCompleted,
      ChallengeState.expired => l10n.shareStatusExpired,
      _ => switch (daysLeft(c.deadline, DateTime.now())) {
          null => null,
          final int d => l10n.shareDaysLeft(d < 0 ? 0 : d),
        },
    };
    final from = c.fromName;
    final details = [
      if (from != null && from.isNotEmpty) l10n.shareFrom(from),
      if (status != null) status,
    ].join(' · ');
    final shareMessage = view.state == ChallengeState.completed
        ? completedShareText(context, view)
        : null;
    final expired = view.state == ChallengeState.expired;
    final completed = view.state == ChallengeState.completed;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        challengeTitle(context, view),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Text(challengeProgressText(context, view),
                        style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: view.progress.fraction,
                  minHeight: 6,
                  color: completed
                      ? theme.colorScheme.tertiary
                      : expired
                          ? theme.colorScheme.outline
                          : null,
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(details, style: muted),
                ],
              ],
            ),
          ),
          Builder(
            builder: (menuContext) => PopupMenuButton<_TileAction>(
              tooltip: l10n.shareMoreActions,
              onSelected: (a) {
                switch (a) {
                  case _TileAction.share:
                    if (shareMessage case final String text) {
                      shareText(menuContext, text);
                    }
                  case _TileAction.hide:
                    hideChallenge(ref.read(databaseProvider), c.id);
                }
              },
              itemBuilder: (context) => [
                if (shareMessage != null)
                  PopupMenuItem(
                    value: _TileAction.share,
                    child: Text(l10n.shareAction),
                  ),
                PopupMenuItem(
                  value: _TileAction.hide,
                  child: Text(l10n.shareHide),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sekce „Výzva splněna! 🎉“ v souhrnu po tréninku (sharing:summary).
class CompletedChallengesSection extends ConsumerWidget {
  const CompletedChallengesSection({super.key, required this.summary});

  final WorkoutSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(completedSinceProvider(summary.startedAt)).valueOrNull ??
            const <ChallengeView>[];
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.shareChallengeCompletedTitle,
              style: theme.textTheme.titleMedium),
          for (final v in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.celebration,
                  color: theme.colorScheme.tertiary),
              title: Text(challengeTitle(context, v)),
              subtitle: Text([
                challengeProgressText(context, v),
                if (v.challenge.fromName case final f? when f.isNotEmpty)
                  l10n.shareFrom(f),
              ].join(' · ')),
              trailing: switch (completedShareText(context, v)) {
                null => null,
                final String text => Builder(
                    builder: (buttonContext) => IconButton(
                      tooltip: l10n.shareAction,
                      icon: const Icon(Icons.ios_share),
                      onPressed: () => shareText(buttonContext, text),
                    ),
                  ),
              },
            ),
        ],
      ),
    );
  }
}
