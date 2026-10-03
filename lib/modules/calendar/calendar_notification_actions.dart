import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_utils.dart';
import '../../providers.dart';
import '../../router.dart';
import '../../services/notification_service.dart';

/// Obsluha akcí ranní připomínky („Počítám s tím“, „Přesunout“,
/// „Dnes nestíhám“) – když aplikace běží i když ji notifikace spustila.
///
/// „Počítám s tím“ jen zavře notifikaci (bez otevření aplikace).
final calendarNotificationActionsProvider = Provider<void>((ref) {
  final service = NotificationService.instance;

  Future<void> handle(NotificationResponse response) async {
    try {
      final action = response.actionId;
      if (action == null ||
          action.isEmpty ||
          action == NotificationService.actionCountMeIn) {
        return;
      }
      final payload = MorningPayload.tryParse(response.payload);
      if (payload == null) return;

      final profile = await ref.read(profileProvider.future);
      if (!profile.onboardingDone) return;
      final router = ref.read(routerProvider);
      await _waitForStartup(router);

      if (action == NotificationService.actionMove) {
        final today = startOfDay(DateTime.now());
        // Stará notifikace z jiného dne už nic nepřesouvá.
        if (payload.day == today) {
          final db = ref.read(databaseProvider);
          final planned = {
            for (final w in await db.plannedWorkouts(today, 1)) w.plan.id,
          };
          for (final id in payload.planIds) {
            if (planned.contains(id)) await db.postponePlan(id, today);
          }
        }
        router.go('/today');
      } else if (action == NotificationService.actionNoTime) {
        final id = payload.planIds.isEmpty ? null : payload.planIds.first;
        router.push(id == null ? '/planb' : '/planb?planId=$id');
      }
    } catch (e) {
      debugPrint('Notification action failed: $e');
    }
  }

  final sub = service.responses.listen((r) => unawaited(handle(r)));
  ref.onDispose(sub.cancel);

  unawaited(() async {
    await service.ensureInitialized();
    final launch = await service.takeLaunchResponse();
    if (launch != null) await handle(launch);
  }());
});

/// Počká, až router opustí úvodní /loading (jinak by ho přesměrování
/// po načtení profilu přebilo).
Future<void> _waitForStartup(GoRouter router) async {
  for (var i = 0; i < 50; i++) {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (path != '/loading' && path != '/welcome' && path.isNotEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
