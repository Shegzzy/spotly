import 'package:assessment_app/features/places/domain/place.dart';
import 'package:assessment_app/features/places/domain/place_category.dart';
import 'package:assessment_app/features/places/domain/place_search.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../../helpers/fixtures.dart';

void main() {
  final crown = buildPlace(
    id: 'crown',
    name: 'Crown & Coils Studio',
    category: PlaceCategory.salon,
    tags: ['Knotless braids', 'Locs'],
    location: const LatLng(6.4478, 3.4741),
    rating: 4.8,
  );
  final fade = buildPlace(
    id: 'fade',
    name: 'The Fade Room',
    category: PlaceCategory.salon,
    area: 'Victoria Island',
    location: const LatLng(6.4299, 3.4190),
    rating: 4.7,
  );
  final jollof = buildPlace(
    id: 'jollof',
    name: 'The Jollof Co.',
    category: PlaceCategory.eatery,
    tags: ['Party jollof', 'Dodo'],
    location: const LatLng(6.4433, 3.4669),
    rating: 4.5,
  );
  final medcare = buildPlace(
    id: 'medcare',
    name: 'MedCare Pharmacy',
    category: PlaceCategory.pharmacy,
    location: const LatLng(6.4466, 3.4768),
    rating: 4.6,
  );
  final cafe = buildPlace(
    id: 'cafe',
    name: 'Bean There Café',
    category: PlaceCategory.cafe,
    area: 'Yaba',
    location: const LatLng(6.5101, 3.3776),
    rating: 4.6,
  );
  final all = [crown, fade, jollof, medcare, cafe];

  List<String> ids(List<Place> places) => [for (final p in places) p.id];

  test('an empty query returns everything, best rated first', () {
    expect(ids(PlaceSearch.run(all)), [
      'crown',
      'fade',
      'medcare',
      'cafe',
      'jollof',
    ]);
  });

  test('filters by category', () {
    expect(ids(PlaceSearch.run(all, category: PlaceCategory.salon)), [
      'crown',
      'fade',
    ]);
  });

  test('matches category synonyms and common spellings', () {
    for (final query in ['salon', 'saloon', 'Salons', 'barber', 'hair']) {
      expect(ids(PlaceSearch.run(all, query: query)), [
        'crown',
        'fade',
      ], reason: query);
    }
    expect(ids(PlaceSearch.run(all, query: 'chemist')), ['medcare']);
    expect(ids(PlaceSearch.run(all, query: 'pharmacies')), ['medcare']);
    expect(ids(PlaceSearch.run(all, query: 'food')), ['jollof']);
  });

  test('tolerates typos and accents', () {
    expect(ids(PlaceSearch.run(all, query: 'pharmcy')), ['medcare']);
    expect(ids(PlaceSearch.run(all, query: 'resturant')), ['jollof']);
    expect(ids(PlaceSearch.run(all, query: 'cafe')), ['cafe']);
    expect(ids(PlaceSearch.run(all, query: 'CAFÉS')), ['cafe']);
  });

  test('matches names, tags and neighbourhoods by prefix', () {
    expect(ids(PlaceSearch.run(all, query: 'jol')), ['jollof']);
    expect(ids(PlaceSearch.run(all, query: 'knotless')), ['crown']);
    expect(ids(PlaceSearch.run(all, query: 'yaba')), ['cafe']);
  });

  test('requires every word to match', () {
    expect(ids(PlaceSearch.run(all, query: 'salon victoria')), ['fade']);
    expect(PlaceSearch.run(all, query: 'salon yaba'), isEmpty);
  });

  test('combines query and category', () {
    expect(
      PlaceSearch.run(all, query: 'jollof', category: PlaceCategory.salon),
      isEmpty,
    );
  });

  test('ranks name matches above category matches', () {
    final pharmacy = buildPlace(
      id: 'wellspring',
      name: 'Wellspring',
      category: PlaceCategory.pharmacy,
      rating: 4.9,
    );
    final cafeNamedPharmacy = buildPlace(
      id: 'odd',
      name: 'Old Pharmacy Café',
      category: PlaceCategory.cafe,
      rating: 4.0,
    );
    final results = PlaceSearch.run([
      pharmacy,
      cafeNamedPharmacy,
    ], query: 'pharmacy');
    expect(ids(results), ['odd', 'wellspring']);
  });

  test('sorts equally good matches by distance from the user', () {
    const nearFade = LatLng(6.4300, 3.4200);
    expect(ids(PlaceSearch.run(all, query: 'salon', origin: nearFade)), [
      'fade',
      'crown',
    ]);
  });

  test('returns nothing for gibberish', () {
    expect(PlaceSearch.run(all, query: 'zzqx'), isEmpty);
  });

  test('tokenize normalises plurals, case and punctuation', () {
    expect(PlaceSearch.tokenize("Mama Tee's Kitchens!"), [
      'mama',
      'tee',
      'kitchen',
    ]);
    expect(PlaceSearch.tokenize('Groceries & Cafés'), ['grocery', 'cafe']);
    expect(PlaceSearch.tokenize('   '), isEmpty);
  });
}
