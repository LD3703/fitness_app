// Firestore pro trenéra a klienta (docs/coach.md). Datový model:
//  trainers/{uid}                      trenér (jméno, popis, kód)
//  trainerCodes/{kód}                  kód → uid trenéra
//  coachLinks/{klient}                 propojení klient → trenér (souhlas)
//    workouts/{s<id>}                  tréninky klienta (CoachWorkout)
//    meta/weight                       tělesná váha (jen se souhlasem)
//    plans/{id}                        plány od trenéra (CoachPlan)
//    notes/{id}                        komentáře trenéra
//    sessions/{id}                     pozvánky na trénink (CoachSession)
//  sharedPlans/{id}                    plán sdílený odkazem
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

import '../social/social_auth.dart';
import '../social/social_backend.dart';
import '../social/social_models.dart' show readDate, readString;
import '../social/social_service.dart' show socialUserProvider;

/// Trenér (trainers/{uid}).
class TrainerProfile {
  const TrainerProfile({
    required this.uid,
    required this.name,
    required this.code,
    this.bio,
    this.clientCount = 0,
    this.zeroSince,
  });

  factory TrainerProfile.fromMap(String uid, Map<String, Object?> m) =>
      TrainerProfile(
        uid: uid,
        name: readString(m['name']) ?? '?',
        code: readString(m['code']) ?? '',
        bio: readString(m['bio']),
        clientCount: (m['clientCount'] as num?)?.toInt() ?? 0,
        zeroSince: readDate(m['zeroSince']),
      );

  final String uid;
  final String name;
  final String code;
  final String? bio;
  final int clientCount;

  /// Od kdy nemá žádného klienta (zapisuje Cloud Function).
  final DateTime? zeroSince;

  /// Kdy přijde o status (bez klientů), jinak null.
  DateTime? get expiresAt =>
      coachStatusExpiresAt(clientCount: clientCount, zeroSince: zeroSince);
}

/// Propojení klient → trenér (coachLinks/{klient}).
class CoachLink {
  const CoachLink({
    required this.clientUid,
    required this.trainerUid,
    required this.clientName,
    required this.trainerName,
    required this.shareWeight,
    this.createdAt,
  });

  factory CoachLink.fromMap(String clientUid, Map<String, Object?> m) =>
      CoachLink(
        clientUid: clientUid,
        trainerUid: readString(m['trainerUid']) ?? '',
        clientName: readString(m['clientName']) ?? '?',
        trainerName: readString(m['trainerName']) ?? '?',
        shareWeight: m['shareWeight'] == true,
        createdAt: readDate(m['createdAt']),
      );

  final String clientUid;
  final String trainerUid;
  final String clientName;
  final String trainerName;
  final bool shareWeight;
  final DateTime? createdAt;
}

/// Komentář trenéra k tréninku.
class CoachNote {
  const CoachNote({
    required this.id,
    required this.workoutId,
    required this.text,
    required this.trainerName,
    this.createdAt,
  });

  factory CoachNote.fromMap(String id, Map<String, Object?> m) => CoachNote(
        id: id,
        workoutId: readString(m['workoutId']) ?? '',
        text: readString(m['text']) ?? '',
        trainerName: readString(m['trainerName']) ?? '?',
        createdAt: readDate(m['createdAt']),
      );

  final String id;
  final String workoutId;
  final String text;
  final String trainerName;
  final DateTime? createdAt;
}

/// Plán sdílený odkazem.
typedef SharedPlan = ({CoachPlan plan, String authorName});

class CoachService {
  CoachService._();

  static final instance = CoachService._();

  FirebaseFirestore get _fs => FirebaseFirestore.instance;

  String? get uid => SocialAuth.instance.currentUser?.uid;

  String get _me {
    final id = uid;
    if (id == null) throw StateError('Not signed in');
    return id;
  }

  static const _timeout = Duration(seconds: 15);

  DocumentReference<Map<String, dynamic>> _trainer(String uid) =>
      _fs.collection('trainers').doc(uid);

  DocumentReference<Map<String, dynamic>> _code(String code) =>
      _fs.collection('trainerCodes').doc(code);

  DocumentReference<Map<String, dynamic>> _link(String clientUid) =>
      _fs.collection('coachLinks').doc(clientUid);

  // -------------------------------------------------------------------
  // Trenér
  // -------------------------------------------------------------------

  Stream<TrainerProfile?> watchTrainer(String uid) =>
      _trainer(uid).snapshots().map((s) {
        final d = s.data();
        return d == null ? null : TrainerProfile.fromMap(s.id, d);
      });

  /// Stát se trenérem: vlastní kód (trainerCodes) + profil trenéra.
  Future<TrainerProfile> becomeTrainer({
    required String name,
    String? bio,
  }) async {
    final me = _me;
    final cleanName = coachName(name);
    final cleanBio = coachBio(bio);
    final random = Random.secure();
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = generateCoachCode(random);
      final batch = _fs.batch()
        // Obsazený kód: create cizího dokumentu pravidla odmítnou.
        ..set(_code(code), {'uid': me})
        ..set(_trainer(me), {
          'name': cleanName,
          if (cleanBio != null) 'bio': cleanBio,
          'code': code,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      try {
        await batch.commit().timeout(_timeout);
        return TrainerProfile(uid: me, name: cleanName, code: code, bio: cleanBio);
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied' || attempt == 4) rethrow;
      }
    }
    throw StateError('No free trainer code');
  }

  Future<void> updateTrainer({required String name, String? bio}) async {
    final me = _me;
    await _trainer(me).update({
      'name': coachName(name),
      'bio': coachBio(bio) ?? FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);
  }

  /// Ukončit status trenéra. Propojení s klienty zruší Cloud Function
  /// onTrainerDeleted.
  Future<void> stopTrainer(TrainerProfile t) async {
    final batch = _fs.batch()
      ..delete(_code(t.code))
      ..delete(_trainer(t.uid));
    await batch.commit().timeout(_timeout);
  }

  Stream<List<CoachLink>> watchMyClients() => _fs
      .collection('coachLinks')
      .where('trainerUid', isEqualTo: _me)
      .snapshots()
      .map((s) => [
            for (final d in s.docs) CoachLink.fromMap(d.id, d.data()),
          ]..sort((a, b) =>
              a.clientName.toLowerCase().compareTo(b.clientName.toLowerCase())));

  /// Tréninky klienta (nejnovější první).
  Stream<List<CoachWorkout>> watchClientWorkouts(
    String clientUid, {
    int limit = 200,
  }) =>
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

  Future<void> removeClient(String clientUid) =>
      _link(clientUid).delete().timeout(_timeout);

  /// Pošle klientovi plán (nový, nebo novou verzi plánu [planId]).
  Future<void> assignPlan(
    String clientUid,
    CoachPlan plan, {
    required String trainerName,
    String? planId,
  }) async {
    final col = _link(clientUid).collection('plans');
    final ref = planId == null ? col.doc() : col.doc(planId);
    final prev = planId == null ? null : (await ref.get()).data();
    final version = ((prev?['version'] as num?)?.toInt() ?? 0) + 1;
    await ref.set({
      'plan': plan.toJson(),
      'version': version,
      'trainerName': coachName(trainerName),
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);
  }

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

  Stream<List<CoachNote>> watchNotes(String clientUid) => _link(clientUid)
      .collection('notes')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => [for (final d in s.docs) CoachNote.fromMap(d.id, d.data())]);

  // -------------------------------------------------------------------
  // Klient
  // -------------------------------------------------------------------

  /// Trenér podle kódu (null = neexistuje nebo už není trenér).
  Future<TrainerProfile?> lookupTrainer(String code) async {
    final c = await _code(code).get().timeout(_timeout);
    final trainerUid = readString(c.data()?['uid']);
    if (trainerUid == null) return null;
    final t = await _trainer(trainerUid).get().timeout(_timeout);
    final d = t.data();
    return d == null ? null : TrainerProfile.fromMap(t.id, d);
  }

  Stream<CoachLink?> watchMyLink() => _link(_me).snapshots().map((s) {
        final d = s.data();
        return d == null ? null : CoachLink.fromMap(s.id, d);
      });

  Future<CoachLink?> myLink() async {
    final me = uid;
    if (me == null) return null;
    final s = await _link(me).get().timeout(_timeout);
    final d = s.data();
    return d == null ? null : CoachLink.fromMap(s.id, d);
  }

  /// Propojí mě s trenérem. Dřívější propojení (jiný trenér) se nejdřív
  /// zruší – jeho tréninky a plány smaže Cloud Function.
  Future<void> connect(
    TrainerProfile trainer, {
    required String clientName,
    required bool shareWeight,
  }) async {
    final me = _me;
    if (trainer.uid == me) throw ArgumentError('Cannot be own trainer');
    final current = await myLink();
    if (current != null) await _link(me).delete().timeout(_timeout);
    await _link(me).set({
      'clientUid': me,
      'trainerUid': trainer.uid,
      'clientName': coachName(clientName),
      'trainerName': coachName(trainer.name),
      'shareWeight': shareWeight,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);
  }

  Future<void> setShareWeight(bool value) async {
    final me = _me;
    await _link(me).update({
      'shareWeight': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);
    if (!value) {
      await _link(me).collection('meta').doc('weight').delete().timeout(_timeout);
    }
  }

  Future<void> disconnect() => _link(_me).delete().timeout(_timeout);

  /// Nahraje tréninky (stejné ID = přepíše, takže opakování nevadí).
  Future<void> uploadWorkouts(List<CoachWorkout> workouts) async {
    if (workouts.isEmpty) return;
    final col = _link(_me).collection('workouts');
    for (var i = 0; i < workouts.length; i += 400) {
      final batch = _fs.batch();
      for (final w in workouts.skip(i).take(400)) {
        batch.set(col.doc(w.id), {
          ...w.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await quietWrite(batch.commit(), timeout: _timeout);
    }
  }

  Future<void> uploadWeights(List<CoachWeightPoint> points) async {
    await quietWrite(
      _link(_me).collection('meta').doc('weight').set({
        ...CoachWeightPoint.listToJson(points),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
      timeout: _timeout,
    );
  }

  Future<List<AssignedPlan>> myAssignedPlans() async {
    final s = await _link(_me).collection('plans').get().timeout(_timeout);
    return [
      for (final d in s.docs)
        if (_tryAssigned(d.id, d.data()) case final p?) p,
    ];
  }

  Stream<List<AssignedPlan>> watchMyAssignedPlans() =>
      _link(_me).collection('plans').snapshots().map((s) => [
            for (final d in s.docs)
              if (_tryAssigned(d.id, d.data()) case final p?) p,
          ]);

  static AssignedPlan? _tryAssigned(String id, Map<String, Object?> data) {
    try {
      return AssignedPlan.fromJson(id, data);
    } on CoachFormatException {
      return null;
    }
  }

  /// Plány, které jsem poslal klientovi [clientUid] (jsem trenér).
  Future<List<AssignedPlan>> clientPlans(String clientUid) async {
    final s = await _link(clientUid).collection('plans').get().timeout(_timeout);
    return [
      for (final d in s.docs)
        if (_tryAssigned(d.id, d.data()) case final p?) p,
    ];
  }

  /// Plán od trenéra už nechci (smaže se u trenéra i se nepřenese znovu).
  Future<void> dismissAssignedPlan(String planId) =>
      _link(_me).collection('plans').doc(planId).delete().timeout(_timeout);

  // -------------------------------------------------------------------
  // Pozvánky na trénink (coachLinks/{klient}/sessions)
  // -------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _sessions(String clientUid) =>
      _link(clientUid).collection('sessions');

  static List<CoachSession> _readSessions(
    QuerySnapshot<Map<String, dynamic>> s,
  ) {
    final list = <CoachSession>[];
    for (final d in s.docs) {
      try {
        list.add(CoachSession.fromJson(
          d.id,
          d.data(),
          updatedAtMs: readDate(d.data()['updatedAt'])?.millisecondsSinceEpoch,
        ));
      } on CoachFormatException {
        // poškozenou pozvánku přeskočit
      }
    }
    list.sort((a, b) => a.startAt.compareTo(b.startAt));
    return list;
  }

  /// Pozvánky od mého trenéra (jsem klient).
  Stream<List<CoachSession>> watchMySessions() =>
      _sessions(_me).snapshots().map(_readSessions);

  /// Přijmu / odmítnu pozvánku (i když jsem si to rozmyslel).
  Future<void> respondSession(String sessionId, {required bool accept}) =>
      _sessions(_me).doc(sessionId).update({
        'status': (accept
                ? CoachSessionStatus.accepted
                : CoachSessionStatus.declined)
            .name,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout);

  /// Pozvánky klienta [clientUid] (jsem jeho trenér).
  Stream<List<CoachSession>> watchClientSessions(String clientUid) =>
      _sessions(clientUid).snapshots().map(_readSessions);

  /// Pozvánky všech mých klientů: klient → pozvánky. Chyba u jednoho
  /// klienta (např. právě zrušené propojení) ostatní nezastaví.
  Stream<Map<String, List<CoachSession>>> watchSessionsOf(
    List<String> clientUids,
  ) {
    final latest = <String, List<CoachSession>>{};
    final subs = <StreamSubscription<List<CoachSession>>>[];
    late final StreamController<Map<String, List<CoachSession>>> c;
    c = StreamController(
      onListen: () {
        if (clientUids.isEmpty) c.add(const {});
        for (final uid in clientUids) {
          subs.add(watchClientSessions(uid).listen(
            (list) {
              latest[uid] = list;
              if (latest.length == clientUids.length) c.add(Map.of(latest));
            },
            onError: (Object e) {
              // Chyba (bez sítě, zrušené propojení) se předá dál – prázdný
              // seznam by kalendáři trenéra smazal události toho klienta.
              debugPrint('Coach: sessions of $uid failed: $e');
              c.addError(e);
            },
          ));
        }
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return c.stream;
  }

  /// Nová pozvánka, nebo úprava [id] – klient ji pak potvrzuje znovu.
  Future<void> saveSession(
    String clientUid,
    CoachSession session, {
    String? id,
  }) async {
    final data = session.toJson();
    if (id == null) {
      await _sessions(clientUid).add({
        ...data,
        'status': CoachSessionStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout);
      return;
    }
    await _sessions(clientUid).doc(id).update({
      ...data,
      if (!data.containsKey('note')) 'note': FieldValue.delete(),
      if (!data.containsKey('planId')) 'planId': FieldValue.delete(),
      'status': CoachSessionStatus.pending.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);
  }

  Future<void> cancelSession(String clientUid, String id) =>
      _sessions(clientUid).doc(id).update({
        'status': CoachSessionStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout);

  Future<void> deleteSession(String clientUid, String id) =>
      _sessions(clientUid).doc(id).delete().timeout(_timeout);

  // -------------------------------------------------------------------
  // Plán sdílený odkazem
  // -------------------------------------------------------------------

  /// Uloží plán a vrátí jeho ID pro odkaz gymbar.app/plan?id=…
  Future<String> sharePlan(CoachPlan plan, {required String authorName}) async {
    final ref = _fs.collection('sharedPlans').doc();
    await ref.set({
      'plan': plan.toJson(),
      'authorUid': _me,
      'authorName': coachName(authorName),
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);
    return ref.id;
  }

  Future<SharedPlan?> fetchSharedPlan(String id) async {
    final s = await _fs.collection('sharedPlans').doc(id).get().timeout(_timeout);
    final d = s.data();
    if (d == null) return null;
    try {
      return (
        plan: CoachPlan.fromJson(d['plan']),
        authorName: readString(d['authorName']) ?? '?',
      );
    } on CoachFormatException {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Providery
// ---------------------------------------------------------------------------

bool _signedIn(Ref ref) =>
    SocialBackend.available && ref.watch(socialUserProvider).valueOrNull != null;

/// Můj profil trenéra (null = nejsem trenér / nepřihlášen).
final myTrainerProvider = StreamProvider<TrainerProfile?>((ref) {
  if (!_signedIn(ref)) return Stream.value(null);
  final me = CoachService.instance.uid;
  return me == null ? Stream.value(null) : CoachService.instance.watchTrainer(me);
});

/// [coach:premium] – trenér má Premium zdarma, dokud má status (dokument
/// trainers/{uid} zmizí po 60 dnech bez klienta, docs/coach.md).
final coachPremiumGrantProvider = Provider<bool>(
  (ref) => ref.watch(myTrainerProvider).valueOrNull != null,
);

/// Moje propojení s trenérem (jako klient).
final myCoachLinkProvider = StreamProvider<CoachLink?>((ref) {
  if (!_signedIn(ref)) return Stream.value(null);
  return CoachService.instance.watchMyLink();
});

final myClientsProvider = StreamProvider.autoDispose<List<CoachLink>>((ref) {
  if (!_signedIn(ref)) return Stream.value(const []);
  return CoachService.instance.watchMyClients();
});

final clientWorkoutsProvider =
    StreamProvider.autoDispose.family<List<CoachWorkout>, String>(
  (ref, clientUid) => CoachService.instance.watchClientWorkouts(clientUid),
);

final coachNotesProvider =
    StreamProvider.autoDispose.family<List<CoachNote>, String>(
  (ref, clientUid) => CoachService.instance.watchNotes(clientUid),
);

final myAssignedPlansProvider =
    StreamProvider.autoDispose<List<AssignedPlan>>((ref) {
  if (!_signedIn(ref)) return Stream.value(const []);
  return CoachService.instance.watchMyAssignedPlans();
});

/// Pozvánky na trénink od mého trenéra (jsem klient).
final mySessionsProvider = StreamProvider<List<CoachSession>>((ref) {
  if (!_signedIn(ref) || ref.watch(myCoachLinkProvider).valueOrNull == null) {
    return Stream.value(const []);
  }
  return CoachService.instance.watchMySessions();
});

final clientSessionsProvider =
    StreamProvider.autoDispose.family<List<CoachSession>, String>(
  (ref, clientUid) => CoachService.instance.watchClientSessions(clientUid),
);

/// Pozvánky všech mých klientů (jsem trenér): klient → pozvánky.
final trainerSessionsProvider =
    StreamProvider<Map<String, List<CoachSession>>>((ref) {
  if (!_signedIn(ref) || ref.watch(myTrainerProvider).valueOrNull == null) {
    return Stream.value(const {});
  }
  final clients = ref.watch(myClientsProvider).valueOrNull;
  if (clients == null) return const Stream.empty();
  return CoachService.instance
      .watchSessionsOf([for (final c in clients) c.clientUid]);
});
