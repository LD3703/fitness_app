import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/text_filter.dart';
import '../social_auth.dart';
import '../social_backend.dart';
import '../social_models.dart';
import '../social_service.dart' show socialUserProvider;
import 'geohash.dart';
import 'gym_logic.dart';
import 'gym_models.dart';
import 'strength_rank.dart';

/// Profil v žebříčku zadaný uživatelem (přezdívka, pohlaví, viditelnost,
/// souhlas s vytištěným žebříčkem a rok narození). Rok narození se ukládá jen do lokálního profilu
/// (`UserProfiles.birthYear`); ven jde jen věková skupina.
typedef GymProfileInput = ({
  String nickname,
  GymGender gender,
  bool show,
  bool printable,
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
        'printable': p.printable,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Člen posilovny. `uid` (= ID dokumentu) slouží úklidu po smazání účtu
  /// (Cloud Function hledá členství podle uid – collectionGroup 'members').
  Map<String, Object?> _memberData(String uid, GymProfileInput p) {
    final group = gymAgeGroupOf(p.birthYear);
    return {
      'uid': uid,
      'nickname': sanitizeGymNickname(p.nickname),
      'gender': p.gender.name,
      if (group != null) 'ageGroup': group.key,
      'joinedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Změna člena (přezdívka, pohlaví, věková skupina – bez skupiny se
  /// pole smaže). `uid` doplní i členům z dřívějších verzí.
  Map<String, Object?> _memberUpdate(String uid, GymProfileInput p) => {
        'uid': uid,
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

  /// Hledání podle začátku názvu nebo města (bez diakritiky), i „název
  /// město“ a „město název“. Prázdný dotaz vrátí posilovny s nejvíc členy.
  /// S polohou [near] se výsledky řadí podle vzdálenosti.
  Future<List<GymWithDistance>> search(
    String query, {
    ({double lat, double lng})? near,
    int limit = 30,
  }) async {
    final q = normalizeGymSearch(query);
    final byId = <String, Gym>{};
    if (q.isEmpty) {
      // S rezervou – skryté posilovny se odfiltrují až v aplikaci.
      final snap = await _gyms
          .orderBy('memberCount', descending: true)
          .limit(limit * 2)
          .get();
      for (final d in snap.docs) {
        byId[d.id] = Gym.fromMap(d.id, d.data());
      }
    } else {
      Future<QuerySnapshot<Map<String, dynamic>>> prefix(String field) => _gyms
          .where(field, isGreaterThanOrEqualTo: q)
          .where(field, isLessThan: gymSearchUpperBound(q))
          .orderBy(field)
          .limit(limit)
          .get();
      // nameCity / cityName mají posilovny z importu a nově založené;
      // nameLower / cityLower i ty starší.
      final results = await Future.wait([
        prefix('nameCity'),
        prefix('cityName'),
        prefix('nameLower'),
        prefix('cityLower'),
      ]);
      for (final snap in results) {
        for (final d in snap.docs) {
          byId[d.id] = Gym.fromMap(d.id, d.data());
        }
      }
    }
    final list = withDistance(byId.values.where((g) => g.isListed), near);
    if (near == null) {
      list.sort((a, b) => b.gym.memberCount.compareTo(a.gym.memberCount));
    }
    return list.take(limit).toList();
  }

  /// Posilovny v okolí bodu, nejbližší první: nejdřív do
  /// [gymNearbyRadiusKm], a když je jich tam málo, do [gymWideRadiusKm].
  Future<List<GymWithDistance>> nearby(
    double lat,
    double lng, {
    int limit = 30,
    double? radiusKm,
  }) async {
    Future<List<GymWithDistance>> within(String field, int precision, double km, int perQuery) async {
      final cells = geohashCellsCovering(lat, lng, km, precision);
      final snaps = await Future.wait([
        for (final part in chunked(cells))
          _gyms.where(field, whereIn: part).limit(perQuery).get(),
      ]);
      final gyms = <String, Gym>{
        for (final s in snaps)
          for (final d in s.docs) d.id: Gym.fromMap(d.id, d.data()),
      };
      return [
        for (final g in withDistance(gyms.values.where((g) => g.isListed), (lat: lat, lng: lng)))
          if (g.km != null && g.km! <= km) g,
      ];
    }

    if (radiusKm != null) {
      final precision = radiusKm <= gymNearbyRadiusKm ? 6 : 5;
      return (await within('g$precision', precision, radiusKm, 150)).take(limit).toList();
    }
    var found = await within('g6', 6, gymNearbyRadiusKm, 150);
    if (found.length < gymNearbyMinResults) {
      found = await within('g5', 5, gymWideRadiusKm, 100);
    }
    return found.take(limit).toList();
  }

  /// Posilovny, které by mohly být tou zakládanou: do
  /// [gymDuplicateRadiusKm] od mé polohy, nebo podobný název ve stejném
  /// městě.
  Future<List<GymWithDistance>> possibleDuplicates({
    required String name,
    required String city,
    ({double lat, double lng})? near,
  }) async {
    final byId = <String, GymWithDistance>{};
    if (near != null) {
      for (final g in await nearby(near.lat, near.lng, radiusKm: gymDuplicateRadiusKm)) {
        byId[g.gym.id] = g;
      }
    }
    final cityKey = normalizeGymSearch(city);
    final firstWord = normalizeGymSearch(name).split(' ').first;
    if (firstWord.isNotEmpty) {
      for (final g in await search(firstWord, near: near, limit: 40)) {
        final sameCity = cityKey.isNotEmpty && normalizeGymSearch(g.gym.city) == cityKey;
        final close = g.km != null && g.km! <= 1;
        if (sameCity || close) byId.putIfAbsent(g.gym.id, () => g);
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) => (a.km ?? double.infinity).compareTo(b.km ?? double.infinity));
    return list.take(8).toList();
  }

  /// Vzdálenost od [near] (bez polohy null); s polohou seřazené od nejbližší,
  /// posilovny bez polohy na konci.
  static List<GymWithDistance> withDistance(
    Iterable<Gym> gyms,
    ({double lat, double lng})? near,
  ) {
    final list = [
      for (final g in gyms)
        (
          gym: g,
          km: near == null || !g.hasLocation
              ? null
              : haversineKm(near.lat, near.lng, g.lat!, g.lng!),
        ),
    ];
    if (near != null) {
      list.sort((a, b) => (a.km ?? double.infinity).compareTo(b.km ?? double.infinity));
    }
    return list;
  }

  /// Založí posilovnu a rovnou do ní vstoupí (z jiné nejdřív odejde).
  /// Vrací ID posilovny.
  Future<String> createGym({
    required String name,
    required String city,
    String? address,
    ({double lat, double lng})? location,
    required GymProfileInput profile,
  }) async {
    final me = _me;
    final current = await membership();
    if (current?.gymId != null) await leaveGym();

    final cleanName = clampText(name, gymNameMaxLength);
    final cleanCity = clampText(city, gymNameMaxLength);
    final cleanAddress =
        address == null ? '' : clampText(address, gymAddressMaxLength);
    // Formulář hrubá slova odmítne už při psaní; tohle je pojistka.
    if ([cleanName, cleanCity, cleanAddress].any(containsSevereProfanity)) {
      throw ArgumentError('Gym name contains a blocked word');
    }
    for (var attempt = 0; attempt < 5; attempt++) {
      final ref = _gyms.doc();
      final code = generateGymCode();
      final batch = _fs.batch()
        ..set(ref, {
          'name': cleanName,
          'nameLower': normalizeGymSearch(cleanName),
          'city': cleanCity,
          'cityLower': normalizeGymSearch(cleanCity),
          'nameCity': gymSearchKeys(cleanName, cleanCity).nameCity,
          'cityName': gymSearchKeys(cleanName, cleanCity).cityName,
          if (cleanAddress.isNotEmpty) 'address': cleanAddress,
          if (location != null) ...gymGeoFields(location.lat, location.lng),
          'code': code,
          'createdBy': me,
          'createdAt': FieldValue.serverTimestamp(),
          'memberCount': 1,
        })
        ..set(_code(code), {'gymId': ref.id, 'name': cleanName, 'city': cleanCity})
        ..set(_member(ref.id, me), _memberData(me, profile))
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

  /// Anonymní rozložení vah pro srovnání „Jak si vedu“ (liftStats,
  /// docs/social.md). Čte se bez přihlášení; chybějící dokument = žádné
  /// skupiny.
  Future<Map<String, LiftDistribution>> liftStats(String docId) async {
    final snap = await _fs
        .collection('liftStats')
        .doc(docId)
        .get()
        .timeout(_writeTimeout);
    return parseLiftStatsGroups(snap.data());
  }

  /// „Doporuč GymBar svému fitku“: zaznamená, že člen poslal majiteli
  /// odkaz (gymReferrals, docs/fitka.md). Odměna zatím není.
  Future<void> recordReferral(String gymId) async {
    final me = _me;
    final ref = _fs.collection('gymReferrals').doc(gymReferralDocId(gymId, me));
    await _fs.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        tx.update(ref, {
          'count': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.set(ref, {
          'gymId': gymId,
          'uid': me,
          'count': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }).timeout(_writeTimeout);
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
      batch.update(memberRef, _memberUpdate(me, profile));
    } else {
      // Počet členů hlídají pravidla: +1 jen spolu se vznikem členství.
      batch
        ..set(memberRef, _memberData(me, profile))
        ..update(_gym(gymId), {'memberCount': FieldValue.increment(1)});
    }
    await batch.commit().timeout(_writeTimeout);
  }

  /// Zakladatel opraví název, město a adresu (kód a QR zůstávají). Kopie
  /// názvu u kódu (náhled před připojením) se mění ve stejné dávce.
  Future<void> updateGymInfo(
    Gym gym, {
    required String name,
    required String city,
    String? address,
  }) async {
    final cleanName = clampText(name, gymNameMaxLength);
    final cleanCity = clampText(city, gymNameMaxLength);
    final cleanAddress =
        address == null ? '' : clampText(address, gymAddressMaxLength);
    if ([cleanName, cleanCity, cleanAddress].any(containsSevereProfanity)) {
      throw ArgumentError('Gym name contains a blocked word');
    }
    final keys = gymSearchKeys(cleanName, cleanCity);
    final batch = _fs.batch()
      ..update(_gym(gym.id), {
        'name': cleanName,
        'nameLower': normalizeGymSearch(cleanName),
        'city': cleanCity,
        'cityLower': normalizeGymSearch(cleanCity),
        'nameCity': keys.nameCity,
        'cityName': keys.cityName,
        'address': cleanAddress.isEmpty ? FieldValue.delete() : cleanAddress,
      });
    if (gym.code.isNotEmpty) {
      batch.update(_code(gym.code), {'name': cleanName, 'city': cleanCity});
    }
    await batch.commit().timeout(_writeTimeout);
  }

  /// Zakladatel smaže prázdnou posilovnu: nejdřív z ní odejde (i se svými
  /// záznamy), pak smaže posilovnu i kód. Zbytek (nahlášení, stav
  /// moderace, doporučení) uklidí Cloud Function onGymDeleted.
  Future<void> deleteGym(Gym gym) async {
    if (!gym.canDelete(_me)) throw StateError('Gym has other members');
    if ((await membership())?.gymId == gym.id) await leaveGym();
    final batch = _fs.batch()..delete(_gym(gym.id));
    if (gym.code.isNotEmpty) batch.delete(_code(gym.code));
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
    // Moje nahlášení cizích záznamů smaže Cloud Function onGymMemberDeleted
    // (aplikace skryté záznamy nevidí a celý žebříček kvůli tomu nečte).
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
      ..update(_member(gymId, me), _memberUpdate(me, profile));
    await batch.commit().timeout(_writeTimeout);
    if (!profile.show) await deleteMyEntries(gymId);
  }

  // -------------------------------------------------------------------
  // Žebříček
  // -------------------------------------------------------------------

  Query<Map<String, dynamic>> _boardQuery(
    String gymId,
    GymCategory category, {
    required bool monthly,
    required String month,
  }) {
    // Skryté záznamy pravidla ostatním nevydají – dotaz je musí vyloučit.
    final q = _entries(gymId)
        .where('category', isEqualTo: category.key)
        .where('hidden', isEqualTo: false);
    return (monthly
            ? q
                .where('monthKey', isEqualTo: month)
                .orderBy('bestMonth', descending: true)
            : q.orderBy('best', descending: true))
        .limit(gymBoardLimit);
  }

  static List<GymEntry> _boardEntries(QuerySnapshot<Map<String, dynamic>> s) => [
        for (final d in s.docs)
          if (GymEntry.fromMap(d.id, d.data()) case final e?) e,
      ];

  /// Záznamy kategorie seřazené podle hodnoty (celkově nebo za měsíc),
  /// bez skrytých. Filtr pohlaví a věku řeší aplikace.
  Stream<List<GymEntry>> watchBoard(
    String gymId,
    GymCategory category, {
    required bool monthly,
    required String month,
  }) =>
      _boardQuery(gymId, category, monthly: monthly, month: month)
          .snapshots()
          .map(_boardEntries);

  /// Jednorázově (vytištěný žebříček, gym_print.dart).
  Future<List<GymEntry>> boardOnce(
    String gymId,
    GymCategory category, {
    required bool monthly,
    required String month,
  }) async =>
      _boardEntries(
        await _boardQuery(gymId, category, monthly: monthly, month: month)
            .get()
            .timeout(_writeTimeout),
      );

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
  /// narození) a pole `uid` u členů z dřívějších verzí. Zapíše jen při
  /// změně.
  Future<void> syncMemberAgeGroup(String gymId, GymAgeGroup? group) async {
    final me = _me;
    final ref = _member(gymId, me);
    final snap = await ref.get().timeout(_writeTimeout);
    final data = snap.data();
    if (data == null) return;
    final sameGroup = readString(data['ageGroup']) == group?.key;
    if (sameGroup && data['uid'] == me) return;
    await quietWrite(
      ref.update({
        if (!sameGroup) 'ageGroup': group?.key ?? FieldValue.delete(),
        'uid': me,
      }),
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

  /// Smím nahlašovat? Vrátí ID mého záznamu (pro pole myEntry), nebo
  /// důvod, proč ještě ne (pravidla: člen aspoň 7 dní s vlastním záznamem).
  Future<({String? myEntry, GymReportBlock? block})> reportEligibility(
    String gymId,
  ) async {
    final me = _me;
    final member = await _member(gymId, me).get().timeout(_writeTimeout);
    final joinedAt = member.data()?['joinedAt'];
    final mine = await _entries(gymId)
        .where('uid', isEqualTo: me)
        .limit(1)
        .get()
        .timeout(_writeTimeout);
    final myEntry = mine.docs.isEmpty ? null : mine.docs.first.id;
    final block = gymReportBlock(
      joinedAt: joinedAt is Timestamp ? joinedAt.toDate() : null,
      hasOwnEntry: myEntry != null,
      now: DateTime.now(),
    );
    return (myEntry: block == null ? myEntry : null, block: block);
  }

  /// Nahlásí záznam (každý člen jen jednou; počítá Cloud Function).
  /// [myEntry] = ID mého záznamu v téže posilovně (reportEligibility).
  Future<void> report(String gymId, String entryId, String myEntry) =>
      _report(gymId, entryId, _me).set({
        'createdAt': FieldValue.serverTimestamp(),
        'myEntry': myEntry,
      }).timeout(_writeTimeout);
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

/// Rozložení vah pro srovnání „Jak si vedu“ podle ID dokumentu liftStats.
final liftStatsProvider = FutureProvider.autoDispose
    .family<Map<String, LiftDistribution>, String>(
  (ref, docId) => GymService.instance.liftStats(docId),
);
