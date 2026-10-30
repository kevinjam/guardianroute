import 'dart:math' as math;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/features/navigation/domain/route_option.dart';
import 'package:guardianroute/features/route_safety/domain/road_risk_level.dart';

class RoutePlanRepository {
  RoutePlanRepository({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  Future<RoutePlanResult> planSafeRoutes({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final result = await _functions.httpsCallable('planSafeRoutes').call({
        'originLat': origin.latitude,
        'originLng': origin.longitude,
        'destLat': destination.latitude,
        'destLng': destination.longitude,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final routesRaw = data['routes'] as List<dynamic>;
      final recommendation = Map<String, dynamic>.from(
        data['recommendation'] as Map,
      );

      final routes = routesRaw
          .map((r) => RouteOption.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();

      return RoutePlanResult(
        routes: routes,
        recommendationMessage: recommendation['message'] as String? ?? '',
        recommendedLabel: RouteLabel.fromWire(
          recommendation['recommendedLabel'] as String?,
        ),
        isDemo: data['isDemo'] as bool? ?? false,
      );
    } catch (_) {
      return _buildClientFallbackRoutes(origin, destination);
    }
  }

  RoutePlanResult _buildClientFallbackRoutes(LatLng origin, LatLng dest) {
    final midLat = (origin.latitude + dest.latitude) / 2;
    final midLng = (origin.longitude + dest.longitude) / 2;
    final dLat = dest.latitude - origin.latitude;
    final dLng = dest.longitude - origin.longitude;

    final directMiles =
        math.sqrt(dLat * dLat + dLng * dLng) * 111.0; // rough km
    final baseKm = math.max(1.2, directMiles);
    final baseMin = math.max(4, (baseKm * 2.5).round());

    final fastestPoly = _encodePolyline([
      origin,
      LatLng(midLat, midLng),
      dest,
    ]);
    final balancedPoly = _encodePolyline([
      origin,
      LatLng(midLat + 0.003, midLng - 0.003),
      dest,
    ]);
    final safestPoly = _encodePolyline([
      origin,
      LatLng(midLat - 0.004, midLng + 0.005),
      dest,
    ]);

    final routes = <RouteOption>[
      RouteOption(
        routeId: 'route-0',
        label: RouteLabel.fastest,
        durationMinutes: baseMin,
        distanceKm: double.parse(baseKm.toStringAsFixed(1)),
        riskScore: 82,
        riskLevel: RoadRiskLevel.critical,
        encodedPolyline: fastestPoly,
        summary: 'Direct corridor (High hazard density)',
      ),
      RouteOption(
        routeId: 'route-1',
        label: RouteLabel.balanced,
        durationMinutes: baseMin + 2,
        distanceKm: double.parse((baseKm * 1.12).toStringAsFixed(1)),
        riskScore: 44,
        riskLevel: RoadRiskLevel.moderate,
        encodedPolyline: balancedPoly,
        summary: 'Northern bypass (Moderate risk)',
      ),
      RouteOption(
        routeId: 'route-2',
        label: RouteLabel.safest,
        durationMinutes: baseMin + 4,
        distanceKm: double.parse((baseKm * 1.22).toStringAsFixed(1)),
        riskScore: 24,
        riskLevel: RoadRiskLevel.low,
        encodedPolyline: safestPoly,
        summary: 'Protected avenue (Avoids critical potholes)',
      ),
    ];

    return RoutePlanResult(
      routes: routes,
      recommendationMessage:
          'The safer route takes approximately 4 minutes longer but avoids high-risk road sections.',
      recommendedLabel: RouteLabel.safest,
      isDemo: true,
    );
  }

  String _encodePolyline(List<LatLng> points) {
    final result = StringBuffer();
    var prevLat = 0;
    var prevLng = 0;
    for (final p in points) {
      final lat = (p.latitude * 1e5).round();
      final lng = (p.longitude * 1e5).round();
      _encodeValue(lat - prevLat, result);
      _encodeValue(lng - prevLng, result);
      prevLat = lat;
      prevLng = lng;
    }
    return result.toString();
  }

  void _encodeValue(int value, StringBuffer out) {
    var v = value < 0 ? ~(value << 1) : (value << 1);
    while (v >= 0x20) {
      out.writeCharCode((0x20 | (v & 0x1f)) + 63);
      v >>= 5;
    }
    out.writeCharCode(v + 63);
  }
}
