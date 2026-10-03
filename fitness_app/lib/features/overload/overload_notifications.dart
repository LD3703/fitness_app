import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/progressive_overload.dart';
import '../../data/database.dart';
import '../workout/workout_service.dart';
import '../../providers.dart';
import '../../services/notification_service.dart';
import '../../services/sync_controller.dart' show deviceLocalizations;
import 'overload_providers.dart';

// Týdenní souhrn progresivního přetížení: v pondělí v čase ranní
// připomínky (jen když má uživatel ranní připomínky zapnuté). Text se
// počítá dopředu – jako by aktuální týden už skončil – a přepočítá se po
// každém tréninku a po změně dat, takže v pondělí odpovídá skutečnosti.
// ID notifikace viz NotificationService (rezervováno 400–409).

/// Naplánuje nebo zruší týdenní souhrn podle profilu a dat.
Future<void> rescheduleOverloadSummary(
  AppDatabase db,
  UserProfile profile,
) async {
  final service = NotificationService.instance;
  if (!profile.onboardingDone || !profile.morningReminderEnabled) {
    await service.cancelOverloadSummary();
    return;
  }
  final now = DateTime.now();
  final monday = overloadWeekStart(now);
  final minutes = profile.morningReminderMinutes;
  final at = DateTime(
    monday.year,
    monday.month,
    monday.day + 7,
    minutes ~/ 60,
    minutes % 60,
  );
  // Hodnocení k příštímu pondělí: tento týden už bude dokončený.
  final history = await loadOverloadHistory(db, profile, at);
  final rated = [
    for (final g in currentOverload(history))
      if (!g.excused && g.status != OverloadStatus.insufficientData) g,
  ];
  if (rated.isEmpty) {
    await service.cancelOverloadSummary();
    return;
  }
  int count(OverloadStatus s) => rated.where((g) => g.status == s).length;
  final l10n = deviceLocalizations();
  await service.scheduleOverloadSummary(
    at: at,
    title: l10n.overloadNotifTitle,
    body: l10n.overloadNotifBody(
      count(OverloadStatus.progressing),
      count(OverloadStatus.stagnating),
      count(OverloadStatus.declining),
    ),
  );
}

/// Háček po tréninku (overload:finished).
Future<void> overloadWorkoutFinished(
  WidgetRef ref,
  WorkoutSummary summary,
) async {
  final db = ref.read(databaseProvider);
  await rescheduleOverloadSummary(db, await db.watchProfile().first);
}

/// Háček po změně dat (overload:sync).
Future<void> overloadSync(Ref ref, UserProfile profile) =>
    rescheduleOverloadSummary(ref.read(databaseProvider), profile);
