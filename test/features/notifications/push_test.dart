import 'package:assessment_app/features/notifications/presentation/notification_banner.dart';
import 'package:assessment_app/features/notifications/push_service.dart';
import 'package:assessment_app/features/places/domain/city.dart';
import 'package:assessment_app/features/places/domain/place_category.dart';
import 'package:assessment_app/features/places/presentation/map/widgets/place_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_app.dart';

void main() {
  final places = [
    buildPlace(id: 'jollof', name: 'The Jollof Co.'),
    buildPlace(
      id: 'zuri',
      name: 'Zuri Hair Atelier',
      category: PlaceCategory.salon,
      city: City.abuja,
      location: const LatLng(9.0757, 7.4720),
    ),
  ];
  const zuri = PlaceNotification(
    placeId: 'zuri',
    title: 'New in Abuja: Zuri Hair Atelier',
    body: 'A bright, unhurried studio for natural hair.',
  );

  Future<void> toggleAlerts(WidgetTester tester) async {
    await tester.tap(find.text('New place alerts'));
    await settle(tester);
  }

  testWidgets('shows notifications that arrive in the app as a banner', (
    tester,
  ) async {
    final push = FakePushService();
    await pumpSpotly(
      tester,
      repository: FakePlaceRepository(places),
      push: push,
    );

    push.receivedController.add(zuri);
    await settle(tester);
    expect(find.byType(NotificationBanner), findsOneWidget);
    expect(find.text('New in Abuja: Zuri Hair Atelier'), findsOneWidget);

    // Tapping it opens the place, and the map behind moves to its city.
    await tester.tap(find.byType(NotificationBanner));
    await settle(tester);
    expect(find.byType(NotificationBanner), findsNothing);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Abuja time'), findsOneWidget);

    await tester.pageBack();
    await settle(tester);
    await settle(tester);
    expect(find.text('1 place in Abuja'), findsOneWidget);
    expect(find.byType(PlaceMarker), findsOneWidget);
  });

  testWidgets('the banner goes away on its own', (tester) async {
    final push = FakePushService();
    await pumpSpotly(
      tester,
      repository: FakePlaceRepository(places),
      push: push,
    );

    push.receivedController.add(zuri);
    await settle(tester);
    expect(find.byType(NotificationBanner), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await settle(tester);
    expect(find.byType(NotificationBanner), findsNothing);
  });

  testWidgets('tapping a notification from the background opens the place', (
    tester,
  ) async {
    final push = FakePushService();
    await pumpSpotly(
      tester,
      repository: FakePlaceRepository(places),
      push: push,
    );

    push.openedController.add(zuri);
    await settle(tester);
    expect(find.text('Zuri Hair Atelier'), findsWidgets);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('a notification that launched the app opens its place', (
    tester,
  ) async {
    final push = FakePushService()..launch = zuri;
    await pumpSpotly(
      tester,
      repository: FakePlaceRepository(places),
      push: push,
      splash: true,
    );
    await settle(tester);

    expect(find.text('About'), findsOneWidget);
    expect(find.text('Abuja time'), findsOneWidget);
  });

  testWidgets('alerts follow the selected city while they are on', (
    tester,
  ) async {
    final push = FakePushService();
    await pumpSpotly(
      tester,
      repository: FakePlaceRepository(places),
      push: push,
    );

    await tester.tap(find.text('Lagos'));
    await settle(tester);
    await toggleAlerts(tester);
    expect(push.followed, [City.lagos]);

    await tester.tap(find.text('Abuja'));
    await settle(tester);
    expect(push.followed, [City.lagos, City.abuja]);

    await tester.tap(find.text('Abuja'));
    await settle(tester);
    await toggleAlerts(tester);
    expect(push.followed, [City.lagos, City.abuja, null]);
  });

  testWidgets('explains why alerts could not be turned on', (tester) async {
    final push = FakePushService(availability: PushAvailability.unavailable);
    await pumpSpotly(
      tester,
      repository: FakePlaceRepository(places),
      push: push,
    );

    await tester.tap(find.text('Lagos'));
    await settle(tester);
    await toggleAlerts(tester);

    expect(
      find.text('Notifications aren’t available in this build.'),
      findsOneWidget,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(push.followed, isEmpty);

    push.availability = PushAvailability.denied;
    await toggleAlerts(tester);
    expect(
      find.text('Notifications are off for Spotly. Turn them on in Settings.'),
      findsOneWidget,
    );
  });
}
