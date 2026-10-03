import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart' show FilePicker, FileType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../services/calendar_service.dart';
import '../../services/notification_service.dart';
import '../../ui/dialogs.dart';
import '../../ui/format.dart';
import 'backup_service.dart';
import 'csv_export.dart';
import 'unit_dialogs.dart';
import 'units.dart';

/// Sekce v Profilu: jednotky, velikost sklenice/láhve, export CSV,
/// záloha a obnovení dat.
class DataProfileSection extends ConsumerStatefulWidget {
  const DataProfileSection({super.key});

  @override
  ConsumerState<DataProfileSection> createState() => _DataProfileSectionState();
}

class _DataProfileSectionState extends ConsumerState<DataProfileSection> {
  bool _busy = false;

  Rect? _shareOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportCsv() => _run(() async {
        final l10n = AppLocalizations.of(context);
        final origin = _shareOrigin();
        try {
          final files = await writeCsvExport(ref.read(databaseProvider));
          await SharePlus.instance.share(ShareParams(
            subject: l10n.dataExportSubject,
            files: [for (final f in files) XFile(f.path, mimeType: 'text/csv')],
            sharePositionOrigin: origin,
          ));
        } catch (e) {
          debugPrint('CSV export failed: $e');
          _snack(l10n.dataExportFailed);
        }
      });

  Future<void> _backup() => _run(() async {
        final l10n = AppLocalizations.of(context);
        final origin = _shareOrigin();
        File? file;
        try {
          file = await BackupService.createBackup(ref.read(databaseProvider));
          await SharePlus.instance.share(ShareParams(
            subject: l10n.dataBackupSubject,
            files: [
              XFile(file.path, mimeType: 'application/octet-stream'),
            ],
            sharePositionOrigin: origin,
          ));
        } catch (e) {
          debugPrint('Backup failed: $e');
          _snack(l10n.dataBackupFailed);
        }
      });

  String _restoreErrorText(AppLocalizations l10n, RestoreError e) =>
      switch (e) {
        RestoreError.notSqlite => l10n.dataRestoreNotSqlite,
        RestoreError.notBackup => l10n.dataRestoreNotBackup,
        RestoreError.newerVersion => l10n.dataRestoreNewer,
        RestoreError.failed => l10n.dataRestoreFailed,
      };

  Future<void> _restore() => _run(() async {
        final l10n = AppLocalizations.of(context);
        final db = ref.read(databaseProvider);
        File? file;
        try {
          final picked = await FilePicker.pickFile(
            dialogTitle: l10n.dataRestore,
            type: FileType.any,
          );
          if (picked == null) return;
          file = await BackupService.prepare(await picked.readAsBytes());
          final info = await BackupService.inspect(db, file);
          if (!mounted) return;
          final ok = await showConfirmDialog(
            context,
            title: l10n.dataRestoreConfirmTitle,
            message: l10n.dataRestoreConfirmMessage(info.workouts),
            confirmLabel: l10n.dataRestoreConfirm,
            destructive: true,
          );
          if (!ok) return;
          // Události a notifikace podle současných dat uklidíme; po obnovení
          // je SyncController naplánuje znovu podle dat ze zálohy.
          await NotificationService.instance.cancelAll();
          await CalendarService.instance.removeFuture(db);
          await BackupService.restore(db, file);
          _snack(l10n.dataRestoreDone);
        } on RestoreException catch (e) {
          debugPrint('Restore failed: $e');
          _snack(_restoreErrorText(l10n, e.error));
        } catch (e) {
          debugPrint('Restore failed: $e');
          _snack(l10n.dataRestoreFailed);
        } finally {
          if (file != null) await BackupService.discard(file);
        }
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider).valueOrNull;
    final units = ref.watch(unitSystemProvider);
    if (profile == null) return const SizedBox.shrink();
    final db = ref.watch(databaseProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.dataSectionTitle,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.straighten),
          title: Text(l10n.dataUnits),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SegmentedButton<UnitSystem>(
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
              selected: {units},
              showSelectedIcon: false,
              onSelectionChanged: (s) => db.updateProfile(
                UserProfilesCompanion(unitSystem: Value(s.first)),
              ),
            ),
          ),
        ),
        if (profile.trackWater) ...[
          ListTile(
            leading: const Icon(Icons.local_drink_outlined),
            title: Text(l10n.dataGlassSize),
            subtitle: Text(formatVolume(context, profile.glassMl)),
            onTap: () async {
              final ml = await showVolumeInputDialog(
                context,
                title: l10n.dataGlassSizeDialog(volumeUnit),
                minMl: 50,
                maxMl: 1000,
                initialMl: profile.glassMl,
              );
              if (ml != null) {
                await db.updateProfile(UserProfilesCompanion(glassMl: Value(ml)));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.water_drop_outlined),
            title: Text(l10n.dataBottleSize),
            subtitle: Text(formatVolume(context, profile.bottleMl)),
            onTap: () async {
              final ml = await showVolumeInputDialog(
                context,
                title: l10n.dataBottleSizeDialog(volumeUnit),
                minMl: 100,
                maxMl: 2000,
                initialMl: profile.bottleMl,
              );
              if (ml != null) {
                await db
                    .updateProfile(UserProfilesCompanion(bottleMl: Value(ml)));
              }
            },
          ),
        ],
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: Text(l10n.dataExportCsv),
          subtitle: Text(l10n.dataExportCsvHint),
          enabled: !_busy,
          onTap: _exportCsv,
        ),
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: Text(l10n.dataBackup),
          subtitle: Text(l10n.dataBackupHint),
          enabled: !_busy,
          onTap: _backup,
        ),
        ListTile(
          leading: const Icon(Icons.settings_backup_restore),
          title: Text(l10n.dataRestore),
          subtitle: Text(l10n.dataRestoreHint),
          enabled: !_busy,
          onTap: _restore,
        ),
        if (_busy) const LinearProgressIndicator(),
        const Divider(),
      ],
    );
  }
}
