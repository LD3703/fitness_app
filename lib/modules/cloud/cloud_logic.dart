// Čistá logika automatické zálohy do cloudu (bez Flutteru a Firebase,
// testy: test/cloud_logic_test.dart).
import 'dart:typed_data';

/// Typ obsahu souboru zálohy v Cloud Storage (gzip s databází SQLite).
/// Stejné hodnoty povoluje storage.rules.
const kCloudGzipContentType = 'application/gzip';
const kCloudSqliteContentType = 'application/x-sqlite3';

/// Největší povolená velikost zálohy (stejně jako storage.rules).
const kCloudMaxBackupBytes = 50 * 1024 * 1024;

/// Pravidelná záloha (háček po změně dat) nejvýš jednou za tuto dobu.
const kCloudSyncInterval = Duration(hours: 24);

/// Záloha po tréninku: nová data jsou nejcennější, proto stačí krátký
/// odstup (chrání jen před opakovaným nahráváním při více trénincích).
const kCloudWorkoutInterval = Duration(minutes: 15);

/// Po nepovedené nebo přeskočené záloze se automaticky zkusí znovu
/// nejdřív po této době.
const kCloudRetryInterval = Duration(hours: 1);

/// Co zálohu spustilo.
enum CloudBackupTrigger {
  /// Háček po dokončeném tréninku.
  workoutFinished,

  /// Háček po změně dat (SyncController).
  sync,

  /// Uživatel právě zapnul automatickou zálohu.
  enabled,

  /// Tlačítko „Zálohovat teď“.
  manual,
}

/// Místo zálohy v cloudu: users/{uid}/backups/<slot>.sqlite.
enum CloudSlot { latest, previous }

String cloudBackupPath(String uid, CloudSlot slot) =>
    'users/$uid/backups/${slot.name}.sqlite';

const _keep = Object();

/// Místní nastavení automatické zálohy (JSON soubor, ne databáze –
/// obnovení zálohy ho nesmí přepsat).
class CloudSettings {
  const CloudSettings({
    this.enabled = false,
    this.wifiOnly = true,
    this.consentAt,
    this.lastBackupAt,
    this.lastFailed = false,
    this.lastFailedAt,
    this.retryAfter,
    this.restoreOfferedUids = const [],
  });

  /// Automatická záloha zapnutá (výchozí vypnuto, zapíná se se souhlasem).
  final bool enabled;

  /// Automaticky zálohovat jen přes Wi-Fi (nebo kabel).
  final bool wifiOnly;

  /// Kdy uživatel souhlasil s ukládáním zálohy do cloudu.
  final DateTime? consentAt;

  /// Poslední úspěšná záloha.
  final DateTime? lastBackupAt;

  /// Poslední pokus o zálohu selhal.
  final bool lastFailed;
  final DateTime? lastFailedAt;

  /// Automatická záloha se nezkouší dřív než v tuto dobu.
  final DateTime? retryAfter;

  /// Účty, kterým už aplikace na tomto zařízení nabídla obnovení.
  final List<String> restoreOfferedUids;

  CloudSettings copyWith({
    bool? enabled,
    bool? wifiOnly,
    Object? consentAt = _keep,
    Object? lastBackupAt = _keep,
    bool? lastFailed,
    Object? lastFailedAt = _keep,
    Object? retryAfter = _keep,
    List<String>? restoreOfferedUids,
  }) =>
      CloudSettings(
        enabled: enabled ?? this.enabled,
        wifiOnly: wifiOnly ?? this.wifiOnly,
        consentAt: identical(consentAt, _keep)
            ? this.consentAt
            : consentAt as DateTime?,
        lastBackupAt: identical(lastBackupAt, _keep)
            ? this.lastBackupAt
            : lastBackupAt as DateTime?,
        lastFailed: lastFailed ?? this.lastFailed,
        lastFailedAt: identical(lastFailedAt, _keep)
            ? this.lastFailedAt
            : lastFailedAt as DateTime?,
        retryAfter: identical(retryAfter, _keep)
            ? this.retryAfter
            : retryAfter as DateTime?,
        restoreOfferedUids: restoreOfferedUids ?? this.restoreOfferedUids,
      );

  Map<String, Object?> toJson() => {
        'enabled': enabled,
        'wifiOnly': wifiOnly,
        'consentAt': consentAt?.toUtc().toIso8601String(),
        'lastBackupAt': lastBackupAt?.toUtc().toIso8601String(),
        'lastFailed': lastFailed,
        'lastFailedAt': lastFailedAt?.toUtc().toIso8601String(),
        'retryAfter': retryAfter?.toUtc().toIso8601String(),
        'restoreOfferedUids': restoreOfferedUids,
      };

  /// Poškozený nebo neúplný soubor nevadí – chybějící hodnoty jsou výchozí.
  factory CloudSettings.fromJson(Object? json) {
    if (json is! Map) return const CloudSettings();
    DateTime? date(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    final uids = json['restoreOfferedUids'];
    return CloudSettings(
      enabled: json['enabled'] == true,
      wifiOnly: json['wifiOnly'] != false,
      consentAt: date(json['consentAt']),
      lastBackupAt: date(json['lastBackupAt']),
      lastFailed: json['lastFailed'] == true,
      lastFailedAt: date(json['lastFailedAt']),
      retryAfter: date(json['retryAfter']),
      restoreOfferedUids: uids is List
          ? [for (final u in uids) if (u is String) u]
          : const [],
    );
  }
}

/// Má se teď spustit záloha?
bool cloudBackupDue(
  CloudSettings settings,
  DateTime now,
  CloudBackupTrigger trigger,
) {
  if (!settings.enabled) return false;
  if (trigger == CloudBackupTrigger.enabled ||
      trigger == CloudBackupTrigger.manual) {
    return true;
  }
  final retry = settings.retryAfter;
  // Hodiny posunuté dozadu: čekání nesmí trvat déle než interval.
  if (retry != null &&
      now.isBefore(retry) &&
      retry.difference(now) <= kCloudRetryInterval) {
    return false;
  }
  final last = settings.lastBackupAt;
  if (last == null || last.isAfter(now)) return true;
  final interval = trigger == CloudBackupTrigger.sync
      ? kCloudSyncInterval
      : kCloudWorkoutInterval;
  return now.difference(last) >= interval;
}

/// Telefon bez tréninků nesmí přepsat zálohu, ve které tréninky jsou
/// (typicky nové zařízení před obnovením).
bool cloudShouldSkipEmpty({
  required int localWorkouts,
  required int? cloudWorkouts,
}) =>
    localWorkouts == 0 && (cloudWorkouts ?? 0) > 0;

/// Začínají data hlavičkou gzip (1f 8b)?
bool looksLikeGzip(Uint8List header) =>
    header.length >= 2 && header[0] == 0x1f && header[1] == 0x8b;

/// Název zařízení pro metadata (hlavička HTTP → jen tisknutelné ASCII,
/// nejvýš 60 znaků).
String sanitizeDeviceName(String name) {
  final buffer = StringBuffer();
  for (final c in name.runes) {
    buffer.writeCharCode(c >= 0x20 && c <= 0x7e ? c : 0x20);
  }
  final clean = buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  return clean.length <= 60 ? clean : clean.substring(0, 60).trim();
}

/// „Samsung SM-S911B“ nebo „Pixel 8“ (když model výrobce už obsahuje).
String androidDeviceLabel(String manufacturer, String model) {
  final m = manufacturer.trim();
  final mod = model.trim();
  if (m.isEmpty) return mod;
  if (mod.toLowerCase().startsWith(m.toLowerCase())) return mod;
  if (mod.isEmpty) return m;
  final brand = m[0].toUpperCase() + m.substring(1);
  return '$brand $mod';
}

/// Metadata zálohy uložená u souboru v Cloud Storage.
class CloudBackupMeta {
  const CloudBackupMeta({
    required this.schemaVersion,
    required this.createdAt,
    required this.deviceName,
    required this.workouts,
    this.compressed = true,
  });

  final int schemaVersion;
  final DateTime createdAt;
  final String deviceName;
  final int workouts;
  final bool compressed;

  Map<String, String> toCustomMetadata() => {
        'schemaVersion': '$schemaVersion',
        'createdAt': createdAt.toUtc().toIso8601String(),
        'deviceName': sanitizeDeviceName(deviceName),
        'workouts': '$workouts',
        'compression': compressed ? 'gzip' : 'none',
      };

  /// Čte metadata; chybějící hodnoty doplní ([fallbackCreatedAt] = čas
  /// nahrání souboru). Bez data vůbec vrací null.
  static CloudBackupMeta? fromCustomMetadata(
    Map<String, String>? metadata, {
    DateTime? fallbackCreatedAt,
  }) {
    final m = metadata ?? const <String, String>{};
    final created =
        DateTime.tryParse(m['createdAt'] ?? '')?.toLocal() ??
            fallbackCreatedAt?.toLocal();
    if (created == null) return null;
    return CloudBackupMeta(
      schemaVersion: int.tryParse(m['schemaVersion'] ?? '') ?? 0,
      createdAt: created,
      deviceName: m['deviceName'] ?? '',
      workouts: int.tryParse(m['workouts'] ?? '') ?? 0,
      compressed: m['compression'] != 'none',
    );
  }
}
