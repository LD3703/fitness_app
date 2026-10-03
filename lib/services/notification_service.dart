import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/wellbeing.dart';
import '../data/database.dart';
import '../l10n/app_localizations.dart';
import '../modules/calendar/free_slots.dart';
import '../ui/format.dart' show formatVolumeFor;
import 'calendar_service.dart';
import 'sync_controller.dart' show deviceLocalizations;

/// Obsah payloadu ranní připomínky: den a ID naplánovaných plánů.
/// Formát: `morning|2026-10-05|3,5`.
class MorningPayload {
  const MorningPayload(this.day, this.planIds);

  final DateTime day;
  final List<int> planIds;

  static const _prefix = 'morning';

  String encode() {
    final d = '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    return '$_prefix|$d|${planIds.join(',')}';
  }

  static MorningPayload? tryParse(String? payload) {
    if (payload == null) return null;
    final parts = payload.split('|');
    if (parts.length != 3 || parts[0] != _prefix) return null;
    final date = DateTime.tryParse(parts[1]);
    if (date == null) return null;
    final ids = [
      for (final s in parts[2].split(','))
        if (int.tryParse(s) case final id?) id,
    ];
    return MorningPayload(DateTime(date.year, date.month, date.day), ids);
  }
}

/// Lokální notifikace: ranní připomínka tréninku, připomínky pití
/// a upozornění na konec pauzy mezi sériemi.
///
/// Opakované notifikace se neplánují jako „denně v 7:30“, ale jako
/// jednotlivé notifikace na 7 dní dopředu. Při každé změně (a spuštění
/// aplikace) se přeplánují, takže texty odpovídají aktuální situaci
/// (nemoc, odložený trénink…) a nevadí změna letního času.
class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Future<void>? _initializing;
  bool _launchTaken = false;
  final _responses = StreamController<NotificationResponse>.broadcast();

  static const _restId = 1;
  static const _restOngoingId = 2;
  static const _morningBase = 100; // +0 … +6
  static const _waterBase = 200; // rezervováno 200 … 399
  static const _waterSlots = 200;
  static const _waterPerDay = 24;
  static const _daysAhead = 7;
  static const _workoutMinutes = kDefaultWorkoutMinutes;

  /// Kategorie (iOS) a akce ranní připomínky.
  static const morningCategory = 'morning_reminder';
  static const actionCountMeIn = 'morning_ok';
  static const actionMove = 'morning_move';
  static const actionNoTime = 'morning_no_time';

  /// Notifikace podporujeme jen na telefonech.
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _init() {
    if (_ready || !supported) return Future.value();
    return _initializing ??= _doInit().whenComplete(() => _initializing = null);
  }

  Future<void> _doInit() async {
    tzdata.initializeTimeZones();
    final l10n = deviceLocalizations();
    final settings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          DarwinNotificationCategory(
            morningCategory,
            actions: [
              DarwinNotificationAction.plain(
                actionCountMeIn,
                l10n.calActionCountMeIn,
              ),
              DarwinNotificationAction.plain(
                actionMove,
                l10n.calActionMove,
                options: {DarwinNotificationActionOption.foreground},
              ),
              DarwinNotificationAction.plain(
                actionNoTime,
                l10n.calActionNoTime,
                options: {DarwinNotificationActionOption.foreground},
              ),
            ],
          ),
        ],
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _responses.add,
    );
    _ready = true;
  }

  /// Klepnutí na notifikaci nebo její akci, když aplikace běží
  /// (nebo ji akce s `showsUserInterface` přivedla do popředí).
  Stream<NotificationResponse> get responses => _responses.stream;

  /// Inicializuje plugin (zaregistruje obsluhu klepnutí a kategorie iOS).
  Future<void> ensureInitialized() async {
    try {
      await _init();
    } catch (e) {
      debugPrint('Notifications init failed: $e');
    }
  }

  /// Notifikace, kterou byla aplikace spuštěna (jen jednou za běh).
  Future<NotificationResponse?> takeLaunchResponse() async {
    if (!supported || _launchTaken) return null;
    _launchTaken = true;
    try {
      await _init();
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      return details.notificationResponse;
    } catch (e) {
      debugPrint('Notification launch details failed: $e');
      return null;
    }
  }

  /// Zruší naplánované notifikace s ID v [from, from + count).
  Future<void> _cancelRange(int from, int count) async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final p in pending) {
        if (p.id >= from && p.id < from + count) {
          await _plugin.cancel(id: p.id);
        }
      }
    } catch (_) {
      for (var i = 0; i < count; i++) {
        await _plugin.cancel(id: from + i);
      }
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  /// Požádá o povolení notifikací. Vrací true, pokud je povoleno.
  Future<bool> requestPermission() async {
    if (!supported) return false;
    try {
      await _init();
      final android = _android;
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _ios;
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (e) {
      debugPrint('Notifications permission failed: $e');
    }
    return false;
  }

  /// Otevře systémové nastavení přesných alarmů (Android 12+), aby
  /// upozornění na konec pauzy chodilo přesně na sekundu.
  Future<void> requestExactAlarms() async {
    if (!supported) return;
    try {
      await _init();
      await _android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Exact alarm permission failed: $e');
    }
  }

  Future<bool> canScheduleExact() async {
    if (!supported) return false;
    try {
      await _init();
      final android = _android;
      if (android == null) return true;
      return await android.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------------
  // Konec pauzy
  // -------------------------------------------------------------------

  static const _restDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'rest_timer',
      'Rest timer',
      channelDescription: 'End of rest between sets',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Naplánuje upozornění na konec pauzy za [after].
  /// Volá se, když uživatel během pauzy odejde z aplikace.
  ///
  /// Na Androidu navíc ukáže trvalou tichou notifikaci s odpočtem
  /// (i na zamykací obrazovce), která po konci pauzy sama zmizí.
  Future<void> scheduleRestEnd(Duration after, AppLocalizations l10n) async {
    if (!supported || after <= Duration.zero) return;
    final end = DateTime.now().add(after);
    try {
      await _init();
      await _plugin.cancel(id: _restId);
      final exact = await canScheduleExact();
      await _plugin.zonedSchedule(
        id: _restId,
        title: l10n.notifRestTitle,
        body: l10n.notifRestBody,
        scheduledDate: tz.TZDateTime.from(end, tz.UTC),
        notificationDetails: _restDetails,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Rest notification failed: $e');
    }
    if (_android != null) {
      try {
        await _plugin.show(
          id: _restOngoingId,
          title: l10n.calRestOngoingTitle,
          body: l10n.calRestOngoingBody,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'rest_countdown',
              'Rest countdown',
              channelDescription: 'Countdown of the rest between sets',
              importance: Importance.low,
              priority: Priority.low,
              ongoing: true,
              autoCancel: false,
              silent: true,
              playSound: false,
              enableVibration: false,
              onlyAlertOnce: true,
              showWhen: true,
              when: end.millisecondsSinceEpoch,
              usesChronometer: true,
              chronometerCountDown: true,
              timeoutAfter: after.inMilliseconds,
              visibility: NotificationVisibility.public,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Rest countdown failed: $e');
      }
    }
  }

  Future<void> cancelRestEnd() async {
    if (!supported) return;
    try {
      await _init();
      await _plugin.cancel(id: _restId);
      await _plugin.cancel(id: _restOngoingId);
    } catch (_) {}
  }

  // -------------------------------------------------------------------
  // Ranní připomínka a pitný režim
  // -------------------------------------------------------------------

  NotificationDetails _morningDetails(AppLocalizations l10n, String body) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'morning_reminder',
          'Workout reminder',
          channelDescription: 'Morning reminder of the planned workout',
          importance: Importance.defaultImportance,
          styleInformation: BigTextStyleInformation(body),
          actions: [
            AndroidNotificationAction(
              actionCountMeIn,
              l10n.calActionCountMeIn,
            ),
            AndroidNotificationAction(
              actionMove,
              l10n.calActionMove,
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              actionNoTime,
              l10n.calActionNoTime,
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: morningCategory,
        ),
      );

  static const _waterDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'water_reminder',
      'Water reminders',
      channelDescription: 'Reminders to drink water',
      importance: Importance.low,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Přeplánuje ranní připomínky a připomínky pití na [_daysAhead] dní.
  ///
  /// S [db] a zapnutým čtením kalendáře připomínka upozorní na kolizi
  /// tréninku s událostí v kalendáři.
  Future<void> reschedule({
    required UserProfile profile,
    required List<PlannedWorkout> planned,
    required List<PeriodSpan> periods,
    required AppLocalizations l10n,
    required String locale,
    AppDatabase? db,
  }) async {
    if (!supported) return;
    try {
      await _init();
      await _cancelRange(_morningBase, _daysAhead);
      await _cancelRange(_waterBase, _waterSlots);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final timeFormat = DateFormat.Hm(locale);

      var entries = const <CalendarEntry>[];
      if (profile.morningReminderEnabled &&
          profile.calendarReadEnabled &&
          db != null) {
        entries = await CalendarService.instance.readEntries(
          db,
          today,
          DateTime(today.year, today.month, today.day + _daysAhead),
        );
      }

      if (profile.morningReminderEnabled) {
        for (var d = 0; d < _daysAhead; d++) {
          final day = DateTime(today.year, today.month, today.day + d);
          final plans = [
            for (final w in planned)
              if (w.day == day) w.plan,
          ];
          if (plans.isEmpty) continue;
          final minutes = profile.morningReminderMinutes;
          final at = DateTime(
              day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
          if (!at.isAfter(now)) continue;

          final names = plans.map((p) {
            final t = p.plannedTimeMinutes;
            if (t == null) return p.name;
            final time = timeFormat
                .format(DateTime(day.year, day.month, day.day, t ~/ 60, t % 60));
            return l10n.notifPlanAtTime(p.name, time);
          }).join(', ');

          final situation = profile.trackPeriods
              ? determineSituation(periods, at)
              : WellbeingSituation.normal;
          var body = switch (situation) {
            WellbeingSituation.illness ||
            WellbeingSituation.injury =>
              l10n.notifMorningIllness(names),
            WellbeingSituation.recovery => l10n.notifMorningRecovery(names),
            WellbeingSituation.cut ||
            WellbeingSituation.normal =>
              l10n.notifMorningBody(names),
          };

          final collision =
              _collisionText(day, plans, entries, l10n, timeFormat);
          if (collision != null) body = '$body\n$collision';

          await _plugin.zonedSchedule(
            id: _morningBase + d,
            title: l10n.notifMorningTitle,
            body: body,
            scheduledDate: tz.TZDateTime.from(at, tz.UTC),
            notificationDetails: _morningDetails(l10n, body),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: MorningPayload(day, [for (final p in plans) p.id]).encode(),
          );
        }
      }

      if (profile.trackWater && profile.waterRemindersEnabled) {
        final times = waterReminderMinutes(
          startMinutes: profile.waterReminderStartMinutes,
          endMinutes: profile.waterReminderEndMinutes,
          intervalMinutes: profile.waterReminderIntervalMinutes,
          maxCount: _waterPerDay,
        );
        for (var d = 0; d < _daysAhead; d++) {
          for (var h = 0; h < times.length; h++) {
            final at = DateTime(today.year, today.month, today.day + d,
                times[h] ~/ 60, times[h] % 60);
            if (!at.isAfter(now)) continue;
            await _plugin.zonedSchedule(
              id: _waterBase + d * _waterPerDay + h,
              title: l10n.notifWaterTitle,
              body: l10n.dataNotifWaterBody(formatVolumeFor(
                l10n.localeName,
                profile.waterGoalMl,
                unit: profile.unitSystem,
              )),
              scheduledDate: tz.TZDateTime.from(at, tz.UTC),
              notificationDetails: _waterDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Notification scheduling failed: $e');
    }
  }

  /// Text o první kolizi tréninku s událostí v kalendáři v den [day].
  String? _collisionText(
    DateTime day,
    List<WorkoutPlan> plans,
    List<CalendarEntry> entries,
    AppLocalizations l10n,
    DateFormat timeFormat,
  ) {
    if (entries.isEmpty) return null;
    for (final p in plans) {
      final t = p.plannedTimeMinutes;
      if (t == null) continue;
      final start = DateTime(day.year, day.month, day.day, t ~/ 60, t % 60);
      final hits = collisionsWith(
        entries,
        start,
        start.add(const Duration(minutes: _workoutMinutes)),
      );
      if (hits.isEmpty) continue;
      final e = hits.first;
      return l10n.calNotifCollision(
        timeFormat.format(e.start),
        e.title,
        p.name,
      );
    }
    return null;
  }

  /// Zruší všechny naplánované notifikace (např. po smazání dat).
  Future<void> cancelAll() async {
    if (!supported) return;
    try {
      await _init();
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
