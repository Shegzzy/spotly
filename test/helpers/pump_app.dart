import 'package:assessment_app/app.dart';
import 'package:assessment_app/core/router/app_router.dart';
import 'package:assessment_app/features/location/location_providers.dart';
import 'package:assessment_app/features/location/location_service.dart';
import 'package:assessment_app/features/location/user_location.dart';
import 'package:assessment_app/features/places/application/place_providers.dart';
import 'package:assessment_app/features/places/domain/place.dart';
import 'package:assessment_app/features/places/domain/place_repository.dart';
import 'package:assessment_app/features/places/presentation/map/map_tiles.dart';
import 'package:assessment_app/features/settings/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePlaceRepository implements PlaceRepository {
  FakePlaceRepository(this.places, {this.error});

  final List<Place> places;
  Object? error;

  @override
  Future<List<Place>> fetchPlaces() async {
    final failure = error;
    if (failure != null) throw failure;
    return places;
  }
}

class FakeLocationService implements LocationService {
  FakeLocationService([
    this.location = const UserLocation.unavailable(LocationAccess.denied),
  ]);

  UserLocation location;

  @override
  Future<UserLocation> locate() async => location;

  @override
  Future<void> openSettings(LocationAccess access) async {}
}

/// Monday 21 September 2026, 12:00 in Lagos.
final testNow = DateTime.utc(2026, 9, 21, 12);

Future<void> pumpSpotly(
  WidgetTester tester, {
  required PlaceRepository repository,
  LocationService? location,
  bool splash = false,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        placeRepositoryProvider.overrideWithValue(repository),
        locationServiceProvider.overrideWithValue(
          location ?? FakeLocationService(),
        ),
        mapTilesEnabledProvider.overrideWithValue(false),
        splashEnabledProvider.overrideWithValue(splash),
        watNowProvider.overrideWith((ref) => Stream.value(testNow)),
      ],
      child: const SpotlyApp(),
    ),
  );
  await settle(tester);
}

/// Lets data load, debounces fire and camera animations finish. Avoids
/// pumpAndSettle because spinners and pulses animate indefinitely.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
