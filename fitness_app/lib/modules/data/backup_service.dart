import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../data/database.dart';
import 'csv.dart' show csvDate;

/// Proč nešlo zálohu obnovit (texty viz data_profile_section.dart).
enum RestoreError {
  /// Soubor není databáze SQLite.
  notSqlite,

  /// Je to SQLite, ale ne záloha této aplikace.
  notBackup,

  /// Záloha pochází z novější verze aplikace.
  newerVersion,

  /// Jiná chyba při čtení nebo zápisu.
  failed,
}

class RestoreException implements Exception {
  RestoreException(this.error, [this.cause]);

  final RestoreError error;
  final Object? cause;

  @override
  String toString() => 'RestoreException($error, $cause)';
}

/// Co je v záloze (pro potvrzovací dialog).
typedef BackupInfo = ({int schemaVersion, int workouts});

/// Záloha celé databáze do jednoho souboru a obnovení ze zálohy.
///
/// Záloha: `VACUUM INTO` vytvoří konzistentní kopii i za běhu aplikace.
///
/// Obnovení: databáze aplikace se NEZAVÍRÁ ani nepřepisuje na disku. Soubor
/// zálohy se připojí (`ATTACH`) k otevřenému spojení a v jedné transakci se
/// obsah všech tabulek nahradí daty ze zálohy. Díky tomu nemusí nic
/// restartovat, streamy (profil, plány…) se hned obnoví a při chybě se
/// transakce vrátí a současná data zůstanou beze změny. Sloupce se berou
/// podle názvů, takže jde obnovit i záloha ze starší verze schématu
/// (chybějící sloupce dostanou výchozí hodnoty).
class BackupService {
  BackupService._();

  static const _alias = 'fitness_backup';

  /// „fitness_backup_2026-09-30.sqlite“.
  static String backupFileName(DateTime now) =>
      'fitness_backup_${csvDate(now)}.sqlite';

  /// Vytvoří soubor zálohy v dočasné složce. [fileName] umožní jiný název
  /// (automatická záloha do cloudu nesmí přepsat ruční zálohu).
  static Future<File> createBackup(AppDatabase db, {String? fileName}) async {
    final dir = await getTemporaryDirectory();
    final file =
        File('${dir.path}/${fileName ?? backupFileName(DateTime.now())}');
    if (await file.exists()) await file.delete();
    await db.customStatement('VACUUM INTO ?', [file.path]);
    return file;
  }

  /// Začíná obsah hlavičkou databáze SQLite 3?
  static bool looksLikeSqlite(Uint8List bytes) {
    const header = 'SQLite format 3';
    if (bytes.length < 100) return false;
    for (var i = 0; i < header.length; i++) {
      if (bytes[i] != header.codeUnitAt(i)) return false;
    }
    return bytes[header.length] == 0;
  }

  /// Uloží vybraný soubor do dočasné složky (výběr souboru může vrátit
  /// jen obsah bez cesty). Soubor po obnovení smaž přes [discard].
  static Future<File> prepare(Uint8List bytes) async {
    if (!looksLikeSqlite(bytes)) {
      throw RestoreException(RestoreError.notSqlite);
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/restore_${DateTime.now().millisecondsSinceEpoch}.sqlite',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Zkontroluje soubor zálohy, který už leží na disku (např. stažený
  /// z cloudu), a vrátí ho připravený pro [inspect] a [restore].
  /// Soubor po obnovení smaž přes [discard].
  static Future<File> prepareFile(File file) async {
    final Uint8List header;
    try {
      final raf = await file.open();
      try {
        header = await raf.read(100);
      } finally {
        await raf.close();
      }
    } catch (e) {
      throw RestoreException(RestoreError.failed, e);
    }
    if (!looksLikeSqlite(header)) {
      throw RestoreException(RestoreError.notSqlite);
    }
    return file;
  }

  /// Smaže dočasný soubor zálohy (i případné -wal / -shm).
  static Future<void> discard(File file) async {
    for (final path in [file.path, '${file.path}-wal', '${file.path}-shm']) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  /// Zkontroluje, že soubor je záloha této aplikace a není novější.
  static Future<BackupInfo> inspect(AppDatabase db, File file) =>
      _withAttached(db, file, () => _validate(db));

  /// Nahradí všechna data v aplikaci obsahem zálohy.
  static Future<void> restore(AppDatabase db, File file) async {
    await _withAttached(db, file, () async {
      await _validate(db);
      await _copyAll(db);
    });
    // Změny přes customStatement drift sám nehlásí – oznámíme je ručně,
    // aby se všechny obrazovky načetly znovu.
    db.markTablesUpdated(db.allTables);
  }

  static Future<T> _withAttached<T>(
    AppDatabase db,
    File file,
    Future<T> Function() body,
  ) async {
    var attached = false;
    try {
      await db.customStatement('ATTACH DATABASE ? AS $_alias', [file.path]);
      attached = true;
      return await body();
    } on RestoreException {
      rethrow;
    } catch (e) {
      throw RestoreException(RestoreError.failed, e);
    } finally {
      if (attached) {
        try {
          await db.customStatement('DETACH DATABASE $_alias');
        } catch (_) {}
      }
    }
  }

  static Future<BackupInfo> _validate(AppDatabase db) async {
    final Set<String> tables;
    try {
      tables = await _tables(db);
    } catch (e) {
      // Poškozený soubor nebo jiný formát.
      throw RestoreException(RestoreError.notSqlite, e);
    }
    final required = {
      db.userProfiles.actualTableName,
      db.exercises.actualTableName,
      db.workoutSessions.actualTableName,
      db.setEntries.actualTableName,
    };
    if (!tables.containsAll(required)) {
      throw RestoreException(RestoreError.notBackup);
    }
    final version = (await db
            .customSelect('PRAGMA $_alias.user_version')
            .getSingle())
        .read<int>('user_version');
    if (version > db.schemaVersion) {
      throw RestoreException(RestoreError.newerVersion);
    }
    final workouts = (await db
            .customSelect(
              'SELECT COUNT(*) AS c FROM $_alias."${db.workoutSessions.actualTableName}"',
            )
            .getSingle())
        .read<int>('c');
    return (schemaVersion: version, workouts: workouts);
  }

  static Future<Set<String>> _tables(AppDatabase db) async {
    final rows = await db
        .customSelect(
          "SELECT name FROM $_alias.sqlite_master WHERE type = 'table'",
        )
        .get();
    return {for (final r in rows) r.read<String>('name')};
  }

  static Future<List<String>> _columns(
    AppDatabase db,
    String schema,
    String table,
  ) async {
    final rows =
        await db.customSelect('PRAGMA $schema.table_info("$table")').get();
    return [for (final r in rows) r.read<String>('name')];
  }

  static Future<void> _copyAll(AppDatabase db) async {
    final backupTables = await _tables(db);
    final tables = db.allTables.toList();
    final exercisesName = db.exercises.actualTableName;

    await db.transaction(() async {
      // Cizí klíče se zkontrolují až při potvrzení transakce.
      await db.customStatement('PRAGMA defer_foreign_keys = ON');

      // Vestavěné cviky, které záloha ze starší verze ještě nemá,
      // si ponecháme (doplní se na konci).
      await db.customStatement('DROP TABLE IF EXISTS temp._restore_seed');
      await db.customStatement(
        'CREATE TEMP TABLE _restore_seed AS '
        'SELECT * FROM main."$exercisesName" WHERE slug IS NOT NULL',
      );

      // Mazání od závislých tabulek k nadřazeným.
      for (final t in tables.reversed) {
        await db.customStatement('DELETE FROM main."${t.actualTableName}"');
      }

      for (final t in tables) {
        final name = t.actualTableName;
        if (!backupTables.contains(name)) continue;
        final mainCols = await _columns(db, 'main', name);
        final bkCols = (await _columns(db, _alias, name)).toSet();
        final cols =
            mainCols.where(bkCols.contains).map((c) => '"$c"').join(', ');
        if (cols.isEmpty) continue;
        await db.customStatement(
          'INSERT INTO main."$name" ($cols) SELECT $cols FROM $_alias."$name"',
        );
      }

      // Profil musí existovat vždy (id 1, viz AppDatabase).
      await db.customStatement(
        'INSERT OR IGNORE INTO main."${db.userProfiles.actualTableName}" '
        '(id) VALUES (1)',
      );

      final exCols = [
        for (final c in await _columns(db, 'main', exercisesName))
          if (c != 'id') '"$c"',
      ].join(', ');
      await db.customStatement(
        'INSERT INTO main."$exercisesName" ($exCols) '
        'SELECT $exCols FROM temp._restore_seed s '
        'WHERE s.slug NOT IN (SELECT slug FROM main."$exercisesName" '
        'WHERE slug IS NOT NULL)',
      );
      await db.customStatement('DROP TABLE temp._restore_seed');
    });
  }
}
