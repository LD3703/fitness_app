// Výběr motivu vzhledu (Profil → Motiv, lib/ui/skins.dart). Každá dlaždice
// je zmenšený náhled obrazovky Dnes v daném motivu.
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/skins.dart';

String skinLabel(AppLocalizations l10n, AppSkin skin) => switch (skin) {
      AppSkin.classic => l10n.skinClassic,
      AppSkin.flowers => l10n.skinFlowers,
      AppSkin.skulls => l10n.skinSkulls,
      AppSkin.neon => l10n.skinNeon,
      AppSkin.retro => l10n.skinRetro,
      AppSkin.y2k => l10n.skinY2k,
      AppSkin.original => l10n.skinOriginal,
    };

/// Otevře výběr motivu; vrátí zvolený, nebo null (zpět).
Future<AppSkin?> showSkinPicker(BuildContext context, AppSkin current) =>
    Navigator.of(context).push<AppSkin>(
      MaterialPageRoute(builder: (_) => SkinPickerScreen(current: current)),
    );

class SkinPickerScreen extends StatelessWidget {
  const SkinPickerScreen({super.key, required this.current});

  final AppSkin current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.skinTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(l10n.skinHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.62,
            children: [
              for (final skin in AppSkin.values)
                SkinPreviewTile(
                  skin: skin,
                  selected: skin == current,
                  onTap: () => Navigator.of(context).pop(skin),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Zmenšený náhled motivu: záhlaví s ozdobou, karta tréninku, lišta.
class SkinPreviewTile extends StatelessWidget {
  const SkinPreviewTile({
    super.key,
    required this.skin,
    required this.selected,
    required this.onTap,
  });

  final AppSkin skin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outer = Theme.of(context).colorScheme;
    final data = skinTheme(skin, brightness: Theme.of(context).brightness);
    final scheme = data.colorScheme;
    final label = skinLabel(l10n, skin);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? outer.primary : outer.outlineVariant,
                width: selected ? 3 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: data,
              child: ExcludeSemantics(
                child: ColoredBox(
                  color: data.scaffoldBackgroundColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 44,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: data.appBarTheme.backgroundColor,
                          ),
                          child: SkinHeaderMotif(skin: skin),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: data.textTheme.titleLarge?.copyWith(
                            fontSize: (data.textTheme.titleLarge?.fontSize ?? 22) * 0.75,
                            height: 1.1,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Card(
                                margin: EdgeInsets.zero,
                                color: scheme.primary,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.todayWorkoutTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: data.textTheme.labelMedium
                                            ?.copyWith(color: scheme.onPrimary),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 26,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: scheme.onPrimary,
                                          borderRadius: BorderRadius.circular(
                                            skinSpec(skin)?.buttonRadius ?? 12,
                                          ),
                                        ),
                                        child: Text(
                                          l10n.workoutStart,
                                          style: data.textTheme.labelMedium?.copyWith(
                                            color: scheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Card(
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(height: 8, width: 60, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: const LinearProgressIndicator(value: 0.7, minHeight: 6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (selected)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(Icons.check_circle, color: scheme.primary),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 22,
                        color: data.navigationBarTheme.backgroundColor,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (var i = 0; i < 5; i++)
                              Icon(
                                Icons.circle,
                                size: 7,
                                color: i == 0 ? scheme.primary : scheme.onSurfaceVariant,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
