import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../social_auth.dart';
import '../social_backend.dart';
import '../social_models.dart';
import '../social_service.dart' show socialUserProvider;
import 'gym_logic.dart';
import 'gym_models.dart';

/// Profil v žebříčku zadaný uživatelem (přezdívka, pohlaví, viditelnost
/// a rok narození). Rok narození se ukládá jen do lokálního profilu
/// (`UserProfiles.birthYear`); ven jde jen věková skupina.
typedef GymProfileInput = ({
  String nickname,
  GymGender gender,
  bool show,
  int? birthYear,
});

/// Věková skupina k zápisu (podle aktuálního roku).
GymAgeGroup? gymAgeGroupOf(int? birthYear) =>
    gymAgeGroupFor(birthYear, DateTime.now().year);

/// Práce s Firestore pro žebříček posilovny. Datový model: docs/social.md.
///
/// Jako [SocialService] předpokládá dostupné Firebase a přihlášení;
/// jinak vyhodí [StateError].
class GymService {
  GymService._();

  static final instance = GymService._();

  FirebaseFirestore get _fs => FirebaseFirestore.instance;

  String? get uid => SocialAuth.instance.currentUser?.uid;

  String get _me {
    final id = uid;
    if (id == null) throw StateError('Not signed in');
    return id;
  }

  static const _writeTimeout = Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> get _gyms =>
      _fs.collection('gyms');

  DocumentReference<Map<String, dynamic>> _gym(String gymId) =>
      _gyms.doc(gymId);

  DocumentReference<Map<String, dynamic>> _member(String gymId, String uid) =>
      _gym(gymId).collection('members').doc(uid);

  CollectionReference<Map<String, dynamic>> _entries(String gymId) =>
      _gym(gymId).collection('entries');

  DocumentReference<Map<String, dynamic>> _entry(
    String gymId,
    String uid,
    GymCategory category,
  ) =>
      _entries(gymId).doc(gymEntryId(uid, category));

  DocumentReference<Map<String, dynamic>> _code(String code) =>
      _fs.collection('gymCodes').doc(code);

  DocumentReference<Map<String, dynamic>> _membership(String uid) =>
      _fs.collection('users').doc(uid).collection('private').doc('gym');

  // -------------------------------------------------------------------
  // Členství
  // -------------------------------------------------------------------

  Stream<GymMembership?> watchMembership() {
    final me = uid;
    if (me == null) return Stream.value(null);
    return _membership(me).snapshots().map((s) {
      final data = s.data();
      return data == null ? null : GymMembership.fromMap(data);
    });
  }

  Future<GymMembership?> membership() async {
    final me = uid;
    if (me == null) return null;
    final data = (await _membership(me).get()).data();
    return data == null ? null : GymMembership.fromMap(data);
  }

  Map<String, Object?> _membershipData(String? gymId, GymProfileInput p) => {
        'gymId': gymId,
        'nickname': sanitizeGymNickname(p.nickname),
        'gender': p.gender.name,
        'show': p.show,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Map<String, Object?> _memberData(GymProfileInput p) {
    final group = gymAgeGroupOf(p.birthYear);
    return {
      'nickname': sanitizeGymNickname(p.nickname),
      'gender': p.gender.name,
      if (group != null) 'ageGroup': group.key,
      'joinedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Změna člena (přezdívka, pohlaví, věková skupina – bez skupiny se
  /// pole smaže).
  Map<String, Object?> _memberUpdate(GymProfileInput p) => {
        'nickname': sanitizeGymNickname(p.nickname),
        'gender': p.gender.name,
        'ageGroup': gymAgeGroupOf(p.birthYear)?.key ?? FieldValue.delete(),
      };

  // -------------------------------------------------------------------
  // Posilovny
  // -------------------------------------------------------------------

  Stream<Gym?> watchGym(String gymId) => _gym(gymId).snapshots().map((s) {
        final data = s.data();
        return data == null ? null : Gym.fromMap(s.id, data);
      });

  Future<Gym?> getGym(String gymId) async {
    final s = await _gym(gymId).get();
    final data = s.data();
    return data == null ? null : Gym.fromMap(s.id, data);
  }

  /// Posilovna podle kódu (z QR / odkazu).
  Future<Gym?> lookupCode(String code) async {
    final data = (await _code(code).get()).data();
    final gymId = readString(data?['gymId']);
    if (gymId == null) return null;
    return getGym(gymId);
  }

  /// Hledání podle začátku názvu nebo města (bez diakritiky). Prázdný
  /// dotaz vrátí posilovny s nejvíc členy.
  Future<List<Gym>> search(String query, {int limit = 20}) async {
    final q = normalizeGymSearch(query);
    if (q.isEmpty) {
      final snap = await _gyms
          .orderBy('memberCount', descending: true)
          .limit(limit)
          .get();
      return [for (final d in snap.docs) Gym.fromMap(d.id, d.data())];
    }
    Future<QuerySnapshot<Map<String, dynamic>>> prefix(String field) => _gyms
        .where(field, isGreaterThanOrEqualTo: q)
        .where(field, isLessThan: gymSearchUpperBound(q))
        .orderBy(field)
        .limit(limit)
        .get();
    final results = await Future.wait([prefix('nameLower'), prefix('cityLower')]);
    final byId = <String, Gym>{};
    for (final snap in results) {
      for (final d in snap.docs) {
        byId[d.id] = Gym.fromMap(d.id, d.data());
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) => b.memberCount.compareTo(a.memberCount));
    return list;
  }

  /// Založí posilovnu a rovnou do ní vstoupí (z jiné nejdřív odejde).
  /// Vrací ID posilovny.
  Future<String> createGym({
    required String name,
    required String city,
    String? address,
    required GymProfileInput profile,
  }) async {
    final me = _me;
    final current = await membership();
    if (current?.gymId != null) await leaveGym();

    final cleanName = clampText(name, gymNameMaxLength);
    final cleanCity = clampText(city, gymNameMaxLength);
    final cleanAddress =
        address == null ? '' : clampText(address, gymAddressMaxLength);
    for (var attempt = 0; attempt < 5; attempt++) {
      final ref = _gyms.doc();
      final code = generateGymCode();
      final batch = _fs.batch()
        ..set(ref, {
          'name': cleanName,
          'nameLower': normalizeGymSearch(cleanName),
          'city': cleanCity,
          'cityLower': normalizeGymSearch(cleanCity),
          if (cleanAddress.isNotEmpty) 'address': cleanAddress,
          'code': code,
          'createdBy': me,
          'createdAt': FieldValue.serverTimestamp(),
          'memberCount': 1,
        })
        ..set(_code(code), {'gymId': ref.id, 'name': cleanName, 'city': cleanCity})
        ..set(_member(ref.id, me), _memberData(profile))
        ..set(_membership(me), _membershipData(ref.id, profile));
      try {
        await batch.commit().timeout(_writeTimeout);
        return ref.id;
      } on FirebaseException catch (e) {
        // Kód už má jiná posilovna (pravidla nedovolí přepsat) → jiný kód.
        if (e.code != 'permission-denied') rethrow;
        debugPrint('Gym: create attempt failed ($e), trying another code.');
      }
    }
    throw StateError('Could not create a gym code');
  }

  /// Vstoupí do posilovny (z jiné nejdřív odejde – člověk je vždy jen
  /// v jedné).
  Future<void> joinGym(String gymId, GymProfileInput profile) async {
    final me = _me;
    final current = await membership();
    if (current?.gymId != null && current?.gymId != gymId) await leaveGym();

    final memberRef = _member(gymId, me);
    final alreadyMember = current?.gymId == gymId &&
        (await memberRef.get().timeout(_writeTimeout)).exists;
    final batch = _fs.batch()..set(_membership(me), _membershipData(gymId, profile));
    if (alreadyMember) {
      batch.update(memberRef, _memberUpdate(profile));
    } else {
      // Počet členů hlídají pravidla: +1 jen spolu se vznikem členství.
      batch
        ..set(memberRef, _memberData(profile))
        ..update(_gym(gymId), {'memberCount': FieldValue.increment(1)});
    }
    await batch.commit().timeout(_writeTimeout);
  }

  /// Odejde z posilovny a smaže svoje záznamy v žebříčku.
  Future<void> leaveGym() async {
    final me = _me;
    final current = await membership();
    final gymId = current?.gymId;
    if (gymId == null) return;
    final memberRef = _member(gymId, me);
    final isMember = (await memberRef.get()).exists;
    final batch = _fs.batch();
    if (isMember) {
      batch
        ..delete(memberRef)
        ..update(_gym(gymId), {'memberCount': FieldValue.increment(-1)});
    }
    for (final ref in await _myEntryRefs(gymId)) {
      batch.delete(ref);
    }
    batch.set(
      _membership(me),
      {'gymId': null, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    await batch.commit().timeout(_writeTimeout);
  }

  /// Změna přezdívky / pohlaví / věkové skupiny / viditelnosti. Záznamy
  /// v žebříčku přepíše volající přes GymPublisher (nebo je při skrytí smaže).
  Future<void> updateProfile(String gymId, GymProfileInput profile) async {
    final me = _me;
    final batch = _fs.batch()
      ..set(_membership(me), _membershipData(gymId, profile))
      ..update(_member(gymId, me), _memberUpdate(profile));
    await batch.commit().timeout(_writeTimeout);
    if (!profile.show) await deleteMyEntries(gymId);
  }

  // -------------------------------------------------------------------
  // Žebříček
  // -------------------------------------------------------------------

  /// Záznamy kategorie seřazené podle hodnoty (celkově nebo za měsíc).
  /// Filtr pohlaví, věku a skryté záznamy řeší aplikace.
  Stream<List<GymEntry>> watchBoard(
    String gymId,
    GymCategory category, {
    required bool monthly,
    required String month,
  }) {
    Query<Map<String, dynamic>> q =
        _entries(gymId).where('category', isEqualTo: category.key);
    q = monthly
        ? q
            .where('monthKey', isEqualTo: month)
            .orderBy('bestMonth', descending: true)
        : q.orderBy('best', descending: true);
    return q.limit(gymBoardLimit).snapshots().map((s) => [
          for (final d in s.docs)
            if (GymEntry.fromMap(d.id, d.data()) case final e?) e,
        ]);
  }

  /// Moje záznamy v posilovně podle kategorie (jeden dotaz podle uid;
  /// záznamy neznámých kategorií se vynechají).
  Future<Map<GymCategory, GymEntry>> myEntries(String gymId) async {
    final me = _me;
    final snap = await _entries(gymId)
        .where('uid', isEqualTo: me)
        .get()
        .timeout(_writeTimeout);
    return {
      for (final d in snap.docs)
        if (GymEntry.fromMap(d.id, d.data()) case final e?)
          if (d.id == gymEntryId(me, e.category)) e.category: e,
    };
  }

  /// Zapíše moje záznamy: mapa kategorie → pole (sloučí se), null = smazat.
  Future<void> writeMyEntries(
    String gymId,
    Map<GymCategory, Map<String, Object?>?> changes,
  ) async {
    if (changes.isEmpty) return;
    final me = _me;
    final batch = _fs.batch();
    for (final e in changes.entries) {
      final ref = _entry(gymId, me, e.key);
      final data = e.value;
      if (data == null) {
        batch.delete(ref);
      } else {
        batch.set(ref, data, SetOptions(merge: true));
      }
    }
    await quietWrite(batch.commit());
  }

  /// Smaže všechny moje záznamy v posilovně (i záznamy kategorií, které
  /// aplikace už nezná).
  Future<void> deleteMyEntries(String gymId) async {
    final refs = await _myEntryRefs(gymId);
    final batch = _fs.batch();
    for (final ref in refs) {
      batch.delete(ref);
    }
    await quietWrite(batch.commit());
  }

  /// Smaže moje záznamy kategorií, které už neexistují (zrušené
  /// kategorie z dřívějších verzí aplikace: `relStrength`, a po přechodu
  /// na slugy cviků `bench` → `bench_press`, `squat` → `back_squat`).
  /// Nové hodnoty pod novým klíčem zapíše GymPublisher hned potom.
  Future<void> deleteRetiredEntries(String gymId) async {
    final me = _me;
    final snap = await _entries(gymId)
        .where('uid', isEqualTo: me)
        .get()
        .timeout(_writeTimeout);
    final stale = [
      for (final d in snap.docs)
        if (gymCategoryFromKey(readString(d.data()['category'])) == null)
          d.reference,
    ];
    if (stale.isEmpty) return;
    final batch = _fs.batch();
    for (final ref in stale) {
      batch.delete(ref);
    }
    await quietWrite(batch.commit());
  }

  /// Odkazy na všechny moje záznamy: známé kategorie (i neexistující
  /// dokumenty – mazání je neškodné) + cokoli dalšího s mým uid.
  Future<Set<DocumentReference<Map<String, dynamic>>>> _myEntryRefs(
    String gymId,
  ) async {
    final me = _me;
    final refs = <DocumentReference<Map<String, dynamic>>>{
      for (final c in GymCategory.values) _entry(gymId, me, c),
    };
    try {
      final snap = await _entries(gymId)
          .where('uid', isEqualTo: me)
          .get()
          .timeout(_writeTimeout);
      refs.addAll(snap.docs.map((d) => d.reference));
    } catch (e) {
      debugPrint('Gym: listing my entries failed: $e');
    }
    return refs;
  }

  /// Věková skupina u člena (mění se s novým rokem / zadáním roku
  /// narození). Zapíše jen při změně.
  Future<void> syncMemberAgeGroup(String gymId, GymAgeGroup? group) async {
    final ref = _member(gymId, _me);
    final snap = await ref.get().timeout(_writeTimeout);
    final data = snap.data();
    if (data == null) return;
    if (readString(data['ageGroup']) == group?.key) return;
    await quietWrite(
      ref.update({'ageGroup': group?.key ?? FieldValue.delete()}),
    );
  }

  // -------------------------------------------------------------------
  // Nahlášení
  // -------------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> _report(
    String gymId,
    String entryId,
    String reporter,
  ) =>
      _entries(gymId).doc(entryId).collection('reports').doc(reporter);

  Future<bool> hasReported(String gymId, String entryId) async =>
      (await _report(gymId, entryId, _me).get()).exists;

  /// Nahlásí záznam (každý člen jen jednou; počítá Cloud Function).
  Future<void> report(String gymId, String entryId) => _report(gymId, entryId, _me)
      .set({'createdAt': FieldValue.serverTimestamp()}).timeout(_writeTimeout);
}

// ---------------------------------------------------------------------------
// Providery
// ---------------------------------------------------------------------------

/// Moje členství (null = nepřihlášen / Firebase chybí / bez dokumentu).
final gymMembershipProvider = StreamProvider<GymMembership?>((ref) {
  if (!ref.watch(socialAvailableProvider)) return Stream.value(null);
  final user = ref.watch(socialUserProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return GymService.instance.watchMembership();
});

final gymProvider = StreamProvider.autoDispose.family<Gym?, String>(
  (ref, gymId) => GymService.instance.watchGym(gymId),
);

typedef GymBoardKey = ({
  String gymId,
  GymCategory category,
  bool monthly,
  String month,
});

final gymBoardProvider =
    StreamProvider.autoDispose.family<List<GymEntry>, GymBoardKey>(
  (ref, k) => GymService.instance.watchBoard(
    k.gymId,
    k.category,
    monthly: k.monthly,
    month: k.month,
  ),
);
