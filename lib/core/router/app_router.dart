import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/places/presentation/details/place_details_screen.dart';
import '../../features/places/presentation/map/map_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const MapScreen(),
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
