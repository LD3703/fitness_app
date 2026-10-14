import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fatigue.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/body_map.dart';
import '../../ui/labels.dart';
import 'fatigue_providers.dart';

/// Barva stavu únavy. Stavy se liší i světlostí (nejen odstínem)
/// a vždy se zobrazují s ikonou a popiskem, nikdy jen barvou.
Color fatigueColor(BuildContext context, FatigueStatus status) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (status) {
    // Světlý motiv: unaveno nejtmavší (červená), zotavuje se nejsvětlejší
    // (oranžová); tmavý motiv obráceně. Zotaveno je ve světlém motivu
    // tmavě zelené (green 800, kontrast ~5 : 1 na bílé) – dřívější
    // 0xFF81C784 mělo jen ~1,9 : 1 a ikona i pruh na kartě zanikaly.
    FatigueStatus.fatigued =>
      dark ? const Color(0xFFFFCDD2) : const Color(0xFFB71C1C),
    FatigueStatus.recovering =>
      dark ? const Color(0xFFFFA726) : const Color(0xFFEF6C00),
    FatigueStatus.recovered =>
      dark ? const Color(0xFF388E3C) : const Color(0xFF2E7D32),
  };
}

IconData fatigueIcon(FatigueStatus status) => switch (status) {
      FatigueStatus.fatigued => Icons.battery_alert,
      FatigueStatus.recovering => Icons.hourglass_bottom,
      FatigueStatus.recovered => Icons.check_circle_outline,
    };

String fatigueStatusLabel(AppLocalizations l10n, FatigueStatus status) =>
    switch (status) {
      FatigueStatus.fatigued => l10n.fatigueStatusFatigued,
      FatigueStatus.recovering => l10n.fatigueStatusRecovering,
      FatigueStatus.recovered => l10n.fatigueStatusRecovered,
    };

/// Karta Dnes: únava svalových partií z tréninků za posledních 7 dní.
/// Bez tréninku v posledních 7 dnech se nezobrazí.
class FatigueTodayCard extends ConsumerWidget {
  const FatigueTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(fatigueProvider).valueOrNull;
    if (report == null || report.sessions == 0) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final sorted = sortedByFatigue(report);
    final active = [
      for (final e in sorted)
        if (fatigueStatus(e.value) != FatigueStatus.recovered) e,
    ];
    final recovered = [
      for (final e in sorted)
        if (fatigueStatus(e.value) == FatigueStatus.recovered) e.key,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.accessibility_new,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.fatigueTitle,
                      style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(l10n.fatigueSubtitle(report.sessions), style: muted),
            const SizedBox(height: 12),
            // Mapa těla: partie v barvě stavu (stejné barvy jako řádky
            // níže, které stav popisují i slovy a ikonou).
            Center(
              child: BodyMap(
                height: 170,
                colors: {
                  for (final e in sorted)
                    if (e.value >= 1)
                      e.key: fatigueColor(context, fatigueStatus(e.value)),
                },
                semanticLabel: l10n.fatigueTitle,
              ),
            ),
            const SizedBox(height: 12),
            for (final e in active) _FatigueRow(group: e.key, percent: e.value),
            if (recovered.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      fatigueIcon(FatigueStatus.recovered),
                      size: 20,
                      color: fatigueColor(context, FatigueStatus.recovered),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        active.isEmpty
                            ? l10n.fatigueAllRecovered
                            : l10n.fatigueRecoveredList(
                                recovered.map(l10n.muscleGroup).join(', '),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(l10n.fatigueHint, style: muted),
          ],
        ),
      ),
    );
  }
}

class _FatigueRow extends StatelessWidget {
  const _FatigueRow({required this.group, required this.percent});

  final MuscleGroup group;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = fatigueStatus(percent);
    final color = fatigueColor(context, status);
    final statusText =
        '${fatigueStatusLabel(l10n, status)} · ${l10n.fatiguePercent(percent.round())}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: '${l10n.muscleGroup(group)}: $statusText',
        excludeSemantics: true,
        child: Row(
          children: [
            Icon(fatigueIcon(status), size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(l10n.muscleGroup(group))),
                      Text(statusText, style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 6,
                    color: color,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
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
