import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_version.dart';
import '../../core/experience_level.dart';
import '../../core/rest_time.dart';
import '../../core/text_filter.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../modules/calendar/calendar_title.dart';
import '../../modules/data/unit_dialogs.dart';
import '../../modules/module_hub.dart';
import '../../providers.dart';
import '../../services/calendar_service.dart';
import '../../services/notification_service.dart';
import '../../ui/training_schedule_selector.dart';
import '../../ui/skins.dart';
import '../../ui/brand_mark.dart';
import '../../ui/dialogs.dart';
import '../../ui/format.dart';
import '../../ui/labels.dart';
import '../../ui/module_switches.dart';
import '../../ui/number_input_dialog.dart';
import '../../ui/weekdays.dart';
import 'skin_picker.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final db = ref.watch(databaseProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final reminder = profile.morningReminderMinutes;
    final reminderText = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: reminder ~/ 60, minute: reminder % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final name = profile.name;

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            text,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProfile)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.profileName),
            subtitle: Text(name == null || name.isEmpty ? '–' : name),
            onTap: () async {
              final newName = await showTextInputDialog(
                context,
                title: l10n.profileName,
                initialValue: name ?? '',
                // Jméno vidí přátelé – bez vyloženě hrubých slov.
                validator: (t) =>
                    containsSevereProfanity(t) ? l10n.textFilterBlocked : null,
              );
              if (newName != null) {
                await db.updateProfile(
                  UserProfilesCompanion(name: Value(newName)),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.cake_outlined),
            title: Text(l10n.profileBirthYear),
            subtitle: Text(profile.birthYear?.toString() ?? '–'),
            trailing: profile.birthYear == null
                ? null
                : IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.clear),
                    onPressed: () => db.updateProfile(
                      const UserProfilesCompanion(birthYear: Value(null)),
                    ),
                  ),
            onTap: () async {
              // Deník bez účtu je pro kohokoli (od 10 let). Žebříček posilovny
              // bere věkovou skupinu až od 13 let (gymMinAgeYears).
              final maxYear = DateTime.now().year - 10;
              final year = await showNumberInputDialog(
                context,
                title: l10n.profileBirthYear,
                min: 1920,
                max: maxYear.toDouble(),
                errorText: l10n.profileBirthYearInvalid(1920, maxYear),
                initialValue: profile.birthYear?.toDouble(),
                allowDecimals: false,
              );
              if (year != null) {
                await db.updateProfile(
                  UserProfilesCompanion(birthYear: Value(year.round())),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.wc_outlined),
            title: Text(l10n.profileSex),
            subtitle: Text(l10n.sex(sexOf(profile.sex))),
            onTap: () async {
              final picked = await _pickSex(context, sexOf(profile.sex));
              if (picked == null) return;
              await db.updateProfile(UserProfilesCompanion(
                sex: Value(picked.$1?.index),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.track_changes),
            title: Text(l10n.trainingGoalTitle),
            subtitle: Text(l10n.trainingFocus(
                trainingFocusOf(profile.trainingFocus))),
            onTap: () async {
              final picked = await _pickGoal(
                  context, trainingFocusOf(profile.trainingFocus));
              if (picked != null) await db.setTrainingGoal(picked);
            },
          ),
          _ExperienceLevelTile(profile: profile),
          ListTile(
            leading: const Icon(Icons.event_repeat),
            title: Text(l10n.scheduleTitle),
            subtitle: Text(l10n.scheduleSummary(
                profile.trainingDaysPerWeek, profile.sessionMinutes)),
            onTap: () => _pickSchedule(context, db, profile),
          ),
          sectionTitle(l10n.profileTrackingSection),
          ModuleSwitches(
            value: (
              water: profile.trackWater,
              weight: profile.trackWeight,
              periods: profile.trackPeriods,
              calories: profile.showCalories,
            ),
            onChanged: (v) => db.updateProfile(UserProfilesCompanion(
              trackWater: Value(v.water),
              trackWeight: Value(v.weight),
              trackPeriods: Value(v.periods),
              showCalories: Value(v.calories),
            )),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.profileTrackingHint,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const Divider(),
          sectionTitle(l10n.profileSettingsSection),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.skinTitle),
            subtitle: Text(skinLabel(l10n, AppSkin.fromKey(profile.skin))),
            onTap: () async {
              final current = AppSkin.fromKey(profile.skin);
              final picked = await showSkinPicker(context, current);
              if (picked != null && picked != current) {
                await db.updateProfile(
                  UserProfilesCompanion(skin: Value(picked.key)),
                );
              }
            },
          ),
          // Světlý / tmavý režim má jen Původní motiv.
          if (AppSkin.fromKey(profile.skin) == AppSkin.original)
            ListTile(
              leading: Icon(_appearanceIcon(profile.themeMode)),
              title: Text(l10n.appearanceTitle),
              subtitle: Text(_appearanceLabel(l10n, profile.themeMode)),
              onTap: () async {
                final mode = await _pickAppearance(context, profile.themeMode);
                if (mode != null && mode != profile.themeMode) {
                  await db.updateProfile(
                    UserProfilesCompanion(themeMode: Value(mode)),
                  );
                }
              },
            ),
          ListTile(
            leading: Icon(profile.coachTone == 1
                ? Icons.sports
                : Icons.sentiment_satisfied_outlined),
            title: Text(l10n.coachToneTitle),
            subtitle: Text(profile.coachTone == 1
                ? '${l10n.coachToneStrict} · ${l10n.coachToneStrictHint}'
                : l10n.coachToneFriendly),
            onTap: () async {
              final tone = await _pickCoachTone(context, profile.coachTone);
              if (tone != null && tone != profile.coachTone) {
                await db.updateProfile(
                  UserProfilesCompanion(coachTone: Value(tone)),
                );
              }
            },
          ),
          if (profile.trackWater)
            ListTile(
              leading: const Icon(Icons.water_drop_outlined),
              title: Text(l10n.profileWaterGoal),
              subtitle: Text(formatVolume(context, profile.waterGoalMl)),
              onTap: () async {
                final ml = await showVolumeInputDialog(
                  context,
                  title: l10n.dataWaterGoalDialog(volumeUnit),
                  minMl: 500,
                  maxMl: 6000,
                  initialMl: profile.waterGoalMl,
                );
                if (ml != null) await db.updateWaterGoal(ml);
              },
            ),
          if (profile.trackPeriods)
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.periodsTitle),
              subtitle: Text(l10n.periodsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/periods'),
            ),
          const Divider(),
          sectionTitle(l10n.profileRemindersSection),
          SwitchListTile(
            secondary: const Icon(Icons.alarm),
            title: Text(l10n.profileMorningReminder),
            subtitle: Text(l10n.profileMorningReminderHint(reminderText)),
            value: profile.morningReminderEnabled,
            onChanged: (v) => _toggleNotifications(
              context,
              v,
              () => db.updateProfile(
                UserProfilesCompanion(morningReminderEnabled: Value(v)),
              ),
            ),
          ),
          if (profile.morningReminderEnabled)
            ListTile(
              leading: const SizedBox(width: 24),
              title: Text(l10n.profileMorningReminderTime),
              trailing: Text(reminderText,
                  style: theme.textTheme.titleMedium),
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime:
                      TimeOfDay(hour: reminder ~/ 60, minute: reminder % 60),
                );
                if (t != null) {
                  await db.updateProfile(UserProfilesCompanion(
                    morningReminderMinutes: Value(t.hour * 60 + t.minute),
                  ));
                }
              },
            ),
          if (profile.trackWater)
            SwitchListTile(
              secondary: const Icon(Icons.water_drop_outlined),
              title: Text(l10n.profileWaterReminders),
              subtitle: Text(l10n.calWaterRemindersHint(
                formatMinutesOfDay(context, profile.waterReminderStartMinutes),
                formatMinutesOfDay(context, profile.waterReminderEndMinutes),
                profile.waterReminderIntervalMinutes,
              )),
              value: profile.waterRemindersEnabled,
              onChanged: (v) => _toggleNotifications(
                context,
                v,
                () => db.updateProfile(
                  UserProfilesCompanion(waterRemindersEnabled: Value(v)),
                ),
              ),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_month_outlined),
            title: Text(l10n.profileCalendarSync),
            subtitle: Text(l10n.profileCalendarSyncHint),
            value: profile.calendarSyncEnabled,
            onChanged: (v) async {
              final calendar = CalendarService.instance;
              if (v && !await calendar.requestPermission()) {
                if (context.mounted) _showDenied(context);
                return;
              }
              await db.updateProfile(
                UserProfilesCompanion(calendarSyncEnabled: Value(v)),
              );
              if (!v) await calendar.removeFuture(db);
            },
          ),
          if (profile.calendarSyncEnabled)
            ListTile(
              leading: const SizedBox(width: 24),
              title: Text(l10n.calendarTitleSetting),
              subtitle: Text(
                '${calendarEventTitle(
                  template: profile.calendarTitle,
                  plan: calendarTitleExamplePlan,
                  defaultTitle: l10n.calendarTitleDefault,
                )}\n${l10n.calendarTitleHint(calendarTitleToken)}',
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editCalendarTitle(context, db, profile),
            ),
          if (Theme.of(context).platform == TargetPlatform.android)
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(l10n.profileExactAlarms),
              subtitle: Text(l10n.profileExactAlarmsHint),
              onTap: NotificationService.instance.requestExactAlarms,
            ),
          const Divider(),
          ...moduleProfileSections(),
          // Průvodce nastavením znovu: router po onboardingDone = false
          // přejde na /welcome, průvodce předvyplní současné hodnoty.
          ListTile(
            leading: const Icon(Icons.assistant_navigation),
            title: Text(l10n.profileSetupWizard),
            subtitle: Text(l10n.profileSetupWizardHint),
            onTap: () => db.updateProfile(
              const UserProfilesCompanion(onboardingDone: Value(false)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.profileAbout),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: l10n.appTitle,
              applicationVersion: '$kAppVersion ($kAppBuildDate)',
              applicationIcon: const BrandMark(size: 48),
              children: [
                Text(l10n.healthDisclaimer),
                const SizedBox(height: 12),
                Text(l10n.aboutImageCredits),
                const SizedBox(height: 12),
                // Licence ODbL: seznam posiloven pochází z OpenStreetMap.
                Text(l10n.socialGymOsmAttribution),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined,
                color: theme.colorScheme.error),
            title: Text(
              l10n.profileDeleteAll,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () async {
              final ok = await showConfirmDialog(
                context,
                title: l10n.profileDeleteAllTitle,
                message: l10n.profileDeleteAllMessage,
                confirmLabel: l10n.profileDeleteAllConfirm,
                destructive: true,
              );
              if (!ok) return;
              await NotificationService.instance.cancelAll();
              await CalendarService.instance.removeFuture(db);
              await db.deleteAllUserData();
              // Router po smazání přesměruje na úvodního průvodce.
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Volby vzhledu v pořadí: podle systému, světlý, tmavý
  /// (hodnoty UserProfile.themeMode, viz AppTheme.themeModeOf).
  static const _appearanceModes = [0, 1, 2];

  static IconData _appearanceIcon(int mode) => switch (mode) {
        1 => Icons.light_mode_outlined,
        2 => Icons.dark_mode_outlined,
        _ => Icons.brightness_auto_outlined,
      };

  static String _appearanceLabel(AppLocalizations l10n, int mode) =>
      switch (mode) {
        1 => l10n.appearanceLight,
        2 => l10n.appearanceDark,
        _ => l10n.appearanceSystem,
      };

  Future<int?> _pickAppearance(BuildContext context, int current) {
    final l10n = AppLocalizations.of(context);
    return showDialog<int>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SimpleDialog(
          title: Text(l10n.appearanceTitle),
          children: [
            for (final mode in _appearanceModes)
              ListTile(
                leading: Icon(_appearanceIcon(mode)),
                title: Text(_appearanceLabel(l10n, mode)),
                trailing: mode == current
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                selected: mode == current,
                onTap: () => Navigator.of(context).pop(mode),
              ),
          ],
        );
      },
    );
  }

  /// Volba pohlaví. Vrací záznam, aby šlo rozlišit „neuvádět“ (null)
  /// od zavření dialogu.
  Future<(Sex?,)?> _pickSex(BuildContext context, Sex? current) {
    final l10n = AppLocalizations.of(context);
    return showDialog<(Sex?,)>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        Widget option(Sex? value) => ListTile(
              title: Text(l10n.sex(value)),
              trailing: value == current
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              selected: value == current,
              onTap: () => Navigator.of(context).pop((value,)),
            );
        return SimpleDialog(
          title: Text(l10n.profileSex),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                l10n.profileSexHint,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            option(Sex.male),
            option(Sex.female),
            option(null),
          ],
        );
      },
    );
  }

  /// Kolikrát týdně a jak dlouho: doporučení a zkrácení programů.
  Future<void> _pickSchedule(
      BuildContext context, AppDatabase db, UserProfile profile) async {
    final l10n = AppLocalizations.of(context);
    var days = profile.trainingDaysPerWeek;
    var minutes = profile.sessionMinutes;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.scheduleTitle),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.scheduleDialogHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TrainingScheduleSelector(
                daysPerWeek: days,
                minutes: minutes,
                padding: EdgeInsets.zero,
                onChanged: (d, m) => setState(() {
                  days = d;
                  minutes = m;
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await db.setTrainingSchedule(daysPerWeek: days, minutes: minutes);
    }
  }

  /// Cíl tréninku (síla / svaly / výdrž): výchozí zaměření tréninků
  /// a varianta hotových programů.
  Future<TrainingFocus?> _pickGoal(BuildContext context, TrainingFocus current) {
    final l10n = AppLocalizations.of(context);
    return showDialog<TrainingFocus>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return SimpleDialog(
          title: Text(l10n.trainingGoalTitle),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                l10n.trainingGoalDialogHint,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            for (final f in TrainingFocus.values)
              ListTile(
                title: Text(l10n.trainingFocus(f)),
                subtitle: Text(l10n.trainingGoalHint(f)),
                trailing: f == current
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                selected: f == current,
                onTap: () => Navigator.of(context).pop(f),
              ),
          ],
        );
      },
    );
  }

  /// Tón zpráv: 0 = přátelský, 1 = přísný trenér (UserProfile.coachTone,
  /// viz core/coach_tone.dart).
  Future<int?> _pickCoachTone(BuildContext context, int current) {
    final l10n = AppLocalizations.of(context);
    return showDialog<int>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        Widget option(int value, IconData icon, String title, String? hint) =>
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              subtitle: hint == null ? null : Text(hint),
              trailing: value == current
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              selected: value == current,
              onTap: () => Navigator.of(context).pop(value),
            );
        return SimpleDialog(
          title: Text(l10n.coachToneTitle),
          children: [
            option(0, Icons.sentiment_satisfied_outlined,
                l10n.coachToneFriendly, null),
            option(1, Icons.sports, l10n.coachToneStrict,
                l10n.coachToneStrictHint),
          ],
        );
      },
    );
  }

  Future<void> _toggleNotifications(
    BuildContext context,
    bool enable,
    Future<void> Function() save,
  ) async {
    if (enable && !await NotificationService.instance.requestPermission()) {
      if (context.mounted) _showDenied(context);
      return;
    }
    await save();
  }


  /// Vlastní název událostí v kalendáři. Výchozí text (nebo prázdné
  /// pole) uloží null – název pak sleduje jazyk aplikace.
  Future<void> _editCalendarTitle(
    BuildContext context,
    AppDatabase db,
    UserProfile profile,
  ) async {
    final l10n = AppLocalizations.of(context);
    final defaultText = l10n.calendarTitleDefault(calendarTitleToken);
    final text = await showTextInputDialog(
      context,
      title: l10n.calendarTitleSetting,
      initialValue: profile.calendarTitle ?? defaultText,
      hintText: defaultText,
    );
    if (text == null || !context.mounted) return;
    await db.updateProfile(UserProfilesCompanion(
      calendarTitle: Value(text == defaultText ? null : text),
    ));
  }
  void _showDenied(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).permissionDenied),
    ));
  }
}

/// Úroveň pokročilosti a kolik zbývá do další (core/experience_level.dart).
class _ExperienceLevelTile extends ConsumerWidget {
  const _ExperienceLevelTile({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final level = experienceLevelOf(profile.experienceLevel);
    final progress = ref.watch(experienceStatusProvider).valueOrNull?.progress;
    final lines = [
      l10n.experienceLevel(level),
      if (progress != null)
        l10n.levelProgress(
          l10n.experienceLevel(progress.next),
          progress.workouts.clamp(0, progress.requirement.workouts),
          progress.requirement.workouts,
          progress.weeks.clamp(0, progress.requirement.weeks),
          progress.requirement.weeks,
        ),
    ];
    return ListTile(
      leading: const Icon(Icons.stairs_outlined),
      title: Text(l10n.levelTitle),
      subtitle: Text(lines.join('\n')),
      isThreeLine: lines.length > 1,
      onTap: () async {
        final picked = await showDialog<ExperienceLevel>(
          context: context,
          builder: (context) {
            final theme = Theme.of(context);
            return SimpleDialog(
              title: Text(l10n.levelTitle),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(
                    l10n.levelDialogHint,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                for (final l in ExperienceLevel.values)
                  ListTile(
                    title: Text(l10n.experienceLevel(l)),
                    subtitle: Text(l10n.experienceLevelHint(l)),
                    trailing: l == level
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(l),
                  ),
              ],
            );
          },
        );
        if (picked != null && picked != level) {
          await ref.read(databaseProvider).setExperienceLevel(picked);
        }
      },
    );
  }
}
