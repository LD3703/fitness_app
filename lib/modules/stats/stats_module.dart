// Modul statistik: objem, frekvence, postřehy, rekordy, série týdnů.
// Napojení na aplikaci je v lib/modules/module_hub.dart pod značkami [stats:*].

import 'package:go_router/go_router.dart';

import 'widgets/records_screen.dart';

export 'widgets/exercise_stats_section.dart' show ExerciseStatsSection;
export 'widgets/frequency_card.dart' show StatsFrequencyCard;
export 'widgets/insights_card.dart' show StatsInsightsCard;
export 'widgets/records_screen.dart' show RecordsScreen, StatsRecordsEntryCard;
export 'widgets/today_cards.dart'
    show StatsStreakTodayCard, StatsWeightDropTodayCard;
export 'widgets/volume_card.dart' show StatsVolumeCard;

/// Obrazovky modulu (přes celou plochu).
List<RouteBase> statsRoutes() => [
      GoRoute(
        path: '/records',
        builder: (context, state) => const RecordsScreen(),
      ),
    ];
