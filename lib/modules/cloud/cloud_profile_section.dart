import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../premium/premium.dart';
import '../../providers.dart';
import '../../router.dart';
import '../../ui/dialogs.dart';
import '../social/social_auth.dart';
import '../social/social_backend.dart';
import '../social/social_service.dart' show socialUserProvider;
import 'cloud_backup_service.dart';
import 'cloud_logic.dart';
import 'cloud_module.dart';
import 'cloud_settings.dart';

/// [cloud:profile] – sekce „Záloha do cloudu“ v Profilu.
class CloudProfileSection extends ConsumerStatefulWidget {
  const CloudProfileSection({super.key});

  @override
  ConsumerState<CloudProfileSection> createState() =>
      _CloudProfileSectionState();
}

class _CloudProfileSectionState extends ConsumerState<CloudProfileSection> {
  bool _busy = false;

  CloudBackupService get _service => CloudBackupService.instance;

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------------
  // Přihlášení
  // ---------------------------------------------------------------------

  Future<void> _signIn() => _run(() async {
        final l10n = AppLocalizations.of(context);
        final method = await _pickSignInMethod();
        if (method == null || !mounted) return;
        final db = ref.read(databaseProvider);
        final router = ref.read(routerProvider);
        try {
          final user = await SocialAuth.instance.signIn(method);
          if (user == null) return;
          // Prázdný telefon + záloha v cloudu → nejdřív nabídnout obnovení
          // (sdílí běh s posluchačem přihlášení v cloudAppProvider).
          await offerCloudRestore(db: db, router: router, uid: user.uid);
        } catch (e) {
          debugPrint('Cloud: sign in failed: $e');
          _snack(l10n.socialSignInFailed);
          return;
        }
        if (!mounted) return;
        final settings = await CloudSettingsStore.instance.load();
        if (!settings.enabled && mounted) await _enable();
      });

  Future<SocialSignInMethod?> _pickSignInMethod() {
    final auth = SocialAuth.instance;
    final methods = [
      if (auth.googleSupported) SocialSignInMethod.google,
      if (auth.appleSupported) SocialSignInMethod.apple,
    ];
    if (methods.length == 1) return Future.value(methods.single);
    if (methods.isEmpty) return Future.value();
    return showModalBottomSheet<SocialSignInMethod>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  l10n.cloudSignInTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final m in methods)
                ListTile(
                  leading: Icon(
                    m == SocialSignInMethod.apple ? Icons.apple : Icons.login,
                  ),
                  title: Text(m == SocialSignInMethod.apple
                      ? l10n.socialSignInApple
                      : l10n.socialSignInGoogle),
                  onTap: () => Navigator.of(context).pop(m),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Zapnutí / vypnutí
  // ---------------------------------------------------------------------

  /// Souhlas → zapnout → hned první záloha.
  Future<void> _enable() async {
    // Premium (cloudBackup): bez předplatného nejdřív paywall.
    final l10n = AppLocalizations.of(context);
    if (!await requirePremium(context, ref, PremiumFeature.cloudBackup) ||
        !mounted) {
      return;
    }
    final ok = await showCloudConsentDialog(context);
    if (!ok || !mounted) return;
    final now = DateTime.now();
    await CloudSettingsStore.instance.update((s) => s.copyWith(
          enabled: true,
          consentAt: now,
          lastFailed: false,
          lastFailedAt: null,
          retryAfter: null,
        ));
    final result = await _service.backupNow(ref.read(databaseProvider));
    _snack(_resultText(l10n, result));
  }

  Future<void> _setEnabled(bool value) => _run(() async {
        if (value) {
          await _enable();
        } else {
          await CloudSettingsStore.instance
              .update((s) => s.copyWith(enabled: false));
        }
      });

  String _resultText(AppLocalizations l10n, CloudBackupResult r) =>
      switch (r) {
        CloudBackupResult.done => l10n.cloudBackupDone,
        CloudBackupResult.skippedEmpty => l10n.cloudBackupSkippedEmpty,
        CloudBackupResult.notSignedIn ||
        CloudBackupResult.failed =>
          l10n.cloudBackupFailed,
      };

  Future<void> _backupNow() => _run(() async {
        // Premium (cloudBackup): bez předplatného nejdřív paywall.
        final l10n = AppLocalizations.of(context);
        if (!await requirePremium(context, ref, PremiumFeature.cloudBackup) ||
            !mounted) {
          return;
        }
        final result = await _service.backupNow(ref.read(databaseProvider));
        _snack(_resultText(l10n, result));
      });

  // ---------------------------------------------------------------------
  // Obnovení a smazání
  // ---------------------------------------------------------------------

  Future<void> _restore() => _run(() async {
        // Obnovení je vždy zdarma (i bez Premium), aby nikdo nepřišel o data.
        final l10n = AppLocalizations.of(context);
        final db = ref.read(databaseProvider);
        final entry = await showModalBottomSheet<CloudBackupEntry>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => const _RestoreSheet(),
        );
        if (entry == null || !mounted) return;
        final ok = await showConfirmDialog(
          context,
          title: l10n.dataRestoreConfirmTitle,
          message: l10n.dataRestoreConfirmMessage(entry.meta.workouts),
          confirmLabel: l10n.dataRestoreConfirm,
          destructive: true,
        );
        if (!ok || !mounted) return;
        await runCloudRestore(context, db, entry);
      });

  Future<void> _deleteBackups() => _run(() async {
        final l10n = AppLocalizations.of(context);
        final ok = await showConfirmDialog(
          context,
          title: l10n.cloudDeleteTitle,
          message: l10n.cloudDeleteMessage,
          confirmLabel: l10n.cloudDeleteConfirm,
          destructive: true,
        );
        if (!ok) return;
        final deleted = await _service.deleteAll();
        _snack(deleted ? l10n.cloudDeleteDone : l10n.cloudDeleteFailed);
      });

  // ---------------------------------------------------------------------

  String _status(BuildContext context, CloudSettings s) {
    final l10n = AppLocalizations.of(context);
    if (!s.enabled) return l10n.cloudStatusOff;
    final last = s.lastBackupAt;
    final lastText = last == null
        ? l10n.cloudStatusNever
        : l10n.cloudStatusLast(cloudDateTime(context, last));
    return s.lastFailed ? '${l10n.cloudStatusFailed}\n$lastText' : lastText;
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(socialAvailableProvider)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(socialUserProvider).valueOrNull;
    final settings =
        ref.watch(cloudSettingsProvider).valueOrNull ?? const CloudSettings();
    final configured = _service.configured;
    // Premium (cloudBackup): bez předplatného se automatická záloha ukazuje
    // jako vypnutá (háčky stejně nic nedělají) se štítkem „Premium“.
    final allowed = ref.watch(premiumProvider
        .select((a) => a.isPremium(PremiumFeature.cloudBackup)));
    final enabled = settings.enabled && allowed;

    final children = <Widget>[
      if (!configured)
        ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: Text(l10n.cloudAutoBackup),
          subtitle: Text(l10n.cloudNotSetUp),
          enabled: false,
        )
      else if (user == null)
        ListTile(
          // Přihlášení je zdarma (obnovení); Premium hlídá až _enable().
          leading: const Icon(Icons.cloud_upload_outlined),
          title: Text(l10n.cloudSignInToBackUp),
          subtitle: Text(l10n.cloudSignInHint),
          trailing: const Icon(Icons.chevron_right),
          enabled: !_busy,
          onTap: _signIn,
        )
      else ...[
        SwitchListTile(
          // Zapnutí volá requirePremium (_enable).
          secondary: Icon(
            enabled && settings.lastFailed
                ? Icons.sync_problem_outlined
                : Icons.cloud_sync_outlined,
            color: enabled && settings.lastFailed
                ? theme.colorScheme.error
                : null,
          ),
          title: Row(
            children: [
              Flexible(child: Text(l10n.cloudAutoBackup)),
              const SizedBox(width: 8),
              const PremiumBadgeIfLocked(feature: PremiumFeature.cloudBackup),
            ],
          ),
          subtitle: Text(_status(context, settings.copyWith(enabled: enabled))),
          isThreeLine: enabled && settings.lastFailed,
          value: enabled,
          onChanged: _busy ? null : _setEnabled,
        ),
        if (enabled) ...[
          SwitchListTile(
            secondary: const Icon(Icons.wifi),
            title: Text(l10n.cloudWifiOnly),
            subtitle: Text(l10n.cloudWifiOnlyHint),
            value: settings.wifiOnly,
            onChanged: _busy
                ? null
                : (v) => CloudSettingsStore.instance
                    .update((s) => s.copyWith(wifiOnly: v)),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(l10n.cloudBackupNow),
            enabled: !_busy,
            onTap: _backupNow,
          ),
        ],
        ListTile(
          leading: const Icon(Icons.cloud_download_outlined),
          title: Text(l10n.cloudRestore),
          subtitle: Text(l10n.cloudRestoreHint),
          enabled: !_busy,
          onTap: _restore,
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: Text(l10n.cloudDeleteBackups),
          enabled: !_busy,
          onTap: _deleteBackups,
        ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.cloudSectionTitle,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        ...children,
        if (_busy) const LinearProgressIndicator(),
        const Divider(),
      ],
    );
  }
}

/// Seznam záloh v cloudu (nejnovější, předchozí) s datem a počtem tréninků.
class _RestoreSheet extends StatefulWidget {
  const _RestoreSheet();

  @override
  State<_RestoreSheet> createState() => _RestoreSheetState();
}

class _RestoreSheetState extends State<_RestoreSheet> {
  late final Future<List<CloudBackupEntry>> _entries = CloudBackupService
      .instance
      .listBackups()
      .timeout(const Duration(seconds: 30));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: FutureBuilder<List<CloudBackupEntry>>(
        future: _entries,
        builder: (context, snapshot) {
          final Widget body;
          if (snapshot.connectionState != ConnectionState.done) {
            body = const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            debugPrint('Cloud: list failed: ${snapshot.error}');
            body = Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.cloudRestoreLoadFailed),
            );
          } else if (snapshot.requireData.isEmpty) {
            body = Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.cloudRestoreEmpty),
            );
          } else {
            body = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final e in snapshot.requireData)
                  ListTile(
                    leading: Icon(e.slot == CloudSlot.latest
                        ? Icons.cloud_done_outlined
                        : Icons.history),
                    title: Text(e.slot == CloudSlot.latest
                        ? l10n.cloudBackupLatest
                        : l10n.cloudBackupPrevious),
                    subtitle: Text([
                      l10n.cloudBackupEntrySubtitle(
                        cloudDateTime(context, e.meta.createdAt),
                        e.meta.workouts,
                      ),
                      if (e.meta.deviceName.isNotEmpty)
                        l10n.cloudBackupEntryDevice(e.meta.deviceName),
                    ].join('\n')),
                    isThreeLine: e.meta.deviceName.isNotEmpty,
                    onTap: () => Navigator.of(context).pop(e),
                  ),
              ],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(l10n.cloudRestore,
                    style: theme.textTheme.titleMedium),
              ),
              body,
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

/// Souhlas s ukládáním zálohy do cloudu (záloha obsahuje i údaje
/// o zdraví). Vrací true, když uživatel souhlasí.
Future<bool> showCloudConsentDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final theme = Theme.of(context);
      Widget point(IconData icon, String text) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(text)),
              ],
            ),
          );
      return AlertDialog(
        icon: const Icon(Icons.cloud_upload_outlined),
        title: Text(l10n.cloudConsentTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.cloudConsentIntro),
              point(Icons.health_and_safety_outlined, l10n.cloudConsentData),
              point(Icons.lock_outline, l10n.cloudConsentWhere),
              point(Icons.person_outline, l10n.cloudConsentAccess),
              point(Icons.delete_outline, l10n.cloudConsentDeletion),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.cloudConsentAccept),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
