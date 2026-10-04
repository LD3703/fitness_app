import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'cloud_logic.dart';

/// Nastavení automatické zálohy v malém JSON souboru ve složce dokumentů
/// aplikace. Záměrně ne v databázi: obnovení zálohy databázi celou
/// nahradí, nastavení zálohy (a souhlas) ale patří k tomuto zařízení.
class CloudSettingsStore {
  CloudSettingsStore._();

  static final instance = CloudSettingsStore._();

  static const _fileName = 'cloud_backup_settings.json';

  CloudSettings? _cache;
  Future<CloudSettings>? _loading;
  Future<void> _writes = Future.value();
  final _changes = StreamController<CloudSettings>.broadcast();

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<CloudSettings> load() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    return _loading ??= _read().then((s) {
      _cache ??= s;
      return _cache!;
    }).whenComplete(() => _loading = null);
  }

  Future<CloudSettings> _read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const CloudSettings();
      return CloudSettings.fromJson(jsonDecode(await file.readAsString()));
    } catch (e) {
      debugPrint('Cloud: settings read failed: $e');
      return const CloudSettings();
    }
  }

  /// Změní nastavení a uloží ho (zápisy jdou po sobě).
  Future<CloudSettings> update(
    CloudSettings Function(CloudSettings current) change,
  ) {
    final result = _writes.then((_) async {
      final next = change(await load());
      _cache = next;
      _changes.add(next);
      try {
        final file = await _file();
        final tmp = File('${file.path}.tmp');
        await tmp.writeAsString(jsonEncode(next.toJson()), flush: true);
        await tmp.rename(file.path);
      } catch (e) {
        debugPrint('Cloud: settings write failed: $e');
      }
      return next;
    });
    _writes = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  Future<void> markRestoreOffered(String uid) => update(
        (s) => s.restoreOfferedUids.contains(uid)
            ? s
            : s.copyWith(restoreOfferedUids: [...s.restoreOfferedUids, uid]),
      );

  /// Aktuální nastavení a každá další změna.
  Stream<CloudSettings> watch() {
    StreamSubscription<CloudSettings>? sub;
    late final StreamController<CloudSettings> controller;
    controller = StreamController<CloudSettings>(
      onListen: () {
        // Odběr změn dřív než načtení, aby se žádná neztratila.
        sub = _changes.stream.listen(controller.add);
        load().then((s) {
          if (!controller.isClosed) controller.add(_cache ?? s);
        });
      },
      onCancel: () async {
        await sub?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }
}

final cloudSettingsProvider = StreamProvider<CloudSettings>(
  (ref) => CloudSettingsStore.instance.watch(),
);
