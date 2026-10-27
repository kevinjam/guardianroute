import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guardianroute/core/services/app_logger.dart';
import 'package:guardianroute/features/sensors/domain/sensor_event_type.dart'
    show DetectedSensorEvent, SensorEventType;

class SensorEventRepository {
  SensorEventRepository({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  })  : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final Map<SensorEventType, DateTime> _localCooldown = {};

  Future<void> submit({
    required String anonymousDeviceId,
    required DetectedSensorEvent event,
    required Position position,
    required int cooldownSeconds,
  }) async {
    final last = _localCooldown[event.type];
    if (last != null &&
        DateTime.now().difference(last).inSeconds < cooldownSeconds) {
      return;
    }

    try {
      await _functions.httpsCallable('processSensorEvent').call({
        'anonymousDeviceId': anonymousDeviceId,
        'eventType': event.type.wireName,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'magnitude': event.magnitude,
        'speed': position.speed >= 0 ? position.speed : null,
        'heading': position.heading >= 0 ? position.heading : null,
        'clientTimestamp': event.occurredAt.toUtc().toIso8601String(),
      });
    } catch (_) {
      try {
        await _firestore.collection('sensorEvents').add({
          'anonymousDeviceId': anonymousDeviceId,
          'eventType': event.type.wireName,
          'location': GeoPoint(position.latitude, position.longitude),
          'geohash': 's8p1x9k',
          'magnitude': event.magnitude,
          'speed': position.speed >= 0 ? position.speed : null,
          'heading': position.heading >= 0 ? position.heading : null,
          'clientTimestamp': event.occurredAt.toUtc().toIso8601String(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e, st) {
        appLogger.w('Sensor fallback upload failed: $e\n$st');
        return;
      }
    }

    _localCooldown[event.type] = DateTime.now();
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'sensor_event_uploaded',
        parameters: {'event_type': event.type.wireName},
      );
    } catch (_) {}
  }
}
