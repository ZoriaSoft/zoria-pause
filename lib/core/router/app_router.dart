import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/pause/application/pause_controller.dart';
import '../../features/setup/presentation/setup_screen.dart';

/// P5 kuralı: first-run gate GoRouter redirect'inde yaşar.
/// Eksik kurulum (izin / engelleyici / karo) → /setup.
/// Biten kurulum /setup'taysa panele döner — wrench `?ref=guide` ile
/// rehberi açar, redirect onu kovmaz.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/setup',
        name: 'setup',
        builder: (context, state) => const SetupScreen(),
      ),
    ],
    redirect: (context, state) {
      final status = ref.read(pauseControllerProvider).value;
      if (status == null || !status.supported) return null;
      final onSetup = state.matchedLocation == '/setup';
      final openedGuide = state.uri.queryParameters['ref'] == 'guide';
      if (status.onboardingIncomplete && !onSetup) return '/setup';
      if (!status.onboardingIncomplete && onSetup && !openedGuide) return '/';
      return null;
    },
  );
  ref.listen(pauseControllerProvider, (_, _) => router.refresh());
  return router;
});
