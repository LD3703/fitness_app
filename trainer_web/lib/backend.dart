// Firestore a přihlášení pro web trenérů. Stejný datový model jako
// aplikace (lib/modules/coach/coach_service.dart, docs/coach.md) a stejná
// pravidla (firestore.rules, sekce „trenéři“).
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

/// Přihlášení přes Apple na webu potřebuje Services ID u Applu a nastavení
/// ve Firebase (docs/coach.md, „Web pro trenéry“). Do té doby je tlačítko
/// skryté – klienti z iPhonu s účtem Apple se na web nepřihlásí.
const kAppleWebSignIn = false;

DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;

String? _str(Object? v) => v is String && v.trim().isNotEmpty ? v : null;

/// Trenér (trainers/{uid}).
class Trainer {
  const Trainer({
    required this.uid,
    required this.name,
    required this.code,
    this.bio,
    this.clientCount = 0,
    this.zeroSince,
  });

  factory Trainer.fromMap(String uid, Map<String, Object?> m) => Trainer(
        uid: uid,
        name: _str(m['name']) ?? '?',
        code: _str(m['code']) ?? '',
        bio: _str(m['bio']),
        clientCount: (m['clientCount'] as num?)?.toInt() ?? 0,
        zeroSince: _date(m['zeroSince']),
      );

  final String uid;
  final String name;
  final String code;
  final String? bio;
  final int clientCount;
  final DateTime? zeroSince;

  DateTime? get expiresAt =>
      coachStatusExpiresAt(clientCount: clientCount, zeroSince: zeroSince);

  /// Pozvánka pro klienty (otevře aplikaci, jinak stránku ke stažení).
  String get inviteLink => 'https://gymbar.app/coach?code=$code';
}

/// Klient (coachLinks/{klient}).
class Client {
  const Client({
    required this.uid,
    required this.name,
    required this.shareWeight,
    this.since,
  });

  factory Client.fromMap(String uid, Map<String, Object?> m) => Client(
        uid: uid,
        name: _str(m['clientName']) ?? '?',
        shareWeight: m['shareWeight'] == true,
        since: _date(m['createdAt']),
      );

  final String uid;
  final String name;
  final bool shareWeight;
  final DateTime? since;
}

/// Komentář trenéra k tréninku (coachLinks/{klient}/notes/{id}).
class Note {
  const Note({
    required this.id,
    required this.workoutId,
    required this.text,
    this.createdAt,
  });

  factory Note.fromMap(String id, Map<String, Object?> m) => Note(
        id: id,
        workoutId: _str(m['workoutId']) ?? '',
        text: _str(m['text']) ?? '',
        createdAt: _date(m['createdAt']),
      );

  final String id;
  final String workoutId;
  final String text;
  final DateTime? createdAt;
}

/// Plán v knihovně trenéra (trainers/{uid}/plans/{id}).
class LibraryPlan {
  const LibraryPlan({required this.id, required this.plan, this.updatedAt});

  final String id;
  final CoachPlan plan;
  final DateTime? updatedAt;
}

/// Plán přiřazený klientovi (coachLinks/{klient}/plans/{id}).
class ClientPlan {
  const ClientPlan({required this.assigned, this.updatedAt});

  final AssignedPlan assigned;
  final DateTime? updatedAt;

  String get id => assigned.id;
}

class Backend {
  Backend._();

  static final instance = Backend._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _fs => FirebaseFirestore.instance;

  static const _timeout = Duration(seconds: 20);

  String get uid {
    final u = _auth.currentUser;
    if (u == null) throw StateError('Not signed in');
    return u.uid;
  }

  // ---------------------------------------------------------------------
  // Přihlášení
  // ---------------------------------------------------------------------

  Stream<User?> authChanges() => _auth.authStateChanges();

  User? get user => _auth.currentUser;

  Future<void> signInWithGoogle() => _auth.signInWithPopup(
      GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'}));

  Future<void> signInWithApple() => _auth.signInWithPopup(
      OAuthProvider('apple.com')
        ..addScope('email')
        ..addScope('name'));

  Future<void> signOut() => _auth.signOut();

  // ---------------------------------------------------------------------
  // Trenér
  // ---------------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> _trainer(String uid) =>
      _fs.collection('trainers').doc(uid);

  DocumentReference<Map<String, dynamic>> _link(String clientUid) =>
      _fs.collection('coachLinks').doc(clientUid);

  CollectionReference<Map<String, dynamic>> get _library =>
      _trainer(uid).collection('plans');

  Stream<Trainer?> watchTrainer() => _trainer(uid).snapshots().map((s) {
        final d = s.data();
        return d == null ? null : Trainer.fromMap(s.id, d);
      });

  /// Stát se trenérem (stejně jako v aplikaci: kód + profil v jedné dávce).
  Future<void> becomeTrainer({required String name, String? bio}) async {
    final me = uid;
    final random = Random.secure();
    final cleanBio = coachBio(bio);
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = generateCoachCode(random);
      final batch = _fs.batch()
        ..set(_fs.collection('trainerCodes').doc(code), {'uid': me})
        ..set(_trainer(me), {
          'name': coachName(name),
          if (cleanBio != null) 'bio': cleanBio,
          'code': code,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      try {
        await batch.commit().timeout(_timeout);
        return;
      } on FirebaseException catch (e) {
        // Obsazený kód – zkusit jiný.
        if (e.code != 'permission-denied' || attempt == 4) rethrow;
      }
    }
  }

  Future<void> updateTrainer({required String name, String? bio}) =>
      _trainer(uid).update({
        'name': coachName(name),
        'bio': coachBio(bio) ?? FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout);

  /// Ukončit status trenéra (propojení a knihovnu smaže Cloud Function).
  Future<void> stopTrainer(Trainer t) async {
    final batch = _fs.batch()
      ..delete(_fs.collection('trainerCodes').doc(t.code))
      ..delete(_trainer(t.uid));
    await batch.commit().timeout(_timeout);
  }

  // ---------------------------------------------------------------------
  // Klienti
  // ---------------------------------------------------------------------

  Stream<List<Client>> watchClients() => _fs
      .collection('coachLinks')
      .where('trainerUid', isEqualTo: uid)
      .snapshots()
      .map((s) => [for (final d in s.docs) Client.fromMap(d.id, d.data())]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));

  /// Tréninky klienta, nejnovější první.
  Stream<List<CoachWorkout>> watchWorkouts(String clientUid, {int limit = 400}) =>
      _link(clientUid)
          .collection('workouts')
          .orderBy('startedAtMs', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => [
                for (final d in s.docs)
                  if (_tryWorkout(d.id, d.data()) case final w?) w,
              ]);

  static CoachWorkout? _tryWorkout(String id, Map<String, Object?> data) {
    try {
      return CoachWorkout.fromJson(id, data);
    } on CoachFormatException {
      return null;
    }
  }

  Stream<List<CoachWeightPoint>> watchWeight(String clientUid) => _link(clientUid)
      .collection('meta')
      .doc('weight')
      .snapshots()
      .map((s) => CoachWeightPoint.listFromJson(s.data()));

  Future<void> removeClient(String clientUid) =>
      _link(clientUid).delete().timeout(_timeout);

  // ---------------------------------------------------------------------
  // Plány klienta
  // ---------------------------------------------------------------------

  Stream<List<ClientPlan>> watchClientPlans(String clientUid) => _link(clientUid)
      .collection('plans')
      .snapshots()
      .map((s) {
        final list = <ClientPlan>[];
        for (final d in s.docs) {
          try {
            list.add(ClientPlan(
              assigned: AssignedPlan.fromJson(d.id, d.data()),
              updatedAt: _date(d.data()['updatedAt']),
            ));
          } on CoachFormatException {
            // poškozený plán přeskočit
          }
        }
        list.sort((a, b) => a.assigned.plan.name
            .toLowerCase()
            .compareTo(b.assigned.plan.name.toLowerCase()));
        return list;
      });

  /// Pošle klientovi plán. Se stejným [planId] přepíše předchozí verzi
  /// (aplikace ji podle čísla verze stáhne znovu).
  Future<void> assignPlan(
    String clientUid,
    CoachPlan plan, {
    required String trainerName,
    String? planId,
  }) async {
    final col = _link(clientUid).collection('plans');
    final ref = planId == null ? col.doc() : col.doc(planId);
    final prev = planId == null ? null : (await ref.get().timeout(_timeout)).data();
    final version = ((prev?['version'] as num?)?.toInt() ?? 0) + 1;
    await ref.set({
      'plan': plan.toJson(),
      'version': version,
      'trainerName': coachName(trainerName),
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);
  }

  Future<void> deleteClientPlan(String clientUid, String planId) => _link(clientUid)
      .collection('plans')
      .doc(planId)
      .delete()
      .timeout(_timeout);

  // ---------------------------------------------------------------------
  // Komentáře
  // ---------------------------------------------------------------------

  Stream<List<Note>> watchNotes(String clientUid) => _link(clientUid)
      .collection('notes')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => [for (final d in s.docs) Note.fromMap(d.id, d.data())]);

  Future<void> addNote(
    String clientUid, {
    required String workoutId,
    required String text,
    required String trainerName,
  }) async {
    final t = text.trim();
    if (t.isEmpty) return;
    await _link(clientUid).collection('notes').add({
      'workoutId': workoutId,
      'text': t.length > coachNoteMax ? t.substring(0, coachNoteMax) : t,
      'trainerName': coachName(trainerName),
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);
  }

  Future<void> deleteNote(String clientUid, String noteId) => _link(clientUid)
      .collection('notes')
      .doc(noteId)
      .delete()
      .timeout(_timeout);

  // ---------------------------------------------------------------------
  // Knihovna plánů
  // ---------------------------------------------------------------------

  Stream<List<LibraryPlan>> watchLibrary() => _library.snapshots().map((s) {
        final list = <LibraryPlan>[];
        for (final d in s.docs) {
          try {
            list.add(LibraryPlan(
              id: d.id,
              plan: CoachPlan.fromJson(d.data()['plan']),
              updatedAt: _date(d.data()['updatedAt']),
            ));
          } on CoachFormatException {
            // poškozený plán přeskočit
          }
        }
        list.sort((a, b) =>
            a.plan.name.toLowerCase().compareTo(b.plan.name.toLowerCase()));
        return list;
      });

  /// Uloží plán do knihovny (nový, když [id] je null). Vrací ID.
  Future<String> saveLibraryPlan(CoachPlan plan, {String? id}) async {
    final ref = id == null ? _library.doc() : _library.doc(id);
    await ref.set({
      'plan': plan.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);
    return ref.id;
  }

  Future<void> deleteLibraryPlan(String id) =>
      _library.doc(id).delete().timeout(_timeout);

  /// Sdílení odkazem gymbar.app/plan?id=… (stejně jako v aplikaci).
  Future<String> sharePlan(CoachPlan plan, {required String authorName}) async {
    final ref = _fs.collection('sharedPlans').doc();
    await ref.set({
      'plan': plan.toJson(),
      'authorUid': uid,
      'authorName': coachName(authorName),
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);
    return ref.id;
  }
}

String sharedPlanUrl(String id) => 'https://gymbar.app/plan?id=$id';
