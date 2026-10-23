// Obrazovka „Jak si vedu“ (/gym/rank, docs/social.md, „Srovnání se zemí
// a světem“): moje maximálky v cvicích žebříčku posilovny a percentil
// v mé zemi a ve světě – pro všechny, nebo pro můj věk a pohlaví.
// Moje hodnoty zůstávají v telefonu; stahuje se jen anonymní rozložení.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/rest_time.dart' show sexOf;
import '../../../data/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../gym/gym_logic.dart';
import '../gym/gym_queries.dart';
import '../gym/gym_service.dart';
import '../gym/strength_rank.dart';
import '../social_backend.dart';
import 'gym_widgets.dart' show gymCategoryLabel;
import 'social_ui.dart';

/// Moje maximálky (z lokální databáze) v cvicích žebříčku, jen nenulové.
final myLiftBestsProvider =
    FutureProvider.autoDispose<List<(GymCategory, double)>>((ref) async {
  final db = ref.watch(databaseProvider);
  final out = <(GymCategory, double)>[];
  for (final c in GymCategory.lifts) {
    final slug = c.exerciseSlug;
    if (slug == null) continue;
    final best = await db.gymBestWeight(slug);
    if (best != null && best > 0) out.add((c, best));
  }
  return out;
});

class StrengthRankScreen extends ConsumerStatefulWidget {
  const StrengthRankScreen({super.key});

  @override
  ConsumerState<StrengthRankScreen> createState() => _StrengthRankScreenState();
}

class _StrengthRankScreenState extends ConsumerState<StrengthRankScreen> {
  bool _mine = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget scaffold(Widget body) => Scaffold(
          appBar: AppBar(title: Text(l10n.socialRankTitle)),
          body: body,
        );
    if (!ref.watch(socialAvailableProvider)) {
      return scaffold(SocialMessage(
        icon: Icons.cloud_off_outlined,
        title: l10n.socialNotSetUp,
        text: l10n.socialNotSetUpHint,
      ));
    }

    // Země: posilovny, jinak z jazyka telefonu.
    final membership = ref.watch(gymMembershipProvider).valueOrNull;
    final gymId = membership?.gymId;
    final gym = gymId == null ? null : ref.watch(gymProvider(gymId)).valueOrNull;
    final country = liftStatsCountry(
      gymCountry: gym?.country,
      localeCountry:
          WidgetsBinding.instance.platformDispatcher.locale.countryCode,
    );

    // Moje skupina: pohlaví z žebříčku nebo z profilu, věk z roku narození.
    final profile = ref.watch(profileProvider).valueOrNull;
    final gender = switch (membership?.gender) {
      GymGender.male => GymGender.male,
      GymGender.female => GymGender.female,
      _ => switch (sexOf(profile?.sex)) {
          Sex.male => GymGender.male,
          Sex.female => GymGender.female,
          null => null,
        },
    };
    final age = gymAgeGroupFor(profile?.birthYear, DateTime.now().year);
    final canMine = gender != null && age != null;
    final mine = _mine && canMine;
    final groupKey = mine
        ? liftStatsGroupKey(gender: gender, age: age)
        : liftStatsGroupKey();

    final bests = ref.watch(myLiftBestsProvider);
    return scaffold(bests.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => SocialMessage(
        icon: Icons.error_outline,
        title: l10n.errorGeneric,
      ),
      data: (list) => list.isEmpty
          ? SocialMessage(
              icon: Icons.fitness_center,
              title: l10n.socialRankTitle,
              text: l10n.socialRankEmpty,
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(liftStatsProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(l10n.socialRankIntro, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: false, label: Text(l10n.socialRankAll)),
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.socialRankMine),
                        enabled: canMine,
                      ),
                    ],
                    selected: {mine},
                    onSelectionChanged: (v) => setState(() => _mine = v.first),
                  ),
                  if (!canMine) ...[
                    const SizedBox(height: 6),
                    Text(l10n.socialRankMineHint, style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: 8),
                  for (final (category, best) in list)
                    _RankCard(
                      category: category,
                      best: best,
                      country: country,
                      groupKey: groupKey,
                    ),
                ],
              ),
            ),
    ));
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.category,
    required this.best,
    required this.country,
    required this.groupKey,
  });

  final GymCategory category;
  final double best;
  final String? country;
  final String groupKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(gymCategoryLabel(l10n, category), style: theme.textTheme.titleMedium),
            Text(l10n.socialRankMyBest(socialKg(context, best)),
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            if (country != null)
              _RankLine(
                label: '${countryFlag(country!)} $country',
                docId: liftStatsDocId(country!, category),
                groupKey: groupKey,
                best: best,
              ),
            _RankLine(
              label: '🌍 ${l10n.socialRankWorld}',
              docId: liftStatsDocId(kLiftStatsWorld, category),
              groupKey: groupKey,
              best: best,
            ),
          ],
        ),
      ),
    );
  }
}

class _RankLine extends ConsumerWidget {
  const _RankLine({
    required this.label,
    required this.docId,
    required this.groupKey,
    required this.best,
  });

  final String label;
  final String docId;
  final String groupKey;
  final double best;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stats = ref.watch(liftStatsProvider(docId));
    final percent = stats.valueOrNull?[groupKey]?.percentBelow(best);
    final text = stats.when(
      loading: () => '…',
      error: (e, _) => l10n.socialOffline,
      data: (_) => percent == null
          ? l10n.socialRankFewData
          : l10n.socialRankBetterThan(liftPercentLabel(percent)),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text(label, style: theme.textTheme.bodyMedium)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: percent == null
                        ? theme.textTheme.bodySmall
                        : theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                if (percent != null) ...[
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// [social:progress] – vstup do srovnání „Jak si vedu“.
class StrengthRankProgressCard extends ConsumerWidget {
  const StrengthRankProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(socialAvailableProvider)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(Icons.public, color: theme.colorScheme.primary),
        title: Text(l10n.socialRankTitle),
        subtitle: Text(l10n.socialRankProgress),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/gym/rank'),
      ),
    );
  }
}
