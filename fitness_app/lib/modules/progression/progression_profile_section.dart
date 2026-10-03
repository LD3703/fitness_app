import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auto_progression.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../premium/premium.dart';
import '../../providers.dart';

String progressionModeLabel(AppLocalizations l10n, ProgressionMode mode) =>
    switch (mode) {
      ProgressionMode.off => l10n.progressionModeOff,
      ProgressionMode.suggest => l10n.progressionModeSuggest,
      ProgressionMode.auto => l10n.progressionModeAuto,
    };

String progressionModeHint(AppLocalizations l10n, ProgressionMode mode) =>
    switch (mode) {
      ProgressionMode.off => l10n.progressionModeOffHint,
      ProgressionMode.suggest => l10n.progressionModeSuggestHint,
      ProgressionMode.auto => l10n.progressionModeAutoHint,
    };

IconData _modeIcon(ProgressionMode mode) => switch (mode) {
      ProgressionMode.off => Icons.block,
      ProgressionMode.suggest => Icons.lightbulb_outline,
      ProgressionMode.auto => Icons.auto_mode,
    };

/// Volba „Automatická progrese: Vypnuto / Navrhovat / Použít automaticky“
/// v Profilu (progression:profile), ukládá UserProfile.progressionMode.
/// Premium (autoProgression): bez předplatného štítek „Premium“ a klepnutí
/// nejdřív otevře paywall (requirePremium).
class ProgressionProfileSection extends ConsumerWidget {
  const ProgressionProfileSection({super.key});

  Future<ProgressionMode?> _pick(BuildContext context, ProgressionMode current) {
    final l10n = AppLocalizations.of(context);
    return showDialog<ProgressionMode>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SimpleDialog(
          title: Text(l10n.progressionSectionTitle),
          children: [
            for (final mode in ProgressionMode.values)
              ListTile(
                leading: Icon(_modeIcon(mode)),
                title: Text(progressionModeLabel(l10n, mode)),
                subtitle: Text(progressionModeHint(l10n, mode)),
                trailing: mode == current
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                selected: mode == current,
                onTap: () => Navigator.of(context).pop(mode),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mode = progressionModeOf(profile.progressionMode);
    final allowed = ref.watch(premiumProvider
        .select((a) => a.isPremium(PremiumFeature.autoProgression)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.progressionSectionTitle,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        ListTile(
          leading: Icon(_modeIcon(mode)),
          title: Text(progressionModeLabel(l10n, mode)),
          subtitle: Text(progressionModeHint(l10n, mode)),
          trailing: allowed
              ? const Icon(Icons.chevron_right)
              : const PremiumBadge(),
          onTap: () async {
            final db = ref.read(databaseProvider);
            if (!await requirePremium(
                  context,
                  ref,
                  PremiumFeature.autoProgression,
                ) ||
                !context.mounted) {
              return;
            }
            final picked = await _pick(context, mode);
            if (picked == null || picked == mode) return;
            await db.updateProfile(
                  UserProfilesCompanion(
                    progressionMode: Value(progressionModeValue(picked)),
                  ),
                );
          },
        ),
        const Divider(),
      ],
    );
  }
}
