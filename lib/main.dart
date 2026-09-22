import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/notifications/firebase_push_service.dart';
import 'features/notifications/push_providers.dart';
import 'features/places/application/place_providers.dart';
import 'features/places/data/asset_place_repository.dart';
import 'features/places/data/fallback_place_repository.dart';
import 'features/places/data/firestore_place_repository.dart';
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
  final (preferences, firebase, _) = await (
    SharedPreferences.getInstance(),
    _initFirebase(),
    SplashScreen.precacheLogo(),
  ).wait;

  final bundled = AssetPlaceRepository();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        // Firestore when available, backed by the bundled sample data so
        // the app still works offline, without Firebase, or if the project
        // goes away.
        placeRepositoryProvider.overrideWithValue(
          firebase
              ? FallbackPlaceRepository(
                  primary: FirestorePlaceRepository(FirebaseFirestore.instance),
                  fallback: bundled,
                )
              : bundled,
        ),
        if (firebase)
          pushServiceProvider.overrideWithValue(
            FirebasePushService(FirebaseMessaging.instance),
          ),
      ],
      child: const SpotlyApp(),
    ),
  );
}

/// Whether Firebase is set up. When it isn't, places come from the bundled
/// data and push notifications are off.
Future<bool> _initFirebase() async {
  if (_dataSource != 'firestore') return false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } on Object catch (error) {
    developer.log('Firebase unavailable', name: 'places', error: error);
    return false;
  }
}
