import 'package:flutter/material.dart';

/// Karta ve stylu grafů na obrazovce Pokrok.
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Text místo grafu, když ještě nejsou data.
class StatsEmpty extends StatelessWidget {
  const StatsEmpty(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 64,
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
}

/// Nadpis podsekce uvnitř karty.
class StatsSubheading extends StatelessWidget {
  const StatsSubheading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// Řádek vodorovného sloupcového grafu: popisek, pruh, hodnota.
typedef HorizontalBarItem = ({String label, double value, String valueText});

/// Jednoduchý vodorovný sloupcový graf z kontejnerů.
class HorizontalBars extends StatelessWidget {
  const HorizontalBars({super.key, required this.items, this.color});

  final List<HorizontalBarItem> items;

  /// Barva pruhů (výchozí primární barva motivu).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = color ?? theme.colorScheme.primary;
    final maxValue = items.fold<double>(0, (m, i) => i.value > m ? i.value : m);
    return Column(
      children: [
        for (final item in items)
          Semantics(
            label: '${item.label}: ${item.valueText}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 12,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: maxValue <= 0
                            ? 0
                            : (item.value / maxValue).clamp(0.02, 1.0),
                        heightFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: Text(
                      item.valueText,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
