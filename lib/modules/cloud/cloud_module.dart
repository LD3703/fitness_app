// Modul „cloud“: automatická záloha do Firebase Cloud Storage a obnovení
// (docs/social.md, „Automatická záloha“). Napojení: module_hub.dart.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../features/workout/workout_service.dart';
import '../../l10n/app_localizations.dart';
import '../../premium/premium.dart';
import '../../providers.dart';
import '../../router.dart';
import '../../ui/dialogs.dart';
import '../data/backup_service.dart';
import '../social/social_service.dart' show socialUserProvider;
import 'cloud_backup_service.dart';
import 'cloud_logic.dart';
import 'cloud_queries.dart';
import 'cloud_settings.dart';

export 'cloud_profile_section.dart' show CloudProfileSection;

/// [cloud:finished] – záloha po tréninku. Jen se spustí, na výsledek se
/// nečeká (souhrn se ukáže hned).
Future<void> cloudWorkoutFinished(WidgetRef ref, WorkoutSummary summary) async {
  // Premium (cloudBackup): bez předplatného se automaticky nezálohuje.
  if (!ref.read(premiumProvider).isPremium(PremiumFeature.cloudBackup)) return;
  unawaited(CloudBackupService.instance.autoBackup(
    ref.read(databaseProvider),
    CloudBackupTrigger.workoutFinished,
  ));
}

/// [cloud:sync] – pravidelná záloha nejvýš jednou za 24 h.
Future<void> cloudSync(Ref ref, UserProfile profile) async {
  if (!profile.onboardingDone) return;
  // Premium (cloudBackup): bez předplatného se automaticky nezálohuje.
  if (!ref.read(premiumProvider).isPremium(PremiumFeature.cloudBackup)) return;
  unawaited(CloudBackupService.instance.autoBackup(
    ref.read(databaseProvider),
    CloudBackupTrigger.sync,
  ));
}

/// [cloud:app] – po přihlášení (i po spuštění s přihlášeným účtem)
/// nabídne obnovení, když je databáze prázdná a v cloudu je záloha.
final cloudAppProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<User?>>(
    socialUserProvider,
    (previous, next) {
      final uid = next.valueOrNull?.uid;
      if (uid == null || previous?.valueOrNull?.uid == uid) return;
      unawaited(offerCloudRestore(
        db: ref.read(databaseProvider),
        router: ref.read(routerProvider),
        uid: uid,
      ));
    },
    fireImmediately: true,
  );
});

Future<void>? _offering;

/// Nabídka obnovení po prvním přihlášení na zařízení bez tréninků
/// („Našli jsme zálohu z 3. října 2026. Obsahuje 124 tréninků. Obnovit…?“).
/// Každému účtu se na zařízení nabídne jen jednou. Souběžná volání
/// (posluchač přihlášení + sekce v Profilu) sdílí jeden běh.
Future<void> offerCloudRestore({
  required AppDatabase db,
  required GoRouter router,
  required String uid,
}) =>
    _offering ??= _offerRestore(db, router, uid)
        .whenComplete(() => _offering = null);

Future<void> _offerRestore(AppDatabase db, GoRouter router, String uid) async {
  // Premium: obnovení existující zálohy je vždy zdarma (o data nikdo
  // nepřijde); placené je jen vytváření záloh.
  final service = CloudBackupService.instance;
  try {
    if (!service.configured) return;
    final store = CloudSettingsStore.instance;
    if ((await store.load()).restoreOfferedUids.contains(uid)) return;
    // Počkat na profil a přesměrování routeru (jinak by dialog zmizel
    // spolu s načítací obrazovkou).
    await db.watchProfile().first;
    await Future<void>.delayed(const Duration(seconds: 1));
    if (await db.cloudWorkoutCount() > 0) {
      await store.markRestoreOffered(uid);
      return;
    }
    final entries =
        await service.listBackups().timeout(const Duration(seconds: 30));
    if (service.currentUid != uid) return;
    if (entries.isEmpty) {
      await store.markRestoreOffered(uid);
      return;
    }
    final context = router.routerDelegate.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final entry = entries.first;
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.cloudRestoreOfferTitle,
      message: l10n.cloudRestoreOfferMessage(
        cloudDate(context, entry.meta.createdAt),
        entry.meta.workouts,
      ),
      confirmLabel: l10n.cloudRestoreOfferConfirm,
    );
    await store.markRestoreOffered(uid);
    // Mezitím mohl přibýt trénink – pak už nic nepřepisovat bez dotazu.
    if (!ok || !context.mounted || await db.cloudWorkoutCount() > 0) return;
    if (!context.mounted) return;
    await runCloudRestore(context, db, entry);
  } catch (e) {
    debugPrint('Cloud: restore offer failed: $e');
  }
}

/// „3. října 2026“ / „3 October 2026“ podle jazyka (celý název měsíce,
/// bez zkratek).
String cloudDate(BuildContext context, DateTime d) =>
    DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(d);

/// „3. října 2026 14:05“.
String cloudDateTime(BuildContext context, DateTime d) {
  final locale = Localizations.localeOf(context).toString();
  return '${DateFormat.yMMMMd(locale).format(d)} ${DateFormat.Hm(locale).format(d)}';
}

String cloudRestoreErrorText(AppLocalizations l10n, RestoreError e) =>
    switch (e) {
      RestoreError.notSqlite => l10n.dataRestoreNotSqlite,
      RestoreError.notBackup => l10n.dataRestoreNotBackup,
      RestoreError.newerVersion => l10n.dataRestoreNewer,
      RestoreError.failed => l10n.dataRestoreFailed,
    };

/// Stáhne a obnoví zálohu s dialogem průběhu (nejde zavřít) a výsledkem
/// ve snackbaru. Vrací true po úspěšném obnovení.
Future<bool> runCloudRestore(
  BuildContext context,
  AppDatabase db,
  CloudBackupEntry entry,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  BuildContext? dialogContext;
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (context) {
      dialogContext = context;
      return PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 24),
              Expanded(child: Text(l10n.cloudRestoring)),
            ],
          ),
        ),
      );
    },
  ));
  // Dialog se postaví v příštím snímku – až pak ho jde spolehlivě zavřít.
  await WidgetsBinding.instance.endOfFrame;
  String message;
  var ok = false;
  try {
    await CloudBackupService.instance.restore(db, entry);
    message = l10n.dataRestoreDone;
    ok = true;
  } on RestoreException catch (e) {
    debugPrint('Cloud: restore failed: $e');
    message = cloudRestoreErrorText(l10n, e.error);
  } catch (e) {
    debugPrint('Cloud: restore failed: $e');
    message = l10n.dataRestoreFailed;
  }
  // Zavřít jen dialog průběhu (router mohl mezitím stránku vyměnit).
  final dc = dialogContext;
  if (dc != null && dc.mounted) Navigator.of(dc).pop();
  messenger?.showSnackBar(SnackBar(content: Text(message)));
  return ok;
}
