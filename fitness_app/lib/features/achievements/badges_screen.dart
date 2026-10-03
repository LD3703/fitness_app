import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../modules/links/deep_links.dart';
import '../../modules/sharing/share_cards.dart';
import '../../modules/sharing/share_service.dart';
import '../workout/workout_service.dart';
import 'achievements_service.dart';
import 'badge_labels.dart';
import 'badges.dart';

const kBadgesRoute = '/badges';

/// Galerie odznaků (badges:routes).
GoRoute badgesRoute() => GoRoute(
      path: kBadgesRoute,
      builder: (context, state) => const BadgesScreen(),
    );

/// Sdílí kartu získaného odznaku (náhled → obrázek + text).
Future<void> shareBadge(
  BuildContext context,
  BadgeDef badge,
  DateTime earnedAt,
) {
  final l10n = AppLocalizations.of(context);
  final name = badgeName(l10n, badge);
  return showShareCardPreview(
    context,
    card: BadgeShareCard(
      label: l10n.badgeShareCardLabel,
      data: BadgeCardData(
        name: name,
        description: badgeDescription(l10n, badge),
        icon: badgeIcon(badge),
        date: earnedAt,
      ),
    ),
    fileName: 'badge_${badge.code}',
    text: l10n.badgeShareText(name, kWebBaseUrl),
  );
}

/// Počet získaných odznaků z katalogu (neznámé kódy se nepočítají).
int _earnedCount(Iterable<Achievement> earned) {
  final codes = {for (final a in earned) a.code};
  return badgeCatalog.where((b) => codes.contains(b.code)).length;
}

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final earned = ref.watch(achievementsProvider).valueOrNull;
    final progress = ref.watch(badgeProgressProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.badgeGalleryTitle)),
      body: earned == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    l10n.badgeEarnedCount(
                      _earnedCount(earned),
                      badgeCatalog.length,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final kind in BadgeKind.values) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      badgeSectionTitle(l10n, kind),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                  Card(
                    child: Column(
                      children: [
                        for (final b in badgeCatalog)
                          if (b.kind == kind)
                            _BadgeTile(
                              badge: b,
                              achievement: earned
                                  .where((a) => a.code == b.code)
                                  .firstOrNull,
                              progress: progress,
                            ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.achievement,
    required this.progress,
  });

  final BadgeDef badge;

  /// Uložený odznak, null = ještě nezískaný.
  final Achievement? achievement;
  final BadgeProgress? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final a = achievement;
    final p = progress?.progressOf(badge);
    final locale = Localizations.localeOf(context).toString();

    return ListTile(
      leading: BadgeAvatar(badge: badge, earned: a != null),
      title: Text(
        badgeName(l10n, badge),
        style: a == null
            ? TextStyle(color: theme.colorScheme.onSurfaceVariant)
            : null,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(badgeDescription(l10n, badge)),
          if (a != null)
            Text(
              l10n.badgeEarnedOn(DateFormat.yMMMd(locale).format(a.earnedAt)),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.primary),
            )
          else if (p != null && p.current > 0)
            Text(l10n.badgeProgress(p.current, p.target), style: muted),
        ],
      ),
      trailing: a != null
          ? IconButton(
              tooltip: l10n.badgeShare,
              icon: const Icon(Icons.ios_share),
              onPressed: () => shareBadge(context, badge, a.earnedAt),
            )
          : Icon(
              Icons.lock_outline,
              color: theme.colorScheme.outline,
              semanticLabel: l10n.badgeLocked,
            ),
    );
  }
}

/// Vstup do galerie z obrazovky Pokrok (badges:progress).
class BadgesEntryCard extends ConsumerWidget {
  const BadgesEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final earned = ref.watch(achievementsProvider).valueOrNull ??
        const <Achievement>[];
    return Card(
      child: ListTile(
        leading:
            Icon(Icons.military_tech_outlined, color: theme.colorScheme.primary),
        title: Text(l10n.badgeGalleryTitle),
        subtitle: Text(
          l10n.badgeEarnedCount(_earnedCount(earned), badgeCatalog.length),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(kBadgesRoute),
      ),
    );
  }
}

/// Sekce v Profilu (badges:profile).
class BadgesProfileSection extends ConsumerWidget {
  const BadgesProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final earned = ref.watch(achievementsProvider).valueOrNull ??
        const <Achievement>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.badgeProfileSection,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.military_tech_outlined),
          title: Text(l10n.badgeGalleryTitle),
          subtitle: Text(
            l10n.badgeEarnedCount(_earnedCount(earned), badgeCatalog.length),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(kBadgesRoute),
        ),
        const Divider(),
      ],
    );
  }
}

/// „Nový odznak!“ v souhrnu po tréninku (badges:summary).
class NewBadgesSummarySection extends ConsumerWidget {
  const NewBadgesSummarySection({super.key, required this.summary});

  final WorkoutSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(newBadgesProvider);
    if (state == null || state.sessionId != summary.sessionId) {
      return const SizedBox.shrink();
    }
    final badges = [
      for (final code in state.codes)
        if (badgeByCode(code) case final b?) b,
    ];
    if (badges.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final earnedAt = DateTime.now();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.badgeNewTitle(badges.length),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          for (final b in badges)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: BadgeAvatar(badge: b, earned: true, size: 40),
              title: Text(badgeName(l10n, b)),
              subtitle: Text(badgeDescription(l10n, b)),
              trailing: IconButton(
                tooltip: l10n.badgeShare,
                icon: const Icon(Icons.ios_share),
                onPressed: () => shareBadge(context, b, earnedAt),
              ),
            ),
        ],
      ),
    );
  }
}
