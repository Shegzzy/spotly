import 'package:assessment_app/features/places/presentation/common/place_card.dart';
import 'package:assessment_app/features/places/presentation/map/widgets/place_marker.dart';
import 'package:assessment_app/main.dart' as app;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the real app end to end (live data, tiles and location) and
/// captures the screenshots used in the README.
///
/// Run with:
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/app_flow_test.dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Waits in real time while still pumping frames, so network tiles,
  /// photos and camera animations have time to finish.
  Future<void> wait(WidgetTester tester, [int ms = 2500]) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await wait(tester, 1500);
    await binding.takeScreenshot(name);
  }

  Finder marker(String name) =>
      find.byWidgetPredicate((w) => w is PlaceMarker && w.label == name);

  testWidgets('search, preview and details in light and dark', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    await app.main();
    // The splash, then network tiles.
    await wait(tester, 9000);

    // The places came from Firestore (and are now in its offline cache),
    // not from the bundled fallback.
    final cached = await FirebaseFirestore.instance
        .collection('places')
        .get(const GetOptions(source: Source.cache));
    expect(cached.docs, hasLength(84));
    await shot(tester, '01-map-light');

    // Filter to salons and preview one.
    await tester.tap(find.text('Salons'));
    await wait(tester);
    await shot(tester, '02-salons');

    await tester.tap(marker('Crown & Coils Studio'));
    await wait(tester);
    expect(
      find.widgetWithText(PlaceCard, 'Crown & Coils Studio'),
      findsOneWidget,
    );
    await shot(tester, '03-preview');

    // Open the details screen.
    await tester.tap(find.widgetWithText(PlaceCard, 'Crown & Coils Studio'));
    await wait(tester, 3500);
    expect(find.text('About'), findsOneWidget);
    await shot(tester, '04-details');

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await wait(tester);
    await shot(tester, '05-details-scrolled');

    await tester.pageBack();
    await wait(tester);

    // Switch to dark mode and search by free text.
    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.tap(find.text('Salons')); // Clear the category.
    await wait(tester);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'pharmacy');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await wait(tester, 3500);
    await shot(tester, '06-search-dark');

    await tester.tap(marker('MedCare Pharmacy'));
    await wait(tester);
    await shot(tester, '07-preview-dark');

    await tester.tap(find.widgetWithText(PlaceCard, 'MedCare Pharmacy'));
    await wait(tester, 3500);
    await shot(tester, '08-details-dark');

    await tester.pageBack();
    await wait(tester);
    await tester.tap(find.byTooltip('Clear search'));
    await wait(tester, 3000);
    await shot(tester, '09-map-dark');

    await tester.tap(find.text('List'));
    await wait(tester);
    await shot(tester, '10-list-dark');

    // Close the list and fly to Abuja.
    await tester.tapAt(const Offset(40, 80));
    await wait(tester);
    await tester.tap(find.text('Lagos'));
    await wait(tester);
    await tester.tap(find.text('Abuja'));
    await wait(tester, 4000);
    expect(find.text('42 places in Abuja'), findsOneWidget);
    await shot(tester, '11-abuja-dark');
  });
}
