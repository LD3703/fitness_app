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

  group('cloudOverwriteDecision', () {
    CloudOverwriteDecision decide({
      bool automatic = true,
      bool confirmed = false,
      required int local,
      int? localBytes = 100000,
      required int? cloud,
      int? cloudBytes = 100000,
    }) =>
        cloudOverwriteDecision(
          automatic: automatic,
          confirmed: confirmed,
          localWorkouts: local,
          localBytes: localBytes,
          cloudWorkouts: cloud,
          cloudBytes: cloudBytes,
        );

    test('bez zálohy v cloudu se nahrává vždy', () {
      expect(decide(local: 0, cloud: null), CloudOverwriteDecision.upload);
      expect(decide(local: 0, cloud: null, localBytes: 1),
          CloudOverwriteDecision.upload);
    });

    test('víc nebo stejně tréninků se nahrává', () {
      expect(decide(local: 120, cloud: 120), CloudOverwriteDecision.upload);
      expect(decide(local: 121, cloud: 120, localBytes: 10),
          CloudOverwriteDecision.upload);
    });

    test('automaticky nikdy nepřepíše zálohu s víc tréninky', () {
      // Prázdný telefon (dřív jediná ochrana).
      expect(decide(local: 0, cloud: 12), CloudOverwriteDecision.skip);
      // Nový telefon s pár tréninky proti velké záloze.
      expect(decide(local: 3, cloud: 120), CloudOverwriteDecision.skip);
      expect(decide(local: 119, cloud: 120), CloudOverwriteDecision.skip);
      // Potvrzení se u automatické zálohy nebere v úvahu.
      expect(decide(local: 3, cloud: 120, confirmed: true),
          CloudOverwriteDecision.skip);
    });

    test('ručně se nejdřív ptá, po potvrzení nahraje', () {
      expect(decide(automatic: false, local: 3, cloud: 120),
          CloudOverwriteDecision.confirm);
      expect(decide(automatic: false, confirmed: true, local: 3, cloud: 120),
          CloudOverwriteDecision.upload);
      expect(decide(automatic: false, local: 130, cloud: 120),
          CloudOverwriteDecision.upload);
    });

    test('bez tréninků rozhoduje velikost (méně než polovina)', () {
      expect(
        decide(local: 0, cloud: 0, localBytes: 40000, cloudBytes: 100000),
        CloudOverwriteDecision.skip,
      );
      expect(
        decide(
          automatic: false,
          local: 0,
          cloud: 0,
          localBytes: 40000,
          cloudBytes: 100000,
        ),
        CloudOverwriteDecision.confirm,
      );
      expect(
        decide(local: 0, cloud: 0, localBytes: 50000, cloudBytes: 100000),
        CloudOverwriteDecision.upload,
      );
      expect(
        decide(local: 0, cloud: 0, localBytes: 90000, cloudBytes: 100000),
        CloudOverwriteDecision.upload,
      );
    });

    test('neznámá velikost o ničem nerozhoduje', () {
      expect(decide(local: 0, cloud: 0, localBytes: null),
          CloudOverwriteDecision.upload);
      expect(decide(local: 0, cloud: 0, cloudBytes: null),
          CloudOverwriteDecision.upload);
      expect(decide(local: 0, cloud: 0, cloudBytes: 0),
          CloudOverwriteDecision.upload);
      // S tréninky se velikost neporovnává (menší soubor po VACUUM je OK).
      expect(decide(local: 5, cloud: 5, localBytes: 10, cloudBytes: 100000),
          CloudOverwriteDecision.upload);
    });
  });

  group('cloudMayRotate', () {
    test('ručně se previous přepisuje vždy', () {
      expect(
        cloudMayRotate(
          automatic: false,
          latestWorkouts: 3,
          latestBytes: 10,
          previousWorkouts: 120,
          previousBytes: 100000,
        ),
        isTrue,
      );
    });

    test('automaticky ne, když je latest menší než previous', () {
      expect(
        cloudMayRotate(
          automatic: true,
          latestWorkouts: 3,
          latestBytes: 1000,
          previousWorkouts: 120,
          previousBytes: 100000,
        ),
        isFalse,
      );
      expect(
        cloudMayRotate(
          automatic: true,
          latestWorkouts: 0,
          latestBytes: 1000,
          previousWorkouts: 0,
          previousBytes: 100000,
        ),
        isFalse,
      );
    });

    test('automaticky ano, když latest není menší nebo previous chybí', () {
      expect(
        cloudMayRotate(
          automatic: true,
          latestWorkouts: 120,
          latestBytes: 100000,
          previousWorkouts: 119,
          previousBytes: 99000,
        ),
        isTrue,
      );
      expect(
        cloudMayRotate(
          automatic: true,
          latestWorkouts: 0,
          latestBytes: 10,
          previousWorkouts: null,
          previousBytes: null,
        ),
        isTrue,
      );
      // Jiný formát (gzip / bez komprese) → velikost se neporovnává.
      expect(
        cloudMayRotate(
          automatic: true,
          latestWorkouts: 0,
          latestBytes: null,
          previousWorkouts: 0,
          previousBytes: null,
        ),
        isTrue,
      );
    });
  });

  test('typ obsahu zálohy', () {
    expect(cloudIsGzipContentType(kCloudGzipContentType), isTrue);
    expect(cloudIsGzipContentType(null), isTrue);
    expect(cloudIsGzipContentType(kCloudSqliteContentType), isFalse);
  });

  test('čekání na potvrzení přežije JSON a jde vymazat', () {
    final s = on.copyWith(needsConfirmation: true);
    expect(CloudSettings.fromJson(s.toJson()).needsConfirmation, isTrue);
    expect(s.copyWith(lastFailed: true).needsConfirmation, isTrue);
    expect(s.copyWith(needsConfirmation: false).needsConfirmation, isFalse);
    expect(const CloudSettings().needsConfirmation, isFalse);
    expect(CloudSettings.fromJson({'needsConfirmation': 'yes'})
        .needsConfirmation, isFalse);
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
