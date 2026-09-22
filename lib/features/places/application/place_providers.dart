import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants.dart';
import '../../location/location_providers.dart';
import '../../settings/theme_mode_controller.dart';
import '../data/asset_place_repository.dart';
import '../domain/city.dart';
import '../domain/place.dart';
import '../domain/place_category.dart';
import '../domain/place_repository.dart';
import '../domain/place_search.dart';

/// Overridden in `main()` when Firestore is configured.
final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => AssetPlaceRepository(),
);

/// Every place from the active data source.
final placesProvider = FutureProvider<List<Place>>(
  (ref) => ref.watch(placeRepositoryProvider).fetchPlaces(),
  // Failures surface in the UI with a "Try again" button instead of
  // silently retrying in the background.
  retry: (_, _) => null,
);

/// The city being browsed. Remembered across launches; the map also
/// switches to the user's own city once it knows where they are.
final selectedCityProvider = NotifierProvider<SelectedCityController, City>(
  SelectedCityController.new,
);

class SelectedCityController extends Notifier<City> {
  static const _key = 'city';

  @override
  City build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
    return City.values.asNameMap()[stored] ?? City.lagos;
  }

  Future<void> select(City city) async {
    if (city == state) return;
    state = city;
    await ref.read(sharedPreferencesProvider).setString(_key, city.name);
  }
}

/// Places in the selected city, before any search or filter.
final cityPlacesProvider = Provider<AsyncValue<List<Place>>>((ref) {
  final city = ref.watch(selectedCityProvider);
  return ref
      .watch(placesProvider)
      .whenData(
        (places) => [
          for (final p in places)
            if (p.city == city) p,
        ],
      );
});

/// The city the user is in, if it's one Spotly covers.
final userCityProvider = Provider<City?>((ref) {
  final position = ref.watch(userLocationProvider).value?.position;
  return position == null ? null : City.containing(position);
});

/// The user's position when it's useful for distances to places in [city],
/// i.e. they're in it. Otherwise every place would be hundreds of
/// kilometres away.
final nearbyOriginProvider = Provider.family<LatLng?, City>((ref, city) {
  if (ref.watch(userCityProvider) != city) return null;
  return ref.watch(userLocationProvider).value?.position;
});

final placeByIdProvider = Provider.family<AsyncValue<Place?>, String>(
  (ref, id) => ref
      .watch(placesProvider)
      .whenData((places) => places.where((p) => p.id == id).firstOrNull),
);

/// What the user is searching for.
class PlaceFilter {
  const PlaceFilter({this.query = '', this.category});

  final String query;
  final PlaceCategory? category;

  bool get isActive => query.trim().isNotEmpty || category != null;

  @override
  bool operator ==(Object other) =>
      other is PlaceFilter &&
      other.query == query &&
      other.category == category;

  @override
  int get hashCode => Object.hash(query, category);
}

final placeFilterProvider =
    NotifierProvider<PlaceFilterController, PlaceFilter>(
      PlaceFilterController.new,
    );

class PlaceFilterController extends Notifier<PlaceFilter> {
  @override
  PlaceFilter build() => const PlaceFilter();

  void setQuery(String query) =>
      state = PlaceFilter(query: query, category: state.category);

  /// Selecting the active category again clears it, like a toggle.
  void toggleCategory(PlaceCategory? category) => state = PlaceFilter(
    query: state.query,
    category: state.category == category ? null : category,
  );

  void clear() => state = const PlaceFilter();
}

/// Places in the selected city matching the current filter, nearest first
/// when we know where the user is.
final searchResultsProvider = Provider<AsyncValue<List<Place>>>((ref) {
  final filter = ref.watch(placeFilterProvider);
  final origin = ref.watch(
    nearbyOriginProvider(ref.watch(selectedCityProvider)),
  );
  return ref
      .watch(cityPlacesProvider)
      .whenData(
        (places) => PlaceSearch.run(
          places,
          query: filter.query,
          category: filter.category,
          origin: origin,
        ),
      );
});

/// The place highlighted on the map, if any.
final selectedPlaceIdProvider =
    NotifierProvider<SelectedPlaceController, String?>(
      SelectedPlaceController.new,
    );

class SelectedPlaceController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;

  void clear() => state = null;
}

/// The current wall-clock time where the places are (West Africa Time),
/// ticking every minute so "Open now" labels stay accurate while the app
/// is open.
final watNowProvider = StreamProvider<DateTime>((ref) async* {
  yield watNow();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => watNow());
});

/// West Africa Time, expressed as a UTC [DateTime] whose fields read as the
/// local time in Lagos or Abuja.
DateTime watNow() => DateTime.now().toUtc().add(AppConstants.watUtcOffset);
