import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../social_logic.dart';
import '../social_models.dart';
import '../social_service.dart';
import 'social_ui.dart';

enum _Metric { workouts, volume }

/// Žebříček mezi přáteli (jen přátelé, žádný veřejný žebříček).
class LeaderboardTab extends ConsumerStatefulWidget {
  const LeaderboardTab({super.key});

  @override
  ConsumerState<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<LeaderboardTab> {
  _Metric _metric = _Metric.workouts;

  double? _value(FriendProfile p, DateTime now) => switch (_metric) {
        _Metric.workouts =>
          p.shareStats ? p.workoutsIn(monthKey(now))?.toDouble() : null,
        _Metric.volume => p.shareStats ? p.volumeIn(isoWeekKey(now)) : null,
      };

  String _format(BuildContext context, double v) => switch (_metric) {
        _Metric.workouts => socialNumber(context, v, pattern: '0'),
        _Metric.volume => socialKg(context, v.roundToDouble()),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final me = ref.watch(socialMeProvider).valueOrNull;
    final friends =
        ref.watch(socialFriendProfilesProvider).valueOrNull ?? const [];
    final now = DateTime.now();
    final everyone = [if (me != null) me, ...friends];
    final ranked = rankBy<FriendProfile>(everyone, (p) => _value(p, now));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<_Metric>(
            segments: [
              ButtonSegment(
                value: _Metric.workouts,
                label: Text(l10n.socialBoardWorkouts),
              ),
              ButtonSegment(
                value: _Metric.volume,
                label: Text(l10n.socialBoardVolume),
              ),
            ],
            selected: {_metric},
            onSelectionChanged: (s) => setState(() => _metric = s.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            switch (_metric) {
              _Metric.workouts => l10n.socialBoardWorkoutsHint,
              _Metric.volume => l10n.socialBoardVolumeHint,
            },
            style: theme.textTheme.bodySmall,
          ),
        ),
        if (ranked.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.socialBoardEmpty, textAlign: TextAlign.center),
          ),
        for (final r in ranked)
          ListTile(
            selected: r.item.uid == me?.uid,
            leading: CircleAvatar(
              backgroundColor: r.rank == 1
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              foregroundColor: r.rank == 1
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              child: Text('${r.rank}'),
            ),
            title: Text(r.item.uid == me?.uid
                ? l10n.socialBoardYou(r.item.displayName)
                : r.item.displayName),
            trailing: Text(
              _format(context, r.value),
              style: theme.textTheme.titleMedium,
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.socialBoardPrivacy, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}
