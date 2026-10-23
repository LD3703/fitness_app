// Tréninky s trenérem v kalendáři telefonu (klient i trenér, docs/coach.md).
//
// Do kalendáře patří jen přijaté pozvánky, které ještě neskončily – každý
// zbývající termín jako samostatná událost. Aplikace si pamatuje, které
// události vytvořila (tabulka CoachCalendarEvents) a s jakou verzí pozvánky
// (updatedAt): změněný termín, zrušení, odmítnutí nebo zrušené propojení
// události smaže a případně vytvoří znovu. Jiné události v kalendáři
// nemění. Rozhodnutí je čistá funkce planCoachCalendar (testy:
// test/coach_calendar_test.dart).
import 'dart:async';

import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../services/calendar_service.dart';
import '../../services/sync_controller.dart' show deviceLocalizations;
import '../calendar/calendar_title.dart';
import '../social/social_service.dart' show socialUserProvider;
import 'coach_service.dart';

/// Pozvánka, která patří do kalendáře: [key] = „`c:<id>`“ (klient) nebo
/// „`t:<klient>/<id>`“ (trenér), [withName] = s kým (trenér / klient).
typedef CoachCalendarItem = ({
  String key,
  CoachSession session,
  String withName,
});

typedef CoachCalendarPlan = ({
  List<String> remove,
  List<CoachCalendarItem> add,
});

String clientSessionKey(String sessionId) => 'c:$sessionId';
String trainerSessionKey(String clientUid, String sessionId) =>
    't:$clientUid/$sessionId';

/// Má pozvánka v kalendáři být?
bool belongsToCalendar(CoachSession s, DateTime now) =>
    s.status == CoachSessionStatus.accepted && s.isActive(now);

int calendarVersion(CoachSession s) => s.updatedAtMs ?? 0;

/// Co smazat a co vytvořit. [existing] = klíč → verze uložených událostí.
/// Přijatá pozvánka, která už skončila, se nemaže (proběhlé tréninky
/// v kalendáři zůstanou); znovu se ale nevytváří. Mazání se týká jen
/// budoucích termínů (CoachCalendar.sync).
CoachCalendarPlan planCoachCalendar(
  List<CoachCalendarItem> items,
  Map<String, int> existing,
  DateTime now,
) {
  final wanted = {
    for (final i in items)
      if (belongsToCalendar(i.session, now) ||
          (i.session.status == CoachSessionStatus.accepted &&
              existing.containsKey(i.key)))
        i.key: i,
  };
  final remove = <String>[
    for (final e in existing.entries)
      if (wanted[e.key] == null ||
          calendarVersion(wanted[e.key]!.session) != e.value)
        e.key,
  ];
  final add = <CoachCalendarItem>[
    for (final w in wanted.values)
      if ((!existing.containsKey(w.key) || remove.contains(w.key)) &&
          belongsToCalendar(w.session, now))
        w,
  ];
  return (remove: remove, add: add);
}

abstract final class CoachCalendar {
  static bool _running = false;

  /// Poslední požadavek, který přišel během běžící synchronizace (spustí
  /// se po ní – vždy s nejnovějšími pozvánkami).
  static ({
    AppDatabase db,
    List<CoachCalendarItem> items,
    AppLocalizations l10n,
  })? _next;

  /// Srovná kalendář s pozvánkami [items]. Bez oprávnění ke kalendáři
  /// nic nedělá (o oprávnění se žádá při přijetí pozvánky).
  static Future<void> sync(
    AppDatabase db,
    List<CoachCalendarItem> items,
    AppLocalizations l10n,
  ) async {
    final calendar = CalendarService.instance;
    if (!calendar.supported || !await calendar.hasPermission()) return;
    if (_running) {
      _next = (db: db, items: items, l10n: l10n);
      return;
    }
    _running = true;
    try {
      final now = DateTime.now();
      final rows = await db.allCoachCalendarEvents();
      final existing = <String, int>{
        for (final r in rows) r.sessionKey: r.version,
      };
      final plan = planCoachCalendar(items, existing, now);
      for (final key in plan.remove) {
        for (final r in rows.where((r) => r.sessionKey == key)) {
          // Proběhlé termíny v kalendáři zůstanou (trénink se konal).
          final start = r.startAt;
          if (start != null && !start.isAfter(now)) continue;
          try {
            await DeviceCalendar.instance.deleteEvent(eventId: r.eventId);
          } catch (_) {
            // Uživatel mohl událost smazat ručně – nevadí.
          }
        }
        await db.deleteCoachCalendarEvents(key);
      }
      if (plan.add.isEmpty) return;
      final template = (await db.watchProfile().first).calendarTitle;
      for (final item in plan.add) {
        final s = item.session;
        final title = l10n.socialCalendarTitle(
          calendarEventTitle(
            template: template,
            plan: s.title,
            defaultTitle: l10n.calendarTitleDefault,
          ),
          item.withName,
        );
        for (final start in s.upcoming(now)) {
          final eventId = await DeviceCalendar.instance.createEvent(
            title: title,
            startDate: start,
            endDate: s.endOf(start),
            description: s.note ?? l10n.coachSessionCalendarDescription,
          );
          await db.addCoachCalendarEvent(
            item.key,
            eventId,
            calendarVersion(s),
            startAt: start,
          );
        }
      }
    } catch (e) {
      debugPrint('Coach: calendar sync failed: $e');
    } finally {
      _running = false;
      final next = _next;
      if (next != null) {
        _next = null;
        unawaited(sync(next.db, next.items, next.l10n));
      }
    }
  }
}

/// [coach:app] – po změně pozvánek (jako klient i jako trenér) srovná
/// kalendář telefonu. Dokud se přihlášení, propojení a pozvánky nenačtou,
/// nic nemění – jinak by se při startu aplikace události smazaly
/// a vytvořily znovu.
final coachAppProvider = Provider<void>((ref) {
  Timer? debounce;
  void schedule() {
    debounce?.cancel();
    debounce = Timer(const Duration(seconds: 2), () => _syncCalendar(ref));
  }

  ref.listen(mySessionsProvider, (_, __) => schedule(), fireImmediately: true);
  ref.listen(trainerSessionsProvider, (_, __) => schedule(),
      fireImmediately: true);
  ref.onDispose(() => debounce?.cancel());
});

Future<void> _syncCalendar(Ref ref) async {
  final loaded = [
    ref.read(socialUserProvider),
    ref.read(myCoachLinkProvider),
    ref.read(myTrainerProvider),
    ref.read(mySessionsProvider),
    ref.read(trainerSessionsProvider),
  ].every((v) => v is AsyncData);
  if (!loaded) return;
  final mine = ref.read(mySessionsProvider).requireValue;
  final ofClients = ref.read(trainerSessionsProvider).requireValue;
  final link = ref.read(myCoachLinkProvider).valueOrNull;
  final names = {
    for (final c in ref.read(myClientsProvider).valueOrNull ?? const <CoachLink>[])
      c.clientUid: c.clientName,
  };
  final items = <CoachCalendarItem>[
    for (final s in mine)
      (
        key: clientSessionKey(s.id),
        session: s,
        withName: link?.trainerName ?? s.trainerName,
      ),
    for (final e in ofClients.entries)
      for (final s in e.value)
        (
          key: trainerSessionKey(e.key, s.id),
          session: s,
          withName: names[e.key] ?? '?',
        ),
  ];
  await CoachCalendar.sync(
    ref.read(databaseProvider),
    items,
    deviceLocalizations(),
  );
}
