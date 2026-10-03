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
