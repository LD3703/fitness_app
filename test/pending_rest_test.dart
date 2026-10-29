// Odpočet pauzy po odchodu z obrazovky tréninku: lišta nad spodní
// navigací (lib/ui/app_shell.dart, pendingRest v rest_timer.dart).
import 'package:fitness_app/features/workout/rest_timer.dart';
import 'package:fitness_app/l10n/app_localizations.dart';
import 'package:fitness_app/ui/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app() => const MaterialApp(
      locale: Locale('cs'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(bottomNavigationBar: PendingRestBar()),
    );

void main() {
  tearDown(() => pendingRest.value = null);

  testWidgets('bez pauzy se lišta neukáže', (tester) async {
    await tester.pumpWidget(_app());
    expect(find.text('Pauza'), findsNothing);
  });

  testWidgets('běžící pauza ukáže odpočet a po konci zmizí', (tester) async {
    await tester.pumpWidget(_app());
    pendingRest.value = (
      sessionId: 1,
      endsAt: DateTime.now().add(const Duration(seconds: 90)),
      totalSeconds: 120,
    );
    await tester.pump();
    expect(find.text('Pauza'), findsOneWidget);
    expect(find.text('1:30'), findsOneWidget);
    expect(find.text('Pokračovat'), findsOneWidget);

    pendingRest.value = (
      sessionId: 1,
      endsAt: DateTime.now().subtract(const Duration(seconds: 1)),
      totalSeconds: 120,
    );
    await tester.pump();
    expect(find.text('Pauza'), findsNothing);
  });
}
