import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../providers.dart';

enum _ActiveChoice { resume, discardAndStart }

/// Spustí nový trénink (volitelně podle plánu) a otevře jeho obrazovku.
/// Pokud už nějaký trénink probíhá, nabídne pokračování nebo jeho zahození.
Future<void> startWorkout(
  BuildContext context,
  WidgetRef ref, {
  int? planId,
}) async {
  final db = ref.read(databaseProvider);
  final l10n = AppLocalizations.of(context);
  final active = await db.getActiveSession();
  if (!context.mounted) return;

  if (active != null) {
    final choice = await showDialog<_ActiveChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workoutInProgressTitle),
        content: Text(l10n.workoutInProgressMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_ActiveChoice.discardAndStart),
            child: Text(l10n.workoutDiscardAndStart),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_ActiveChoice.resume),
            child: Text(l10n.workoutResume),
          ),
        ],
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == _ActiveChoice.resume) {
      context.push('/workout/${active.id}');
      return;
    }
    await db.discardSession(active.id);
    if (!context.mounted) return;
  }

  final id = await db.startSession(planId: planId);
  if (!context.mounted) return;
  context.push('/workout/$id');
}
