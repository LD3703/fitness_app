// Modul „social“ (v3): přátelé, výzvy, žebříčky na Firebase.
// Napojení na aplikaci: lib/modules/module_hub.dart a deep_links.dart.
import 'package:go_router/go_router.dart';

import '../links/deep_links.dart';
import 'social_backend.dart';
import 'gym/gym_logic.dart';
import 'social_logic.dart';
import 'ui/add_friend_screen.dart';
import 'ui/friends_screen.dart';
import 'ui/gym_join_screens.dart';
import 'ui/gym_screen.dart';
import 'ui/invite_challenge_screens.dart';

export 'social_backend.dart' show socialAvailableProvider;
export 'social_messaging.dart' show socialAppProvider;
export 'social_publisher.dart' show SocialPublisher;
export 'ui/gym_screen.dart' show GymProgressCard;
export 'ui/social_ui.dart' show SocialProfileSection;

/// [social:init]
Future<void> socialInit() => SocialBackend.init();

/// [social:routes]
List<RouteBase> socialRoutes() => [
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) =>
                AddFriendScreen(code: state.uri.queryParameters['code'] ?? ''),
          ),
          GoRoute(
            path: 'scan',
            builder: (context, state) => const ScanFriendScreen(),
          ),
          GoRoute(
            path: 'invite',
            builder: (context, state) => InviteWorkoutScreen(
              friendUid: state.uri.queryParameters['uid'] ?? '',
              friendName: state.uri.queryParameters['name'] ?? '?',
            ),
          ),
          GoRoute(
            path: 'challenge',
            builder: (context, state) => CreateChallengeScreen(
              friendUid: state.uri.queryParameters['uid'] ?? '',
              friendName: state.uri.queryParameters['name'] ?? '?',
            ),
          ),
        ],
      ),
      // Žebříček posilovny (docs/social.md, „Žebříček posilovny“).
      GoRoute(
        path: '/gym',
        builder: (context, state) => const GymScreen(),
        routes: [
          GoRoute(
            path: 'find',
            builder: (context, state) =>
                GymFindScreen(from: state.uri.queryParameters['from']),
          ),
          GoRoute(
            path: 'scan',
            builder: (context, state) =>
                GymScanScreen(from: state.uri.queryParameters['from']),
          ),
          GoRoute(
            path: 'join',
            builder: (context, state) => GymJoinScreen(
              code: state.uri.queryParameters['code'],
              gymId: state.uri.queryParameters['id'],
              from: state.uri.queryParameters['from'],
            ),
          ),
          GoRoute(
            path: 'create',
            builder: (context, state) =>
                GymCreateScreen(from: state.uri.queryParameters['from']),
          ),
        ],
      ),
    ];

/// [links:social] – fitnessapp://friend?code=XXXX nebo <web>/friend?code=XXXX.
bool socialDeepLink(Uri uri, GoRouter router) {
  if (!isAppLink(uri, 'friend')) return false;
  final code = uri.queryParameters['code'];
  final normalized = code == null ? null : normalizeFriendCode(code);
  router.push(normalized == null
      ? '/friends'
      : '/friends/add?code=${Uri.encodeQueryComponent(normalized)}');
  return true;
}

/// [links:social] – fitnessapp://gym?code=XXXXXX nebo <web>/gym?code=XXXXXX.
bool socialGymDeepLink(Uri uri, GoRouter router) {
  if (!isAppLink(uri, 'gym')) return false;
  final code = parseGymCode(uri.toString());
  router.push(code == null ? '/gym' : '/gym/join?code=$code');
  return true;
}
