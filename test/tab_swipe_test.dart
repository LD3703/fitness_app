// Přepínání záložek přejetím (lib/ui/app_shell.dart, SwipeBranchContainer).
import 'package:fitness_app/l10n/app_localizations.dart';
import 'package:fitness_app/ui/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/today',
      routes: [
        StatefulShellRoute(
          builder: (context, state, shell) => AppShell(navigationShell: shell),
          navigatorContainerBuilder: (context, shell, children) =>
              SwipeBranchContainer(navigationShell: shell, children: children),
          branches: [
            for (final path in kTabRootPaths)
              StatefulShellBranch(routes: [
                GoRoute(
                  path: path,
                  builder: (context, state) =>
                      Scaffold(body: Center(child: Text('stránka $path'))),
                  routes: [
                    GoRoute(
                      path: 'detail',
                      builder: (context, state) =>
                          Scaffold(body: Center(child: Text('detail $path'))),
                    ),
                  ],
                ),
              ]),
          ],
        ),
      ],
    );

Widget _app(GoRouter router) => MaterialApp.router(
      routerConfig: router,
      locale: const Locale('cs'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );

void main() {
  testWidgets('přejetí doleva / doprava přepne záložku', (tester) async {
    final router = _router();
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    expect(find.text('stránka /today'), findsOneWidget);

    await tester.fling(
        find.text('stránka /today'), const Offset(-400, 0), 1500);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/plans');
    expect(find.text('stránka /plans'), findsOneWidget);

    await tester.fling(
        find.text('stránka /plans'), const Offset(400, 0), 1500);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/today');
  });

  testWidgets('klepnutí na záložku přepne hned, stav záložky zůstane',
      (tester) async {
    final router = _router();
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('stránka /profile'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/profile');
  });

  testWidgets('v detailu (mimo kořen záložky) přejetí záložku nepřepne',
      (tester) async {
    final router = _router();
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    router.go('/plans/detail');
    await tester.pumpAndSettle();
    expect(find.text('detail /plans'), findsOneWidget);
    await tester.fling(
        find.text('detail /plans'), const Offset(-400, 0), 1500);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/plans/detail');
  });
}
