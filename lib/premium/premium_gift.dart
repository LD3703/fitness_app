// Premium na půl roku zdarma pro první uživatele.
//
// Dokud Premium není spuštěné ([kPremiumLaunched] = false), dostane
// každý po dokončení úvodního nastavení jednorázovou hlášku „Až spustíme
// Premium, dostaneš ho na půl roku zdarma“ a do profilu se uloží, kdy
// se stal prvním uživatelem (UserProfiles.premiumEarlyAt). Půlrok běží
// až od spuštění Premium (kPremiumLaunchDate, hasPremiumAccess). S účtem
// se slib uloží i na server a vrátí se na novém telefonu
// (modules/social/premium_early_sync.dart).

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../data/database.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import 'premium.dart';

/// Datum konce dárku v jazyce aplikace („3. dubna 2027“).
String formatPremiumGiftDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMMd(Localizations.localeOf(context).toString())
        .format(date);

/// Neviditelná karta na obrazovce Dnes ([premium:today]): když má
/// uživatel dostat dárek, uloží ho a ukáže uvítací hlášku. Jinak nic.
class PremiumGiftWelcome extends ConsumerStatefulWidget {
  const PremiumGiftWelcome({super.key});

  @override
  ConsumerState<PremiumGiftWelcome> createState() => _PremiumGiftWelcomeState();
}

class _PremiumGiftWelcomeState extends ConsumerState<PremiumGiftWelcome> {
  /// Hláška jen jednou za běh aplikace (i kdyby se karta znovu
  /// sestavila dřív, než se dárek uloží do databáze).
  static bool _handled = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    if (!_handled &&
        profile != null &&
        shouldMarkPremiumEarlyUser(
          launched: kPremiumLaunched,
          onboardingDone: profile.onboardingDone,
          earlyAt: profile.premiumEarlyAt,
        )) {
      _handled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _grant());
    }
    return const SizedBox.shrink();
  }

  Future<void> _grant() async {
    final db = ref.read(databaseProvider);
    try {
      await db.updateProfile(
        UserProfilesCompanion(premiumEarlyAt: Value(DateTime.now())),
      );
    } catch (e) {
      debugPrint('Premium gift save failed: $e');
      return;
    }
    if (!mounted) return;
    unawaited(showDialog<void>(
      context: context,
      builder: (context) => const PremiumGiftDialog(),
    ));
  }
}

/// Uvítací hláška „Premium na půl roku zdarma“ (od spuštění Premium).
class PremiumGiftDialog extends StatelessWidget {
  const PremiumGiftDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      icon: Icon(
        Icons.workspace_premium,
        size: 40,
        color: theme.colorScheme.tertiary,
      ),
      title: Text(l10n.premiumGiftTitle, textAlign: TextAlign.center),
      content: Text(l10n.premiumGiftBody, textAlign: TextAlign.center),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.premiumGiftButton),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}

/// Řádek v Profilu, dokud dárek platí: před spuštěním Premium „půl roku
/// zdarma od spuštění“, potom „platí do …“. Ukazuje ho
/// [PremiumProfileSection].
class PremiumGiftProfileTile extends ConsumerWidget {
  const PremiumGiftProfileTile({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(premiumProvider);
    final until = access.giftUntil;
    if (!access.giftActive) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        Icons.workspace_premium,
        color: theme.colorScheme.tertiary,
      ),
      title: Text(l10n.premiumGiftProfileTitle),
      subtitle: Text(
        until == null
            ? l10n.premiumGiftProfilePending
            : l10n.premiumGiftProfileUntil(formatPremiumGiftDate(context, until)),
      ),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
