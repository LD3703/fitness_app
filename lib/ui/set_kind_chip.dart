import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Štítek druhu série s celým slovem („Rozcvička“, „Drop série“).
/// Používá ho trénink i editor plánu.
class SetKindChip extends StatelessWidget {
  const SetKindChip({super.key, required this.isWarmup, this.showIcon = true});

  /// true = rozcvička, false = drop série.
  final bool isWarmup;

  /// Ikona před slovem (v tréninku je ikona už místo čísla série).
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background =
        isWarmup ? scheme.tertiaryContainer : scheme.secondaryContainer;
    final foreground =
        isWarmup ? scheme.onTertiaryContainer : scheme.onSecondaryContainer;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                isWarmup ? Icons.whatshot : Icons.trending_down,
                size: 12,
                color: foreground,
              ),
              const SizedBox(width: 3),
            ],
            Text(
              isWarmup ? l10n.setKindWarmup : l10n.setKindDrop,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
