import 'package:assessment_app/features/places/data/fallback_place_repository.dart';
import 'package:assessment_app/features/places/data/firestore_place_repository.dart';
import 'package:assessment_app/features/places/domain/place.dart';
import 'package:assessment_app/features/places/domain/place_category.dart';
import 'package:assessment_app/features/places/domain/place_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

class _StubRepository implements PlaceRepository {
  _StubRepository({this.places = const [], this.error});

  final List<Place> places;
  final Object? error;
  int calls = 0;

  @override
  Future<List<Place>> fetchPlaces() async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return places;
  }
}

void main() {
  group('FirestorePlaceRepository.placeFromDocument', () {
    test('maps a document, converting the GeoPoint location', () {
      final place = FirestorePlaceRepository.placeFromDocument('suya-spot', {
        'name': 'Suya Spot',
        'category': 'eatery',
        'location': const GeoPoint(6.4876, 3.3552),
        'address': '90 Eric Moore Road',
        'area': 'Surulere',
        'rating': 4.5,
        'reviewCount': 932,
        'hours': List.filled(7, '17:00-02:00'),
        'tags': ['Beef suya'],
      });

      expect(place.id, 'suya-spot');
      expect(place.category, PlaceCategory.eatery);
      expect(place.location.latitude, 6.4876);
      expect(place.location.longitude, 3.3552);
      expect(place.hours.days.first!.isOvernight, isTrue);
    });
  });

  group('FallbackPlaceRepository', () {
    final bundled = [buildPlace(id: 'bundled')];
    final remote = [buildPlace(id: 'remote')];

    test('uses the primary source when it has data', () async {
      final fallback = _StubRepository(places: bundled);
      final repository = FallbackPlaceRepository(
        primary: _StubRepository(places: remote),
        fallback: fallback,
      );
      expect(await repository.fetchPlaces(), remote);
      expect(fallback.calls, 0);
    });

    test('falls back when the primary source fails', () async {
      final repository = FallbackPlaceRepository(
        primary: _StubRepository(
          error: const PlaceRepositoryException('offline'),
        ),
        fallback: _StubRepository(places: bundled),
      );
      expect(await repository.fetchPlaces(), bundled);
    });

    test('falls back when the primary source is empty', () async {
      final repository = FallbackPlaceRepository(
        primary: _StubRepository(),
        fallback: _StubRepository(places: bundled),
      );
      expect(await repository.fetchPlaces(), bundled);
    });
  });
}
