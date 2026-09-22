import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/places/application/place_providers.dart';
import 'features/places/data/asset_place_repository.dart';
import 'features/places/data/fallback_place_repository.dart';
import 'features/places/data/firestore_place_repository.dart';
import 'features/places/domain/place_repository.dart';
import 'features/settings/theme_mode_controller.dart';
import 'features/splash/splash_screen.dart';
import 'firebase_options.dart';

/// `firestore` (default) or `bundled`, e.g.
/// `flutter run --dart-define=DATA_SOURCE=bundled`.
const _dataSource = String.fromEnvironment(
  'DATA_SOURCE',
  defaultValue: 'firestore',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The native launch screen stays up until the first frame, so do the
  // startup work here rather than behind a loading state.
  final (preferences, repository, _) = await (
    SharedPreferences.getInstance(),
    _createRepository(),
    SplashScreen.precacheLogo(),
  ).wait;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        placeRepositoryProvider.overrideWithValue(repository),
      ],
      child: const SpotlyApp(),
    ),
  );
}

/// Firestore when available, backed by the bundled sample data so the app
/// still works offline, without Firebase, or if the project goes away.
Future<PlaceRepository> _createRepository() async {
  final bundled = AssetPlaceRepository();
  if (_dataSource != 'firestore') return bundled;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return FallbackPlaceRepository(
      primary: FirestorePlaceRepository(FirebaseFirestore.instance),
      fallback: bundled,
    );
  } on Object catch (error) {
    developer.log('Firebase unavailable', name: 'places', error: error);
    return bundled;
  }
}
