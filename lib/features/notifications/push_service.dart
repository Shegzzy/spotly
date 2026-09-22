import '../places/domain/city.dart';

/// A push notification about a place, e.g. "New in Abuja: Zuri Hair
/// Atelier". Tapping it opens the place.
class PlaceNotification {
  const PlaceNotification({required this.placeId, this.title, this.body});

  final String placeId;
  final String? title;
  final String? body;
}

enum PushAvailability {
  enabled,

  /// The user said no; only the system settings can change that now.
  denied,

  /// This build or device can't receive pushes, e.g. iOS without an APNs
  /// key, or Firebase turned off.
  unavailable,
}

/// Push notifications about new places. The app only sees this interface:
/// `FirebasePushService` is the real one, and [DisabledPushService] stands
/// in when Firebase isn't set up (and in tests).
abstract interface class PushService {
  /// The notification the user tapped to launch the app, if any.
  Future<PlaceNotification?> launchNotification();

  /// Notifications the user tapped while the app was in the background.
  Stream<PlaceNotification> get opened;

  /// Notifications that arrive while the app is on screen. The system
  /// doesn't show these, so the app does.
  Stream<PlaceNotification> get received;

  /// Asks for permission if needed. Never throws.
  Future<PushAvailability> enable();

  /// Follows new places in [city] only, or none when it's null.
  Future<void> follow(City? city);
}

class DisabledPushService implements PushService {
  const DisabledPushService();

  @override
  Future<PlaceNotification?> launchNotification() async => null;

  @override
  Stream<PlaceNotification> get opened => const Stream.empty();

  @override
  Stream<PlaceNotification> get received => const Stream.empty();

  @override
  Future<PushAvailability> enable() async => PushAvailability.unavailable;

  @override
  Future<void> follow(City? city) async {}
}
