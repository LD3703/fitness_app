// Jediné místo, které používá balíček `health` (Health Connect na Androidu,
// HealthKit / Apple Zdraví na iOS). Zbytek modulu pracuje jen s typy
// z tohoto souboru – balíček `health` má vlastní třídu WorkoutSummary,
// která by se tloukla s WorkoutSummary aplikace.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import 'health_logic.dart';

/// Je Health Connect / Apple Zdraví na tomto telefonu k dispozici?
enum HealthAvailability {
  available,

  /// Android: aplikaci Health Connect je potřeba nainstalovat nebo aktualizovat.
  needsInstall,

  /// Zařízení to nepodporuje (starý Android, jiná platforma).
  unsupported,
}

/// Výsledek zapnutí synchronizace.
enum HealthAccessResult { granted, denied, needsInstall, unsupported }

class HealthService {
  HealthService._();

  static final HealthService instance = HealthService._();

  final Health _health = Health();
  Future<void>? _configured;

  bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get isIOS => !kIsWeb && Platform.isIOS;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  /// Co aplikace potřebuje: zapsat trénink (+ energii), číst a zapsat váhu.
  /// Energii tréninku zapisuje Health Connect jako TotalCaloriesBurnedRecord,
  /// HealthKit jako totalEnergyBurned u HKWorkout (aktivní energie).
  List<HealthDataType> get _types => [
        HealthDataType.WORKOUT,
        isIOS
            ? HealthDataType.ACTIVE_ENERGY_BURNED
            : HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.WEIGHT,
      ];

  static const _permissions = [
    HealthDataAccess.WRITE,
    HealthDataAccess.WRITE,
    HealthDataAccess.READ_WRITE,
  ];

  Future<void> _ensureConfigured() async {
    final future = _configured ??= _health.configure();
    try {
      await future;
    } catch (_) {
      _configured = null;
      rethrow;
    }
  }

  Future<HealthAvailability> availability() async {
    if (!isSupportedPlatform) return HealthAvailability.unsupported;
    if (isIOS) return HealthAvailability.available;
    final status = await _health.getHealthConnectSdkStatus();
    return switch (status) {
      HealthConnectSdkStatus.sdkAvailable => HealthAvailability.available,
      HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
        HealthAvailability.needsInstall,
      HealthConnectSdkStatus.sdkUnavailable ||
      null =>
        HealthAvailability.unsupported,
    };
  }

  /// Otevře Obchod Play s aplikací Health Connect (jen Android).
  Future<void> installHealthConnect() => _health.installHealthConnect();

  /// Zkontroluje dostupnost a požádá o oprávnění.
  Future<HealthAccessResult> requestAccess() async {
    switch (await availability()) {
      case HealthAvailability.unsupported:
        return HealthAccessResult.unsupported;
      case HealthAvailability.needsInstall:
        return HealthAccessResult.needsInstall;
      case HealthAvailability.available:
        break;
    }
    await _ensureConfigured();

    if (!_isAndroid) {
      // HealthKit neprozradí, co uživatel povolil; true = dialog se ukázal.
      final shown =
          await _health.requestAuthorization(_types, permissions: _permissions);
      return shown ? HealthAccessResult.granted : HealthAccessResult.denied;
    }

    // Health Connect: requestAuthorization může viset, když je vše
    // povoleno – proto nejdřív hasPermissions.
    final hasAll =
        await _health.hasPermissions(_types, permissions: _permissions) ??
            false;
    if (!hasAll) {
      await _health.requestAuthorization(_types, permissions: _permissions);
    }
    // Bez zápisu tréninků nemá synchronizace smysl.
    if (!await canWriteWorkouts()) return HealthAccessResult.denied;

    // Health Connect standardně dovolí číst jen 30 dní před udělením
    // oprávnění; pro import váhy za 90 dní požádáme i o historii.
    try {
      if (await _health.isHealthDataHistoryAvailable() &&
          !await _health.isHealthDataHistoryAuthorized()) {
        await _health.requestHealthDataHistoryAuthorization();
      }
    } catch (e) {
      debugPrint('Health history permission failed: $e');
    }
    return HealthAccessResult.granted;
  }

  /// Připraveno k synchronizaci na pozadí (bez dialogů).
  Future<bool> isReady() async {
    if (await availability() != HealthAvailability.available) return false;
    await _ensureConfigured();
    return canWriteWorkouts();
  }

  Future<bool> _has(HealthDataType type, HealthDataAccess access) async {
    // Na iOS nelze zjistit (vrací null u čtení) – zkusíme a chybu zachytíme.
    if (!_isAndroid) return true;
    return await _health.hasPermissions([type], permissions: [access]) ??
        false;
  }

  Future<bool> canWriteWorkouts() =>
      _has(HealthDataType.WORKOUT, HealthDataAccess.WRITE);

  Future<bool> canWriteWorkoutEnergy() => _has(
        isIOS
            ? HealthDataType.ACTIVE_ENERGY_BURNED
            : HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataAccess.WRITE,
      );

  Future<bool> canReadWeight() =>
      _has(HealthDataType.WEIGHT, HealthDataAccess.READ);

  Future<bool> canWriteWeight() =>
      _has(HealthDataType.WEIGHT, HealthDataAccess.WRITE);

  /// Zapíše silový trénink. Plán B (krátká domácí rutina v intervalech)
  /// jako HIIT – typ existuje na obou platformách.
  Future<bool> writeWorkout({
    required bool planB,
    required DateTime start,
    required DateTime end,
    int? kcal,
    required String title,
  }) async {
    await _ensureConfigured();
    final HealthWorkoutActivityType type;
    if (planB) {
      type = HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING;
    } else if (isIOS) {
      type = HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING;
    } else {
      type = HealthWorkoutActivityType.STRENGTH_TRAINING;
    }
    return _health.writeWorkoutData(
      activityType: type,
      start: start,
      end: end,
      totalEnergyBurned: kcal,
      // Titulek zobrazuje jen Health Connect (iOS ho ignoruje).
      title: title,
      // Trénink se v aplikaci aktivně zaznamenával (start/stop). Na iOS je
      // povoleno jen automatic/manual.
      recordingMethod:
          _isAndroid ? RecordingMethod.active : RecordingMethod.automatic,
    );
  }

  /// Měření váhy v Health (v kg) v daném rozmezí.
  Future<List<WeightSample>> readWeights(DateTime from, DateTime to) async {
    await _ensureConfigured();
    final points = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.WEIGHT],
      preferredUnits: const {HealthDataType.WEIGHT: HealthDataUnit.KILOGRAM},
      startTime: from,
      endTime: to,
    );
    return [
      for (final p in points)
        if (p.value case NumericHealthValue(:final numericValue))
          (at: p.dateFrom.toLocal(), kg: numericValue.toDouble()),
    ];
  }

  /// Zapíše ručně zadanou váhu (kg).
  Future<bool> writeWeight(DateTime at, double kg) async {
    await _ensureConfigured();
    return _health.writeHealthData(
      value: kg,
      unit: HealthDataUnit.KILOGRAM,
      type: HealthDataType.WEIGHT,
      startTime: at,
      recordingMethod: RecordingMethod.manual,
    );
  }
}
