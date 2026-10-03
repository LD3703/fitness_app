import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/foundation.dart';

import '../../services/calendar_service.dart';
import '../../services/sync_controller.dart';

/// Zapíše společný trénink do kalendáře telefonu (jako CalendarService).
/// Vrací true, když se událost vytvořila.
Future<bool> addSocialWorkoutToCalendar({
  required String planName,
  required String friendName,
  required DateTime start,
  required int durationMinutes,
  bool askPermission = true,
}) async {
  final calendar = CalendarService.instance;
  if (!calendar.supported) return false;
  try {
    var granted = (await DeviceCalendar.instance.hasPermissions()) ==
        CalendarPermissionStatus.granted;
    if (!granted && askPermission) {
      granted = await calendar.requestPermission();
    }
    if (!granted) return false;
    final l10n = deviceLocalizations();
    await DeviceCalendar.instance.createEvent(
      title: l10n.socialCalendarTitle(planName, friendName),
      startDate: start,
      endDate: start.add(Duration(minutes: durationMinutes.clamp(15, 480))),
      description: l10n.socialCalendarDescription(friendName),
    );
    return true;
  } catch (e) {
    debugPrint('Social: calendar event failed: $e');
    return false;
  }
}
