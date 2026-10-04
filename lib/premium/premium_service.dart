import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import 'premium.dart';

/// Výsledek nákupu.
enum PremiumPurchaseOutcome { purchased, cancelled, failed }

/// Nákupy přes RevenueCat. Nic nedělá, dokud není [kPremiumLaunched]
/// true a nejsou vyplněné API klíče – aplikace bez klíčů nikdy nespadne.
class PremiumService {
  PremiumService._();

  static final instance = PremiumService._();

  /// Aktivní nárok „premium“ v RevenueCat (null = zatím neověřeno).
  final entitlement = ValueNotifier<bool?>(null);

  bool _configured = false;
  String? _managementUrl;

  /// Je RevenueCat nastavený (spuštěné Premium a vyplněný klíč)?
  bool get isConfigured => _configured;

  /// Odkaz na správu předplatného v obchodě (od RevenueCat).
  String? get managementUrl => _managementUrl;

  static String get _apiKey {
    if (kIsWeb) return '';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => kRevenueCatAndroidKey,
      TargetPlatform.iOS => kRevenueCatIosKey,
      _ => '',
    };
  }

  /// Volá se při startu aplikace (module_hub, [premium:init]).
  Future<void> init() async {
    if (!kPremiumLaunched || _configured) return;
    final key = _apiKey;
    if (key.isEmpty) {
      debugPrint('Premium: RevenueCat API key is not set, purchases disabled.');
      return;
    }
    try {
      await rc.Purchases.configure(rc.PurchasesConfiguration(key));
      _configured = true;
      rc.Purchases.addCustomerInfoUpdateListener(_apply);
      _apply(await rc.Purchases.getCustomerInfo());
    } catch (e) {
      debugPrint('Premium init failed: $e');
    }
  }

  void _apply(rc.CustomerInfo info) {
    entitlement.value =
        info.entitlements.active.containsKey(kPremiumEntitlementId);
    _managementUrl = info.managementURL;
  }

  /// Roční balíček z aktuální nabídky (null = nabídka není k dispozici).
  Future<rc.Package?> yearlyPackage() async {
    if (!_configured) return null;
    try {
      final offerings = await rc.Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return null;
      return current.annual ?? current.availablePackages.firstOrNull;
    } catch (e) {
      debugPrint('Premium offerings failed: $e');
      return null;
    }
  }

  /// Koupí [package]. Zrušení uživatelem není chyba.
  Future<PremiumPurchaseOutcome> buy(rc.Package package) async {
    if (!_configured) return PremiumPurchaseOutcome.failed;
    try {
      final result =
          await rc.Purchases.purchase(rc.PurchaseParams.package(package));
      _apply(result.customerInfo);
      return entitlement.value == true
          ? PremiumPurchaseOutcome.purchased
          : PremiumPurchaseOutcome.failed;
    } on PlatformException catch (e) {
      final code = rc.PurchasesErrorHelper.getErrorCode(e);
      if (code == rc.PurchasesErrorCode.purchaseCancelledError) {
        return PremiumPurchaseOutcome.cancelled;
      }
      debugPrint('Premium purchase failed: $code');
      return PremiumPurchaseOutcome.failed;
    } catch (e) {
      debugPrint('Premium purchase failed: $e');
      return PremiumPurchaseOutcome.failed;
    }
  }

  /// Obnoví dřívější nákupy. true = Premium je aktivní, false = žádný
  /// nákup nenalezen, null = chyba / nákupy nejsou dostupné.
  Future<bool?> restore() async {
    if (!_configured) return null;
    try {
      _apply(await rc.Purchases.restorePurchases());
      return entitlement.value == true;
    } catch (e) {
      debugPrint('Premium restore failed: $e');
      return null;
    }
  }
}
