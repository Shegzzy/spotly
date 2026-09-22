import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../places/domain/city.dart';
import 'push_service.dart';

/// Firebase Cloud Messaging. Each city is a topic (`places-lagos`,
/// `places-abuja`), and messages carry the place to open as `placeId` data.
///
/// iOS needs the Push Notifications capability and an APNs key in the
/// Firebase project before it can receive anything. Without them there's no
/// APNs token, so [enable] reports that pushes aren't available rather than
/// asking for a permission that could never be used.
class FirebasePushService implements PushService {
  FirebasePushService(this._messaging);

  final FirebaseMessaging _messaging;

  static String topicFor(City city) => 'places-${city.name}';

  @override
  Future<PlaceNotification?> launchNotification() async {
    try {
      return _toPlace(await _messaging.getInitialMessage());
    } on Object catch (error) {
      _log('Could not read the launch notification', error);
      return null;
    }
  }

  @override
  Stream<PlaceNotification> get opened =>
      _places(FirebaseMessaging.onMessageOpenedApp);

  @override
  Stream<PlaceNotification> get received =>
      _places(FirebaseMessaging.onMessage);

  @override
  Future<PushAvailability> enable() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          await _apnsToken() == null) {
        _log('No APNs token; push is not configured for iOS');
        return PushAvailability.unavailable;
      }
      final settings = await _messaging.requestPermission();
      return switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => PushAvailability.enabled,
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently ||
        AuthorizationStatus.notDetermined => PushAvailability.denied,
      };
    } on Object catch (error) {
      _log('Could not enable push', error);
      return PushAvailability.unavailable;
    }
  }

  @override
  Future<void> follow(City? city) async {
    for (final each in City.values) {
      try {
        if (each == city) {
          await _messaging.subscribeToTopic(topicFor(each));
        } else {
          await _messaging.unsubscribeFromTopic(topicFor(each));
        }
      } on Object catch (error) {
        _log('Could not update the ${topicFor(each)} topic', error);
      }
    }
  }

  /// The token arrives shortly after launch when the app can receive
  /// pushes, and never when it can't.
  Future<String?> _apnsToken() async {
    for (var attempt = 0; attempt < 6; attempt++) {
      final token = await _messaging.getAPNSToken();
      if (token != null) return token;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  static Stream<PlaceNotification> _places(
    Stream<RemoteMessage> messages,
  ) async* {
    await for (final message in messages) {
      if (_toPlace(message) case final place?) yield place;
    }
  }

  static PlaceNotification? _toPlace(RemoteMessage? message) {
    final placeId = message?.data['placeId'];
    if (message == null || placeId is! String) return null;
    return PlaceNotification(
      placeId: placeId,
      title: message.notification?.title,
      body: message.notification?.body,
    );
  }

  static void _log(String message, [Object? error]) =>
      developer.log(message, name: 'push', error: error);
}
