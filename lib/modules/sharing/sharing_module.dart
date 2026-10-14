// Napojení modulu sdílení na aplikaci (volá se z module_hub.dart
// a lib/modules/links/deep_links.dart).

import 'package:flutter/foundation.dart' show debugPrint;
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

/// Odkaz s výzvou (gymbar://challenge?… nebo `<web>/challenge?…`)
/// otevře obrazovku výzvy se stejnými parametry.
bool handleChallengeLink(Uri uri, GoRouter router) {
  if (!isAppLink(uri, 'challenge')) return false;
  final Map<String, String> params;
  try {
    params = uri.queryParameters;
  } catch (e) {
    // Neplatné kódování (např. „%FF“ → FormatException, jiné chyby
    // dekódování → ArgumentError) – obrazovka by odkaz stejně nepřečetla;
    // odkaz je náš, takže ho dál nikomu nepředáváme.
    debugPrint('Challenge link ignored: $e');
    return true;
  }
  // Adresu skládáme znovu z dekódovaných parametrů (znovu zakódované),
  // aby se do routeru nedostalo nic, co by šlo přečíst jinak.
  router.push(Uri(
    path: kChallengeRoute,
    queryParameters: params.isEmpty ? null : params,
  ).toString());
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
