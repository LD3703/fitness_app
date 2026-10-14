import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/dialogs.dart';
import '../gym/gym_models.dart';
import '../moderation_logic.dart';
import '../moderation_service.dart';
import 'social_ui.dart';

/// Výběr důvodu nahlášení. U uživatele i volba „Zároveň zablokovat“.
/// null = zrušeno.
Future<({ContentReportReason reason, bool block})?> _showReportDialog(
  BuildContext context, {
  required String title,
  required String message,
  required List<ContentReportReason> reasons,
  bool offerBlock = false,
}) {
  final l10n = AppLocalizations.of(context);
  var reason = reasons.first;
  var block = offerBlock;
  return showDialog<({ContentReportReason reason, bool block})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message),
              const SizedBox(height: 8),
              // Bez RadioGroup/groupValue – stabilní napříč verzemi Flutteru.
              for (final r in reasons)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    reason == r
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: reason == r
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(_reasonLabel(l10n, r)),
                  onTap: () => setState(() => reason = r),
                ),
              if (offerBlock)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: block,
                  onChanged: (v) => setState(() => block = v ?? false),
                  title: Text(l10n.moderationAlsoBlock),
                  subtitle: Text(l10n.moderationAlsoBlockHint),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop((reason: reason, block: block)),
            child: Text(l10n.moderationReport),
          ),
        ],
      ),
    ),
  );
}

String _reasonLabel(AppLocalizations l10n, ContentReportReason r) =>
    switch (r) {
      ContentReportReason.offensive => l10n.moderationReasonOffensive,
      ContentReportReason.spam => l10n.moderationReasonSpam,
      ContentReportReason.other => l10n.moderationReasonOther,
      ContentReportReason.closed => l10n.moderationReasonClosed,
      ContentReportReason.duplicate => l10n.moderationReasonDuplicate,
    };

/// Nahlásit posilovnu (název, město, adresa).
Future<void> reportGymFlow(BuildContext context, Gym gym) async {
  final l10n = AppLocalizations.of(context);
  final choice = await _showReportDialog(
    context,
    title: l10n.moderationReportTitle(gym.name),
    message: l10n.moderationReportGymMessage,
    reasons: kGymReportReasons,
  );
  if (choice == null || !context.mounted) return;
  try {
    await ModerationService.instance.report(
      kind: ContentReportKind.gym,
      targetId: gym.id,
      targetName: gym.name,
      reason: choice.reason,
    );
    if (context.mounted) showSocialSnack(context, l10n.moderationReported);
  } catch (e) {
    debugPrint('Moderation: report gym failed: $e');
    if (context.mounted) showSocialSnack(context, l10n.errorGeneric);
  }
}

/// Nahlásit přítele (a volitelně ho rovnou zablokovat).
Future<void> reportUserFlow(
  BuildContext context, {
  required String uid,
  required String name,
}) async {
  final l10n = AppLocalizations.of(context);
  final choice = await _showReportDialog(
    context,
    title: l10n.moderationReportTitle(name),
    message: l10n.moderationReportUserMessage(name),
    reasons: kUserReportReasons,
    offerBlock: true,
  );
  if (choice == null || !context.mounted) return;
  // Po zablokování řádek přítele zmizí (context už nebude připojený),
  // proto si messenger vezmeme předem.
  final messenger = ScaffoldMessenger.of(context);
  void snack(String text) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
  try {
    await ModerationService.instance.report(
      kind: ContentReportKind.user,
      targetId: uid,
      targetName: name,
      reason: choice.reason,
    );
    if (choice.block) await ModerationService.instance.block(uid, name);
    snack(l10n.moderationReported);
  } catch (e) {
    debugPrint('Moderation: report user failed: $e');
    snack(l10n.errorGeneric);
  }
}

/// Zablokovat přítele (bez nahlášení).
Future<void> blockUserFlow(
  BuildContext context, {
  required String uid,
  required String name,
}) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showConfirmDialog(
    context,
    title: l10n.moderationBlockTitle(name),
    message: l10n.moderationBlockMessage(name),
    confirmLabel: l10n.moderationBlock,
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  void snack(String text) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
  try {
    await ModerationService.instance.block(uid, name);
    snack(l10n.moderationBlocked);
  } catch (e) {
    debugPrint('Moderation: block failed: $e');
    snack(l10n.errorGeneric);
  }
}

/// Řádek „Zablokovaní uživatelé“ (Přátelé → účet); klepnutí otevře seznam
/// s možností odblokovat.
class BlockedUsersTile extends ConsumerWidget {
  const BlockedUsersTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final blocked = ref.watch(blockedUsersProvider).valueOrNull ?? const [];
    return ListTile(
      leading: const Icon(Icons.block),
      title: Text(l10n.moderationBlockedList),
      subtitle: Text(l10n.moderationBlockedCount(blocked.length)),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => const _BlockedUsersSheet(),
      ),
    );
  }
}

class _BlockedUsersSheet extends ConsumerWidget {
  const _BlockedUsersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final blocked = ref.watch(blockedUsersProvider).valueOrNull ?? const [];
    return SafeArea(
      child: blocked.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text(l10n.moderationNoneBlocked),
            )
          : ListView(
              shrinkWrap: true,
              children: [
                for (final b in blocked)
                  ListTile(
                    leading: const Icon(Icons.person_off_outlined),
                    title: Text(b.name),
                    trailing: TextButton(
                      onPressed: () =>
                          ModerationService.instance.unblock(b.uid),
                      child: Text(l10n.moderationUnblock),
                    ),
                  ),
              ],
            ),
    );
  }
}
