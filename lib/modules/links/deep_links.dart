import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../router.dart';

// [links-imports:sharing]
import '../sharing/sharing_module.dart';
//
// [links-imports:widgets]
import '../widgets/widget_content.dart' show kWidgetUriScheme;
//
// [links-imports:social]
import '../social/social_module.dart';
//

/// Vlastní schéma odkazů do aplikace, např. fitnessapp://challenge?...
/// Až bude jasný název aplikace, změň ho i v tool/platform/links.dart.
const kAppLinkScheme = 'fitnessapp';

/// Adresa webu. Odkazy ke sdílení vedou sem; web nabídne otevření
/// aplikace nebo stažení z obchodu. TODO: doplnit po koupi domény.
const kWebBaseUrl = 'https://example.com';

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
      //
    ];

/// Poslouchá příchozí odkazy (i ten, kterým se aplikace spustila)
/// a předá je modulům. Čeká, až se načte profil, aby odkaz nepřebil
/// úvodní přesměrování.
final deepLinkProvider = Provider<void>((ref) {
  final appLinks = AppLinks();

  Future<void> handle(Uri uri) async {
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
/// fitnessapp://<path>?... i https://<web>/<path>?...
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
