import 'package:geolocator/geolocator.dart';
import 'package:guardianroute/core/services/app_logger.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class LocationPermissionDenied implements Exception {
  LocationPermissionDenied(this.message);
  final String message;

  @override
  String toString() => message;
}

class LocationService {
  Future<bool>? _ensurePermissionInFlight;

  Future<bool> openAppSettings() => ph.openAppSettings();

  Future<bool> ensurePermission() {
    return _ensurePermissionInFlight ??= _ensurePermissionOnce().whenComplete(() {
      _ensurePermissionInFlight = null;
    });
  }

  Future<bool> _ensurePermissionOnce() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationPermissionDenied(
        'Location services are disabled. Enable GPS to use the map.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationPermissionDenied('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDenied(
        'Location permission permanently denied. Enable it in Settings.',
      );
    }

    return true;
  }

  Future<Position> getCurrentPosition() async {
    await ensurePermission();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    );
  }
}

/// Watches permission + position for the map experience.
class LocationTracker {
  LocationTracker(this._service);

  final LocationService _service;

  Stream<Position> track() async* {
    try {
      await _service.ensurePermission();
      yield await _service.getCurrentPosition();
      yield* _service.positionStream();
    } catch (e, st) {
      appLogger.w('Location tracking stopped: $e\n$st');
      rethrow;
    }
  }
}
