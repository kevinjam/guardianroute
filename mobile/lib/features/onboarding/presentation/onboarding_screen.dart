import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardianroute/features/authentication/presentation/auth_controller.dart';
import 'package:guardianroute/features/onboarding/presentation/onboarding_preferences.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.route, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Safer routes for Kampala riders',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Report hazards, see community intelligence on the map, '
                'and choose routes that balance time and safety.',
                style: theme.textTheme.bodyLarge,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await markOnboardingComplete(ref);
                  if (!context.mounted) return;
                  final signedIn = ref.read(authStateProvider).value != null;
                  context.go(signedIn ? '/map' : '/auth');
                },
                child: const Text('Get started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
