import 'place.dart';

/// Source of places. The app ships a bundled-JSON implementation and a
/// Firestore one; the UI only ever sees this interface.
abstract interface class PlaceRepository {
  Future<List<Place>> fetchPlaces();
}

class PlaceRepositoryException implements Exception {
  const PlaceRepositoryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'PlaceRepositoryException: $message';
}
