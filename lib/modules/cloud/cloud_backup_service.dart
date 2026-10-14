import 'dart:async';
import 'dart:convert' show Converter;
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/database.dart';
import '../../services/calendar_service.dart';
import '../../services/notification_service.dart';
import '../data/backup_service.dart';
import '../social/social_backend.dart';
import 'cloud_logic.dart';
import 'cloud_queries.dart';
import 'cloud_settings.dart';

/// Záloha v cloudu (pro seznam při obnovení).
class CloudBackupEntry {
  const CloudBackupEntry({
    required this.slot,
    required this.meta,
    this.sizeBytes,
  });

  final CloudSlot slot;
  final CloudBackupMeta meta;
  final int? sizeBytes;
}

enum CloudBackupResult {
  done,

  /// Automatická záloha: data v telefonu vypadají menší než záloha
  /// v cloudu – nepřepisuje se (viz [cloudOverwriteDecision]).
  skippedSmaller,

  /// Ruční záloha: data v telefonu vypadají menší než záloha v cloudu –
  /// přepíše se až po potvrzení (`backupNow(db, confirmed: true)`).
  needsConfirmation,

  /// Automatická záloha čekala ve frontě a mezitím ji uživatel vypnul
  /// (nebo smazal zálohy).
  disabled,

  notSignedIn,
  failed,
}

/// Automatická záloha databáze do Firebase Cloud Storage a obnovení.
///
/// Soubory: users/{uid}/backups/latest.sqlite a previous.sqlite (obsah je
/// databáze SQLite zkomprimovaná gzipem, typ application/gzip; metadata
/// viz [CloudBackupMeta]). Klient Storage neumí kopírovat na serveru,
/// proto se dosavadní latest před nahráním nové zálohy stáhne a nahraje
/// jako previous.
///
/// Automatická záloha nikdy neblokuje UI (háčky ji jen spustí) a chyby
/// nehlásí – jen uloží stav „poslední záloha selhala“ do nastavení.
class CloudBackupService {
  CloudBackupService._();

  static final instance = CloudBackupService._();

  Future<CloudBackupResult>? _running;
  String? _deviceName;

  /// Operace se soubory v cloudu (záloha, smazání) běží jedna po druhé –
  /// smazání tak nikdy nepoběží souběžně s nahráváním, které by zálohu
  /// hned zase vytvořilo.
  Future<void> _tail = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Firebase běží a projekt má Cloud Storage (výchozí bucket).
  bool get configured {
    if (!SocialBackend.available) return false;
    try {
      final bucket = Firebase.app().options.storageBucket;
      return bucket != null && bucket.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Přihlášený uživatel (Google / Apple přes modul social).
  String? get currentUid =>
      SocialBackend.available ? FirebaseAuth.instance.currentUser?.uid : null;

  bool get busy => _running != null;

  Reference _ref(String uid, CloudSlot slot) =>
      FirebaseStorage.instance.ref(cloudBackupPath(uid, slot));

  /// Spustí zálohu, pokud je zapnutá a na řadě. Nikdy nevyhazuje chybu.
  Future<void> autoBackup(AppDatabase db, CloudBackupTrigger trigger) async {
    // Premium (cloudBackup) hlídají volající háčky v cloud_module.dart.
    try {
      if (!configured || currentUid == null) return;
      final settings = await CloudSettingsStore.instance.load();
      if (!cloudBackupDue(settings, DateTime.now(), trigger)) return;
      if (settings.wifiOnly && !await _onWifi()) return;
      await backupNow(db, automatic: true);
    } catch (e) {
      debugPrint('Cloud: auto backup failed: $e');
    }
  }

  /// Záloha hned (běží nejvýš jedna najednou; souběžné volání dostane
  /// výsledek té běžící). [automatic] = háčky: menší data než v cloudu se
  /// nenahrají nikdy. Ruční záloha s menšími daty vrátí
  /// [CloudBackupResult.needsConfirmation]; po souhlasu uživatele se volá
  /// znovu s [confirmed] – ta počká na případnou běžící zálohu a spustí se.
  Future<CloudBackupResult> backupNow(
    AppDatabase db, {
    bool automatic = false,
    bool confirmed = false,
  }) {
    final running = _running;
    if (running != null && !confirmed) return running;
    late final Future<CloudBackupResult> run;
    run = _serial(
      () => _backup(db, automatic: automatic, confirmed: confirmed),
    ).whenComplete(() {
      if (identical(_running, run)) _running = null;
    });
    _running = run;
    return run;
  }

  Future<bool> _onWifi() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
    } catch (e) {
      debugPrint('Cloud: connectivity check failed: $e');
      return false;
    }
  }

  static CloudBackupMeta? _meta(FullMetadata? m) => m == null
      ? null
      : CloudBackupMeta.fromCustomMetadata(
          m.customMetadata,
          fallbackCreatedAt: m.timeCreated,
        );

  Future<FullMetadata?> _metadata(Reference ref) async {
    try {
      return await ref.getMetadata();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return null;
      rethrow;
    }
  }

  Future<CloudBackupResult> _backup(
    AppDatabase db, {
    required bool automatic,
    required bool confirmed,
  }) async {
    final uid = currentUid;
    if (uid == null || !configured) return CloudBackupResult.notSignedIn;
    final store = CloudSettingsStore.instance;
    // Automatická záloha mohla čekat ve frontě (_serial) – mezitím ji
    // uživatel mohl vypnout nebo zálohy smazat.
    if (automatic && !(await store.load()).enabled) {
      return CloudBackupResult.disabled;
    }
    final started = DateTime.now();
    final stamp = started.millisecondsSinceEpoch;
    File? raw;
    File? gz;
    File? rotated;
    try {
      final tmp = await getTemporaryDirectory();
      gz = File('${tmp.path}/cloud_upload_$stamp.sqlite.gz');
      rotated = File('${tmp.path}/cloud_rotate_$stamp.sqlite.gz');
      final workouts = await db.cloudWorkoutCount();
      final latestRef = _ref(uid, CloudSlot.latest);
      final current = await _metadata(latestRef);
      final currentMeta = _meta(current);

      raw = await BackupService.createBackup(
        db,
        fileName: 'cloud_backup_$stamp.sqlite',
      );
      await gzipFile(raw, gz);
      final gzBytes = await gz.length();
      if (gzBytes >= kCloudMaxBackupBytes) {
        throw StateError('Backup is too large for the cloud.');
      }

      if (current != null) {
        // Menší data než v cloudu (nový / vymazaný telefon) nesmí
        // automaticky přepsat jedinou dobrou kopii.
        final currentGzip = cloudIsGzipContentType(current.contentType);
        final decision = cloudOverwriteDecision(
          automatic: automatic,
          confirmed: confirmed,
          localWorkouts: workouts,
          // Velikost ve stejném formátu, v jakém je záloha v cloudu.
          localBytes: currentGzip ? gzBytes : await raw.length(),
          cloudWorkouts: currentMeta?.workouts ?? 0,
          cloudBytes: current.size,
        );
        if (decision == CloudOverwriteDecision.confirm) {
          return CloudBackupResult.needsConfirmation;
        }
        if (decision == CloudOverwriteDecision.skip) {
          await store.update((s) => s.copyWith(
                needsConfirmation: true,
                retryAfter: DateTime.now().add(kCloudRetryInterval),
              ));
          return CloudBackupResult.skippedSmaller;
        }

        // Dosavadní nejnovější záloha → previous. Automaticky ne, když
        // je menší než previous (previous by přišlo o větší kopii).
        final previousRef = _ref(uid, CloudSlot.previous);
        var rotate = true;
        if (automatic) {
          final previous = await _metadata(previousRef);
          final sameFormat = previous != null &&
              cloudIsGzipContentType(previous.contentType) == currentGzip;
          rotate = cloudMayRotate(
            automatic: true,
            latestWorkouts: currentMeta?.workouts ?? 0,
            latestBytes: sameFormat ? current.size : null,
            previousWorkouts:
                previous == null ? null : _meta(previous)?.workouts ?? 0,
            previousBytes: sameFormat ? previous.size : null,
          );
        }
        if (rotate) {
          await latestRef.writeToFile(rotated);
          await previousRef.putFile(
            rotated,
            SettableMetadata(
              contentType: currentGzip
                  ? kCloudGzipContentType
                  : kCloudSqliteContentType,
              customMetadata: current.customMetadata,
            ),
          );
        }
      }

      final meta = CloudBackupMeta(
        schemaVersion: db.schemaVersion,
        createdAt: started,
        deviceName: await _device(),
        workouts: workouts,
      );
      await latestRef.putFile(
        gz,
        SettableMetadata(
          contentType: kCloudGzipContentType,
          customMetadata: meta.toCustomMetadata(),
        ),
      );
      await store.update((s) => s.copyWith(
            lastBackupAt: started,
            lastFailed: false,
            lastFailedAt: null,
            retryAfter: null,
            needsConfirmation: false,
          ));
      return CloudBackupResult.done;
    } catch (e) {
      debugPrint('Cloud: backup failed: $e');
      final now = DateTime.now();
      await store.update((s) => s.copyWith(
            lastFailed: true,
            lastFailedAt: now,
            retryAfter: now.add(kCloudRetryInterval),
          ));
      return CloudBackupResult.failed;
    } finally {
      if (raw != null) await BackupService.discard(raw);
      if (gz != null) await _delete(gz);
      if (rotated != null) await _delete(rotated);
    }
  }

  /// Zálohy v cloudu (nejnovější první). Bez přihlášení prázdný seznam.
  Future<List<CloudBackupEntry>> listBackups() async {
    final uid = currentUid;
    if (uid == null || !configured) return const [];
    final entries = <CloudBackupEntry>[];
    for (final slot in CloudSlot.values) {
      final m = await _metadata(_ref(uid, slot));
      if (m == null) continue;
      final meta = CloudBackupMeta.fromCustomMetadata(
        m.customMetadata,
        fallbackCreatedAt: m.timeCreated ?? m.updated,
      );
      if (meta == null) continue;
      entries.add(CloudBackupEntry(slot: slot, meta: meta, sizeBytes: m.size));
    }
    return entries;
  }

  /// Stáhne zálohu, ověří ji a nahradí jí všechna data v aplikaci.
  /// Chyby jako [RestoreException] (texty jako u obnovení ze souboru).
  Future<void> restore(AppDatabase db, CloudBackupEntry entry) async {
    final uid = currentUid;
    if (uid == null) throw RestoreException(RestoreError.failed, 'signed out');
    if (entry.meta.schemaVersion > db.schemaVersion) {
      throw RestoreException(RestoreError.newerVersion);
    }
    final tmp = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final download = File('${tmp.path}/cloud_download_$stamp');
    final sqlite = File('${tmp.path}/cloud_restore_$stamp.sqlite');
    try {
      await _ref(uid, entry.slot).writeToFile(download);
      if (await _isGzip(download)) {
        await gunzipFile(download, sqlite);
      } else {
        await download.copy(sqlite.path);
      }
      final file = await BackupService.prepareFile(sqlite);
      // Ověřit ještě před úklidem notifikací a kalendáře.
      await BackupService.inspect(db, file);
      // Stejně jako obnovení ze souboru (data_profile_section.dart):
      // po obnovení je SyncController naplánuje znovu podle zálohy.
      // Po chybě obnovení je naplánuje znovu runCloudRestore (cloud_module).
      await NotificationService.instance.cancelAll();
      await CalendarService.instance.removeFuture(db);
      await BackupService.restore(db, file);
    } on RestoreException {
      rethrow;
    } catch (e) {
      throw RestoreException(RestoreError.failed, e);
    } finally {
      await _delete(download);
      await BackupService.discard(sqlite);
    }
    // Data v telefonu teď odpovídají záloze z cloudu – automatická záloha
    // už nemusí čekat na potvrzení (kdyby byla obnovená menší previous,
    // příští automatická záloha stav nastaví znovu).
    try {
      await CloudSettingsStore.instance.update((s) => s.copyWith(
            needsConfirmation: false,
            retryAfter: null,
          ));
    } catch (e) {
      debugPrint('Cloud: settings update after restore failed: $e');
    }
  }

  /// Smaže obě zálohy v cloudu a vypne automatickou zálohu.
  /// Volá se i při smazání účtu (před smazáním účtu ve Firebase Auth).
  /// Počká na běžící zálohu (jinak by ji po smazání nahrála znovu).
  /// Nevyhazuje chybu; vrací false, když se mazání nepovedlo.
  Future<bool> deleteAll() => _serial(_deleteAll);

  Future<bool> _deleteAll() async {
    var ok = true;
    final uid = currentUid;
    if (uid != null && configured) {
      for (final slot in CloudSlot.values) {
        try {
          await _ref(uid, slot).delete();
        } on FirebaseException catch (e) {
          if (e.code != 'object-not-found') {
            debugPrint('Cloud: delete failed: $e');
            ok = false;
          }
        } catch (e) {
          debugPrint('Cloud: delete failed: $e');
          ok = false;
        }
      }
    }
    await CloudSettingsStore.instance.update((s) => s.copyWith(
          enabled: false,
          lastBackupAt: null,
          lastFailed: false,
          lastFailedAt: null,
          retryAfter: null,
          needsConfirmation: false,
        ));
    return ok;
  }

  Future<String> _device() async {
    final cached = _deviceName;
    if (cached != null) return cached;
    var name = '';
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        name = androidDeviceLabel(a.manufacturer, a.model);
      } else if (Platform.isIOS) {
        final i = await info.iosInfo;
        name = i.modelName.isNotEmpty ? i.modelName : i.model;
      }
    } catch (e) {
      debugPrint('Cloud: device info failed: $e');
    }
    if (name.isEmpty) name = Platform.operatingSystem;
    return _deviceName = sanitizeDeviceName(name);
  }

  static Future<bool> _isGzip(File file) async {
    final raf = await file.open();
    try {
      final Uint8List header = await raf.read(2);
      return looksLikeGzip(header);
    } finally {
      await raf.close();
    }
  }

  static Future<void> _delete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

/// Zkomprimuje soubor gzipem (proudově, bez načtení celého do paměti).
Future<void> gzipFile(File source, File target) =>
    _transformFile(source, target, gzip.encoder);

/// Rozbalí soubor gzip.
Future<void> gunzipFile(File source, File target) =>
    _transformFile(source, target, gzip.decoder);

Future<void> _transformFile(
  File source,
  File target,
  Converter<List<int>, List<int>> codec,
) async {
  final sink = target.openWrite();
  var ok = false;
  try {
    await sink.addStream(source.openRead().transform(codec));
    ok = true;
  } finally {
    // Cílový soubor zavřít vždy – i po chybě čtení nebo (de)komprese
    // (Stream.pipe ho v tom případě nechá otevřený). Chyba zavření po
    // předchozí chybě se ignoruje, aby nepřekryla tu původní.
    try {
      await sink.close();
    } catch (_) {
      if (ok) rethrow;
    }
  }
}
