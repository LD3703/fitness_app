import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'modules/module_hub.dart';
import 'router.dart';
import 'services/sync_controller.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initModules();
  runApp(const ProviderScope(child: FitnessApp()));
}

class FitnessApp extends ConsumerWidget {
  const FitnessApp({super.key});

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
