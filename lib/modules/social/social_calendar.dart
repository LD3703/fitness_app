import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/foundation.dart';

import '../../data/database.dart';
import '../../services/calendar_service.dart';
import '../../services/sync_controller.dart';
import '../calendar/calendar_title.dart';

/// Zapíše společný trénink do kalendáře telefonu (jako CalendarService).
/// Vrací true, když se událost vytvořila. Název plánu dostane stejný tvar
/// jako ostatní události (vlastní název z Profilu, [calendarEventTitle]).
Future<bool> addSocialWorkoutToCalendar({
  required AppDatabase db,
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
    final profile = await db.watchProfile().first;
    final title = calendarEventTitle(
      template: profile.calendarTitle,
      plan: planName,
      defaultTitle: l10n.calendarTitleDefault,
    );
    await DeviceCalendar.instance.createEvent(
      title: l10n.socialCalendarTitle(title, friendName),
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
