import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../modules/links/deep_links.dart' show kWebBaseUrl;
import 'premium.dart';
import 'premium_service.dart';

/// Podmínky použití a zásady ochrany soukromí (doplň skutečné adresy).
const kPremiumTermsUrl = '$kWebBaseUrl/terms';
const kPremiumPrivacyUrl = '$kWebBaseUrl/privacy';

/// Správa předplatného, když RevenueCat odkaz nevrátí.
const _playSubscriptionsUrl = 'https://play.google.com/store/account/subscriptions';
const _appStoreSubscriptionsUrl = 'https://apps.apple.com/account/subscriptions';

/// Routa paywallu – registruje se jen při [kPremiumLaunched].
GoRoute premiumRoute() => GoRoute(
      path: kPremiumRoute,
      builder: (context, state) => PremiumScreen(
        highlight: premiumFeatureByName(state.uri.queryParameters['feature']),
      ),
    );

/// Odkaz na správu předplatného v obchodě.
Uri premiumManageUri(TargetPlatform platform) {
  final fromStore = PremiumService.instance.managementUrl;
  if (fromStore != null && fromStore.isNotEmpty) return Uri.parse(fromStore);
  return Uri.parse(platform == TargetPlatform.iOS
      ? _appStoreSubscriptionsUrl
      : _playSubscriptionsUrl);
}

Future<void> openPremiumManage(BuildContext context) => launchUrl(
      premiumManageUri(Theme.of(context).platform),
      mode: LaunchMode.externalApplication,
    );

/// Paywall: výhody, cena za rok, měsíc zdarma, koupit / obnovit nákupy.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key, this.highlight});

  /// Funkce, kvůli které uživatel paywall otevřel (zvýrazní se).
  final PremiumFeature? highlight;

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  rc.Package? _package;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadOffer();
  }

  Future<void> _loadOffer() async {
    final package = await PremiumService.instance.yearlyPackage();
    if (!mounted) return;
    setState(() {
      _package = package;
      _loading = false;
    });
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _buy() async {
    final l10n = AppLocalizations.of(context);
    final package = _package;
    if (package == null) {
      _snack(l10n.premiumUnavailable);
      return;
    }
    setState(() => _busy = true);
    final outcome = await PremiumService.instance.buy(package);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case PremiumPurchaseOutcome.purchased:
        _snack(l10n.premiumThanks);
        context.pop(true);
      case PremiumPurchaseOutcome.cancelled:
        break;
      case PremiumPurchaseOutcome.failed:
        _snack(l10n.premiumPurchaseFailed);
    }
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final result = await PremiumService.instance.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case true:
        _snack(l10n.premiumRestoreDone);
        context.pop(true);
      case false:
        _snack(l10n.premiumRestoreNone);
      case null:
        _snack(l10n.premiumUnavailable);
    }
  }

  void _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final access = ref.watch(premiumProvider);
    final price = _package?.storeProduct.priceString ?? kPremiumFallbackPrice;
    final features = [
      // Funkce, kvůli které uživatel přišel, je první.
      if (widget.highlight != null) widget.highlight!,
      for (final f in PremiumFeature.values)
        if (f != widget.highlight) f,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.premiumTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 56,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(height: 12),
            Text(
              access.isSubscriber
                  ? l10n.premiumActiveTitle
                  : l10n.premiumPaywallTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              access.isSubscriber
                  ? l10n.premiumActiveBody
                  : l10n.premiumPaywallSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final f in features)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        premiumFeatureIcon(f),
                        color: f == widget.highlight
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.primary,
                      ),
                      title: Text(
                        premiumFeatureLabel(l10n, f),
                        style: f == widget.highlight
                            ? const TextStyle(fontWeight: FontWeight.bold)
                            : null,
                      ),
                      trailing: access.isSubscriber
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.premiumFreeForever,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            if (access.isSubscriber)
              OutlinedButton.icon(
                onPressed: () => openPremiumManage(context),
                icon: const Icon(Icons.manage_accounts_outlined),
                label: Text(l10n.premiumManage),
              )
            else ...[
              Text(
                l10n.premiumPricePerYear(price),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.premiumTrialNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy || _loading ? null : _buy,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _busy || _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.premiumBuy),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _restore,
                child: Text(l10n.premiumRestore),
              ),
              TextButton(
                onPressed: () => openPremiumManage(context),
                child: Text(l10n.premiumManage),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              l10n.premiumLegalNote,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _open(kPremiumTermsUrl),
                  child: Text(l10n.premiumTerms),
                ),
                TextButton(
                  onPressed: () => _open(kPremiumPrivacyUrl),
                  child: Text(l10n.premiumPrivacy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
