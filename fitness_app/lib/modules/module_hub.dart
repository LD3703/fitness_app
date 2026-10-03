// Místo, kde se funkce verzí 2 a 3 („moduly“) napojují na aplikaci.
//
// Každý modul má vlastní složku lib/modules/<modul>/ a sem přidává jen
// řádky pod svou značku // [<modul>:<místo>]. Značky neodstraňuj.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/database.dart';
import '../features/workout/workout_service.dart';
import 'links/deep_links.dart';

// [imports:stats]
import 'stats/stats_module.dart';
//
// [imports:sharing]
import 'sharing/sharing_module.dart';
//
// [imports:calendar]
import 'calendar/calendar_notification_actions.dart';
import 'calendar/calendar_plan_section.dart';
import 'calendar/calendar_profile_section.dart';
import 'calendar/calendar_today_card.dart';
//
// [imports:widgets]
import 'widgets/home_widget_service.dart';
//
// [imports:health]
import 'health/health_section.dart';
import 'health/health_sync.dart';
//
// [imports:data]
import 'data/data_profile_section.dart';
import 'data/exercise_edit_screen.dart';
import 'data/units.dart';
//
// [imports:social]
import 'social/social_module.dart';
//
// [imports:fatigue]
import '../features/fatigue/fatigue_card.dart';
//
// [imports:overload]
import '../features/overload/overload_card.dart';
import '../features/overload/overload_notifications.dart';
//
// [imports:badges]
import '../features/achievements/achievements_service.dart';
import '../features/achievements/badges_screen.dart';
//
// [imports:progression]
import 'progression/progression_profile_section.dart';
import 'progression/progression_service.dart';
import 'progression/progression_summary.dart';
// [imports:cloud]
import 'cloud/cloud_module.dart';
// [imports:wear]
import 'wear/wear_bridge.dart';
import 'wear/wear_profile_section.dart';
// [imports:premium]
import '../premium/premium.dart';
import '../premium/premium_gift.dart';
import '../premium/premium_profile_section.dart';
import '../premium/premium_screen.dart';
import '../premium/premium_service.dart';
//

/// Inicializace před spuštěním aplikace (např. Firebase).
/// Chyba jednoho modulu nesmí zastavit start aplikace.
Future<void> initModules() async {
  final inits = <Future<void> Function()>[
    // [stats:init]
    //
    // [sharing:init]
    //
    // [calendar:init]
    //
    // [widgets:init]
    //
    // [health:init]
    //
    // [data:init]
    //
    // [social:init]
    socialInit,
    //
    // [premium:init]
    PremiumService.instance.init,
    //
  ];
  for (final init in inits) {
    try {
      await init();
    } catch (e) {
      debugPrint('Module init failed: $e');
    }
  }
}

/// Providery, které mají běžet po celou dobu (posluchače odkazů apod.).
/// Aplikace je v kořeni sleduje přes ref.watch.
List<ProviderListenable<Object?>> moduleAppProviders() => [
      deepLinkProvider,
      // [stats:app]
      //
      // [sharing:app]
      //
      // [calendar:app]
      calendarNotificationActionsProvider,
      //
      // [widgets:app]
      widgetsAppProvider,
      //
      // [health:app]
      //
      // [data:app]
      unitSystemProvider,
      //
      // [social:app]
      socialAppProvider,
      //
      // [cloud:app]
      cloudAppProvider,
      // [wear:app]
      // Premium (wearOs) hlídá WearBridge (stav „premiumRequired“).
      wearAppProvider,
      // [premium:app]
      premiumProfileSyncProvider,
      //
    ];

/// Obrazovky přes celou plochu (bez spodní lišty).
List<RouteBase> moduleRoutes() => [
      // [stats:routes]
      ...statsRoutes(),
      //
      // [sharing:routes]
      challengeRoute(),
      //
      // [calendar:routes]
      //
      // [widgets:routes]
      //
      // [health:routes]
      //
      // [data:routes]
      GoRoute(
        path: '/exercise-edit',
        builder: (context, state) => ExerciseEditScreen(
          exerciseId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      //
      // [social:routes]
      ...socialRoutes(),
      //
      // [badges:routes]
      badgesRoute(),
      //
      // [premium:routes]
      // Paywall existuje jen po spuštění Premium (do té doby nikde).
      if (kPremiumLaunched) premiumRoute(),
      //
    ];

/// Karty na obrazovce Dnes (pod vodou a váhou). Každá karta si sama
/// rozhodne, jestli se ukáže (jinak vrátí SizedBox.shrink()).
List<Widget> moduleTodayCards() => [
      // [stats:today]
      const StatsWeightDropTodayCard(),
      const StatsStreakTodayCard(),
      //
      // [sharing:today]
      const ChallengesTodayCard(),
      //
      // [calendar:today]
      const CalendarTodayCard(),
      //
      // [widgets:today]
      //
      // [health:today]
      //
      // [data:today]
      //
      // [social:today]
      //
      // [fatigue:today]
      const FatigueTodayCard(),
      //
      // [premium:today]
      // Jednorázová hláška „Premium na půl roku zdarma“ (nic nezobrazí).
      const PremiumGiftWelcome(),
      //
    ];

/// Karty na obrazovce Pokrok (pod grafy, nad historií).
List<Widget> moduleProgressCards() => [
      // [stats:progress]
      const StatsInsightsCard(),
      const StatsVolumeCard(),
      const StatsFrequencyCard(),
      const StatsRecordsEntryCard(),
      //
      // [overload:progress]
      const OverloadProgressCard(),
      //
      // [badges:progress]
      const BadgesEntryCard(),
      //
      // [sharing:progress]
      //
      // [calendar:progress]
      //
      // [widgets:progress]
      //
      // [health:progress]
      //
      // [data:progress]
      //
      // [social:progress]
      const GymProgressCard(),
      //
    ];

/// Sekce v Profilu (nad „O aplikaci“). Každá sekce má vlastní nadpis.
List<Widget> moduleProfileSections() => [
      // [premium:profile]
      const PremiumProfileSection(),
      //
      // [badges:profile]
      const BadgesProfileSection(),
      //
      // [stats:profile]
      //
      // [sharing:profile]
      //
      // [calendar:profile]
      const CalendarProfileSection(),
      //
      // [widgets:profile]
      //
      // [health:profile]
      const HealthProfileSection(),
      //
      // [data:profile]
      const DataProfileSection(),
      //
      // [cloud:profile]
      const CloudProfileSection(),
      //
      // [social:profile]
      const SocialProfileSection(),
      //
      // [progression:profile]
      // Premium (autoProgression): štítek a paywall uvnitř sekce.
      const ProgressionProfileSection(),
      // [wear:profile]
      // Premium (wearOs): upoutávka uvnitř sekce.
      const WearProfileSection(),
      //
    ];

/// Sekce v detailu cviku (pod návodem).
List<Widget> moduleExerciseDetailSections(Exercise exercise) => [
      // [stats:exercise]
      ExerciseStatsSection(exercise: exercise),
      //
      // [sharing:exercise]
      ExerciseShareSection(exercise: exercise),
      //
      // [calendar:exercise]
      //
      // [widgets:exercise]
      //
      // [health:exercise]
      //
      // [data:exercise]
      CustomExerciseEditButton(exercise: exercise),
      //
      // [social:exercise]
      //
    ];

/// Sekce v editoru plánu (pod seznamem cviků).
List<Widget> modulePlanEditorSections(int planId) => [
      // [stats:plan]
      //
      // [sharing:plan]
      //
      // [calendar:plan]
      CalendarPlanSection(planId: planId),
      //
      // [widgets:plan]
      //
      // [health:plan]
      //
      // [data:plan]
      //
      // [social:plan]
      //
    ];

/// Akce v souhrnu po tréninku (tlačítka pod rekordy, např. Sdílet).
List<Widget> moduleSummaryActions(WorkoutSummary summary) => [
      // [stats:summary]
      //
      // [sharing:summary]
      SharingSummaryActions(summary: summary),
      CompletedChallengesSection(summary: summary),
      //
      // [badges:summary]
      NewBadgesSummarySection(summary: summary),
      //
      // [progression:summary]
      // Premium (autoProgression): bez předplatného zamčená upoutávka.
      ProgressionSummarySection(summary: summary),
      //
      // [calendar:summary]
      //
      // [widgets:summary]
      //
      // [health:summary]
      //
      // [data:summary]
      //
      // [social:summary]
      //
    ];

/// Co se má stát po dokončení tréninku (před zobrazením souhrnu).
/// Volá se s ref obrazovky tréninku; chyby se jen zapíšou do logu.
typedef WorkoutFinishedHook = Future<void> Function(
  WidgetRef ref,
  WorkoutSummary summary,
);

List<WorkoutFinishedHook> moduleWorkoutFinishedHooks() => [
      // [stats:finished]
      //
      // [sharing:finished]
      sharingWorkoutFinished,
      //
      // [calendar:finished]
      //
      // [widgets:finished]
      //
      // [health:finished]
      healthWorkoutFinishedHook,
      //
      // [data:finished]
      //
      // [social:finished]
      SocialPublisher.onWorkoutFinished,
      //
      // [badges:finished]
      achievementsWorkoutFinished,
      //
      // [overload:finished]
      overloadWorkoutFinished,
      //
      // [progression:finished]
      progressionWorkoutFinished,
      // [cloud:finished]
      cloudWorkoutFinished,
      //
    ];

/// Po každé změně dat (s odstupem 2 s, viz SyncController).
typedef SyncHook = Future<void> Function(Ref ref, UserProfile profile);

List<SyncHook> moduleSyncHooks() => [
      // [stats:sync]
      //
      // [sharing:sync]
      sharingSync,
      //
      // [calendar:sync]
      //
      // [widgets:sync]
      widgetsSyncHook,
      //
      // [health:sync]
      healthSyncHook,
      //
      // [data:sync]
      //
      // [social:sync]
      SocialPublisher.onSync,
      //
      // [badges:sync]
      achievementsSync,
      //
      // [overload:sync]
      overloadSync,
      //
      // [cloud:sync]
      cloudSync,
      //
    ];

/// Spustí háčky po tréninku; chyba jednoho neovlivní ostatní.
Future<void> runWorkoutFinishedHooks(
  WidgetRef ref,
  WorkoutSummary summary,
) async {
  for (final hook in moduleWorkoutFinishedHooks()) {
    try {
      await hook(ref, summary);
    } catch (e) {
      debugPrint('Workout hook failed: $e');
    }
  }
}
