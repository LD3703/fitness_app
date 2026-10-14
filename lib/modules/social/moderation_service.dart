import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'moderation_logic.dart';
import 'social_auth.dart';
import 'social_backend.dart';
import 'social_models.dart';
import 'social_service.dart' show SocialService, socialUserProvider;

/// Zablokovaný uživatel (users/{me}/blocked/{uid}).
class BlockedUser {
  const BlockedUser({required this.uid, required this.name});

  final String uid;
  final String name;
}

/// Nahlášení obsahu a blokování uživatelů.
class ModerationService {
  ModerationService._();

  static final instance = ModerationService._();

  FirebaseFirestore get _fs => FirebaseFirestore.instance;

  String get _me {
    final id = SocialAuth.instance.currentUser?.uid;
    if (id == null) throw StateError('Not signed in');
    return id;
  }

  CollectionReference<Map<String, dynamic>> _blocked(String uid) =>
      _fs.collection('users').doc(uid).collection('blocked');

  /// Nahlásí obsah. Opakované nahlášení stejného cíle pravidla odmítnou
  /// (dokument už existuje) – to se bere jako úspěch.
  Future<void> report({
    required ContentReportKind kind,
    required String targetId,
    required String targetName,
    required ContentReportReason reason,
  }) async {
    final me = _me;
    final ref = _fs
        .collection('contentReports')
        .doc(contentReportId(kind, targetId, me));
    try {
      await ref.set({
        ...contentReportFields(
          kind: kind,
          targetId: targetId,
          targetName: targetName,
          reason: reason,
          reporterUid: me,
        ),
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      debugPrint('Moderation: already reported ($kind $targetId).');
    }
  }

  /// Zablokuje uživatele: zruší přátelství v obou směrech a zapíše ho
  /// do seznamu blokovaných – pravidla mu pak nedovolí se znovu přidat
  /// (ani se starým kódem přítele) ani posílat novinky. Můj kód přítele
  /// se vymění, aby se po odblokování nepřidal se starým.
  Future<void> block(String uid, String name) async {
    final me = _me;
    final users = _fs.collection('users');
    final batch = _fs.batch()
      ..set(_blocked(me).doc(uid), {
        'uid': uid,
        'name': name.trim().isEmpty
            ? '?'
            : name.trim().length > 40
                ? name.trim().substring(0, 40)
                : name.trim(),
        'since': FieldValue.serverTimestamp(),
      })
      ..delete(users.doc(me).collection('friends').doc(uid))
      ..delete(users.doc(uid).collection('friends').doc(me));
    await quietWrite(batch.commit());
    await _removeSharedContent(me, uid);
    try {
      await SocialService.instance.rotateFriendCode();
    } catch (e) {
      debugPrint('Moderation: friend code rotation failed: $e');
    }
  }

  /// Po zablokování smaže, co mezi námi zůstalo: jeho novinky u mě,
  /// pozvánky oběma směry a společné výzvy. Chyba blokování nezastaví.
  Future<void> _removeSharedContent(String me, String uid) async {
    try {
      final users = _fs.collection('users');
      final invitations = _fs.collection('invitations');
      final refs = <DocumentReference<Map<String, dynamic>>>[
        ...(await users
                .doc(me)
                .collection('feed')
                .where('fromUid', isEqualTo: uid)
                .get())
            .docs
            .map((d) => d.reference),
        ...(await invitations
                .where('toUid', isEqualTo: me)
                .where('fromUid', isEqualTo: uid)
                .get())
            .docs
            .map((d) => d.reference),
        ...(await invitations
                .where('fromUid', isEqualTo: me)
                .where('toUid', isEqualTo: uid)
                .get())
            .docs
            .map((d) => d.reference),
        ...(await _fs
                .collection('challenges')
                .where('members', arrayContains: me)
                .get())
            .docs
            .where((d) =>
                (d.data()['members'] as List<Object?>?)?.contains(uid) ?? false)
            .map((d) => d.reference),
      ];
      for (var i = 0; i < refs.length; i += 400) {
        final batch = _fs.batch();
        for (final r in refs.skip(i).take(400)) {
          batch.delete(r);
        }
        await quietWrite(batch.commit());
      }
    } catch (e) {
      debugPrint('Moderation: cleanup after block failed: $e');
    }
  }

  Future<void> unblock(String uid) =>
      quietWrite(_blocked(_me).doc(uid).delete());

  Stream<List<BlockedUser>> watchBlocked() {
    final me = SocialAuth.instance.currentUser?.uid;
    if (me == null) return Stream.value(const []);
    return _blocked(me).snapshots().map((s) => [
          for (final d in s.docs)
            BlockedUser(uid: d.id, name: readString(d.data()['name']) ?? '?'),
        ]);
  }
}

/// Zablokovaní uživatelé (Přátelé → Účet a sdílení).
final blockedUsersProvider = StreamProvider<List<BlockedUser>>((ref) {
  ref.watch(socialUserProvider);
  return ModerationService.instance.watchBlocked();
});
