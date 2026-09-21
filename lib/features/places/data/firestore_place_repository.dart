import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/place.dart';
import '../domain/place_repository.dart';

/// Reads places from the `places` collection in Cloud Firestore.
///
/// Documents mirror `assets/data/places.json`, except `location` is stored as
/// a native [GeoPoint] so it can back geo queries later.
class FirestorePlaceRepository implements PlaceRepository {
  FirestorePlaceRepository(
    this._firestore, {
    this.timeout = const Duration(seconds: 8),
  });

  static const collection = 'places';

  final FirebaseFirestore _firestore;
  final Duration timeout;

  @override
  Future<List<Place>> fetchPlaces() async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .get()
          .timeout(timeout);
      return List.unmodifiable([
        for (final doc in snapshot.docs) placeFromDocument(doc.id, doc.data()),
      ]);
    } on FirebaseException catch (e) {
      throw PlaceRepositoryException('Firestore request failed', e);
    } on TimeoutException catch (e) {
      throw PlaceRepositoryException('Firestore timed out', e);
    } on TypeError catch (e) {
      throw PlaceRepositoryException('A Firestore document is malformed', e);
    } on FormatException catch (e) {
      throw PlaceRepositoryException('A Firestore document is malformed', e);
    }
  }

  static Place placeFromDocument(String id, Map<String, Object?> data) {
    final location = data['location'];
    return Place.fromJson({
      ...data,
      'id': id,
      if (location is GeoPoint)
        'location': {'lat': location.latitude, 'lng': location.longitude},
    });
  }
}
