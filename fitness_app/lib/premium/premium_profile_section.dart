import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'premium.dart';
import 'premium_gift.dart';
import 'premium_screen.dart';

/// Sekce „Premium“ v Profilu. Dokud Premium není spuštěné, ukáže jen
/// dárek pro první uživatele („Premium zdarma do …“), jinak nic.
class PremiumProfileSection extends ConsumerWidget {
  const PremiumProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(premiumProvider);
    final showGift = access.giftActive && !access.isSubscriber;
    if (!access.showsPurchaseUi && !showGift) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.premiumProfileSection,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        if (showGift)
          PremiumGiftProfileTile(
            onTap: access.showsPurchaseUi
                ? () => context.push(premiumLocation())
                : null,
          )
        else
          ListTile(
            leading: Icon(
              Icons.workspace_premium_outlined,
              color: access.isSubscriber ? theme.colorScheme.tertiary : null,
            ),
            title: Text(access.isSubscriber
                ? l10n.premiumProfileActive
                : l10n.premiumProfileFree),
            subtitle: Text(access.isSubscriber
                ? l10n.premiumActiveBody
                : l10n.premiumProfileFreeHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(premiumLocation()),
          ),
        if (access.isSubscriber)
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: Text(l10n.premiumManage),
            onTap: () => openPremiumManage(context),
          ),
        const Divider(),
      ],
    );
  }
}
