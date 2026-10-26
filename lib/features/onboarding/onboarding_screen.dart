import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/experience_level.dart';
import '../../core/rest_time.dart';
import '../../core/text_filter.dart';
import '../../data/database.dart';
import '../../data/seed/content_i18n.dart';
import '../../data/seed/plan_templates.dart';
import '../../l10n/app_localizations.dart';
import '../../premium/premium.dart';
import '../../providers.dart';
import '../../services/calendar_service.dart';
import '../../services/notification_service.dart';
import '../../ui/brand_mark.dart';
import '../../ui/format.dart';
import '../../ui/labels.dart';
import '../../ui/module_switches.dart';
import '../../ui/skins.dart';
import '../../ui/weekdays.dart';
import '../profile/skin_picker.dart';

/// Kroky průvodce. Krok [body] se přeskočí, když uživatel nesleduje vodu
/// ani váhu.
enum _Step {
  welcome,
  about,
  goal,
  level,
  tracking,
  body,
  look,
  tone,
  reminders,
  plan,
  done,
}

/// Úvodní průvodce při prvním spuštění (a znovu z Profilu): krok po kroku
/// jméno a údaje o sobě, cíl tréninku, úroveň pokročilosti, co sledovat, pitný režim a váha,
/// vzhled, tón zpráv, připomínky a první plán z hotového programu.
/// Na konci uloží profil (onboardingDone) a router přesměruje na Dnes.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  final _birthYear = TextEditingController();
  final _waterGoal = TextEditingController(text: '2500');
  final _weight = TextEditingController();
  Sex? _sex;
  ModuleSettings _modules =
      (water: true, weight: true, periods: true, calories: true);
  UnitSystem _units = unitSystemNotifier.value;

  /// Cíl tréninku (síla / svaly / výdrž) – výchozí zaměření tréninků
  /// a varianta hotových programů.
  TrainingFocus _goal = TrainingFocus.muscle;

  /// Úroveň pokročilosti – doporučené programy a počet sérií.
  ExperienceLevel _level = ExperienceLevel.beginner;

  /// Tón zpráv: 0 = přátelský, 1 = přísný trenér (UserProfile.coachTone).
  int _coachTone = 0;
  AppSkin _skin = AppSkin.classic;
  bool _morningReminder = false;
  int _morningMinutes = 450;
  bool _waterReminders = false;
  bool _calendarSync = false;

  /// Hotový program, který se na konci přidá do Plánů (null = žádný).
  TemplateProgram? _program;

  _Step _step = _Step.welcome;
  String? _error;
  bool _saving = false;

  /// Nejnižší povolený rok narození je 1920, nejvyšší „před 10 lety“
  /// (deník je pro kohokoli od 10 let, stejně jako v Profilu).
  int get _maxBirthYear => DateTime.now().year - 10;

  List<_Step> get _steps => [
        for (final s in _Step.values)
          if (s != _Step.body || _modules.water || _modules.weight) s,
      ];

  @override
  void initState() {
    super.initState();
    // Stávající uživatel (po aktualizaci nebo znovu z Profilu) uvidí své
    // dosavadní hodnoty.
    final p = ref.read(profileProvider).valueOrNull;
    if (p != null) {
      _name.text = p.name ?? '';
      _birthYear.text = p.birthYear?.toString() ?? '';
      _sex = sexOf(p.sex);
      _units = p.unitSystem;
      _waterGoal.text = mlToUnit(p.waterGoalMl, _units).round().toString();
      _modules = (
        water: p.trackWater,
        weight: p.trackWeight,
        periods: p.trackPeriods,
        calories: p.showCalories,
      );
      _coachTone = p.coachTone == 1 ? 1 : 0;
      _goal = trainingFocusOf(p.trainingFocus);
      _level = experienceLevelOf(p.experienceLevel);
      _skin = AppSkin.fromKey(p.skin);
      _morningReminder = p.morningReminderEnabled;
      _morningMinutes = p.morningReminderMinutes;
      _waterReminders = p.waterRemindersEnabled;
      _calendarSync = p.calendarSyncEnabled;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _birthYear.dispose();
    _waterGoal.dispose();
    _weight.dispose();
    super.dispose();
  }

  AppDatabase get _db => ref.read(databaseProvider);

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
    _db.updateProfile(UserProfilesCompanion(unitSystem: Value(units)));
  }

  /// Motiv se uloží hned – aplikace se přebarví a uživatel vidí výsledek.
  void _setSkin(AppSkin skin) {
    setState(() => _skin = skin);
    _db.updateProfile(UserProfilesCompanion(skin: Value(skin.key)));
  }

  /// Zapnutí připomínky si řekne o povolení oznámení / kalendáře.
  Future<void> _toggle(
    bool enable,
    Future<bool> Function() requestPermission,
    void Function(bool) apply,
  ) async {
    if (enable && !await requestPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).permissionDenied),
        ));
      }
      return;
    }
    if (mounted) setState(() => apply(enable));
  }

  Future<void> _pickMorningTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: _morningMinutes ~/ 60, minute: _morningMinutes % 60),
    );
    if (t != null) setState(() => _morningMinutes = t.hour * 60 + t.minute);
  }

  int? get _birthYearValue => int.tryParse(_birthYear.text.trim());

  /// Pitný režim v ml (null = nesleduje se nebo neplatné – viz [_validate]).
  int? get _waterGoalMl {
    final value = int.tryParse(_waterGoal.text.trim());
    if (!_modules.water || value == null) return null;
    return unitToMl(value.toDouble(), _units).clamp(500, 6000).toInt();
  }

  double? get _weightKg {
    final value = parseDecimal(_weight.text);
    if (!_modules.weight || value == null) return null;
    return unitToKg(value, _units).clamp(20, 400).toDouble();
  }

  /// Chyba v aktuálním kroku, nebo null.
  String? _validate(_Step step) {
    final l10n = AppLocalizations.of(context);
    switch (step) {
      case _Step.about:
        if (containsSevereProfanity(_name.text)) return l10n.textFilterBlocked;
        if (_birthYear.text.trim().isNotEmpty) {
          final year = _birthYearValue;
          if (year == null || year < 1920 || year > _maxBirthYear) {
            return l10n.profileBirthYearInvalid(1920, _maxBirthYear);
          }
        }
      case _Step.body:
        if (_modules.water) {
          final min = mlToUnit(500, _units).floorToDouble();
          final max = mlToUnit(6000, _units).ceilToDouble();
          final value = int.tryParse(_waterGoal.text.trim());
          if (value == null || value < min || value > max) {
            return l10n.dataRangeInvalid(
              formatDecimal(context, min, maxDecimals: 0),
              formatDecimal(context, max, maxDecimals: 0),
            );
          }
        }
        if (_modules.weight && _weight.text.trim().isNotEmpty) {
          final min = kgToUnit(20, _units).floorToDouble();
          final max = kgToUnit(400, _units).ceilToDouble();
          final value = parseDecimal(_weight.text);
          if (value == null || value < min || value > max) {
            return l10n.dataRangeInvalid(
              formatDecimal(context, min, maxDecimals: 0),
              formatDecimal(context, max, maxDecimals: 0),
            );
          }
        }
      default:
        break;
    }
    return null;
  }

  void _next() {
    final error = _validate(_step);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    FocusScope.of(context).unfocus();
    final steps = _steps;
    final i = steps.indexOf(_step);
    if (i == steps.length - 1) {
      _finish();
      return;
    }
    setState(() {
      _error = null;
      _step = steps[i + 1];
    });
  }

  void _back() {
    FocusScope.of(context).unfocus();
    final steps = _steps;
    final i = steps.indexOf(_step);
    if (i <= 0) return;
    setState(() {
      _error = null;
      _step = steps[i - 1];
    });
  }

  Future<void> _finish() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final db = _db;
    final weight = _weightKg;
    if (weight != null) await db.logWeight(DateTime.now(), weight);
    final program = _program;
    if (program != null && mounted) {
      await db.addProgram(
        program,
        languageCode: Localizations.localeOf(context).languageCode,
        goal: _goal,
        level: _level,
      );
    }
    // Tréninky pro další úroveň se počítají od zvolení úrovně; stejná
    // úroveň při opakovaném průvodci počítání nevynuluje.
    final previous = ref.read(profileProvider).valueOrNull;
    if (previous == null ||
        previous.experienceSince == null ||
        experienceLevelOf(previous.experienceLevel) != _level) {
      await db.setExperienceLevel(_level);
    }
    final name = _name.text.trim();
    final water = _waterGoalMl;
    await db.updateProfile(UserProfilesCompanion(
      name: Value(name.isEmpty ? null : name),
      birthYear: Value(_birthYearValue),
      sex: Value(_sex?.index),
      waterGoalMl: water == null ? const Value.absent() : Value(water),
      unitSystem: Value(_units),
      trackWater: Value(_modules.water),
      trackWeight: Value(_modules.weight),
      trackPeriods: Value(_modules.periods),
      showCalories: Value(_modules.calories),
      coachTone: Value(_coachTone),
      trainingFocus: Value(_goal.index),
      skin: Value(_skin.key),
      morningReminderEnabled: Value(_morningReminder),
      morningReminderMinutes: Value(_morningMinutes),
      waterRemindersEnabled: Value(_modules.water && _waterReminders),
      calendarSyncEnabled: Value(_calendarSync),
      onboardingDone: const Value(true),
    ));
    // Přesměrování na Dnes zařídí router, jakmile se profil uloží.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final steps = _steps;
    final index = steps.indexOf(_step);
    final last = index == steps.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step != _Step.welcome)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: index / (steps.length - 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.onboardingStepOf(index, steps.length - 1),
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    children: _content(context, _step),
                  ),
                ),
              ),
            ),
            // Chyba nad tlačítky – vidět i u dlouhého kroku.
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (index > 0)
                    TextButton(
                      onPressed: _saving ? null : _back,
                      child: Text(l10n.onboardingBack),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving ? null : _next,
                    child: Text(switch (_step) {
                      _Step.welcome => l10n.onboardingStart,
                      _ when last => l10n.onboardingFinish,
                      _ => l10n.onboardingNext,
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Nadpis a vysvětlení kroku.
  List<Widget> _header(BuildContext context, String title, [String? hint]) {
    final theme = Theme.of(context);
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(title, style: theme.textTheme.headlineSmall),
      ),
      if (hint != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Text(
            hint,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      const SizedBox(height: 16),
    ];
  }

  Widget _padded(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: child,
      );

  List<Widget> _content(BuildContext context, _Step step) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final lang = Localizations.localeOf(context).languageCode;
    String programName(TemplateProgram p) => seedText(lang,
        en: p.nameEn, cs: p.nameCs, other: (t) => t.programNames[p.slug]);
    String programDescription(TemplateProgram p) => seedText(lang,
        en: p.descriptionEn,
        cs: p.descriptionCs,
        other: (t) => t.programDescriptions[p.slug]);

    switch (step) {
      case _Step.welcome:
        return [
          const SizedBox(height: 24),
          const Center(child: BrandMark(size: 72)),
          const SizedBox(height: 24),
          _padded(Text(l10n.onboardingTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium)),
          const SizedBox(height: 12),
          _padded(Text(l10n.onboardingWizardIntro,
              textAlign: TextAlign.center, style: theme.textTheme.bodyLarge)),
          const SizedBox(height: 32),
          _padded(Text(l10n.healthDisclaimer,
              textAlign: TextAlign.center, style: muted)),
        ];

      case _Step.about:
        return [
          ..._header(
              context, l10n.onboardingAboutTitle, l10n.onboardingAboutHint),
          _padded(TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.profileName),
          )),
          const SizedBox(height: 16),
          _padded(TextField(
            controller: _birthYear,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(labelText: l10n.profileBirthYear),
          )),
          const SizedBox(height: 16),
          _padded(Text(l10n.profileSex, style: theme.textTheme.titleSmall)),
          const SizedBox(height: 8),
          _padded(Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in [Sex.male, Sex.female, null])
                ChoiceChip(
                  label: Text(l10n.sex(s)),
                  selected: _sex == s,
                  onSelected: (_) => setState(() => _sex = s),
                ),
            ],
          )),
          const SizedBox(height: 6),
          _padded(Text(l10n.profileSexHint, style: muted)),
          const SizedBox(height: 16),
          _padded(Text(l10n.dataUnits, style: theme.textTheme.titleSmall)),
          const SizedBox(height: 8),
          _padded(SegmentedButton<UnitSystem>(
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
          )),
        ];

      case _Step.goal:
        return [
          ..._header(
              context, l10n.onboardingGoalTitle, l10n.onboardingGoalHint),
          for (final f in TrainingFocus.values) ...[
            _padded(_ChoiceCard(
              selected: _goal == f,
              icon: switch (f) {
                TrainingFocus.strength => Icons.fitness_center,
                TrainingFocus.muscle => Icons.accessibility_new,
                TrainingFocus.conditioning => Icons.directions_run,
              },
              title: l10n.trainingFocus(f),
              body: l10n.trainingGoalHint(f),
              onTap: () => setState(() => _goal = f),
            )),
            const SizedBox(height: 8),
          ],
        ];

      case _Step.level:
        return [
          ..._header(
              context, l10n.onboardingLevelTitle, l10n.onboardingLevelHint),
          for (final level in ExperienceLevel.values) ...[
            _padded(_ChoiceCard(
              selected: _level == level,
              icon: switch (level) {
                ExperienceLevel.beginner => Icons.emoji_people,
                ExperienceLevel.intermediate => Icons.trending_up,
                ExperienceLevel.advanced => Icons.military_tech_outlined,
              },
              title: l10n.experienceLevel(level),
              body: l10n.experienceLevelHint(level),
              onTap: () => setState(() {
                _level = level;
                // Program z jiné úrovně se v nabídce už neukáže.
                if (_program?.level != level) _program = null;
              }),
            )),
            const SizedBox(height: 8),
          ],
        ];

      case _Step.tracking:
        return [
          ..._header(
              context, l10n.onboardingModulesTitle, l10n.onboardingIntro),
          ModuleSwitches(
            value: _modules,
            onChanged: (v) => setState(() => _modules = v),
          ),
        ];

      case _Step.body:
        return [
          ..._header(context, l10n.onboardingBodyTitle),
          if (_modules.water) ...[
            _padded(TextField(
              controller: _waterGoal,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.dataWaterGoalDialog(volumeUnit),
              ),
            )),
            const SizedBox(height: 16),
          ],
          if (_modules.weight)
            _padded(TextField(
              controller: _weight,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.dataOnboardingWeight(weightUnit),
              ),
            )),
        ];

      case _Step.look:
        return [
          ..._header(context, l10n.onboardingLookTitle, l10n.skinHint),
          _padded(GridView.count(
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
                  selected: skin == _skin,
                  onTap: () => _setSkin(skin),
                ),
            ],
          )),
        ];

      case _Step.tone:
        return [
          ..._header(context, l10n.coachToneTitle, l10n.onboardingToneIntro),
          _padded(_ToneCard(
            selected: _coachTone == 0,
            icon: Icons.sentiment_satisfied_outlined,
            title: l10n.coachToneFriendly,
            example: l10n.onboardingToneExample(l10n.encSkipNormal1),
            onTap: () => setState(() => _coachTone = 0),
          )),
          const SizedBox(height: 8),
          _padded(_ToneCard(
            selected: _coachTone == 1,
            icon: Icons.sports,
            title: l10n.coachToneStrict,
            example: l10n.onboardingToneExample(l10n.coachSkip2),
            hint: l10n.coachToneStrictHint,
            onTap: () => setState(() => _coachTone = 1),
          )),
        ];

      case _Step.reminders:
        final time = formatMinutesOfDay(context, _morningMinutes);
        return [
          ..._header(context, l10n.profileRemindersSection,
              l10n.onboardingRemindersHint),
          SwitchListTile(
            secondary: const Icon(Icons.alarm),
            title: Text(l10n.profileMorningReminder),
            subtitle: Text(l10n.profileMorningReminderHint(time)),
            value: _morningReminder,
            onChanged: (v) => _toggle(
              v,
              NotificationService.instance.requestPermission,
              (v) => _morningReminder = v,
            ),
          ),
          if (_morningReminder)
            ListTile(
              leading: const SizedBox(width: 24),
              title: Text(l10n.profileMorningReminderTime),
              trailing: Text(time, style: theme.textTheme.titleMedium),
              onTap: _pickMorningTime,
            ),
          if (_modules.water)
            SwitchListTile(
              secondary: const Icon(Icons.water_drop_outlined),
              title: Text(l10n.profileWaterReminders),
              value: _waterReminders,
              onChanged: (v) => _toggle(
                v,
                NotificationService.instance.requestPermission,
                (v) => _waterReminders = v,
              ),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_month_outlined),
            title: Text(l10n.profileCalendarSync),
            subtitle: Text(l10n.profileCalendarSyncHint),
            value: _calendarSync,
            onChanged: (v) => _toggle(
              v,
              CalendarService.instance.requestPermission,
              (v) => _calendarSync = v,
            ),
          ),
        ];

      case _Step.plan:
        final premium =
            ref.watch(premiumProvider).isPremium(PremiumFeature.allPrograms);
        return [
          ..._header(
              context, l10n.onboardingPlanTitle, l10n.onboardingPlanHint),
          _padded(_ChoiceCard(
            selected: _program == null,
            icon: Icons.edit_note,
            title: l10n.onboardingPlanNone,
            onTap: () => setState(() => _program = null),
          )),
          const SizedBox(height: 8),
          // Jen programy pro zvolenou úroveň, ostatní jsou v Plánech.
          for (final (i, p) in templatePrograms.indexed)
            if (p.level == _level && !isProgramLocked(i, premium: premium)) ...[
              _padded(_ChoiceCard(
                selected: _program == p,
                icon: Icons.auto_awesome_outlined,
                title: programName(p),
                body: programDescription(p),
                note: l10n.onboardingPlanVariant(
                    l10n.trainingFocus(programGoal(p, _goal))),
                onTap: () => setState(() => _program = p),
              )),
              const SizedBox(height: 8),
            ],
          _padded(Text(l10n.onboardingPlanMore, style: muted)),
        ];

      case _Step.done:
        final program = _program;
        return [
          const SizedBox(height: 16),
          Icon(Icons.check_circle_outline,
              size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          _padded(Text(l10n.onboardingDoneTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium)),
          const SizedBox(height: 12),
          _padded(Text(l10n.onboardingDoneBody,
              textAlign: TextAlign.center, style: theme.textTheme.bodyLarge)),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.track_changes),
            title: Text(l10n.trainingGoalTitle),
            subtitle: Text(l10n.trainingFocus(_goal)),
          ),
          ListTile(
            leading: const Icon(Icons.stairs_outlined),
            title: Text(l10n.levelTitle),
            subtitle: Text(l10n.experienceLevel(_level)),
          ),
          if (program != null)
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(l10n.onboardingPlanTitle),
              subtitle: Text(programName(program)),
            ),
        ];
    }
  }
}

/// Volitelná karta (cíl, program): ikona, název, popis a výběr.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
    this.body,
    this.note,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String? body;
  final String? note;
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
                      if (body != null) ...[
                        const SizedBox(height: 4),
                        Text(body!, style: theme.textTheme.bodyMedium),
                      ],
                      if (note != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          note!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.primary),
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
