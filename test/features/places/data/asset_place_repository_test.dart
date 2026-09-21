import 'dart:convert';

import 'package:assessment_app/features/places/data/asset_place_repository.dart';
import 'package:assessment_app/features/places/domain/place_category.dart';
import 'package:assessment_app/features/places/domain/place_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads and parses the bundled Lagos sample data', () async {
    final repository = AssetPlaceRepository(latency: Duration.zero);
    final places = await repository.fetchPlaces();

    expect(places, hasLength(42));
    expect(
      places.map((p) => p.id).toSet(),
      hasLength(42),
      reason: 'ids are unique',
    );
    for (final category in PlaceCategory.values) {
      expect(
        places.where((p) => p.category == category),
        isNotEmpty,
        reason: category.name,
      );
    }
    for (final place in places) {
      // Every sample place sits in Lagos.
      expect(
        place.location.latitude,
        inInclusiveRange(6.35, 6.70),
        reason: place.id,
      );
      expect(
        place.location.longitude,
        inInclusiveRange(3.25, 3.65),
        reason: place.id,
      );
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
