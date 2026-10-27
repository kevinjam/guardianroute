import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianroute/core/config/app_flavor.dart';
import 'package:guardianroute/core/providers/app_providers.dart';
import 'package:guardianroute/features/guardian_pulse/data/demo_pulse_events.dart';
import 'package:guardianroute/features/guardian_pulse/data/guardian_pulse_repository.dart';
import 'package:guardianroute/features/guardian_pulse/domain/guardian_pulse_event.dart';

final guardianPulseRepositoryProvider = Provider<GuardianPulseRepository>((ref) {
  return GuardianPulseRepository();
});

final guardianPulseStreamProvider =
    StreamProvider<List<GuardianPulseEvent>>((ref) {
  return ref.watch(guardianPulseRepositoryProvider).watchActivePulses();
});

final mapGuardianPulsesProvider = Provider<AsyncValue<List<GuardianPulseEvent>>>((ref) {
  final config = ref.watch(appConfigProvider);
  final live = ref.watch(guardianPulseStreamProvider);

  return live.when(
    data: (pulses) {
      final useDemo = config.flavor == AppFlavor.demo ||
          config.flavor == AppFlavor.development;
      if (!useDemo || pulses.isNotEmpty) {
        return AsyncData(pulses);
      }
      return AsyncData(kampalaDemoPulseEvents());
    },
    loading: () => const AsyncLoading(),
    error: (error, stackTrace) {
      if (config.flavor == AppFlavor.development ||
          config.flavor == AppFlavor.demo) {
        return AsyncData(kampalaDemoPulseEvents());
      }
      return AsyncError(error, stackTrace);
    },
  );
});

class SelectedPulseNotifier extends Notifier<GuardianPulseEvent?> {
  @override
  GuardianPulseEvent? build() => null;

  void set(GuardianPulseEvent? pulse) => state = pulse;

  void clear() => state = null;
}

final selectedPulseProvider =
    NotifierProvider<SelectedPulseNotifier, GuardianPulseEvent?>(
  SelectedPulseNotifier.new,
);

Future<Map<String, dynamic>> runGuardianPulseScan() async {
  final result =
      await FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('runGuardianPulseNow').call();
  return Map<String, dynamic>.from(result.data as Map);
}
