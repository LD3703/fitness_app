import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/foundation.dart';

import '../core/date_utils.dart';
import '../data/database.dart';
import '../l10n/app_localizations.dart';
import '../modules/calendar/free_slots.dart';

/// Zápis naplánovaných tréninků do kalendáře telefonu.
///
/// Aplikace si pamatuje ID událostí, které sama vytvořila (tabulka
/// CalendarLinks). Při synchronizaci smaže své budoucí události a vytvoří
/// je znovu podle aktuálních plánů – jiné události v kalendáři nemění.
class CalendarService {
  CalendarService._();

  static final instance = CalendarService._();

  static const _defaultStartMinutes = 17 * 60;
  static const _durationMinutes = 60;

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<bool> requestPermission() async {
    if (!supported) return false;
    try {
      final status = await DeviceCalendar.instance.requestPermissions();
      return status == CalendarPermissionStatus.granted;
    } catch (e) {
      debugPrint('Calendar permission failed: $e');
      return false;
    }
  }

  /// Má aplikace plný přístup (i ke čtení událostí)?
  Future<bool> hasPermission() async {
    if (!supported) return false;
    return _hasPermission();
  }

  Future<bool> _hasPermission() async {
    try {
      final status = await DeviceCalendar.instance.hasPermissions();
      return status == CalendarPermissionStatus.granted;
    } catch (_) {
      return false;
    }
  }

  /// Srovná události v kalendáři s naplánovanými tréninky [planned].
  Future<void> sync(
    AppDatabase db,
    List<PlannedWorkout> planned,
    AppLocalizations l10n,
  ) async {
    if (!supported || !await _hasPermission()) return;
    try {
      await removeFuture(db);
      for (final w in planned) {
        final minutes = w.plan.plannedTimeMinutes ?? _defaultStartMinutes;
        final start = DateTime(
          w.day.year,
          w.day.month,
          w.day.day,
          minutes ~/ 60,
          minutes % 60,
        );
        final eventId = await DeviceCalendar.instance.createEvent(
          title: w.plan.name,
          startDate: start,
          endDate: start.add(const Duration(minutes: _durationMinutes)),
          description: l10n.calendarEventDescription,
        );
        await db.addCalendarLink(eventId, w.plan.id, w.day);
      }
    } catch (e) {
      debugPrint('Calendar sync failed: $e');
    }
  }

  /// Smaže události, které aplikace vytvořila od dneška dál.
  Future<void> removeFuture(AppDatabase db) async {
    if (!supported) return;
    final links = await db.calendarLinksFrom(startOfDay(DateTime.now()));
    for (final link in links) {
      try {
        await DeviceCalendar.instance.deleteEvent(eventId: link.eventId);
      } catch (_) {
        // Uživatel mohl událost smazat ručně – nevadí.
      }
      await db.deleteCalendarLink(link.id);
    }
  }

  /// Události ze všech kalendářů telefonu, které zasahují do [from, to).
  ///
  /// Vynechá události, které vytvořila sama aplikace (tabulka CalendarLinks),
  /// zrušené události a události označené jako „volno“. Bez oprávnění
  /// nebo při chybě vrátí prázdný seznam.
  Future<List<CalendarEntry>> readEntries(
    AppDatabase db,
    DateTime from,
    DateTime to,
  ) async {
    if (!supported || !await _hasPermission()) return const [];
    try {
      final own = {
        for (final link in await db.calendarLinksFrom(
          startOfDay(from).subtract(const Duration(days: 1)),
        ))
          link.eventId,
      };
      final events = await DeviceCalendar.instance.listEvents(from, to);
      return [
        for (final e in events)
          if (!own.contains(e.eventId) &&
              !own.contains(e.instanceId) &&
              e.status != EventStatus.canceled &&
              e.availability != EventAvailability.free)
            CalendarEntry(
              title: e.title,
              start: e.startDate.toLocal(),
              end: e.endDate.toLocal(),
              allDay: e.isAllDay,
            ),
      ];
    } catch (e) {
      debugPrint('Calendar read failed: $e');
      return const [];
    }
  }
}
