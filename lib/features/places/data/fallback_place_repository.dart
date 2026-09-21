import 'dart:developer' as developer;

import '../domain/place.dart';
import '../domain/place_repository.dart';

/// Uses [primary] (e.g. Firestore) and quietly switches to [fallback] (the
/// bundled sample data) if it fails or has nothing, so the map is never
/// empty because of a backend problem.
class FallbackPlaceRepository implements PlaceRepository {
  const FallbackPlaceRepository({
    required this.primary,
    required this.fallback,
  });

  final PlaceRepository primary;
  final PlaceRepository fallback;

  @override
  Future<List<Place>> fetchPlaces() async {
    try {
      final places = await primary.fetchPlaces();
      if (places.isNotEmpty) return places;
      developer.log('Primary source is empty; using fallback', name: 'places');
    } on PlaceRepositoryException catch (error) {
      developer.log(
        'Primary source failed; using fallback',
        name: 'places',
        error: error.cause ?? error,
      );
    }
    return fallback.fetchPlaces();
  }
}
