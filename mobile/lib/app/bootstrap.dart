import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianroute/app/app.dart';
import 'package:guardianroute/core/config/app_config.dart';
import 'package:guardianroute/core/services/app_logger.dart';
import 'package:guardianroute/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/providers/app_providers.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (config.useFirebaseEmulators) {
    await _connectFirebaseEmulators(config.emulatorHost);
  }

  await _configureAppCheck(config);
  await _configureCrashlytics();
  await _configureRemoteConfig();
  await _configureFirestore();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: GuardianRouteApp(config: config),
    ),
  );
}

Future<void> _connectFirebaseEmulators(String host) async {
  appLogger.i('Connecting Firebase emulators at $host');
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instanceFor(region: 'europe-west1').useFunctionsEmulator(host, 5001);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
}

Future<void> _configureAppCheck(AppConfig config) async {
  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
      providerApple: const AppleDebugProvider(),
    );
  } else {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidPlayIntegrityProvider(),
      providerApple: const AppleDeviceCheckProvider(),
    );
  }
}

Future<void> _configureCrashlytics() async {
  if (kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  } else {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

Future<void> _configureRemoteConfig() async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ),
  );
  await remoteConfig.setDefaults(const {
    'risk_hazard_weight': 0.30,
    'risk_harsh_braking_weight': 0.20,
    'risk_sensor_anomalies_weight': 0.15,
    'risk_verified_reports_weight': 0.15,
    'risk_environmental_weight': 0.10,
    'risk_time_of_day_weight': 0.05,
    'risk_historical_weight': 0.05,
    'hazard_warning_distance_meters': 300,
    'guardian_pulse_min_events': 15,
    'guardian_pulse_window_minutes': 30,
    'guardian_pulse_spike_factor': 4,
    'guardian_pulse_baseline_per_hour': 2,
    'guardian_pulse_geohash_precision': 7,
    'demo_mode_enabled': false,
    'vertical_shock_threshold': 4.0,
    'harsh_braking_threshold': 5.5,
    'vibration_variance_threshold': 2.5,
    'avoidance_lateral_threshold': 4.5,
    'sensor_min_speed_avoidance': 3.0,
    'sensor_upload_cooldown_seconds': 60,
  });
  try {
    await remoteConfig.fetchAndActivate();
  } catch (e, st) {
    appLogger.w('Remote Config fetch failed; using defaults: $e\n$st');
  }
}

Future<void> _configureFirestore() async {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
}
