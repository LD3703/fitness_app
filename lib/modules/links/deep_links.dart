import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../router.dart';
import 'link_decoding.dart';

// [links-imports:sharing]
import '../sharing/sharing_module.dart';
//
// [links-imports:widgets]
import '../widgets/widget_content.dart' show kWidgetUriScheme;
//
// [links-imports:social]
import '../social/social_module.dart';
//
// [links-imports:coach]
import '../coach/coach_module.dart';
//

/// Vlastní schéma odkazů do aplikace, např. gymbar://challenge?...
/// Při změně ho uprav i v tool/platform/links.dart a docs/web/*.html.
const kAppLinkScheme = 'gymbar';

/// Adresa webu (Firebase Hosting, složka docs/web). Odkazy ke sdílení
/// vedou sem; web nabídne otevření aplikace nebo stažení z obchodu.
const kWebBaseUrl = 'https://gymbar.app';

/// Zásady ochrany soukromí (stránka docs/web/privacy.html nahraná na web).
/// Stejnou adresu je potřeba zadat v Google Play Console a App Store Connect.
const kPrivacyPolicyUrl = '$kWebBaseUrl/privacy';

/// Podmínky použití (docs/web/terms.html) – souhlas před přihlášením
/// k přátelům a žebříčku, odkaz v Profilu i u Premium.
const kTermsUrl = '$kWebBaseUrl/terms';

/// Odkazy do obchodů. TODO: doplnit po vydání aplikace.
const kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=cz.dedina.fitness_app';
const kAppStoreUrl = 'https://apps.apple.com/app/id0000000000';

/// Obsluha odkazu: vrátí true, když odkaz zpracovala.
typedef DeepLinkHandler = bool Function(Uri uri, GoRouter router);

List<DeepLinkHandler> deepLinkHandlers() => [
      // [links:sharing]
      handleChallengeLink,
      //
      // [links:widgets]
      // Odkazy z widgetu (homewidget://) zpracuje widgetsAppProvider přes
      // home_widget; tady je jen „spolkneme“, aby je nikdo nezpracoval podruhé.
      (uri, router) => uri.scheme == kWidgetUriScheme,
      //
      // [links:social]
      socialDeepLink,
      socialGymDeepLink,
      //
      // [links:coach]
      coachDeepLink,
      sharedPlanDeepLink,
      //
    ];

/// Poslouchá příchozí odkazy (i ten, kterým se aplikace spustila)
/// a předá je modulům. Čeká, až se načte profil, aby odkaz nepřebil
/// úvodní přesměrování.
final deepLinkProvider = Provider<void>((ref) {
  final appLinks = AppLinks();

  Future<void> handle(Uri uri) async {
    // Odkaz, který nejde dekódovat, nedostane žádný modul – jinak by
    // FormatException vyletěla až v obrazovce otevřené routerem a místo
    // ní by se ukázala chybová stránka navigace.
    if (!isDecodableLink(uri)) {
      debugPrint('Deep link ignored (invalid encoding): $uri');
      return;
    }
    try {
      final profile = await ref.read(profileProvider.future);
      if (!profile.onboardingDone) return;
      final router = ref.read(routerProvider);
      for (final handler in deepLinkHandlers()) {
        if (handler(uri, router)) return;
      }
    } catch (e) {
      debugPrint('Deep link failed: $e');
    }
  }

  final sub = appLinks.uriLinkStream.listen(
    (uri) => unawaited(handle(uri)),
    onError: (Object e) => debugPrint('Deep link error: $e'),
  );
  ref.onDispose(sub.cancel);
});

/// Je odkaz určený aplikaci s danou cestou? Přijme obě podoby:
/// `gymbar://<path>?...` i `https://<web>/<path>?...`
bool isAppLink(Uri uri, String path) {
  if (uri.scheme == kAppLinkScheme) {
    // U vlastního schématu je první část cesty v „host“.
    return uri.host == path ||
        uri.pathSegments.isNotEmpty && uri.pathSegments.first == path;
  }
  final web = Uri.parse(kWebBaseUrl);
  return (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host == web.host &&
      uri.pathSegments.isNotEmpty &&
      uri.pathSegments.first == path;
}
