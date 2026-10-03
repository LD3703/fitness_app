import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Které části aplikace uživatel sleduje.
typedef ModuleSettings = ({
  bool water,
  bool weight,
  bool periods,
  bool calories,
});

/// Přepínače sledovaných modulů – sdílené úvodním průvodcem a Profilem.
class ModuleSwitches extends StatelessWidget {
  const ModuleSwitches({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ModuleSettings value;
  final ValueChanged<ModuleSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = value;
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.fitness_center),
          title: Text(l10n.moduleWorkouts),
          subtitle: Text(l10n.moduleWorkoutsHint),
          value: true,
          onChanged: null,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.water_drop_outlined),
          title: Text(l10n.moduleWater),
          subtitle: Text(l10n.moduleWaterHint),
          value: v.water,
          onChanged: (x) => onChanged((
            water: x,
            weight: v.weight,
            periods: v.periods,
            calories: v.calories,
          )),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.monitor_weight_outlined),
          title: Text(l10n.moduleWeight),
          subtitle: Text(l10n.moduleWeightHint),
          value: v.weight,
          onChanged: (x) => onChanged((
            water: v.water,
            weight: x,
            periods: v.periods,
            calories: v.calories,
          )),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.flag_outlined),
          title: Text(l10n.modulePeriods),
          subtitle: Text(l10n.modulePeriodsHint),
          value: v.periods,
          onChanged: (x) => onChanged((
            water: v.water,
            weight: v.weight,
            periods: x,
            calories: v.calories,
          )),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.local_fire_department_outlined),
          title: Text(l10n.moduleCalories),
          subtitle: Text(l10n.moduleCaloriesHint),
          value: v.calories,
          onChanged: (x) => onChanged((
            water: v.water,
            weight: v.weight,
            periods: v.periods,
            calories: x,
          )),
        ),
      ],
    );
  }
}
