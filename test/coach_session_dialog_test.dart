import 'package:fitness_app/l10n/app_localizations.dart';
import 'package:fitness_app/modules/coach/ui/session_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

void main() {
  for (final locale in const [Locale('cs'), Locale('pl'), Locale('de')]) {
    testWidgets('formulář pozvánky (${locale.languageCode}) vrátí termín',
        (tester) async {
      CoachSession? result;
      final start = DateTime.now().add(const Duration(days: 3));
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showDialog<CoachSession>(
              context: context,
              builder: (_) => SessionEditorDialog(
                trainerName: 'Tom',
                plans: const [
                  AssignedPlan(
                    id: 'p1',
                    plan: CoachPlan(name: 'Záda'),
                    version: 1,
                    trainerName: 'Tom',
                  ),
                ],
                initial: CoachSession(
                  id: 's1',
                  startAt: DateTime(start.year, start.month, start.day, 7, 30),
                  durationMin: 45,
                  weeks: 12,
                  title: '',
                  planId: 'p1',
                  trainerName: 'Tom',
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect((result!.id, result!.weeks, result!.durationMin, result!.title),
          ('s1', 12, 45, 'Záda'));
      expect((result!.startAt.hour, result!.startAt.minute), (7, 30));
    });
  }

  testWidgets('pozvánka u klienta: nevyřízená má Přijmout i Odmítnout',
      (tester) async {
    final start = DateTime.now().add(const Duration(days: 1));
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('cs'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ClientSessionTile(
          session: CoachSession(
            id: 's1',
            startAt: start,
            durationMin: 60,
            weeks: 4,
            title: 'Nohy',
            note: 'Vem si švihadlo',
            trainerName: 'Tom',
          ),
        ),
      ),
    ));
    expect(find.text('Přijmout'), findsOneWidget);
    expect(find.text('Odmítnout'), findsOneWidget);
    expect(find.textContaining('Vem si švihadlo'), findsOneWidget);
  });
}
