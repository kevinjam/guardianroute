import 'package:flutter/foundation.dart';
import 'package:guardianroute/core/config/app_flavor.dart';

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.useFirebaseEmulators,
    this.emulatorHost = '127.0.0.1',
  });

  final AppFlavor flavor;
  final bool useFirebaseEmulators;

  /// Host for Firebase emulators (Auth/Firestore/Functions/Storage).
  final String emulatorHost;

  /// Android emulator → host machine. iOS Simulator / desktop → loopback.
  static String defaultEmulatorHost() {
    if (kIsWeb) return 'localhost';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return '127.0.0.1';
      case TargetPlatform.android:
        return '10.0.2.2';
      default:
        return '127.0.0.1';
    }
  }

  static AppConfig fromEnvironment() {
    const flavorName = String.fromEnvironment(
      'FLAVOR',
      defaultValue: 'development',
    );
    const useEmulators = bool.fromEnvironment(
      'USE_FIREBASE_EMULATORS',
      defaultValue: false,
    );
    const hostOverride = String.fromEnvironment('FIREBASE_EMULATOR_HOST');

    return AppConfig(
      flavor: AppFlavor.fromName(flavorName),
      useFirebaseEmulators: useEmulators,
      emulatorHost: hostOverride.isNotEmpty
          ? hostOverride
          : defaultEmulatorHost(),
    );
  }
}
