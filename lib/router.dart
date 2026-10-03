import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/database.dart';
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
      builder: (context, state) =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
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
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
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
