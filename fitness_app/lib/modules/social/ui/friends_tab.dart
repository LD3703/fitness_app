import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/dialogs.dart';
import '../social_logic.dart';
import '../social_models.dart';
import '../social_service.dart';
import 'social_ui.dart';

enum _FriendAction { invite, challenge, remove }

/// Záložka Přátelé: přidání přítele a seznam se společnými sériemi.
class FriendsTab extends ConsumerWidget {
  const FriendsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(socialMeProvider).valueOrNull;
    final friends = ref.watch(socialFriendProfilesProvider);
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(socialFriendProfilesProvider);
        await ref.read(socialFriendProfilesProvider.future).catchError(
              (_) => const <FriendProfile>[],
            );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _AddFriendCard(code: me?.friendCode),
          ...friends.when<List<Widget>>(
            loading: () => [
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              ListTile(
                leading: const Icon(Icons.cloud_off_outlined),
                title: Text(l10n.socialOffline),
              ),
            ],
            data: (list) => list.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.socialNoFriends,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]
                : [
                    for (final f in list)
                      _FriendTile(
                        friend: f,
                        streak: me == null || !me.shareStats || !f.shareStats
                            ? null
                            : pairStreak(me.weeks, f.weeks, now),
                      ),
                  ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AddFriendCard extends StatelessWidget {
  const _AddFriendCard({required this.code});

  final String? code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = code;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.socialAddFriend,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.socialAddFriendHint),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.qr_code_2, size: 18),
                  label: Text(l10n.socialMyCode),
                  onPressed: c == null ? null : () => showMyCode(context, c),
                ),
                ActionChip(
                  avatar: const Icon(Icons.qr_code_scanner, size: 18),
                  label: Text(l10n.socialScan),
                  onPressed: () => context.push('/friends/scan'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.share_outlined, size: 18),
                  label: Text(l10n.socialShareLink),
                  onPressed:
                      c == null ? null : () => shareFriendInvite(context, c),
                ),
                ActionChip(
                  avatar: const Icon(Icons.keyboard_outlined, size: 18),
                  label: Text(l10n.socialEnterCode),
                  onPressed: () async {
                    final text = await showTextInputDialog(
                      context,
                      title: l10n.socialEnterCode,
                      hintText: 'ABCD2345',
                    );
                    if (text != null && context.mounted) {
                      openAddFriend(context, text);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Můj QR kód a kód přítele.
Future<void> showMyCode(BuildContext context, String code) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.socialMyCodeHint, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: QrImageView(
                    data: socialFriendAppLink(code),
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  code,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(letterSpacing: 4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        if (context.mounted) {
                          showSocialSnack(context, l10n.socialCopied);
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: Text(l10n.socialCopy),
                    ),
                    TextButton.icon(
                      onPressed: () => shareFriendInvite(context, code),
                      icon: const Icon(Icons.share_outlined),
                      label: Text(l10n.socialShareLink),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend, required this.streak});

  final FriendProfile friend;
  final int? streak;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = streak;
    final name = friend.displayName;
    final query = 'uid=${Uri.encodeQueryComponent(friend.uid)}'
        '&name=${Uri.encodeQueryComponent(name)}';
    return ListTile(
      leading: CircleAvatar(
        child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase()),
      ),
      title: Text(name),
      subtitle: Text(
        s == null
            ? l10n.socialStreakHidden
            : s == 0
                ? l10n.socialStreakNone
                : l10n.socialStreak(s),
      ),
      trailing: PopupMenuButton<_FriendAction>(
        onSelected: (a) async {
          switch (a) {
            case _FriendAction.invite:
              context.push('/friends/invite?$query');
            case _FriendAction.challenge:
              context.push('/friends/challenge?$query');
            case _FriendAction.remove:
              final ok = await showConfirmDialog(
                context,
                title: l10n.socialRemoveTitle(name),
                confirmLabel: l10n.socialRemove,
                destructive: true,
              );
              if (ok) await SocialService.instance.removeFriend(friend.uid);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _FriendAction.invite,
            child: Text(l10n.socialInviteWorkout),
          ),
          PopupMenuItem(
            value: _FriendAction.challenge,
            child: Text(l10n.socialChallengeFriend),
          ),
          PopupMenuItem(
            value: _FriendAction.remove,
            child: Text(l10n.socialRemove),
          ),
        ],
      ),
    );
  }
}
