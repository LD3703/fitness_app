// Premium: přepínač spuštění, seznam funkcí, stav předplatného, zámky.
//
// Dokud je kPremiumLaunched false, je odemčené VŠECHNO a nikde se
// neukáže paywall ani nákup – aplikace je celá zdarma. Až bude
// živnostenský list a účty v obchodech, stačí přepnout na true
// a vyplnit klíče RevenueCat (README, kapitola Premium).

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/database.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import 'premium_rules.dart';
import 'premium_service.dart';

export 'premium_rules.dart';

/// Hlavní vypínač Premium. false = vše zdarma, žádné nákupy.
const kPremiumLaunched = false;

/// Veřejné API klíče RevenueCat (Project settings → API keys).
/// Prázdné = nákupy vypnuté (aplikace funguje dál, nic nespadne).
const kRevenueCatAndroidKey = '';
const kRevenueCatIosKey = '';

/// Identifikátor nároku (entitlement) v RevenueCat.
const kPremiumEntitlementId = 'premium';

/// Cesta obrazovky Premium (paywall).
const kPremiumRoute = '/premium';

/// Cena, když se nepodaří načíst nabídku z obchodu.
const kPremiumFallbackPrice = '8 €';

/// Funkce, které jsou po spuštění Premium jen pro předplatitele.
/// Nové hodnoty přidávej na konec.
enum PremiumFeature {
  unlimitedPlans,
  allPrograms,
  extraHomeRoutines,
  periodBands,
  fullHistory,
  insights,
  calendarSuggestions,
  csvExport,
  autoProgression,
  cloudBackup,
  wearOs,
}

/// Stav přístupu k Premium funkcím.
@immutable
class PremiumAccess {
  const PremiumAccess({
    required this.launched,
    required this.profilePremium,
    required this.entitlementActive,
    this.giftUntil,
    this.giftActive = false,
  });

  /// Bylo Premium spuštěno ([kPremiumLaunched])?
  final bool launched;

  /// Příznak v profilu (poslední známý stav předplatného).
  final bool profilePremium;

  /// Aktivní nárok „premium“ v RevenueCat.
  final bool entitlementActive;

  /// Do kdy platí Premium zdarma pro první uživatele (null = nemá).
  final DateTime? giftUntil;

  /// Platí dárek právě teď?
  final bool giftActive;

  /// Odemčené vše (před spuštěním Premium nebo s předplatným).
  bool get hasPremium => hasPremiumAccess(
        launched: launched,
        profilePremium: profilePremium,
        entitlementActive: entitlementActive,
        giftActive: giftActive,
      );

  /// Má uživatel funkci [feature]? Všechny funkce patří pod jedno
  /// předplatné.
  bool isPremium(PremiumFeature feature) => hasPremium;

  /// Ukazovat paywall, odznaky „Premium“ a sekci v profilu?
  bool get showsPurchaseUi => launched;

  /// Má uživatel opravdu zaplacené předplatné (pro sekci v profilu)?
  bool get isSubscriber => launched && (profilePremium || entitlementActive);

  @override
  bool operator ==(Object other) =>
      other is PremiumAccess &&
      other.launched == launched &&
      other.profilePremium == profilePremium &&
      other.entitlementActive == entitlementActive &&
      other.giftUntil == giftUntil &&
      other.giftActive == giftActive;

  @override
  int get hashCode => Object.hash(
      launched, profilePremium, entitlementActive, giftUntil, giftActive);
}

/// Nárok z RevenueCat (null = neověřeno nebo nákupy vypnuté).
final premiumEntitlementProvider = Provider<bool?>((ref) {
  final notifier = PremiumService.instance.entitlement;
  void listener() => ref.invalidateSelf();
  notifier.addListener(listener);
  ref.onDispose(() => notifier.removeListener(listener));
  return notifier.value;
});

/// Stav Premium pro celou aplikaci: `ref.watch(premiumProvider).isPremium(f)`.
final premiumProvider = Provider<PremiumAccess>((ref) {
  final giftUntil = ref.watch(
    profileProvider.select((p) => p.valueOrNull?.premiumGiftUntil),
  );
  // Konec dárku se přepočítá při další změně profilu nebo startu
  // aplikace (stačí – dárek trvá půl roku).
  final giftActive = isPremiumGiftActive(giftUntil, DateTime.now());
  if (!kPremiumLaunched) {
    return PremiumAccess(
      launched: false,
      profilePremium: false,
      entitlementActive: false,
      giftUntil: giftUntil,
      giftActive: giftActive,
    );
  }
  final profilePremium = ref.watch(
    profileProvider.select((p) => p.valueOrNull?.isPremium ?? false),
  );
  final entitlement = ref.watch(premiumEntitlementProvider);
  return PremiumAccess(
    launched: true,
    profilePremium: profilePremium,
    entitlementActive: entitlement ?? false,
    giftUntil: giftUntil,
    giftActive: giftActive,
  );
});

/// Ukládá ověřený stav předplatného do profilu (UserProfile.isPremium),
/// aby ho znaly i háčky modulů a platil i bez internetu. Sleduje se
/// v kořeni aplikace ([premium:app]).
final premiumProfileSyncProvider = Provider<bool>((ref) {
  if (!kPremiumLaunched) return false;
  final entitlement = ref.watch(premiumEntitlementProvider);
  final stored = ref.watch(
    profileProvider.select((p) => p.valueOrNull?.isPremium),
  );
  if (entitlement == null || stored == null || entitlement == stored) {
    return stored ?? false;
  }
  final db = ref.read(databaseProvider);
  unawaited(Future.microtask(
    () => db.updateProfile(UserProfilesCompanion(isPremium: Value(entitlement))),
  ));
  return entitlement;
});

/// Adresa paywallu se zvýrazněnou funkcí.
String premiumLocation([PremiumFeature? feature]) => feature == null
    ? kPremiumRoute
    : '$kPremiumRoute?feature=${feature.name}';

/// Funkce podle názvu z adresy (null = neznámá).
PremiumFeature? premiumFeatureByName(String? name) =>
    name == null ? null : PremiumFeature.values.asNameMap()[name];

/// true = funkce je dostupná. Jinak otevře paywall a vrátí true jen
/// tehdy, když si ji uživatel mezitím koupil.
Future<bool> requirePremium(
  BuildContext context,
  WidgetRef ref,
  PremiumFeature feature,
) async {
  final access = ref.read(premiumProvider);
  if (access.isPremium(feature) || !access.showsPurchaseUi) return true;
  await context.push<bool>(premiumLocation(feature));
  if (!context.mounted) return false;
  return ref.read(premiumProvider).isPremium(feature);
}

/// Název funkce pro paywall a zamčené karty.
String premiumFeatureLabel(AppLocalizations l10n, PremiumFeature feature) =>
    switch (feature) {
      PremiumFeature.unlimitedPlans => l10n.premiumFeatureUnlimitedPlans,
      PremiumFeature.allPrograms => l10n.premiumFeatureAllPrograms,
      PremiumFeature.extraHomeRoutines => l10n.premiumFeatureExtraHomeRoutines,
      PremiumFeature.periodBands => l10n.premiumFeaturePeriodBands,
      PremiumFeature.fullHistory => l10n.premiumFeatureFullHistory,
      PremiumFeature.insights => l10n.premiumFeatureInsights,
      PremiumFeature.calendarSuggestions =>
        l10n.premiumFeatureCalendarSuggestions,
      PremiumFeature.csvExport => l10n.premiumFeatureCsvExport,
      PremiumFeature.autoProgression => l10n.premiumFeatureAutoProgression,
      PremiumFeature.cloudBackup => l10n.premiumFeatureCloudBackup,
      PremiumFeature.wearOs => l10n.premiumFeatureWearOs,
    };

/// Ikona funkce.
IconData premiumFeatureIcon(PremiumFeature feature) => switch (feature) {
      PremiumFeature.unlimitedPlans => Icons.playlist_add,
      PremiumFeature.allPrograms => Icons.auto_awesome_outlined,
      PremiumFeature.extraHomeRoutines => Icons.home_outlined,
      PremiumFeature.periodBands => Icons.view_week_outlined,
      PremiumFeature.fullHistory => Icons.timeline,
      PremiumFeature.insights => Icons.lightbulb_outline,
      PremiumFeature.calendarSuggestions => Icons.event_available_outlined,
      PremiumFeature.csvExport => Icons.table_chart_outlined,
      PremiumFeature.autoProgression => Icons.trending_up,
      PremiumFeature.cloudBackup => Icons.cloud_upload_outlined,
      PremiumFeature.wearOs => Icons.watch_outlined,
    };

/// Malý štítek „Premium“.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 14,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.premiumBadge,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onTertiaryContainer),
          ),
        ],
      ),
    );
  }
}

/// Štítek „Premium“ jen tehdy, když je funkce zamčená (jinak nic).
class PremiumBadgeIfLocked extends ConsumerWidget {
  const PremiumBadgeIfLocked({super.key, required this.feature});

  final PremiumFeature feature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed =
        ref.watch(premiumProvider.select((a) => a.isPremium(feature)));
    return allowed ? const SizedBox.shrink() : const PremiumBadge();
  }
}

/// Ukáže [child], když má uživatel funkci [feature]; jinak zamčenou
/// kartu se štítkem „Premium“ (klepnutí otevře paywall), nebo [locked].
class PremiumGate extends ConsumerWidget {
  const PremiumGate({
    super.key,
    required this.feature,
    required this.child,
    this.locked,
    this.compact = false,
  });

  final PremiumFeature feature;
  final Widget child;

  /// Vlastní náhrada za zamčený obsah.
  final Widget? locked;

  /// Malý řádek místo karty (např. uvnitř jiné karty).
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed =
        ref.watch(premiumProvider.select((a) => a.isPremium(feature)));
    if (allowed) return child;
    return locked ?? PremiumLockedPlaceholder(feature: feature, compact: compact);
  }
}

/// Zamčená funkce: karta (nebo řádek) s názvem a štítkem „Premium“.
class PremiumLockedPlaceholder extends StatelessWidget {
  const PremiumLockedPlaceholder({
    super.key,
    required this.feature,
    this.compact = false,
    this.text,
  });

  final PremiumFeature feature;
  final bool compact;

  /// Vlastní text (výchozí je název funkce).
  final String? text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = text ?? premiumFeatureLabel(l10n, feature);
    void open() => context.push(premiumLocation(feature));

    if (compact) {
      return InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(Icons.lock_outline,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 6),
              const PremiumBadge(),
            ],
          ),
        ),
      );
    }
    return Card(
      child: ListTile(
        leading: Icon(premiumFeatureIcon(feature)),
        title: Text(label),
        subtitle: Text(l10n.premiumLockedHint),
        trailing: const PremiumBadge(),
        onTap: open,
      ),
    );
  }
}
