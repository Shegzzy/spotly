import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/places/presentation/details/place_details_screen.dart';
import '../../features/places/presentation/map/map_screen.dart';
import '../../features/splash/splash_screen.dart';

/// Whether the app opens on the splash screen. Tests start on the map.
final splashEnabledProvider = Provider<bool>((ref) => true);

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: ref.read(splashEnabledProvider) ? '/splash' : '/',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (_, state) =>
            NoTransitionPage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/',
        // Only ever animates in from the splash: the map fades up while
        // settling from a slight zoom, as if the camera is landing on it.
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 550),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween(begin: 1.06, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          ),
          child: const MapScreen(),
        ),
        routes: [
          GoRoute(
            path: 'place/:id',
            builder: (_, state) =>
                PlaceDetailsScreen(placeId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
