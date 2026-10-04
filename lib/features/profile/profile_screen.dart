import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../modules/data/unit_dialogs.dart';
import '../../modules/module_hub.dart';
import '../../providers.dart';
import '../../services/calendar_service.dart';
import '../../services/notification_service.dart';
import '../../ui/dialogs.dart';
import '../../ui/format.dart';
import '../../ui/module_switches.dart';
import '../../ui/number_input_dialog.dart';
import '../../ui/weekdays.dart';

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
              // Stejný rozsah jako v žebříčku posilovny (gym_logic.dart).
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
          if (Theme.of(context).platform == TargetPlatform.android)
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(l10n.profileExactAlarms),
              subtitle: Text(l10n.profileExactAlarmsHint),
              onTap: NotificationService.instance.requestExactAlarms,
            ),
          const Divider(),
          ...moduleProfileSections(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.profileAbout),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: l10n.appTitle,
              applicationVersion: '0.1.0',
              children: [Text(l10n.aboutImageCredits)],
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

  void _showDenied(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).permissionDenied),
    ));
  }
}
