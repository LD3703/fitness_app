// Obnovení zálohy a Premium: předplatné zůstává podle telefonu, slib
// prvního uživatele se ze zálohy převezme, když ho telefon nemá
// (BackupService.restore, premiumEarlyAfterRestore).
import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fitness_app/data/database.dart';
import 'package:fitness_app/modules/data/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('gymbar_backup'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// Záloha z telefonu s daným profilem.
  Future<File> backupWith(UserProfilesCompanion profile) async {
    final old = AppDatabase(NativeDatabase.memory());
    await old.updateProfile(profile);
    final file = File('${dir.path}/backup.sqlite');
    await old.customStatement('VACUUM INTO ?', [file.path]);
    await old.close();
    return file;
  }

  // Data v databázi jsou v sekundách – porovnává se bez milisekund.
  final early = DateTime(2026, 10, 3, 12);

  test('nový telefon bez účtu převezme slib prvního uživatele ze zálohy',
      () async {
    final file = await backupWith(UserProfilesCompanion(
      premiumEarlyAt: Value(early),
      isPremium: const Value(true),
    ));
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await BackupService.restore(db, file);

    final profile = await db.watchProfile().first;
    expect(profile.premiumEarlyAt, early);
    // Stav předplatného ze zálohy se nepřebírá.
    expect(profile.isPremium, isFalse);
  });

  test('slib z telefonu má přednost a podvržené datum se nepřevezme', () async {
    final file = await backupWith(UserProfilesCompanion(
      premiumEarlyAt: Value(DateTime.now().add(const Duration(days: 400))),
    ));
    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);
    await BackupService.restore(fresh, file);
    expect((await fresh.watchProfile().first).premiumEarlyAt, isNull);

    final mine = AppDatabase(NativeDatabase.memory());
    addTearDown(mine.close);
    await mine
        .updateProfile(UserProfilesCompanion(premiumEarlyAt: Value(early)));
    await BackupService.restore(mine, file);
    expect((await mine.watchProfile().first).premiumEarlyAt, early);
  });
}
