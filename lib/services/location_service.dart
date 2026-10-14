import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Poloha telefonu pro „posilovny v okolí“. Používá se jen v telefonu
/// (seřazení seznamu, buňky geohashe pro dotaz) a nikam se neukládá –
/// výjimkou je poloha posilovny, kterou zakladatel výslovně uloží.
typedef GeoPosition = ({double lat, double lng});

/// Proč se poloha nepodařila zjistit.
enum LocationFailure { serviceOff, denied, deniedForever, unavailable }

typedef LocationResult = ({GeoPosition? position, LocationFailure? failure});

class LocationService {
  LocationService._();

  static final instance = LocationService._();

  /// Poslední zjištěná poloha (jen v paměti, do zavření aplikace).
  GeoPosition? last;

  /// Smí aplikace polohu číst bez dotazu (uživatel už ji povolil)?
  Future<bool> hasPermission() async {
    try {
      final p = await Geolocator.checkPermission();
      return p == LocationPermission.whileInUse ||
          p == LocationPermission.always;
    } catch (e) {
      debugPrint('Location: permission check failed: $e');
      return false;
    }
  }

  /// Aktuální poloha; když ještě není povolená, zeptá se.
  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return (position: null, failure: LocationFailure.serviceOff);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return (position: null, failure: LocationFailure.deniedForever);
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return (position: null, failure: LocationFailure.denied);
      }
      Position? p;
      try {
        // Stačí přibližná přesnost – posilovny se řadí po desítkách metrů.
        p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (e) {
        debugPrint('Location: current position failed ($e), using last known.');
        p = await Geolocator.getLastKnownPosition();
      }
      if (p == null) {
        return (position: null, failure: LocationFailure.unavailable);
      }
      final point = (lat: p.latitude, lng: p.longitude);
      last = point;
      return (position: point, failure: null);
    } catch (e) {
      debugPrint('Location: failed: $e');
      return (position: null, failure: LocationFailure.unavailable);
    }
  }

  /// Nastavení polohy (vypnutá služba) nebo oprávnění aplikace.
  Future<void> openSettings(LocationFailure failure) async {
    try {
      if (failure == LocationFailure.serviceOff) {
        await Geolocator.openLocationSettings();
      } else {
        await Geolocator.openAppSettings();
      }
    } catch (e) {
      debugPrint('Location: settings failed: $e');
    }
  }
}
