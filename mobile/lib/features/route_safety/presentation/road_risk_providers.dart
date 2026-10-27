import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianroute/core/config/app_flavor.dart';
import 'package:guardianroute/core/providers/app_providers.dart';
import 'package:guardianroute/features/route_safety/data/demo_road_segments.dart';
import 'package:guardianroute/features/route_safety/data/road_risk_repository.dart';
import 'package:guardianroute/features/route_safety/domain/road_segment.dart';

const _riskOverlayKey = 'risk_map_overlay_enabled';

final roadRiskRepositoryProvider = Provider<RoadRiskRepository>((ref) {
  return RoadRiskRepository();
});

final roadSegmentsStreamProvider = StreamProvider<List<RoadSegment>>((ref) {
  return ref.watch(roadRiskRepositoryProvider).watchHighRiskSegments();
});

final mapRoadSegmentsProvider = Provider<AsyncValue<List<RoadSegment>>>((ref) {
  final config = ref.watch(appConfigProvider);
  final live = ref.watch(roadSegmentsStreamProvider);

  return live.when(
    data: (segments) {
      final useDemo = config.flavor == AppFlavor.demo ||
          config.flavor == AppFlavor.development;
      if (!useDemo || segments.isNotEmpty) {
        return AsyncData(segments);
      }
      return AsyncData(kampalaDemoRoadSegments());
    },
    loading: () => const AsyncLoading(),
    error: (error, stackTrace) {
      if (config.flavor == AppFlavor.development ||
          config.flavor == AppFlavor.demo) {
        return AsyncData(kampalaDemoRoadSegments());
      }
      return AsyncError(error, stackTrace);
    },
  );
});

final riskWeightsSummaryProvider = Provider<Map<String, double>>((ref) {
  final rc = FirebaseRemoteConfig.instance;
  return {
    'hazard': rc.getDouble('risk_hazard_weight'),
    'harshBraking': rc.getDouble('risk_harsh_braking_weight'),
    'sensorAnomalies': rc.getDouble('risk_sensor_anomalies_weight'),
    'verifiedReports': rc.getDouble('risk_verified_reports_weight'),
    'environmental': rc.getDouble('risk_environmental_weight'),
    'timeOfDay': rc.getDouble('risk_time_of_day_weight'),
    'historical': rc.getDouble('risk_historical_weight'),
  };
});

class RiskOverlayNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_riskOverlayKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_riskOverlayKey, value);
    state = value;
  }
}

final riskOverlayEnabledProvider =
    NotifierProvider<RiskOverlayNotifier, bool>(RiskOverlayNotifier.new);

Future<Map<String, dynamic>> runRoadRiskRecalculation() async {
  final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('runRoadRiskRecalculation')
      .call();
  return Map<String, dynamic>.from(result.data as Map);
}
