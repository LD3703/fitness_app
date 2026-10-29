import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/water_pace.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../services/calendar_service.dart';
import '../../ui/weekdays.dart';

/// Sekce v Profilu: čtení kalendáře (volná okna, kolize) a nastavení
/// připomínek pití – od kdy, večerka a pauza před spaním
/// (core/water_pace.dart).
class CalendarProfileSection extends ConsumerWidget {
  const CalendarProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();
    final db = ref.watch(databaseProvider);
    final showWater = profile.trackWater && profile.waterRemindersEnabled;
    final from = profile.waterReminderStartMinutes;
    final bedtime = profile.bedtimeMinutes;
    final stop = profile.waterStopBeforeBedMinutes;
    final last = lastDrinkMinutes(
        startMinutes: from, bedtimeMinutes: bedtime, stopBeforeBedMinutes: stop);

    Future<void> pickTime({required bool start}) async {
      final current = start ? from : bedtime;
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      );
      if (t == null) return;
      final minutes = t.hour * 60 + t.minute;
      final newFrom = start ? minutes : from;
      final newBed = start ? bedtime : minutes;
      // Na pití musí zbýt aspoň hodina (večerka po půlnoci je v pořádku).
      final newLast = lastDrinkMinutes(
          startMinutes: newFrom,
          bedtimeMinutes: newBed,
          stopBeforeBedMinutes: stop);
      if (newLast - newFrom < 60) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.calWaterRangeInvalid)),
          );
        }
        return;
      }
      await db.updateProfile(start
          ? UserProfilesCompanion(waterReminderStartMinutes: Value(minutes))
          : UserProfilesCompanion(bedtimeMinutes: Value(minutes)));
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
            leading: const Icon(Icons.bedtime_outlined),
            title: Text(l10n.waterBedtime),
            trailing: Text(
              formatMinutesOfDay(context, bedtime),
              style: theme.textTheme.titleMedium,
            ),
            onTap: () => pickTime(start: false),
          ),
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(l10n.waterStopBeforeBed),
            subtitle: Text(l10n.waterLastDrink(formatMinutesOfDay(context, last))),
            trailing: DropdownButton<int>(
              value: kWaterStopBeforeBedOptions.contains(stop) ? stop : null,
              hint: Text(l10n.calMinutes(stop)),
              underline: const SizedBox.shrink(),
              items: [
                for (final m in kWaterStopBeforeBedOptions)
                  DropdownMenuItem(
                    value: m,
                    child: Text(m == 0 ? l10n.waterStopNone : l10n.calMinutes(m)),
                  ),
              ],
              onChanged: (m) {
                if (m == null) return;
                db.updateProfile(UserProfilesCompanion(
                  waterStopBeforeBedMinutes: Value(m),
                ));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
            child: Text(
              l10n.waterPacedHint,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
        const Divider(),
      ],
    );
  }
}
