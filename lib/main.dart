import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'modules/module_hub.dart';
import 'providers.dart';
import 'router.dart';
import 'services/sync_controller.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Písmo Archivo (OFL) v seznamu licencí v okně O aplikaci.
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Archivo'], text);
  });
  // Adresář posiloven z OpenStreetMap (docs/gyms_import.md).
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['OpenStreetMap'],
      'Gym directory data © OpenStreetMap contributors.\n\n'
      'The data is available under the Open Database License (ODbL) 1.0: '
      'https://opendatacommons.org/licenses/odbl/1-0/\n\n'
      'https://www.openstreetmap.org/copyright',
    );
  });
  await initModules();
  runApp(const ProviderScope(child: GymBarApp()));
}

class GymBarApp extends ConsumerWidget {
  const GymBarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Notifikace a kalendář se přeplánují po každé změně dat.
    ref.watch(syncControllerProvider);
    for (final p in moduleAppProviders()) {
      ref.watch(p);
    }
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: AppTheme.themeModeOf(
        ref.watch(profileProvider.select((p) => p.valueOrNull?.themeMode)),
      ),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
    );
  }
}
