import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/module_switches.dart';

/// Úvodní průvodce při prvním spuštění: jméno, výběr toho, co chce
/// uživatel sledovat, jednotky a tón zpráv (přátelský / přísný trenér).
/// Po dokončení router přesměruje na Dnes.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  final _waterGoal = TextEditingController(text: '2500');
  final _weight = TextEditingController();
  ModuleSettings _modules =
      (water: true, weight: true, periods: true, calories: true);
  UnitSystem _units = unitSystemNotifier.value;

  /// Tón zpráv: 0 = přátelský, 1 = přísný trenér (UserProfile.coachTone).
  int _coachTone = 0;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Stávající uživatel (po aktualizaci) uvidí své dosavadní hodnoty.
    final p = ref.read(profileProvider).valueOrNull;
    if (p != null) {
      _name.text = p.name ?? '';
      _units = p.unitSystem;
      _waterGoal.text = mlToUnit(p.waterGoalMl, _units).round().toString();
      _modules = (
        water: p.trackWater,
        weight: p.trackWeight,
        periods: p.trackPeriods,
        calories: p.showCalories,
      );
      _coachTone = p.coachTone == 1 ? 1 : 0;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _waterGoal.dispose();
    _weight.dispose();
    super.dispose();
  }

  /// Přepne jednotky a převede už zadané hodnoty.
  void _setUnits(UnitSystem units) {
    final old = _units;
    if (units == old) return;
    final water = int.tryParse(_waterGoal.text.trim());
    final weight = parseDecimal(_weight.text);
    setState(() {
      _units = units;
      unitSystemNotifier.value = units;
      if (water != null) {
        _waterGoal.text =
            mlToUnit(unitToMl(water.toDouble(), old), units).round().toString();
      }
      if (weight != null) {
        _weight.text = plainNumber(
          roundDecimals(kgToUnit(unitToKg(weight, old), units), 1),
        );
      }
    });
    ref
        .read(databaseProvider)
        .updateProfile(UserProfilesCompanion(unitSystem: Value(units)));
  }

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context);
    int? goal;
    if (_modules.water) {
      final min = mlToUnit(500, _units).floorToDouble();
      final max = mlToUnit(6000, _units).ceilToDouble();
      final value = int.tryParse(_waterGoal.text.trim());
      if (value == null || value < min || value > max) {
        setState(() => _error = l10n.dataRangeInvalid(
              formatDecimal(context, min, maxDecimals: 0),
              formatDecimal(context, max, maxDecimals: 0),
            ));
        return;
      }
      goal = unitToMl(value.toDouble(), _units).clamp(500, 6000).toInt();
    }
    double? weight;
    if (_modules.weight && _weight.text.trim().isNotEmpty) {
      final min = kgToUnit(20, _units).floorToDouble();
      final max = kgToUnit(400, _units).ceilToDouble();
      final value = parseDecimal(_weight.text);
      if (value == null || value < min || value > max) {
        setState(() => _error = l10n.dataRangeInvalid(
              formatDecimal(context, min, maxDecimals: 0),
              formatDecimal(context, max, maxDecimals: 0),
            ));
        return;
      }
      weight = unitToKg(value, _units).clamp(20, 400).toDouble();
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final db = ref.read(databaseProvider);
    if (weight != null) await db.logWeight(DateTime.now(), weight);
    final name = _name.text.trim();
    await db.updateProfile(UserProfilesCompanion(
      name: Value(name.isEmpty ? null : name),
      waterGoalMl: goal == null ? const Value.absent() : Value(goal),
      unitSystem: Value(_units),
      trackWater: Value(_modules.water),
      trackWeight: Value(_modules.weight),
      trackPeriods: Value(_modules.periods),
      showCalories: Value(_modules.calories),
      coachTone: Value(_coachTone),
      onboardingDone: const Value(true),
    ));
    // Přesměrování na Dnes zařídí router, jakmile se profil uloží.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.onboardingTitle,
                      style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(l10n.onboardingIntro),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.profileName),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.onboardingModulesTitle,
                      style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ModuleSwitches(
              value: _modules,
              onChanged: (v) => setState(() => _modules = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(l10n.dataUnits, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<UnitSystem>(
                    segments: [
                      ButtonSegment(
                        value: UnitSystem.metric,
                        label: Text(l10n.dataUnitsMetric),
                      ),
                      ButtonSegment(
                        value: UnitSystem.imperial,
                        label: Text(l10n.dataUnitsImperial),
                      ),
                    ],
                    selected: {_units},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => _setUnits(s.first),
                  ),
                  if (_modules.water) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _waterGoal,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: l10n.dataWaterGoalDialog(volumeUnit),
                      ),
                    ),
                  ],
                  if (_modules.weight) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.dataOnboardingWeight(weightUnit),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(l10n.coachToneTitle,
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    l10n.onboardingToneIntro,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ToneCard(
                    selected: _coachTone == 0,
                    icon: Icons.sentiment_satisfied_outlined,
                    title: l10n.coachToneFriendly,
                    example: l10n.onboardingToneExample(l10n.encSkipNormal1),
                    onTap: () => setState(() => _coachTone = 0),
                  ),
                  const SizedBox(height: 8),
                  _ToneCard(
                    selected: _coachTone == 1,
                    icon: Icons.sports,
                    title: l10n.coachToneStrict,
                    example: l10n.onboardingToneExample(l10n.coachSkip2),
                    hint: l10n.coachToneStrictHint,
                    onTap: () => setState(() => _coachTone = 1),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _finish,
                    child: Text(l10n.onboardingStart),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.onboardingChangeLater,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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

/// Volitelná karta tónu zpráv s ukázkovou hláškou.
class _ToneCard extends StatelessWidget {
  const _ToneCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.example,
    required this.onTap,
    this.hint,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String example;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: selected
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        example,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontStyle: FontStyle.italic),
                      ),
                      if (hint != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          hint!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? scheme.primary : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
