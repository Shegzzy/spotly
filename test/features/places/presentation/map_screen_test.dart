import 'package:assessment_app/features/location/user_location.dart';
import 'package:assessment_app/features/places/domain/city.dart';
import 'package:assessment_app/features/places/domain/opening_hours.dart';
import 'package:assessment_app/features/places/domain/place_category.dart';
import 'package:assessment_app/features/places/presentation/common/place_card.dart';
import 'package:assessment_app/features/places/presentation/map/widgets/place_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final places = [
    buildPlace(
      id: 'crown',
      name: 'Crown & Coils Studio',
      category: PlaceCategory.salon,
      location: const LatLng(6.4800, 3.4150),
      tags: ['Knotless braids'],
      rating: 4.8,
    ),
    buildPlace(
      id: 'jollof',
      name: 'The Jollof Co.',
      category: PlaceCategory.eatery,
      location: const LatLng(6.4750, 3.4250),
      rating: 4.5,
    ),
    buildPlace(
      id: 'medcare',
      name: 'MedCare Pharmacy',
      category: PlaceCategory.pharmacy,
      location: const LatLng(6.4850, 3.4250),
      hours: OpeningHours(List.filled(7, TimeRange.parse('00:00-24:00'))),
      rating: 4.6,
    ),
  ];

  final abuja = [
    buildPlace(
      id: 'zuri',
      name: 'Zuri Hair Atelier',
      category: PlaceCategory.salon,
      city: City.abuja,
      location: const LatLng(9.0757, 7.4720),
    ),
    buildPlace(
      id: 'arewa',
      name: 'Arewa Grill House',
      city: City.abuja,
      location: const LatLng(9.0813, 7.4842),
    ),
  ];

  Finder markerFor(String name) =>
      find.byWidgetPredicate((w) => w is PlaceMarker && w.label == name);

  testWidgets('shows a pin for every place and a results summary', (
    tester,
  ) async {
    await pumpSpotly(tester, repository: FakePlaceRepository(places));

    expect(find.byType(PlaceMarker), findsNWidgets(3));
    expect(find.text('3 places in Lagos'), findsOneWidget);
  });

  testWidgets('category chips filter the pins', (tester) async {
    await pumpSpotly(tester, repository: FakePlaceRepository(places));

    // The chip row scrolls horizontally and builds lazily.
    final pharmacies = find.text('Pharmacies');
    await tester.scrollUntilVisible(
      pharmacies,
      120,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(pharmacies);
    await tester.pump();
    await tester.tap(pharmacies);
    await settle(tester);

    expect(find.byType(PlaceMarker), findsOneWidget);
    expect(markerFor('MedCare Pharmacy'), findsOneWidget);
    expect(find.text('1 pharmacy in Lagos'), findsOneWidget);

    // Tapping the active chip again clears the filter.
    await tester.tap(pharmacies);
    await settle(tester);
    expect(find.byType(PlaceMarker), findsNWidgets(3));
  });

  testWidgets('search understands synonyms like "saloon"', (tester) async {
    await pumpSpotly(tester, repository: FakePlaceRepository(places));

    await tester.enterText(find.byType(TextField), 'saloon');
    await settle(tester);

    expect(find.byType(PlaceMarker), findsOneWidget);
    expect(markerFor('Crown & Coils Studio'), findsOneWidget);
    expect(find.text('1 place for “saloon”'), findsOneWidget);
  });

  testWidgets('an unmatched search offers to clear the filters', (
    tester,
  ) async {
    await pumpSpotly(tester, repository: FakePlaceRepository(places));

    await tester.enterText(find.byType(TextField), 'zzqx');
    await settle(tester);
    expect(find.text('No matches'), findsOneWidget);
    expect(find.byType(PlaceMarker), findsNothing);

    await tester.tap(find.text('Clear'));
    await settle(tester);
    expect(find.byType(PlaceMarker), findsNWidgets(3));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('tapping a pin previews it, and the card opens details', (
    tester,
  ) async {
    await pumpSpotly(tester, repository: FakePlaceRepository(places));

    await tester.tap(markerFor('The Jollof Co.'));
    await settle(tester);

    final card = find.widgetWithText(PlaceCard, 'The Jollof Co.');
    expect(card, findsOneWidget);
    expect(
      tester.widget<PlaceMarker>(markerFor('The Jollof Co.')).selected,
      isTrue,
    );

    await tester.tap(card);
    await settle(tester);

    expect(find.text('About'), findsOneWidget);
    expect(find.text('Directions'), findsOneWidget);
    expect(find.text('Opening hours'), findsOneWidget);
  });

  testWidgets('shows a retry option when places fail to load', (tester) async {
    final repository = FakePlaceRepository(places, error: Exception('offline'));
    await pumpSpotly(tester, repository: repository);

    expect(find.text('Couldn’t load places'), findsOneWidget);

    repository.error = null;
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(find.byType(PlaceMarker), findsNWidgets(3));
  });

  testWidgets('the theme toggle switches between light and dark', (
    tester,
  ) async {
    await pumpSpotly(tester, repository: FakePlaceRepository(places));
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(TextField))).brightness;

    final initial = brightness();
    await tester.tap(
      find.byTooltip(
        initial == Brightness.dark
            ? 'Switch to light mode'
            : 'Switch to dark mode',
      ),
    );
    await settle(tester);
    expect(brightness(), isNot(initial));
  });

  group('cities', () {
    testWidgets('shows one city at a time and remembers the switch', (
      tester,
    ) async {
      await pumpSpotly(
        tester,
        repository: FakePlaceRepository([...places, ...abuja]),
      );
      expect(find.byType(PlaceMarker), findsNWidgets(3));
      expect(find.text('3 places in Lagos'), findsOneWidget);

      await tester.tap(find.text('Lagos'));
      await settle(tester);
      expect(find.text('Choose a city'), findsOneWidget);
      expect(find.text('2 places'), findsOneWidget);

      await tester.tap(find.text('Abuja'));
      await settle(tester);
      await settle(tester); // The flight between cities takes longer.

      expect(find.byType(PlaceMarker), findsNWidgets(2));
      expect(markerFor('Zuri Hair Atelier'), findsOneWidget);
      expect(find.text('2 places in Abuja'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getString('city'),
        'abuja',
      );
    });

    testWidgets('opens on the city the user is in', (tester) async {
      await pumpSpotly(
        tester,
        repository: FakePlaceRepository([...places, ...abuja]),
        location: FakeLocationService(
          const UserLocation(
            access: LocationAccess.granted,
            position: LatLng(9.0700, 7.4700),
          ),
        ),
      );
      await settle(tester);

      expect(find.text('2 places in Abuja'), findsOneWidget);
    });

    testWidgets('explains what it shows to users outside both cities', (
      tester,
    ) async {
      await pumpSpotly(
        tester,
        repository: FakePlaceRepository([...places, ...abuja]),
        location: FakeLocationService(
          const UserLocation(
            access: LocationAccess.granted,
            position: LatLng(51.5072, -0.1276),
          ),
        ),
      );

      expect(
        find.text(
          'You’re outside Lagos and Abuja, so we’re showing places in Lagos.',
        ),
        findsOneWidget,
      );
      expect(find.text('3 places in Lagos'), findsOneWidget);
    });
  });
}
