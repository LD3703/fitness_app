// Widget na ploše (Android): pitný režim a dnešní trénink.
//
// Texty se skládají tady v Dartu (jazyk telefonu), nativní widget
// (tool/platform/widgets.dart) je jen zobrazí. Klepnutí na widget otevře
// aplikaci na obrazovce Dnes, tlačítko „+ sklenice“ otevře aplikaci
// a přičte vodu.

import 'dart:async';
import 'dart:ui' show AppLifecycleState, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../core/date_utils.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
import '../../ui/format.dart' show formatVolumeFor, formatVolumeNumberFor;
import '../../services/sync_controller.dart';
import 'widget_content.dart';

/// Widget je zatím jen pro Android (iOS WidgetKit potřebuje cíl v Xcode).
bool get _supported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// O kolik se ve dny tréninku zvedá cíl pitného režimu (jako na obrazovce Dnes).
const _trainingBonusMl = 500;

bool _dateFormattingReady = false;

/// Háček po změně dat (module_hub: [widgets:sync]).
Future<void> widgetsSyncHook(Ref ref, UserProfile profile) =>
    refreshHomeWidget(ref.read(databaseProvider));

/// Přepočítá data widgetu a nechá ho překreslit.
Future<void> refreshHomeWidget(AppDatabase db) async {
  if (!_supported) return;
  final profile = await db.watchProfile().first;
  // Před dokončením úvodu widget ukazuje jen „Otevři aplikaci“.
  if (!profile.onboardingDone) return;

  if (!_dateFormattingReady) {
    await initializeDateFormatting();
    _dateFormattingReady = true;
  }
  final l10n = deviceLocalizations();
  final locale = l10n.localeName;

  final now = DateTime.now();
  final today = startOfDay(now);
  final tomorrow = endOfDayExclusive(now);

  final planned = await db.plannedWorkouts(today, 2);
  final finished = await db.watchFinishedPlanIds(now).first;
  final active = await db.getActiveSession();
  final water = await db.watchWaterTotal(now).first;
  final trained = await db.watchWorkoutDoneOn(now).first;

  List<WorkoutPlan> plansOn(DateTime day) => [
        for (final p in planned)
          if (p.day == day) p.plan,
      ]..sort((a, b) => (a.plannedTimeMinutes ?? 24 * 60)
          .compareTo(b.plannedTimeMinutes ?? 24 * 60));

  final goalToday = profile.waterGoalMl + (trained ? _trainingBonusMl : 0);
  final goalTomorrow = profile.waterGoalMl;
  final glass = profile.glassMl > 0 ? profile.glassMl : 250;

  final data = <String, String>{
    WidgetKeys.title: l10n.widgetTitle,
    WidgetKeys.day: widgetDayKey(today),
    WidgetKeys.workout: _workoutLine(
      l10n,
      locale,
      plansOn(today),
      finished: finished,
      inProgress: active != null,
    ),
    WidgetKeys.water:
        _waterLine(l10n, locale, profile.unitSystem, water, goalToday),
    WidgetKeys.percent: '${waterPercent(water, goalToday)}',
    WidgetKeys.dayNext: widgetDayKey(tomorrow),
    WidgetKeys.workoutNext: _workoutLine(
      l10n,
      locale,
      plansOn(tomorrow),
      finished: const {},
      inProgress: false,
    ),
    WidgetKeys.waterNext:
        _waterLine(l10n, locale, profile.unitSystem, 0, goalTomorrow),
    WidgetKeys.percentNext: '0',
    WidgetKeys.waterVisible: profile.trackWater ? '1' : '0',
    WidgetKeys.glassMl: '$glass',
    // Texty ARB jsou bez jednotky – jednotku (ml/oz) dodá formatVolumeFor.
    WidgetKeys.addLabel: l10n.widgetAddGlass(
      formatVolumeFor(locale, glass, unit: profile.unitSystem),
    ),
    WidgetKeys.addDescription: l10n.widgetAddGlassDescription(
      formatVolumeFor(locale, glass, unit: profile.unitSystem),
    ),
  };
  for (final e in data.entries) {
    await HomeWidget.saveWidgetData<String>(e.key, e.value);
  }
  await HomeWidget.updateWidget(qualifiedAndroidName: kAndroidWidgetClass);
}

String _waterLine(
  AppLocalizations l10n,
  String locale,
  UnitSystem unit,
  int current,
  int goal,
) =>
    l10n.widgetWaterProgress(
      formatVolumeNumberFor(locale, current, unit: unit),
      formatVolumeFor(locale, goal, unit: unit),
    );

String _workoutLine(
  AppLocalizations l10n,
  String locale,
  List<WorkoutPlan> plans, {
  required Set<int> finished,
  required bool inProgress,
}) {
  if (inProgress) return l10n.widgetWorkoutInProgress;
  if (plans.isEmpty) return l10n.widgetRestDay;
  final pending = [
    for (final p in plans)
      if (!finished.contains(p.id)) p,
  ];
  if (pending.isEmpty) return l10n.widgetWorkoutDone;
  final plan = pending.first;
  final minutes = plan.plannedTimeMinutes;
  var line = minutes == null
      ? plan.name
      : l10n.widgetWorkoutPlanned(plan.name, _formatTime(minutes, locale));
  if (pending.length > 1) line = '$line +${pending.length - 1}';
  return line;
}

String _formatTime(int minutes, String locale) {
  final time = DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60);
  final format = PlatformDispatcher.instance.alwaysUse24HourFormat
      ? DateFormat.Hm(locale)
      : DateFormat.jm(locale);
  return format.format(time);
}

/// Běží po celou dobu aplikace (module_hub: [widgets:app]):
/// zpracuje klepnutí na widget a překresluje ho při změně vody a tréninků
/// (SyncController na vodu nereaguje) a při návratu do aplikace (nový den).
final widgetsAppProvider = Provider<void>((ref) {
  if (!_supported) return;

  Timer? debounce;
  void scheduleRefresh() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(_safeRefresh(ref));
    });
  }

  ref.listen(waterTodayProvider, (_, __) => scheduleRefresh());
  ref.listen(activeSessionProvider, (_, __) => scheduleRefresh());
  ref.listen(finishedPlanIdsTodayProvider, (_, __) => scheduleRefresh());
  ref.listen(workoutDoneTodayProvider, (_, __) => scheduleRefresh());

  final lifecycle = AppLifecycleListener(
    onStateChange: (state) {
      if (state == AppLifecycleState.resumed) scheduleRefresh();
    },
  );

  // Klepnutí zpracováváme po jednom, aby se nonce nečetl souběžně.
  var queue = Future<void>.value();
  void enqueue(Uri? uri) {
    queue = queue.then((_) => _handleWidgetUri(ref, uri));
  }

  // Aplikace spuštěná klepnutím na widget …
  unawaited(HomeWidget.initiallyLaunchedFromHomeWidget()
      .then(enqueue)
      .catchError((Object e) => debugPrint('Widget launch failed: $e')));
  // … a klepnutí, když už aplikace běží.
  final sub = HomeWidget.widgetClicked.listen(
    enqueue,
    onError: (Object e) => debugPrint('Widget click error: $e'),
  );

  ref.onDispose(() {
    debounce?.cancel();
    lifecycle.dispose();
    unawaited(sub.cancel());
  });
});

Future<void> _safeRefresh(Ref ref) async {
  try {
    await refreshHomeWidget(ref.read(databaseProvider));
  } catch (e) {
    debugPrint('Home widget refresh failed: $e');
  }
}

Future<void> _handleWidgetUri(Ref ref, Uri? uri) async {
  if (uri == null || uri.scheme != kWidgetUriScheme) return;
  try {
    final profile = await ref.read(profileProvider.future);
    if (!profile.onboardingDone) return;

    if (uri.host == kWidgetHostWater && profile.trackWater) {
      final nonce = int.tryParse(uri.queryParameters['n'] ?? '');
      final last = int.tryParse(
        await HomeWidget.getWidgetData<String>(WidgetKeys.lastWaterNonce) ??
            '',
      );
      if (shouldAddWater(nonce, last)) {
        if (nonce != null) {
          await HomeWidget.saveWidgetData<String>(
            WidgetKeys.lastWaterNonce,
            '$nonce',
          );
        }
        final db = ref.read(databaseProvider);
        await db.addWater(parseWidgetMl(uri, profile.glassMl));
        // Hned překreslit (a tím i vydat nový nonce).
        await refreshHomeWidget(db);
      }
    }

    ref.read(routerProvider).go('/today');
  } catch (e) {
    debugPrint('Widget click failed: $e');
  }
}
