// Premium na půl roku zdarma pro první uživatele.
//
// Dokud Premium není spuštěné ([kPremiumLaunched] = false), dostane
// každý po dokončení úvodního nastavení jednorázovou hlášku „Premium
// na půl roku zdarma“ a do profilu se uloží, do kdy dárek platí
// (UserProfiles.premiumGiftUntil). Před spuštěním plateb je stejně
// všechno zdarma; po spuštění se dárek dodrží (hasPremiumAccess).
// Stávající uživatelé hlášku uvidí při prvním otevření po aktualizaci.

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
        shouldGrantPremiumGift(
          launched: kPremiumLaunched,
          onboardingDone: profile.onboardingDone,
          giftUntil: profile.premiumGiftUntil,
        )) {
      _handled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _grant());
    }
    return const SizedBox.shrink();
  }

  Future<void> _grant() async {
    final until = premiumGiftEnd(DateTime.now());
    final db = ref.read(databaseProvider);
    try {
      await db.updateProfile(
        UserProfilesCompanion(premiumGiftUntil: Value(until)),
      );
    } catch (e) {
      debugPrint('Premium gift save failed: $e');
      return;
    }
    if (!mounted) return;
    unawaited(showDialog<void>(
      context: context,
      builder: (context) => PremiumGiftDialog(until: until),
    ));
  }
}

/// Uvítací hláška „Premium na půl roku zdarma“.
class PremiumGiftDialog extends StatelessWidget {
  const PremiumGiftDialog({super.key, required this.until});

  final DateTime until;

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
      content: Text(
        l10n.premiumGiftBody(formatPremiumGiftDate(context, until)),
        textAlign: TextAlign.center,
      ),
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

/// Řádek v Profilu, dokud dárek platí („Premium zdarma do …“).
/// Po spuštění Premium ho ukazuje [PremiumProfileSection] sama.
class PremiumGiftProfileTile extends ConsumerWidget {
  const PremiumGiftProfileTile({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(premiumProvider);
    final until = access.giftUntil;
    if (!access.giftActive || until == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        Icons.workspace_premium,
        color: theme.colorScheme.tertiary,
      ),
      title: Text(l10n.premiumGiftProfileTitle),
      subtitle: Text(
        l10n.premiumGiftProfileUntil(formatPremiumGiftDate(context, until)),
      ),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
