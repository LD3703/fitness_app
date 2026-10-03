import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../social_calendar.dart';
import '../social_models.dart';
import '../social_publisher.dart';
import '../social_queries.dart';
import '../social_service.dart';
import 'social_ui.dart';

/// Záložka Novinky: rekordy přátel, pozvánky a výzvy.
class FeedTab extends ConsumerStatefulWidget {
  const FeedTab({super.key});

  @override
  ConsumerState<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends ConsumerState<FeedTab> {
  final _markedRead = <String>{};
  final _busy = <String>{};

  void _markRead(List<FeedItem> items) {
    final unread =
        items.where((i) => !i.read && !_markedRead.contains(i.id)).toList();
    if (unread.isEmpty) return;
    _markedRead.addAll(unread.map((i) => i.id));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => SocialService.instance.markAllRead(unread),
    );
  }

  Future<void> _run(FeedItem item, Future<String?> Function() action) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy.add(item.id));
    String? message;
    try {
      message = await action();
    } catch (e) {
      debugPrint('Social: feed action failed: $e');
      message = l10n.socialOffline;
    }
    if (!mounted) return;
    setState(() => _busy.remove(item.id));
    if (message != null) showSocialSnack(context, message);
  }

  Future<String> _myName() async => SocialPublisher.displayName(
      await ref.read(databaseProvider).watchProfile().first);

  // Rekord přítele → výzva „překonej rekord“ (lokální řádek s remoteId).
  Future<String?> _acceptRecord(FeedItem item) async {
    final l10n = AppLocalizations.of(context);
    final slug = item.str('exerciseSlug');
    final value = item.number('value');
    if (slug == null || value == null) return null;
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final deadline = DateTime(now.year, now.month, now.day + 30, 23, 59);
    final id = await SocialService.instance.createChallenge(
      friendUid: item.fromUid,
      myName: await _myName(),
      kind: RemoteChallengeKind.beatRecord,
      target: value,
      deadline: deadline,
      creatorAccepted: true,
      notify: 'tookOn',
      exerciseSlug: slug,
      exerciseNameEn: item.str('exerciseNameEn'),
      exerciseNameCs: item.str('exerciseNameCs'),
    );
    final exercise = await db.socialExerciseBySlug(slug);
    await db.socialInsertChallenge(
      remoteId: id,
      kind: ChallengeKind.beatRecord,
      targetValue: value,
      fromName: item.fromName,
      deadline: deadline,
      exerciseSlug: slug,
      exerciseId: exercise?.id,
    );
    await SocialService.instance
        .updateFeedItem(item.id, status: InviteStatus.accepted);
    return l10n.socialChallengeAccepted;
  }

  Future<String?> _answerInvite(FeedItem item, bool accept) async {
    final l10n = AppLocalizations.of(context);
    final id = item.str('invitationId');
    if (id == null) return null;
    final inv = await SocialService.instance.getInvitation(id);
    if (inv == null || inv.status == InviteStatus.cancelled) {
      await SocialService.instance
          .updateFeedItem(item.id, status: InviteStatus.cancelled);
      return l10n.socialInviteGone;
    }
    await SocialService.instance
        .answerInvitation(inv, accept: accept, myName: await _myName());
    await SocialService.instance.updateFeedItem(
      item.id,
      status: accept ? InviteStatus.accepted : InviteStatus.declined,
    );
    if (!accept) return null;
    final added = await addSocialWorkoutToCalendar(
      planName: inv.planName,
      friendName: inv.fromName,
      start: inv.startAt,
      durationMinutes: inv.durationMinutes,
    );
    return added ? l10n.socialCalendarAdded : l10n.socialCalendarNotAdded;
  }

  Future<String?> _answerChallenge(FeedItem item, bool accept) async {
    final l10n = AppLocalizations.of(context);
    final id = item.str('challengeId');
    if (id == null) return null;
    final remote = await SocialService.instance.getChallenge(id);
    if (remote == null) {
      await SocialService.instance
          .updateFeedItem(item.id, status: InviteStatus.cancelled);
      return l10n.socialChallengeGone;
    }
    if (accept) {
      final db = ref.read(databaseProvider);
      final profile = await db.watchProfile().first;
      final kind = switch (remote.kind) {
        RemoteChallengeKind.workoutsInMonth => ChallengeKind.workoutsInMonth,
        RemoteChallengeKind.weeklyWater => ChallengeKind.weeklyWater,
        _ => ChallengeKind.beatRecord,
      };
      final slug = remote.exerciseSlug;
      final exercise = slug == null ? null : await db.socialExerciseBySlug(slug);
      await db.socialInsertChallenge(
        remoteId: id,
        kind: kind,
        // Voda: cíl je vlastní týdenní cíl (ml) – ven jdou jen procenta.
        targetValue: kind == ChallengeKind.weeklyWater
            ? (profile.waterGoalMl * 7).toDouble()
            : remote.target,
        fromName: item.fromName,
        deadline: remote.deadline,
        exerciseSlug: slug,
        exerciseId: exercise?.id,
      );
    }
    await SocialService.instance.answerChallenge(id, accept: accept);
    await SocialService.instance.updateFeedItem(
      item.id,
      status: accept ? InviteStatus.accepted : InviteStatus.declined,
    );
    return accept ? l10n.socialChallengeAccepted : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(socialFeedProvider);
    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => SocialMessage(
        icon: Icons.cloud_off_outlined,
        title: l10n.socialOffline,
      ),
      data: (items) {
        _markRead(items);
        final visible =
            items.where((i) => FeedType.all.contains(i.type)).toList();
        if (visible.isEmpty) {
          return SocialMessage(
            icon: Icons.dynamic_feed_outlined,
            title: l10n.socialFeedEmpty,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: visible.length,
          itemBuilder: (context, i) => _tile(context, visible[i]),
        );
      },
    );
  }

  Widget _tile(BuildContext context, FeedItem item) {
    final l10n = AppLocalizations.of(context);
    final busy = _busy.contains(item.id);
    final pending = item.status == null;
    final name = item.fromName;
    final exercise = socialExerciseName(
      context,
      slug: item.str('exerciseSlug'),
      nameEn: item.str('exerciseNameEn'),
      nameCs: item.str('exerciseNameCs'),
    );

    String statusText(String? s) => switch (s) {
          InviteStatus.accepted => l10n.socialStatusAccepted,
          InviteStatus.declined => l10n.socialStatusDeclined,
          InviteStatus.cancelled => l10n.socialStatusCancelled,
          _ => '',
        };

    List<Widget> answerButtons(Future<String?> Function(bool) answer) => [
          TextButton(
            onPressed: busy ? null : () => _run(item, () => answer(false)),
            child: Text(l10n.socialDecline),
          ),
          FilledButton(
            onPressed: busy ? null : () => _run(item, () => answer(true)),
            child: Text(l10n.socialAccept),
          ),
        ];

    late final IconData icon;
    late final String text;
    var actions = <Widget>[];

    switch (item.type) {
      case FeedType.friend:
        icon = Icons.person_add_alt_1_outlined;
        text = l10n.socialFeedFriend(name);
      case FeedType.pr:
        icon = Icons.emoji_events_outlined;
        text = l10n.socialFeedRecord(
            name, exercise, socialKg(context, item.number('value') ?? 0));
        actions = pending
            ? [
                FilledButton.tonal(
                  onPressed:
                      busy ? null : () => _run(item, () => _acceptRecord(item)),
                  child: Text(l10n.socialAcceptChallenge),
                ),
              ]
            : [Text(statusText(item.status))];
      case FeedType.invite:
        icon = Icons.event_outlined;
        final start = item.date('startAt');
        text = l10n.socialFeedInvite(
          name,
          item.str('planName') ?? '',
          start == null ? '' : socialDateTime(context, start),
        );
        final past = start != null && start.isBefore(DateTime.now());
        actions = pending && !past
            ? answerButtons((a) => _answerInvite(item, a))
            : [Text(past && pending ? l10n.socialExpired : statusText(item.status))];
      case FeedType.inviteReply:
        icon = item.data['accepted'] == true
            ? Icons.event_available_outlined
            : Icons.event_busy_outlined;
        final start = item.date('startAt');
        final when = start == null ? '' : socialDateTime(context, start);
        final plan = item.str('planName') ?? '';
        text = item.data['accepted'] == true
            ? l10n.socialFeedInviteAccepted(name, plan, when)
            : l10n.socialFeedInviteDeclined(name, plan, when);
      case FeedType.challenge:
        icon = Icons.flag_outlined;
        final desc = socialChallengeText(
          context,
          kind: item.str('kind') ?? '',
          target: item.number('target') ?? 0,
          exerciseName: exercise,
        );
        final deadline = item.date('deadline');
        final by = deadline == null ? '' : socialDate(context, deadline);
        if (item.str('role') == 'tookOn') {
          text = l10n.socialFeedTookOn(name, desc);
        } else {
          text = l10n.socialFeedChallenge(name, desc, by);
          final expired = deadline != null && deadline.isBefore(DateTime.now());
          actions = pending && !expired
              ? answerButtons((a) => _answerChallenge(item, a))
              : [
                  Text(expired && pending
                      ? l10n.socialExpired
                      : statusText(item.status)),
                ];
        }
      case FeedType.challengeDone:
        icon = Icons.military_tech_outlined;
        text = l10n.socialFeedChallengeDone(name);
      default:
        return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: item.read
                            ? null
                            : const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        socialDateTime(context, item.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (actions.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
