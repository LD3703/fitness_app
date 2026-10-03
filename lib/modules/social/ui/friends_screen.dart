import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../../../ui/dialogs.dart';
import '../social_auth.dart';
import '../social_backend.dart';
import '../social_messaging.dart';
import '../social_publisher.dart';
import '../social_queries.dart';
import '../social_service.dart';
import 'feed_tab.dart';
import 'friends_tab.dart';
import 'leaderboard_tab.dart';
import 'social_ui.dart';

/// /friends – přátelé, žebříček a novinky.
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (!ref.watch(socialAvailableProvider)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.socialTitle)),
        body: SocialMessage(
          icon: Icons.cloud_off_outlined,
          title: l10n.socialNotSetUp,
          text: l10n.socialNotSetUpHint,
        ),
      );
    }
    final user = ref.watch(socialUserProvider);
    return user.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.socialTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.socialTitle)),
        body: SocialMessage(
          icon: Icons.error_outline,
          title: l10n.errorGeneric,
        ),
      ),
      data: (u) => u == null
          ? Scaffold(
              appBar: AppBar(title: Text(l10n.socialTitle)),
              body: const SocialSignInView(),
            )
          : const _SignedInView(),
    );
  }
}

class _SignedInView extends ConsumerStatefulWidget {
  const _SignedInView();

  @override
  ConsumerState<_SignedInView> createState() => _SignedInViewState();
}

class _SignedInViewState extends ConsumerState<_SignedInView> {
  @override
  void initState() {
    super.initState();
    unawaited(prepareSocialProfile(ref.read(databaseProvider)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unread = ref.watch(socialUnreadCountProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.socialTitle),
          actions: [
            IconButton(
              tooltip: l10n.socialSettings,
              icon: const Icon(Icons.manage_accounts_outlined),
              onPressed: () => showSocialSettings(context),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.socialTabFriends),
              Tab(text: l10n.socialTabLeaderboard),
              Tab(
                child: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(l10n.socialTabFeed),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [FriendsTab(), LeaderboardTab(), FeedTab()],
        ),
      ),
    );
  }
}

/// Po přihlášení: založí profil na serveru a zveřejní statistiky.
/// Souběžná volání (přihlášení + otevření obrazovky) sdílí jeden běh,
/// aby nevznikly dva kódy přítele.
Future<void> prepareSocialProfile(AppDatabase db) =>
    _preparing ??= _prepareSocialProfile(db)
        .whenComplete(() => _preparing = null);

Future<void>? _preparing;

Future<void> _prepareSocialProfile(AppDatabase db) async {
  try {
    final profile = await db.watchProfile().first;
    String lang;
    try {
      lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    } catch (_) {
      lang = 'en';
    }
    await SocialService.instance.ensureProfile(
      displayName: SocialPublisher.displayName(profile),
      shareRecords: profile.shareRecordsWithFriends,
      shareStats: profile.shareWorkoutStatsWithFriends,
      lang: lang,
    );
    await SocialPublisher.publishStats(db, profile, force: true);
  } catch (e) {
    debugPrint('Social: profile setup failed: $e');
  }
}

/// Přihlášení přes Google / Apple s vysvětlením, co se sdílí.
class SocialSignInView extends ConsumerStatefulWidget {
  const SocialSignInView({super.key, this.onSignedIn});

  final VoidCallback? onSignedIn;

  @override
  ConsumerState<SocialSignInView> createState() => _SocialSignInViewState();
}

class _SocialSignInViewState extends ConsumerState<SocialSignInView> {
  bool _busy = false;

  Future<void> _signIn(SocialSignInMethod method) async {
    final l10n = AppLocalizations.of(context);
    final db = ref.read(databaseProvider);
    setState(() => _busy = true);
    try {
      final user = await SocialAuth.instance.signIn(method);
      if (user != null) {
        await prepareSocialProfile(db);
        if (mounted) widget.onSignedIn?.call();
      }
    } catch (e) {
      debugPrint('Social: sign in failed: $e');
      if (mounted) showSocialSnack(context, l10n.socialSignInFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = SocialAuth.instance;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.groups_outlined, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(l10n.socialSignInTitle,
            style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(l10n.socialSignInText, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.socialPrivacyTitle, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(l10n.socialPrivacyShared),
                const SizedBox(height: 4),
                Text(l10n.socialPrivacyNever),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_busy)
          const Center(child: CircularProgressIndicator())
        else ...[
          if (auth.googleSupported)
            FilledButton.icon(
              onPressed: () => _signIn(SocialSignInMethod.google),
              icon: const Icon(Icons.login),
              label: Text(l10n.socialSignInGoogle),
            ),
          if (auth.appleSupported) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                foregroundColor: theme.brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
              ),
              onPressed: () => _signIn(SocialSignInMethod.apple),
              icon: const Icon(Icons.apple),
              label: Text(l10n.socialSignInApple),
            ),
          ],
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Nastavení: sdílení, odhlášení, smazání účtu
// ---------------------------------------------------------------------------

Future<void> showSocialSettings(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _SocialSettingsSheet(),
    );

class _SocialSettingsSheet extends ConsumerStatefulWidget {
  const _SocialSettingsSheet();

  @override
  ConsumerState<_SocialSettingsSheet> createState() =>
      _SocialSettingsSheetState();
}

class _SocialSettingsSheetState extends ConsumerState<_SocialSettingsSheet> {
  bool _busy = false;

  Future<void> _setSharing({bool? records, bool? stats}) async {
    final db = ref.read(databaseProvider);
    await db.updateProfile(UserProfilesCompanion(
      shareRecordsWithFriends:
          records == null ? const Value.absent() : Value(records),
      shareWorkoutStatsWithFriends:
          stats == null ? const Value.absent() : Value(stats),
    ));
    final profile = await db.watchProfile().first;
    await SocialPublisher.publishStats(db, profile, force: true);
  }

  Future<void> _signOut() async {
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    await SocialMessaging.instance.unregister();
    await SocialAuth.instance.signOut();
    SocialPublisher.reset();
    if (mounted) nav.pop();
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.socialDeleteTitle,
      message: l10n.socialDeleteMessage,
      confirmLabel: l10n.socialDeleteConfirm,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);
    setState(() => _busy = true);
    try {
      await SocialMessaging.instance.unregister();
      await SocialService.instance.deleteAllServerData();
      try {
        await SocialAuth.instance.deleteAuthUser();
      } on FirebaseAuthException catch (e) {
        if (e.code != 'requires-recent-login') rethrow;
        if (await SocialAuth.instance.reauthenticate()) {
          await SocialAuth.instance.deleteAuthUser();
        } else {
          // Data jsou smazaná; účet zmizí i přes Cloud Function nebo
          // při dalším pokusu. Aspoň odhlásit.
          await SocialAuth.instance.signOut();
        }
      }
      await db.socialForgetRemoteIds();
      SocialPublisher.reset();
      messenger.showSnackBar(SnackBar(content: Text(l10n.socialDeleted)));
      if (mounted) nav.pop();
    } catch (e) {
      debugPrint('Social: delete account failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.socialDeleteFailed)));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider).valueOrNull;
    final user = SocialAuth.instance.currentUser;
    final me = ref.watch(socialMeProvider).valueOrNull;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _busy
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: Text(me?.displayName ?? user?.displayName ?? '–'),
                    subtitle: Text(user?.email ?? ''),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text(
                      l10n.socialNameHint,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(l10n.socialShareRecords),
                    subtitle: Text(l10n.socialShareRecordsHint),
                    value: profile?.shareRecordsWithFriends ?? false,
                    onChanged: profile == null
                        ? null
                        : (v) => _setSharing(records: v),
                  ),
                  SwitchListTile(
                    title: Text(l10n.socialShareStats),
                    subtitle: Text(l10n.socialShareStatsHint),
                    value: profile?.shareWorkoutStatsWithFriends ?? false,
                    onChanged:
                        profile == null ? null : (v) => _setSharing(stats: v),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text(
                      l10n.socialPrivacyNever,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(l10n.socialSignOut),
                    onTap: _signOut,
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_forever_outlined,
                        color: theme.colorScheme.error),
                    title: Text(
                      l10n.socialDeleteAccount,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
      ),
    );
  }
}
