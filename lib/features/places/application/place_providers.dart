import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../location/location_providers.dart';
import '../data/asset_place_repository.dart';
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

/// Places matching the current filter, nearest first when we know where
/// the user is.
final searchResultsProvider = Provider<AsyncValue<List<Place>>>((ref) {
  final filter = ref.watch(placeFilterProvider);
  final origin = ref.watch(nearbyOriginProvider);
  return ref
      .watch(placesProvider)
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

/// The current wall-clock time in Lagos, ticking every minute so
/// "Open now" labels stay accurate while the app is open.
final lagosNowProvider = StreamProvider<DateTime>((ref) async* {
  yield lagosNow();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => lagosNow());
});

/// Lagos wall-clock time, expressed as a UTC [DateTime] whose fields read
/// as local Lagos time.
DateTime lagosNow() => DateTime.now().toUtc().add(AppConstants.lagosUtcOffset);
