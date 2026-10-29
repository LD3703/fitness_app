import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/workout/rest_timer.dart';
import '../l10n/app_localizations.dart';
import 'format.dart';

/// Spodní navigace s pěti záložkami. Každá záložka si drží vlastní historii.
/// Nad ní je během pauzy rozpracovaného tréninku odpočet ([PendingRestBar]).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PendingRestBar(),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              // Opakované klepnutí na aktivní záložku vrátí na její začátek.
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.today_outlined),
                selectedIcon: const Icon(Icons.today),
                label: l10n.tabToday,
              ),
              NavigationDestination(
                icon: const Icon(Icons.event_note_outlined),
                selectedIcon: const Icon(Icons.event_note),
                label: l10n.tabPlans,
              ),
              NavigationDestination(
                icon: const Icon(Icons.fitness_center_outlined),
                selectedIcon: const Icon(Icons.fitness_center),
                label: l10n.tabExercises,
              ),
              NavigationDestination(
                icon: const Icon(Icons.insights_outlined),
                selectedIcon: const Icon(Icons.insights),
                label: l10n.tabProgress,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: l10n.tabProfile,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Odpočet pauzy, která běží po odchodu z obrazovky tréninku
/// ([pendingRest]); klepnutí vrátí do tréninku. Po konci pauzy zmizí.
class PendingRestBar extends StatefulWidget {
  const PendingRestBar({super.key});

  @override
  State<PendingRestBar> createState() => PendingRestBarState();
}

class PendingRestBarState extends State<PendingRestBar> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    pendingRest.addListener(_sync);
    _sync();
  }

  void _sync() {
    final rest = pendingRest.value;
    final running = rest != null && rest.endsAt.isAfter(DateTime.now());
    if (running && _ticker == null) {
      _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
        final r = pendingRest.value;
        if (r == null || !r.endsAt.isAfter(DateTime.now())) {
          _ticker?.cancel();
          _ticker = null;
        }
        if (mounted) setState(() {});
      });
    } else if (!running) {
      _ticker?.cancel();
      _ticker = null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    pendingRest.removeListener(_sync);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rest = pendingRest.value;
    final left = rest?.endsAt.difference(DateTime.now());
    if (rest == null || left == null || left <= Duration.zero) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progress = rest.totalSeconds <= 0
        ? 0.0
        : (left.inMilliseconds / (rest.totalSeconds * 1000)).clamp(0.0, 1.0);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: InkWell(
        onTap: () => context.push('/workout/${rest.sessionId}'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: progress),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.workoutRest,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatDuration(left + const Duration(milliseconds: 999)),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.push('/workout/${rest.sessionId}'),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.workoutResume),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
