import 'package:flutter/material.dart';

import '../../data/enums.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/labels.dart';
import 'badges.dart';

/// Ikona odznaku (Material ikony, žádné emoji).
IconData badgeIcon(BadgeDef b) => switch (b.kind) {
      BadgeKind.overloadStreak => Icons.local_fire_department,
      BadgeKind.mastery => Icons.military_tech,
      BadgeKind.records => Icons.emoji_events,
      BadgeKind.consistency => Icons.event_available,
    };

String badgeName(AppLocalizations l10n, BadgeDef b) => switch (b.kind) {
      BadgeKind.overloadStreak => l10n.badgeOverloadStreakName(b.threshold),
      BadgeKind.mastery =>
        l10n.badgeMasteryName(l10n.muscleGroup(b.group ?? MuscleGroup.fullBody)),
      BadgeKind.records => l10n.badgeRecordsName(b.threshold),
      BadgeKind.consistency => l10n.badgeConsistencyName(b.threshold),
    };

/// Jak odznak získat (zobrazuje se u zamčených i získaných odznaků).
/// Pozn.: text mistrovství obsahuje čísla 8 a 4 (masteryWeeks,
/// masteryProgressingWeeks v core/progressive_overload.dart).
String badgeDescription(AppLocalizations l10n, BadgeDef b) => switch (b.kind) {
      BadgeKind.overloadStreak => l10n.badgeOverloadStreakDescription(b.threshold),
      BadgeKind.mastery => l10n.badgeMasteryDescription(
          l10n.muscleGroup(b.group ?? MuscleGroup.fullBody)),
      BadgeKind.records => l10n.badgeRecordsDescription(b.threshold),
      BadgeKind.consistency => l10n.badgeConsistencyDescription(b.threshold),
    };

String badgeSectionTitle(AppLocalizations l10n, BadgeKind kind) =>
    switch (kind) {
      BadgeKind.overloadStreak => l10n.badgeSectionOverload,
      BadgeKind.mastery => l10n.badgeSectionMastery,
      BadgeKind.records => l10n.badgeSectionRecords,
      BadgeKind.consistency => l10n.badgeSectionConsistency,
    };

/// Kulatá ikona odznaku: získaný barevně, zamčený šedě.
class BadgeAvatar extends StatelessWidget {
  const BadgeAvatar({
    super.key,
    required this.badge,
    required this.earned,
    this.size = 44,
  });

  final BadgeDef badge;
  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: earned ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        border: earned ? Border.all(color: scheme.primary, width: 2) : null,
      ),
      child: Icon(
        badgeIcon(badge),
        size: size * 0.55,
        color: earned
            ? scheme.onPrimaryContainer
            : scheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    );
  }
}
