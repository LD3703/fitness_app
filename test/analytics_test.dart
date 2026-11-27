// Statistiky používání (lib/modules/analytics/): souhlas, názvy obrazovek
// bez ID, parametry událostí a dotaz na souhlas.
import 'package:fitness_app/l10n/app_localizations.dart';
import 'package:fitness_app/modules/analytics/analytics.dart';
import 'package:fitness_app/modules/analytics/analytics_consent_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Goal { muscle }

void main() {
  test('odesílá se jen v release, s Firebase a se souhlasem', () {
    expect(
        shouldSendAnalytics(
            releaseBuild: true, firebaseReady: true, consent: true),
        isTrue);
    // Ještě neodpověděl = nic.
    expect(
        shouldSendAnalytics(
            releaseBuild: true, firebaseReady: true, consent: null),
        isFalse);
    expect(
        shouldSendAnalytics(
            releaseBuild: true, firebaseReady: true, consent: false),
        isFalse);
    expect(
        shouldSendAnalytics(
            releaseBuild: false, firebaseReady: true, consent: true),
        isFalse);
    expect(
        shouldSendAnalytics(
            releaseBuild: true, firebaseReady: false, consent: true),
        isFalse);
  });

  test('název obrazovky ze vzoru cesty, bez ID a parametrů', () {
    expect(screenNameFor('/today'), 'today');
    expect(screenNameFor('/plans/:id'), 'plans/id');
    expect(screenNameFor('/workout/:sessionId'), 'workout/sessionId');
    // Skutečné ID (když vzor chybí) se nepošle.
    expect(screenNameFor('/plans/42/item/7'), 'plans/id/item/id');
    expect(screenNameFor('/planb?planId=3'), 'planb');
    expect(screenNameFor('/'), 'root');
    expect(screenNameFor(''), 'root');
  });

  test('parametry: bool jako 0/1, enum názvem, null vynechán, krátký text',
      () {
    final params = analyticsParams({
      'from_plan': true,
      'light': false,
      'sets': 12,
      'goal': _Goal.muscle,
      'program': null,
      'long': 'x' * 150,
    });
    expect(params['from_plan'], 1);
    expect(params['light'], 0);
    expect(params['sets'], 12);
    expect(params['goal'], 'muscle');
    expect(params.containsKey('program'), isFalse);
    expect((params['long']! as String).length, 100);
  });

  test('mimo release a bez Firebase se nic neodešle a nic nespadne', () {
    Analytics.consent.value = true;
    // V testu není release ani Firebase – jen nesmí vyhodit chybu.
    Analytics.log(AnalyticsEvent.workoutStart, {'from_plan': true});
    Analytics.screen('today');
    Analytics.setUserProperties({'level': 'beginner'});
    expect(Analytics.active, isFalse);
    Analytics.consent.value = null;
  });

  Widget app(Widget home) => MaterialApp(
        locale: const Locale('cs'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );

  Widget opener() => Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showAnalyticsConsentSheet(context),
              child: const Text('Otevřít'),
            ),
          ),
        ),
      );

  for (final (label, expected) in [('Ne, díky', false), ('Ano, pomůžu', true)]) {
    testWidgets('dotaz na souhlas: „$label“ uloží $expected', (tester) async {
      Analytics.consent.value = null;
      await tester.pumpWidget(app(opener()));
      await tester.tap(find.text('Otevřít'));
      await tester.pumpAndSettle();
      expect(find.text('Pomůžeš nám vylepšovat GymBar?'), findsOneWidget);
      // Obě volby jsou vidět vedle sebe.
      expect(find.text('Ne, díky'), findsOneWidget);
      expect(find.text('Ano, pomůžu'), findsOneWidget);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text('Pomůžeš nám vylepšovat GymBar?'), findsNothing);
      expect(Analytics.consent.value, expected);
      Analytics.consent.value = null;
    });
  }

  testWidgets('zavření dotazu bez odpovědi nic neuloží', (tester) async {
    Analytics.consent.value = null;
    await tester.pumpWidget(app(opener()));
    await tester.tap(find.text('Otevřít'));
    await tester.pumpAndSettle();
    // Klepnutí mimo panel.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('Pomůžeš nám vylepšovat GymBar?'), findsNothing);
    expect(Analytics.consent.value, isNull);
  });
}
