import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardianroute/features/authentication/presentation/auth_controller.dart';
import 'package:guardianroute/features/authentication/presentation/sign_in_screen.dart';
import 'package:guardianroute/features/hazard_reporting/presentation/report_hazard_screen.dart';
import 'package:guardianroute/features/hazard_reporting/presentation/report_result_screen.dart';
import 'package:guardianroute/features/guardian_pulse/presentation/safety_screen.dart';
import 'package:guardianroute/features/home/presentation/home_map_screen.dart';
import 'package:guardianroute/features/navigation/presentation/active_navigation_screen.dart';
import 'package:guardianroute/features/navigation/presentation/route_comparison_screen.dart';
import 'package:guardianroute/features/onboarding/presentation/onboarding_preferences.dart';
import 'package:guardianroute/features/onboarding/presentation/onboarding_screen.dart';
import 'package:guardianroute/features/profile/presentation/profile_screen.dart';
import 'package:guardianroute/app/router_refresh.dart';
import 'package:guardianroute/features/splash/presentation/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingComplete = ref.watch(onboardingCompleteProvider);
  final refresh = ref.watch(routerRefreshListenableProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (location == '/splash') return null;

      if (authState.isLoading) return null;

      final user = authState.value;
      final isAuthRoute = location == '/auth';
      final isOnboarding = location == '/onboarding';

      // Finish onboarding before map/auth (even when already signed in).
      if (!onboardingComplete) {
        if (!isOnboarding) return '/onboarding';
        return null;
      }

      if (isOnboarding) {
        return user != null ? '/map' : '/auth';
      }

      if (user == null && !isAuthRoute) {
        return '/auth';
      }

      if (user != null && isAuthRoute) {
        return '/map';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) => const HomeMapScreen(),
        routes: [
          GoRoute(
            path: 'report',
            name: 'report_hazard',
            builder: (context, state) => const ReportHazardScreen(),
          ),
          GoRoute(
            path: 'report/:reportId',
            name: 'report_result',
            builder: (context, state) => ReportResultScreen(
              reportId: state.pathParameters['reportId']!,
            ),
          ),
          GoRoute(
            path: 'routes',
            name: 'route_comparison',
            builder: (context, state) => const RouteComparisonScreen(),
          ),
          GoRoute(
            path: 'navigate',
            name: 'active_navigation',
            builder: (context, state) => const ActiveNavigationScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/safety',
        name: 'safety',
        builder: (context, state) => const SafetyScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
