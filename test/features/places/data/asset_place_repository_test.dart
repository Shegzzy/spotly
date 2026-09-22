import 'dart:convert';

import 'package:assessment_app/features/places/data/asset_place_repository.dart';
import 'package:assessment_app/features/places/domain/city.dart';
import 'package:assessment_app/features/places/domain/place_category.dart';
import 'package:assessment_app/features/places/domain/place_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads and parses the bundled sample data', () async {
    final repository = AssetPlaceRepository(latency: Duration.zero);
    final places = await repository.fetchPlaces();

    expect(places, hasLength(84));
    expect(
      places.map((p) => p.id).toSet(),
      hasLength(84),
      reason: 'ids are unique',
    );
    for (final city in City.values) {
      final inCity = places.where((p) => p.city == city);
      expect(inCity, hasLength(42), reason: city.name);
      for (final category in PlaceCategory.values) {
        expect(
          inCity.where((p) => p.category == category),
          isNotEmpty,
          reason: '${city.name} ${category.name}',
        );
      }
    }
    for (final place in places) {
      // Every place sits in the city it says it's in.
      expect(City.containing(place.location), place.city, reason: place.id);
      expect(place.photos, isNotEmpty, reason: place.id);
    }
  });

  test('caches after the first load', () async {
    final repository = AssetPlaceRepository(latency: Duration.zero);
    expect(
      identical(await repository.fetchPlaces(), await repository.fetchPlaces()),
      isTrue,
    );
  });

  test('round-trips a place through JSON', () async {
    final places = await AssetPlaceRepository(
      latency: Duration.zero,
    ).fetchPlaces();
    final original = places.firstWhere((p) => p.priceLevel != null);
    final copy = AssetPlaceRepository.parse(
      jsonEncode({
        'places': [original.toJson()],
      }),
    ).single;
    expect(copy.toJson(), original.toJson());
  });

  test('reports malformed data as a repository error', () async {
    final repository = AssetPlaceRepository(
      bundle: _StringBundle('{"places": [{"id": 1}]}'),
      latency: Duration.zero,
    );
    await expectLater(
      repository.fetchPlaces(),
      throwsA(isA<PlaceRepositoryException>()),
    );
  });
}

class _StringBundle extends CachingAssetBundle {
  _StringBundle(this.value);

  final String value;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
}
