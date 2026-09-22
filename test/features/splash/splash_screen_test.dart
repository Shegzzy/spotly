import 'dart:async';

import 'package:assessment_app/features/places/domain/place.dart';
import 'package:assessment_app/features/places/domain/place_repository.dart';
import 'package:assessment_app/features/places/presentation/map/map_screen.dart';
import 'package:assessment_app/features/places/presentation/map/widgets/place_marker.dart';
import 'package:assessment_app/features/splash/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_app.dart';

class _PendingPlaceRepository implements PlaceRepository {
  final _places = Completer<List<Place>>();

  @override
  Future<List<Place>> fetchPlaces() => _places.future;
}

void main() {
  testWidgets('opens on the map once the intro has played', (tester) async {
    await pumpSpotly(
      tester,
      repository: FakePlaceRepository([buildPlace(id: 'a')]),
      splash: true,
    );
    await settle(tester);

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.byType(PlaceMarker), findsOneWidget);
  });

  testWidgets('waits for places, but not forever', (tester) async {
    await pumpSpotly(
      tester,
      repository: _PendingPlaceRepository(),
      splash: true,
    );

    // The intro has finished, but places are still loading.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Spotly'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Finding places around Lagos…'), findsOneWidget);
  });
}
