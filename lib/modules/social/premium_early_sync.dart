// Dárek Premium pro první uživatele i na účtu (lib/premium/premium_gift.dart).
// Po přihlášení se slib „první uživatel“ uloží do users/{uid}/private/premium
// a na novém telefonu (nebo po přeinstalování) se odtud vrátí do profilu.
// Zapsat ho pravidla dovolí jen před spuštěním Premium (dokud ve Firestore
// není config/premium) – pak už nový účet slib nezíská. Logika rozhodnutí
// je v premiumEarlySync (premium_rules.dart, testy test/premium_test.dart).
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../premium/premium.dart';
import '../../providers.dart';
import 'social_backend.dart';
import 'social_service.dart' show socialUserProvider;

/// Běží po celou dobu ([social:app]): po přihlášení a při změně slibu
/// v telefonu porovná telefon s účtem.
final premiumEarlySyncProvider = Provider<void>((ref) {
  if (!ref.watch(socialAvailableProvider)) return;
  final uid = ref.watch(socialUserProvider.select((u) => u.valueOrNull?.uid));
  if (uid == null) return;
  final profile = ref.watch(profileProvider.select(
    (p) => p.hasValue ? (loaded: true, earlyAt: p.value?.premiumEarlyAt) : null,
  ));
  if (profile == null) return;
  unawaited(_sync(ref.read(databaseProvider), uid, profile.earlyAt));
});

Future<void> _sync(AppDatabase db, String uid, DateTime? local) async {
  try {
    final doc = FirebaseFirestore.instance.doc('users/$uid/private/premium');
    final snap = await doc.get();
    final at = snap.data()?['earlyAt'];
    final server = at is Timestamp ? at.toDate() : null;
    switch (premiumEarlySync(local: local, server: server)) {
      case PremiumEarlySync.pull:
        await db.updateProfile(UserProfilesCompanion(premiumEarlyAt: Value(server)));
      case PremiumEarlySync.push:
        // Po spuštění Premium pravidla zápis odmítnou – slib zůstane jen
        // v telefonu, kde vznikl.
        await doc.set({'earlyAt': FieldValue.serverTimestamp()});
      case PremiumEarlySync.none:
        break;
    }
  } catch (e) {
    debugPrint('Premium early-user sync failed: $e');
  }
}
