import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/dialogs.dart';
import 'health_service.dart';
import 'health_sync.dart';

/// Sekce v Profilu: přepínač synchronizace s Health Connect / Apple Zdraví.
class HealthProfileSection extends ConsumerStatefulWidget {
  const HealthProfileSection({super.key});

  @override
  ConsumerState<HealthProfileSection> createState() =>
      _HealthProfileSectionState();
}

class _HealthProfileSectionState extends ConsumerState<HealthProfileSection> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final service = HealthService.instance;
    final profile = ref.watch(profileProvider).valueOrNull;
    if (profile == null || !service.isSupportedPlatform) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.healthSectionTitle,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        SwitchListTile(
          secondary: _busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.favorite_border),
          title: Text(
            service.isIOS ? l10n.healthSyncIos : l10n.healthSyncAndroid,
          ),
          subtitle: Text(
            profile.trackWeight
                ? l10n.healthSyncHint
                : l10n.healthSyncHintWorkoutsOnly,
          ),
          value: profile.healthSyncEnabled,
          onChanged: _busy ? null : _toggle,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.healthPrivacyNote,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const Divider(),
      ],
    );
  }

  Future<void> _toggle(bool enable) async {
    final db = ref.read(databaseProvider);
    final l10n = AppLocalizations.of(context);
    if (!enable) {
      // Co už v Health je, tam zůstane; jen se přestane synchronizovat.
      await db.updateProfile(
        UserProfilesCompanion(healthSyncEnabled: Value(false)),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await HealthSync.instance.enable();
      if (!mounted) return;
      switch (result) {
        case HealthAccessResult.granted:
          await db.updateProfile(
            UserProfilesCompanion(healthSyncEnabled: Value(true)),
          );
        case HealthAccessResult.needsInstall:
          final install = await showConfirmDialog(
            context,
            title: l10n.healthInstallTitle,
            message: l10n.healthInstallMessage,
            confirmLabel: l10n.healthInstallAction,
          );
          if (install) await HealthService.instance.installHealthConnect();
        case HealthAccessResult.denied:
          _snack(l10n.healthPermissionDenied);
        case HealthAccessResult.unsupported:
          _snack(l10n.healthUnavailable);
      }
    } catch (e) {
      debugPrint('Health enable failed: $e');
      if (mounted) _snack(l10n.healthUnavailable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
