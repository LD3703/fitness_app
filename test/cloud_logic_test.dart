import 'dart:typed_data';

import 'package:fitness_app/modules/cloud/cloud_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 3, 12);
  const on = CloudSettings(enabled: true);

  group('cloudBackupDue', () {
    test('vypnutá záloha se nikdy nespustí', () {
      for (final t in CloudBackupTrigger.values) {
        expect(cloudBackupDue(const CloudSettings(), now, t), isFalse);
      }
    });

    test('první záloha hned', () {
      expect(cloudBackupDue(on, now, CloudBackupTrigger.sync), isTrue);
      expect(
          cloudBackupDue(on, now, CloudBackupTrigger.workoutFinished), isTrue);
    });

    test('sync nejvýš jednou za 24 h', () {
      final s = on.copyWith(
          lastBackupAt: now.subtract(const Duration(hours: 23)));
      expect(cloudBackupDue(s, now, CloudBackupTrigger.sync), isFalse);
      final s2 = on.copyWith(
          lastBackupAt: now.subtract(const Duration(hours: 24)));
      expect(cloudBackupDue(s2, now, CloudBackupTrigger.sync), isTrue);
    });

    test('po tréninku stačí 15 minut od poslední zálohy', () {
      final s = on.copyWith(
          lastBackupAt: now.subtract(const Duration(hours: 2)));
      expect(cloudBackupDue(s, now, CloudBackupTrigger.workoutFinished),
          isTrue);
      expect(cloudBackupDue(s, now, CloudBackupTrigger.sync), isFalse);
      final s2 = on.copyWith(
          lastBackupAt: now.subtract(const Duration(minutes: 5)));
      expect(cloudBackupDue(s2, now, CloudBackupTrigger.workoutFinished),
          isFalse);
    });

    test('po chybě se automaticky čeká, ručně ne', () {
      final s = on.copyWith(
        lastFailed: true,
        retryAfter: now.add(const Duration(minutes: 30)),
      );
      expect(cloudBackupDue(s, now, CloudBackupTrigger.sync), isFalse);
      expect(cloudBackupDue(s, now, CloudBackupTrigger.workoutFinished),
          isFalse);
      expect(cloudBackupDue(s, now, CloudBackupTrigger.manual), isTrue);
      expect(
          cloudBackupDue(s, now.add(const Duration(hours: 1)),
              CloudBackupTrigger.sync),
          isTrue);
    });

    test('hodiny posunuté dozadu záloze nezabrání', () {
      final s = on.copyWith(
        lastBackupAt: now.add(const Duration(days: 300)),
        retryAfter: now.add(const Duration(days: 300)),
      );
      expect(cloudBackupDue(s, now, CloudBackupTrigger.sync), isTrue);
    });
  });

  test('prázdný telefon nepřepíše zálohu s tréninky', () {
    expect(cloudShouldSkipEmpty(localWorkouts: 0, cloudWorkouts: 12), isTrue);
    expect(cloudShouldSkipEmpty(localWorkouts: 0, cloudWorkouts: 0), isFalse);
    expect(cloudShouldSkipEmpty(localWorkouts: 0, cloudWorkouts: null),
        isFalse);
    expect(cloudShouldSkipEmpty(localWorkouts: 3, cloudWorkouts: 120),
        isFalse);
  });

  test('nastavení přežije JSON i poškozený obsah', () {
    final s = CloudSettings(
      enabled: true,
      wifiOnly: false,
      consentAt: DateTime(2026, 10, 1, 8),
      lastBackupAt: DateTime(2026, 10, 2, 21, 30),
      lastFailed: true,
      lastFailedAt: DateTime(2026, 10, 3, 7),
      retryAfter: DateTime(2026, 10, 3, 8),
      restoreOfferedUids: const ['abc'],
    );
    final back = CloudSettings.fromJson(s.toJson());
    expect(back.enabled, isTrue);
    expect(back.wifiOnly, isFalse);
    expect(back.consentAt, s.consentAt);
    expect(back.lastBackupAt, s.lastBackupAt);
    expect(back.lastFailed, isTrue);
    expect(back.lastFailedAt, s.lastFailedAt);
    expect(back.retryAfter, s.retryAfter);
    expect(back.restoreOfferedUids, ['abc']);

    final broken = CloudSettings.fromJson({'enabled': 'yes', 'wifiOnly': 1});
    expect(broken.enabled, isFalse);
    expect(broken.wifiOnly, isTrue);
    expect(CloudSettings.fromJson(null).enabled, isFalse);
  });

  test('copyWith umí hodnotu vymazat', () {
    final s = on.copyWith(lastBackupAt: now, retryAfter: now);
    final cleared = s.copyWith(retryAfter: null);
    expect(cleared.retryAfter, isNull);
    expect(cleared.lastBackupAt, now);
  });

  test('metadata tam a zpět', () {
    final meta = CloudBackupMeta(
      schemaVersion: 9,
      createdAt: DateTime.utc(2026, 10, 3, 12, 5),
      deviceName: 'Pixel 8',
      workouts: 124,
    );
    final m = meta.toCustomMetadata();
    expect(m['schemaVersion'], '9');
    expect(m['workouts'], '124');
    expect(m['compression'], 'gzip');
    final back = CloudBackupMeta.fromCustomMetadata(m)!;
    expect(back.schemaVersion, 9);
    expect(back.workouts, 124);
    expect(back.deviceName, 'Pixel 8');
    expect(back.createdAt.isAtSameMomentAs(meta.createdAt), isTrue);
    expect(back.compressed, isTrue);
  });

  test('metadata bez údajů použijí čas nahrání', () {
    final uploaded = DateTime.utc(2026, 9, 1);
    final m = CloudBackupMeta.fromCustomMetadata(null,
        fallbackCreatedAt: uploaded)!;
    expect(m.workouts, 0);
    expect(m.schemaVersion, 0);
    expect(m.createdAt.isAtSameMomentAs(uploaded), isTrue);
    expect(CloudBackupMeta.fromCustomMetadata(const {}), isNull);
  });

  test('cesty záloh', () {
    expect(cloudBackupPath('u1', CloudSlot.latest),
        'users/u1/backups/latest.sqlite');
    expect(cloudBackupPath('u1', CloudSlot.previous),
        'users/u1/backups/previous.sqlite');
  });

  test('gzip hlavička', () {
    expect(looksLikeGzip(Uint8List.fromList([0x1f, 0x8b, 8])), isTrue);
    expect(looksLikeGzip(Uint8List.fromList([0x53, 0x51])), isFalse);
    expect(looksLikeGzip(Uint8List(1)), isFalse);
  });

  test('název zařízení', () {
    expect(androidDeviceLabel('Google', 'Pixel 8'), 'Google Pixel 8');
    expect(androidDeviceLabel('samsung', 'SM-S911B'), 'Samsung SM-S911B');
    expect(androidDeviceLabel('OnePlus', 'OnePlus 12'), 'OnePlus 12');
    expect(sanitizeDeviceName('  Lukášův\n iPhone  '), 'Luk v iPhone');
    expect(sanitizeDeviceName('x' * 100).length, 60);
  });
}
