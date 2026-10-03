import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../providers.dart';
import '../../services/notification_service.dart';
import '../../services/sync_controller.dart';
import 'social_backend.dart';
import 'social_publisher.dart';
import 'social_queries.dart';
import 'social_service.dart';

/// Push notifikace přes FCM (posílá je Cloud Function při nové položce
/// v novinkách). V popředí je aplikace ukáže jako lokální notifikaci;
/// na pozadí je zobrazí systém sám. Bez nasazených funkcí push nechodí,
/// novinky jsou ale vidět v aplikaci.
class SocialMessaging {
  SocialMessaging._();

  static final instance = SocialMessaging._();

  final _local = FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _onMessage;
  StreamSubscription<String>? _onRefresh;
  String? _savedToken;
  bool _permissionAsked = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'friends',
      'Friends',
      channelDescription: 'Records, invitations and challenges from friends',
      importance: Importance.defaultImportance,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Spustí posluchače (jednou) a zaregistruje token.
  Future<void> start() async {
    if (!SocialBackend.available) return;
    try {
      _onMessage ??= FirebaseMessaging.onMessage.listen(
        (m) => unawaited(_showLocal(m)),
        onError: (Object e) => debugPrint('Social: FCM error: $e'),
      );
      _onRefresh ??= FirebaseMessaging.instance.onTokenRefresh.listen(
        (t) => unawaited(_save(t)),
        onError: (Object e) => debugPrint('Social: FCM token error: $e'),
      );
      await registerToken(force: true);
    } catch (e) {
      debugPrint('Social: messaging start failed: $e');
    }
  }

  /// Uloží FCM token k účtu (o povolení požádá jen jednou za běh).
  Future<void> registerToken({bool force = false}) async {
    if (!SocialBackend.available || SocialService.instance.uid == null) return;
    if (_savedToken != null && !force) return;
    try {
      if (!_permissionAsked) {
        _permissionAsked = true;
        await FirebaseMessaging.instance.requestPermission();
      }
      final token = await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 15));
      if (token != null) await _save(token);
    } catch (e) {
      // Např. iOS bez APNs tokenu nebo bez připojení – zkusí se příště.
      debugPrint('Social: FCM token failed: $e');
    }
  }

  Future<void> _save(String token) async {
    if (SocialService.instance.uid == null) return;
    String lang;
    try {
      lang = deviceLocalizations().localeName;
    } catch (_) {
      lang = 'en';
    }
    await SocialService.instance.saveFcmToken(token, lang);
    _savedToken = token;
  }

  /// Při odhlášení / smazání účtu: token odebrat, ať push nechodí dál.
  Future<void> unregister() async {
    final token = _savedToken;
    _savedToken = null;
    if (!SocialBackend.available) return;
    try {
      if (token != null && SocialService.instance.uid != null) {
        await SocialService.instance.removeFcmToken(token);
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Social: FCM unregister failed: $e');
    }
  }

  Future<void> _showLocal(RemoteMessage message) async {
    final n = message.notification;
    final title = n?.title ?? message.data['title']?.toString();
    final body = n?.body ?? message.data['body']?.toString();
    if (title == null && body == null) return;
    try {
      // Plugin je singleton: inicializuje ho jen NotificationService, jinak
      // by druhé initialize() přepsalo jeho obsluhu klepnutí a kategorie iOS.
      await NotificationService.instance.ensureInitialized();
      await _local.show(
        id: 5000 + (message.messageId ?? '$title$body').hashCode % 1000,
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } catch (e) {
      debugPrint('Social: local notification failed: $e');
    }
  }
}

/// Lokální výzvy od přátel (sleduje se kvůli completedAt od modulu sharing).
final socialLocalChallengesProvider = StreamProvider<List<Challenge>>(
  (ref) => ref.watch(databaseProvider).socialWatchRemoteChallenges(),
);

/// [social:app] – běží po celou dobu: po přihlášení zapne push,
/// zpracovává příchozí odpovědi na pozvánky (zápis do kalendáře)
/// a hned hlásí splněné výzvy.
final socialAppProvider = Provider<void>((ref) {
  if (!ref.watch(socialAvailableProvider)) return;
  ref.listen(socialLocalChallengesProvider, (_, next) {
    final list = next.valueOrNull;
    if (list != null && list.any((c) => c.completedAt != null)) {
      unawaited(SocialPublisher.syncChallenges(ref.read(databaseProvider)));
    }
  });
  ref.listen(socialUserProvider, (_, next) {
    if (next.valueOrNull != null) unawaited(SocialMessaging.instance.start());
  }, fireImmediately: true);
  ref.listen(socialFeedProvider, (_, next) {
    final items = next.valueOrNull;
    if (items != null && items.isNotEmpty) {
      unawaited(SocialPublisher.processInbox(items));
    }
  });
});
