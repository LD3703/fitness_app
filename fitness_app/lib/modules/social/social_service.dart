import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gym/gym_service.dart';
import 'social_auth.dart';
import 'social_backend.dart';
import 'social_logic.dart';
import 'social_models.dart';

/// Přítel s tímto kódem neexistuje / je to vlastní kód / už je přítel.
enum AddFriendError { notFound, self, alreadyFriend, notSignedIn }

class AddFriendException implements Exception {
  AddFriendException(this.error);

  final AddFriendError error;
}

/// Práce s Firestore. Datový model: docs/social.md.
///
/// Všechny metody předpokládají, že je Firebase k dispozici
/// ([SocialBackend.available]) a uživatel přihlášený; jinak vyhodí
/// [StateError]. UI je volá jen v takovém stavu, háčky to kontrolují.
class SocialService {
  SocialService._();

  static final instance = SocialService._();

  FirebaseFirestore get _fs => FirebaseFirestore.instance;

  String? get uid => SocialAuth.instance.currentUser?.uid;

  String get _me {
    final id = uid;
    if (id == null) throw StateError('Not signed in');
    return id;
  }

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      _fs.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _friends(String uid) =>
      userDoc(uid).collection('friends');

  CollectionReference<Map<String, dynamic>> _feed(String uid) =>
      userDoc(uid).collection('feed');

  DocumentReference<Map<String, dynamic>> _private(String uid) =>
      userDoc(uid).collection('private').doc('messaging');

  DocumentReference<Map<String, dynamic>> _code(String code) =>
      _fs.collection('friendCodes').doc(code);

  CollectionReference<Map<String, dynamic>> get _invitations =>
      _fs.collection('invitations');

  CollectionReference<Map<String, dynamic>> get _challenges =>
      _fs.collection('challenges');

  // -------------------------------------------------------------------
  // Profil
  // -------------------------------------------------------------------

  /// Založí dokument uživatele a jeho kód přítele, pokud ještě nejsou.
  Future<void> ensureProfile({
    required String displayName,
    required bool shareRecords,
    required bool shareStats,
    required String lang,
  }) async {
    final me = _me;
    final snap = await userDoc(me).get();
    if (snap.exists && readString(snap.data()?['friendCode']) != null) return;
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = generateFriendCode();
      final batch = _fs.batch()
        ..set(_code(code), {'uid': me, 'name': _name(displayName)})
        ..set(userDoc(me), {
          'displayName': _name(displayName),
          'friendCode': code,
          'createdAt': FieldValue.serverTimestamp(),
          'shareRecords': shareRecords,
          'shareStats': shareStats,
          'lang': lang,
        });
      try {
        await batch.commit();
        return;
      } on FirebaseException catch (e) {
        // Kód už někdo má (pravidla nedovolí přepsat cizí) → zkusit jiný.
        if (e.code != 'permission-denied') rethrow;
      }
    }
    throw StateError('Could not create a friend code');
  }

  static String _name(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t.length > 40 ? t.substring(0, 40) : t;
  }

  Stream<FriendProfile?> watchMe() {
    final me = uid;
    if (me == null) return Stream.value(null);
    return userDoc(me).snapshots().map((s) {
      final data = s.data();
      return data == null ? null : FriendProfile.fromMap(me, data);
    });
  }

  /// Sloučí změny do vlastního dokumentu (statistiky, nastavení sdílení).
  /// Jméno se propisuje i do dokumentu kódu (ukáže se při přidání).
  Future<void> updateMe(Map<String, Object?> fields) async {
    final me = _me;
    // Pravidla povolí jméno jen 1–40 znaků.
    final rawName = fields['displayName'];
    final name = rawName is String ? _name(rawName) : null;
    final data = {...fields, if (name != null) 'displayName': name};
    final batch = _fs.batch()..set(userDoc(me), data, SetOptions(merge: true));
    final code = await _myCode();
    if (name != null && code != null) {
      batch.set(_code(code), {'uid': me, 'name': name});
    }
    await quietWrite(batch.commit());
  }

  Future<String?> _myCode() async {
    try {
      final snap = await userDoc(_me).get();
      return readString(snap.data()?['friendCode']);
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------
  // Přátelé
  // -------------------------------------------------------------------

  Stream<List<FriendLink>> watchFriends() {
    final me = uid;
    if (me == null) return Stream.value(const []);
    return _friends(me).snapshots().map((q) => [
          for (final d in q.docs)
            FriendLink(uid: d.id, since: readDate(d.data()['since'])),
        ]);
  }

  Future<List<String>> friendUids() async {
    final q = await _friends(_me).get();
    return [for (final d in q.docs) d.id];
  }

  /// Profily přátel. Kdo nás mezitím odebral, se přeskočí.
  Future<List<FriendProfile>> loadProfiles(Iterable<String> uids) async {
    final result = await Future.wait(uids.map((u) async {
      try {
        final s = await userDoc(u).get();
        final data = s.data();
        return data == null ? null : FriendProfile.fromMap(u, data);
      } catch (e) {
        debugPrint('Social: profile $u not readable: $e');
        return null;
      }
    }));
    return result.whereType<FriendProfile>().toList();
  }

  /// Kdo má tento kód: uid a jméno (pro potvrzení před přidáním).
  Future<({String uid, String name})?> lookupCode(String code) async {
    final snap = await _code(code).get();
    final data = snap.data();
    final id = readString(data?['uid']);
    if (id == null) return null;
    return (uid: id, name: readString(data?['name']) ?? '?');
  }

  /// Přidá přítele podle kódu. Vazba vznikne na obou stranách hned –
  /// kód (z QR nebo odkazu) slouží jako pozvánka.
  Future<String> addFriend(String code, {required String myName}) async {
    final me = uid;
    if (me == null) throw AddFriendException(AddFriendError.notSignedIn);
    final target = await lookupCode(code);
    if (target == null) throw AddFriendException(AddFriendError.notFound);
    if (target.uid == me) throw AddFriendException(AddFriendError.self);
    final existing = await _friends(me).doc(target.uid).get();
    if (existing.exists) throw AddFriendException(AddFriendError.alreadyFriend);

    final now = FieldValue.serverTimestamp();
    final batch = _fs.batch()
      // U přítele: pravidla ověří, že znám jeho platný kód.
      ..set(_friends(target.uid).doc(me), {'since': now, 'code': code})
      ..set(_friends(me).doc(target.uid), {'since': now})
      ..set(_feed(target.uid).doc(), _feedData(FeedType.friend, me, myName, {}));
    await batch.commit().timeout(const Duration(seconds: 15));
    return target.name;
  }

  Future<void> removeFriend(String friendUid) async {
    final me = _me;
    final batch = _fs.batch()
      ..delete(_friends(me).doc(friendUid))
      ..delete(_friends(friendUid).doc(me));
    await quietWrite(batch.commit());
  }

  // -------------------------------------------------------------------
  // Novinky
  // -------------------------------------------------------------------

  Map<String, Object?> _feedData(
    String type,
    String fromUid,
    String fromName,
    Map<String, Object?> data,
  ) =>
      {
        'type': type,
        'fromUid': fromUid,
        'fromName': _name(fromName),
        'createdAt': FieldValue.serverTimestamp(),
        'data': data,
        'read': false,
      };

  Stream<List<FeedItem>> watchFeed({int limit = 50}) {
    final me = uid;
    if (me == null) return Stream.value(const []);
    return _feed(me)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => [
              for (final d in q.docs) FeedItem.fromMap(d.id, d.data()),
            ]);
  }

  /// Zapíše položku do novinek přátel [to] (výchozí: všem přátelům).
  Future<void> fanOut(
    String type,
    String myName,
    Map<String, Object?> data, {
    List<String>? to,
  }) async {
    final me = _me;
    final targets = to ?? await friendUids();
    if (targets.isEmpty) return;
    // Dávka unese max. 500 zápisů.
    for (var i = 0; i < targets.length; i += 400) {
      final batch = _fs.batch();
      for (final f in targets.skip(i).take(400)) {
        batch.set(_feed(f).doc(), _feedData(type, me, myName, data));
      }
      await quietWrite(batch.commit());
    }
  }

  Future<void> updateFeedItem(
    String id, {
    bool? read,
    String? status,
    bool? handled,
  }) async {
    await quietWrite(_feed(_me).doc(id).update({
      if (read != null) 'read': read,
      if (status != null) 'status': status,
      if (handled != null) 'handled': handled,
    }));
  }

  Future<void> markAllRead(Iterable<FeedItem> items) async {
    final unread = items.where((i) => !i.read).toList();
    if (unread.isEmpty) return;
    final batch = _fs.batch();
    for (final i in unread) {
      batch.update(_feed(_me).doc(i.id), {'read': true});
    }
    await quietWrite(batch.commit());
  }

  // -------------------------------------------------------------------
  // Pozvánky na trénink
  // -------------------------------------------------------------------

  Future<String> sendInvitation({
    required String toUid,
    required String myName,
    required String planName,
    required DateTime startAt,
    required int durationMinutes,
  }) async {
    final me = _me;
    final ref = _invitations.doc();
    final batch = _fs.batch()
      ..set(ref, {
        'fromUid': me,
        'fromName': _name(myName),
        'toUid': toUid,
        'planName': _name(planName),
        'startAt': Timestamp.fromDate(startAt),
        'durationMinutes': durationMinutes,
        'status': InviteStatus.pending,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..set(
        _feed(toUid).doc(),
        _feedData(FeedType.invite, me, myName, {
          'invitationId': ref.id,
          'planName': _name(planName),
          'startAt': Timestamp.fromDate(startAt),
          'durationMinutes': durationMinutes,
        }),
      );
    await quietWrite(batch.commit());
    return ref.id;
  }

  Future<Invitation?> getInvitation(String id) async {
    final s = await _invitations.doc(id).get();
    final data = s.data();
    return data == null ? null : Invitation.fromMap(id, data);
  }

  /// Odpověď na pozvánku: změní stav a dá vědět odesílateli.
  Future<void> answerInvitation(
    Invitation inv, {
    required bool accept,
    required String myName,
  }) async {
    final me = _me;
    final status = accept ? InviteStatus.accepted : InviteStatus.declined;
    final batch = _fs.batch()
      ..update(_invitations.doc(inv.id), {'status': status})
      ..set(
        _feed(inv.fromUid).doc(),
        _feedData(FeedType.inviteReply, me, myName, {
          'invitationId': inv.id,
          'accepted': accept,
          'planName': inv.planName,
          'startAt': Timestamp.fromDate(inv.startAt),
          'durationMinutes': inv.durationMinutes,
        }),
      );
    await quietWrite(batch.commit());
  }

  // -------------------------------------------------------------------
  // Výzvy
  // -------------------------------------------------------------------

  /// Založí výzvu mezi mnou a [friendUid]. [notify] = položka do novinek
  /// přítele ('invite' = přijmi výzvu, 'tookOn' = beru tvůj rekord).
  Future<String> createChallenge({
    required String friendUid,
    required String myName,
    required String kind,
    required double target,
    required DateTime deadline,
    required bool creatorAccepted,
    required String notify,
    String? exerciseSlug,
    String? exerciseNameEn,
    String? exerciseNameCs,
  }) async {
    final me = _me;
    final ref = _challenges.doc();
    final batch = _fs.batch()
      ..set(ref, {
        'creatorUid': me,
        'creatorName': _name(myName),
        'members': [me, friendUid],
        'kind': kind,
        'target': target,
        'deadline': Timestamp.fromDate(deadline),
        'createdAt': FieldValue.serverTimestamp(),
        'exerciseSlug': exerciseSlug,
        'exerciseName': exerciseNameEn,
        'accepted': {if (creatorAccepted) me: true},
        'declined': <String, Object?>{},
        'completed': <String, Object?>{},
        'progress': <String, Object?>{},
      })
      ..set(
        _feed(friendUid).doc(),
        _feedData(FeedType.challenge, me, myName, {
          'challengeId': ref.id,
          'kind': kind,
          'target': target,
          'deadline': Timestamp.fromDate(deadline),
          'role': notify,
          if (exerciseSlug != null) 'exerciseSlug': exerciseSlug,
          if (exerciseNameEn != null) 'exerciseNameEn': exerciseNameEn,
          if (exerciseNameCs != null) 'exerciseNameCs': exerciseNameCs,
        }),
      );
    await quietWrite(batch.commit());
    return ref.id;
  }

  Future<RemoteChallenge?> getChallenge(String id) async {
    final s = await _challenges.doc(id).get();
    final data = s.data();
    return data == null ? null : RemoteChallenge.fromMap(id, data);
  }

  Future<List<RemoteChallenge>> myChallenges() async {
    final q = await _challenges.where('members', arrayContains: _me).get();
    return [for (final d in q.docs) RemoteChallenge.fromMap(d.id, d.data())];
  }

  Future<void> answerChallenge(String id, {required bool accept}) async {
    final me = _me;
    await quietWrite(_challenges.doc(id).update({
      (accept ? 'accepted.$me' : 'declined.$me'): true,
    }));
  }

  /// Zapíše můj postup / splnění výzvy (jen procenta nebo počty).
  Future<void> reportChallenge(
    String id, {
    DateTime? completedAt,
    double? progress,
  }) async {
    final me = _me;
    final fields = <String, Object?>{
      if (completedAt != null) 'completed.$me': Timestamp.fromDate(completedAt),
      if (progress != null) 'progress.$me': progress,
    };
    if (fields.isEmpty) return;
    await quietWrite(_challenges.doc(id).update(fields));
  }

  // -------------------------------------------------------------------
  // Push notifikace
  // -------------------------------------------------------------------

  /// Tokeny jsou v users/{uid}/private/messaging – vidí je jen vlastník
  /// (a Cloud Functions), ne přátelé.
  Future<void> saveFcmToken(String token, String lang) => quietWrite(
        _private(_me).set({
          'fcmTokens': FieldValue.arrayUnion([token]),
          'lang': lang,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );

  Future<void> removeFcmToken(String token) => quietWrite(
        _private(_me).set({
          'fcmTokens': FieldValue.arrayRemove([token]),
        }, SetOptions(merge: true)),
      );

  // -------------------------------------------------------------------
  // Smazání účtu
  // -------------------------------------------------------------------

  /// Smaže všechna moje data na serveru. Cloud Function při smazání účtu
  /// uklízí totéž znovu (pro jistotu), ale aplikace na ni nespoléhá.
  Future<void> deleteAllServerData() async {
    final me = _me;
    // Z posilovny odejít (smaže záznamy v žebříčku, sníží počet členů).
    try {
      await GymService.instance.leaveGym();
    } catch (e) {
      debugPrint('Social: leaving gym failed: $e');
    }
    final code = await _myCode();
    final friends = await friendUids();

    final refs = <DocumentReference<Map<String, dynamic>>>[
      for (final f in friends) _friends(f).doc(me),
      for (final f in friends) _friends(me).doc(f),
      ...(await _feed(me).get()).docs.map((d) => d.reference),
      ...(await _invitations.where('fromUid', isEqualTo: me).get())
          .docs
          .map((d) => d.reference),
      ...(await _invitations.where('toUid', isEqualTo: me).get())
          .docs
          .map((d) => d.reference),
      ...(await _challenges.where('members', arrayContains: me).get())
          .docs
          .map((d) => d.reference),
      _private(me),
      userDoc(me).collection('private').doc('gym'),
      if (code != null) _code(code),
      userDoc(me),
    ];
    for (var i = 0; i < refs.length; i += 400) {
      final batch = _fs.batch();
      for (final r in refs.skip(i).take(400)) {
        batch.delete(r);
      }
      await batch.commit().timeout(const Duration(seconds: 20));
    }
  }
}

// ---------------------------------------------------------------------------
// Providery
// ---------------------------------------------------------------------------

/// Přihlášený uživatel Firebase (null = nepřihlášen nebo Firebase chybí).
final socialUserProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(socialAvailableProvider)) return Stream.value(null);
  return FirebaseAuth.instance.authStateChanges();
});

final socialMeProvider = StreamProvider<FriendProfile?>((ref) {
  final user = ref.watch(socialUserProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return SocialService.instance.watchMe();
});

final socialFriendLinksProvider = StreamProvider<List<FriendLink>>((ref) {
  final user = ref.watch(socialUserProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return SocialService.instance.watchFriends();
});

/// Profily přátel (načtou se při změně seznamu, obnoví se tahem dolů).
final socialFriendProfilesProvider =
    FutureProvider<List<FriendProfile>>((ref) async {
  final links = await ref.watch(socialFriendLinksProvider.future);
  if (links.isEmpty) return const [];
  final profiles =
      await SocialService.instance.loadProfiles(links.map((l) => l.uid));
  profiles.sort((a, b) =>
      a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
  return profiles;
});

final socialFeedProvider = StreamProvider<List<FeedItem>>((ref) {
  final user = ref.watch(socialUserProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return SocialService.instance.watchFeed();
});

final socialUnreadCountProvider = Provider<int>((ref) {
  final feed = ref.watch(socialFeedProvider).valueOrNull ?? const [];
  return feed.where((i) => !i.read).length;
});

final socialInvitationProvider =
    FutureProvider.autoDispose.family<Invitation?, String>(
  (ref, id) => SocialService.instance.getInvitation(id),
);

final socialChallengeProvider =
    FutureProvider.autoDispose.family<RemoteChallenge?, String>(
  (ref, id) => SocialService.instance.getChallenge(id),
);
