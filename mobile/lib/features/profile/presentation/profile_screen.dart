import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardianroute/core/providers/app_providers.dart';
import 'package:guardianroute/firebase_options.dart';
import 'package:guardianroute/features/authentication/presentation/auth_controller.dart';
import 'package:guardianroute/features/navigation/presentation/navigation_session_providers.dart';
import 'package:guardianroute/features/sensors/presentation/sensor_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final config = ref.watch(appConfigProvider);
    final auth = ref.read(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.label ?? 'Rider'),
            subtitle: Text(user?.isAnonymous == true ? 'Guest account' : user?.email ?? ''),
          ),
          const Divider(),
          ListTile(
            title: const Text('Environment'),
            subtitle: Text(config.flavor.displayName),
          ),
          ListTile(
            title: const Text('Firebase project'),
            subtitle: Text(DefaultFirebaseOptions.projectId),
          ),
          ListTile(
            title: const Text('Firebase emulators'),
            subtitle: Text(config.useFirebaseEmulators ? 'Enabled' : 'Disabled'),
          ),
          SwitchListTile(
            title: const Text('Navigation voice warnings'),
            subtitle: const Text(
              'Speak hazard proximity alerts during active navigation.',
            ),
            value: ref.watch(navigationVoiceEnabledProvider),
            onChanged: (value) => ref
                .read(navigationVoiceEnabledProvider.notifier)
                .setEnabled(value),
          ),
          SwitchListTile(
            title: const Text('Road Guardian sensors'),
            subtitle: const Text(
              'Detect bumps and braking while the map is open. '
              'Anonymous events only — no trip history.',
            ),
            value: ref.watch(sensorContributionEnabledProvider),
            onChanged: (value) =>
                ref.read(sensorContributionEnabledProvider.notifier).setEnabled(value),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) context.go('/auth');
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
