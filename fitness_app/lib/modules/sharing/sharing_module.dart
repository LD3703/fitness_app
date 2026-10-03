// Napojení modulu sdílení na aplikaci (volá se z module_hub.dart
// a lib/modules/links/deep_links.dart).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database.dart';
import '../../features/workout/workout_service.dart';
import '../../providers.dart';
import '../links/deep_links.dart';
import 'challenge_screen.dart';
import 'challenge_service.dart';

export 'challenge_screen.dart' show challengeRoute;
export 'challenge_widgets.dart' show ChallengesTodayCard, CompletedChallengesSection;
export 'sharing_actions.dart' show SharingSummaryActions, ExerciseShareSection;

/// Odkaz s výzvou (fitnessapp://challenge?… nebo <web>/challenge?…)
/// otevře obrazovku výzvy se stejnými parametry.
bool handleChallengeLink(Uri uri, GoRouter router) {
  if (!isAppLink(uri, 'challenge')) return false;
  final query = uri.query;
  router.push(query.isEmpty ? kChallengeRoute : '$kChallengeRoute?$query');
  return true;
}

/// Po tréninku: označí splněné výzvy (souhrn je pak ukáže).
Future<void> sharingWorkoutFinished(
  WidgetRef ref,
  WorkoutSummary summary,
) async {
  await checkChallenges(ref.read(databaseProvider));
}

/// Po změně dat: označí splněné výzvy (např. voda za týden).
Future<void> sharingSync(Ref ref, UserProfile profile) async {
  await checkChallenges(ref.read(databaseProvider));
}
