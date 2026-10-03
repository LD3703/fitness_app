import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../services/calendar_service.dart';
import '../../ui/weekdays.dart';

/// Sekce v Profilu: čtení kalendáře (volná okna, kolize) a nastavení
/// intervalu připomínek pití.
class CalendarProfileSection extends ConsumerWidget {
  const CalendarProfileSection({super.key});

  static const _intervals = [60, 90, 120, 180];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();
    final db = ref.watch(databaseProvider);
    final showWater = profile.trackWater && profile.waterRemindersEnabled;
    final from = profile.waterReminderStartMinutes;
    final to = profile.waterReminderEndMinutes;
    final interval = profile.waterReminderIntervalMinutes;

    Future<void> pickTime({required bool start}) async {
      final current = start ? from : to;
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      );
      if (t == null) return;
      final minutes = t.hour * 60 + t.minute;
      final newFrom = start ? minutes : from;
      final newTo = start ? to : minutes;
      if (newTo <= newFrom) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.calWaterRangeInvalid)),
          );
        }
        return;
      }
      await db.updateProfile(start
          ? UserProfilesCompanion(waterReminderStartMinutes: Value(minutes))
          : UserProfilesCompanion(waterReminderEndMinutes: Value(minutes)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.calProfileSection,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.event_available_outlined),
          title: Text(l10n.calReadSwitch),
          subtitle: Text(l10n.calReadHint),
          value: profile.calendarReadEnabled,
          onChanged: (v) async {
            if (v && !await CalendarService.instance.requestPermission()) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.permissionDenied)),
                );
              }
              return;
            }
            await db.updateProfile(
              UserProfilesCompanion(calendarReadEnabled: Value(v)),
            );
          },
        ),
        if (showWater) ...[
          ListTile(
            leading: const Icon(Icons.water_drop_outlined),
            title: Text(l10n.calWaterFrom),
            trailing: Text(
              formatMinutesOfDay(context, from),
              style: theme.textTheme.titleMedium,
            ),
            onTap: () => pickTime(start: true),
          ),
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(l10n.calWaterTo),
            trailing: Text(
              formatMinutesOfDay(context, to),
              style: theme.textTheme.titleMedium,
            ),
            onTap: () => pickTime(start: false),
          ),
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(l10n.calWaterInterval),
            trailing: DropdownButton<int>(
              value: _intervals.contains(interval) ? interval : null,
              hint: Text(l10n.calMinutes(interval)),
              underline: const SizedBox.shrink(),
              items: [
                for (final m in _intervals)
                  DropdownMenuItem(value: m, child: Text(l10n.calMinutes(m))),
              ],
              onChanged: (m) {
                if (m == null) return;
                db.updateProfile(UserProfilesCompanion(
                  waterReminderIntervalMinutes: Value(m),
                ));
              },
            ),
          ),
        ],
        const Divider(),
      ],
    );
  }
}
