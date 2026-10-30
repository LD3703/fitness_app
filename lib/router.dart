import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/database.dart';
import 'l10n/app_localizations.dart';
import 'modules/module_hub.dart';
import 'providers.dart';

import 'features/exercises/exercise_detail_screen.dart';
import 'features/exercises/exercises_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/periods/periods_screen.dart';
import 'features/planb/plan_b_screen.dart';
import 'features/plans/plan_editor_screen.dart';
import 'features/plans/plan_item_editor_screen.dart';
import 'features/plans/plans_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/today/today_screen.dart';
import 'features/workout/workout_screen.dart';
import 'ui/app_shell.dart';

/// Router aplikace. Dokud uživatel neprojde úvodním průvodcem,
/// přesměruje každou cestu na /welcome.
final routerProvider = Provider<GoRouter>((ref) {
  final profile = ValueNotifier<UserProfile?>(null);
  ref.listen<AsyncValue<UserProfile>>(
    profileProvider,
    (_, next) => profile.value = next.valueOrNull,
    fireImmediately: true,
  );
  ref.onDispose(profile.dispose);

  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: profile,
    redirect: (context, state) {
      final p = profile.value;
      final loc = state.matchedLocation;
      if (p == null) return loc == '/loading' ? null : '/loading';
      if (!p.onboardingDone) return loc == '/welcome' ? null : '/welcome';
      if (loc == '/welcome' || loc == '/loading') return '/today';
      return null;
    },
    routes: [..._routes, ...moduleRoutes()],
  );
});

final _routes = <RouteBase>[
    GoRoute(
      path: '/loading',
      builder: (context, state) => const _LoadingScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const OnboardingScreen(),
    ),
    // Trénink běží přes celou obrazovku, bez spodní navigace.
    GoRoute(
      path: '/workout/:sessionId',
      builder: (context, state) => WorkoutScreen(
        sessionId: int.parse(state.pathParameters['sessionId']!),
      ),
    ),
    GoRoute(
      path: '/periods',
      builder: (context, state) => const PeriodsScreen(),
    ),
    GoRoute(
      path: '/planb',
      builder: (context, state) => PlanBScreen(
        planId: int.tryParse(state.uri.queryParameters['planId'] ?? ''),
      ),
    ),
    // Záložky vedle sebe – přepínání i přejetím (ui/app_shell.dart).
    StatefulShellRoute(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      navigatorContainerBuilder: (context, shell, children) =>
          SwipeBranchContainer(navigationShell: shell, children: children),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/today',
            builder: (context, state) => const TodayScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/plans',
            builder: (context, state) => const PlansScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => PlanEditorScreen(
                  planId: int.parse(state.pathParameters['id']!),
                ),
                routes: [
                  GoRoute(
                    path: 'item/:itemId',
                    builder: (context, state) => PlanItemEditorScreen(
                      planId: int.parse(state.pathParameters['id']!),
                      planExerciseId:
                          int.parse(state.pathParameters['itemId']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/exercises',
            builder: (context, state) => const ExercisesScreen(),
            routes: [
              // Odkaz ze samolepky na stroji (gymbar.app/ex?id=<slug>).
              GoRoute(
                path: 'slug/:slug',
                builder: (context, state) => ExerciseBySlugScreen(
                  slug: state.pathParameters['slug']!,
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => ExerciseDetailScreen(
                  exerciseId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/progress',
            builder: (context, state) => const ProgressScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ]),
      ],
    ),
];

/// Načítání profilu. Když databáze selže (např. chyba převodu na novou
/// verzi), ukáže chybu s možností zkusit znovu místo nekonečného kolečka.
class _LoadingScreen extends ConsumerWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    if (!profile.hasError) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(l10n.errorGeneric, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                '${profile.error}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: Text(l10n.socialRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
