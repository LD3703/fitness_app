// Modul „coach“: trenér a klient (docs/coach.md). Napojení na aplikaci:
// lib/modules/module_hub.dart a lib/modules/links/deep_links.dart.
import 'package:go_router/go_router.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

import '../links/deep_links.dart';
import 'ui/client_screens.dart';
import 'ui/coach_screen.dart';
import 'ui/shared_plan_screen.dart';

export 'coach_calendar.dart' show coachAppProvider;
export 'coach_links.dart';
export 'coach_sync.dart' show CoachSync;
export 'ui/coach_widgets.dart' show CoachPlanSection, CoachProfileSection;
export 'ui/session_widgets.dart' show CoachSessionsTodayCard;

/// [coach:routes]
List<RouteBase> coachRoutes() => [
      GoRoute(
        path: '/coach',
        builder: (context, state) => const CoachScreen(),
        routes: [
          GoRoute(
            path: 'connect',
            builder: (context, state) => CoachConnectScreen(
              code: state.uri.queryParameters['code'] ?? '',
            ),
          ),
          GoRoute(
            path: 'clients',
            builder: (context, state) => const ClientsScreen(),
          ),
          GoRoute(
            path: 'client',
            builder: (context, state) => ClientDetailScreen(
              clientUid: state.uri.queryParameters['uid'] ?? '',
              clientName: state.uri.queryParameters['name'] ?? '?',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/shared-plan',
        builder: (context, state) =>
            SharedPlanScreen(id: state.uri.queryParameters['id'] ?? ''),
      ),
    ];

/// [links:coach] – gymbar://coach?code=… nebo `<web>/coach?code=…`.
bool coachDeepLink(Uri uri, GoRouter router) {
  if (!isAppLink(uri, 'coach')) return false;
  final code = parseCoachCode(uri.toString());
  router.push(code == null ? '/coach' : '/coach/connect?code=$code');
  return true;
}

/// [links:coach] – gymbar://plan?id=… nebo `<web>/plan?id=…`.
bool sharedPlanDeepLink(Uri uri, GoRouter router) {
  if (!isAppLink(uri, 'plan')) return false;
  final id = uri.queryParameters['id'];
  if (id == null || !RegExp(r'^[A-Za-z0-9]{10,40}$').hasMatch(id)) {
    router.push('/plans');
    return true;
  }
  router.push('/shared-plan?id=$id');
  return true;
}
