import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../places/application/place_providers.dart';
import '../settings/theme_mode_controller.dart';
import 'push_service.dart';

/// Overridden in `main()` when Firebase is available.
final pushServiceProvider = Provider<PushService>(
  (ref) => const DisabledPushService(),
);

/// Whether "New place alerts" is on. Remembered across launches.
final placeAlertsProvider = NotifierProvider<PlaceAlertsController, bool>(
  PlaceAlertsController.new,
);

class PlaceAlertsController extends Notifier<bool> {
  static const _key = 'place_alerts';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  /// Turns alerts on (asking for permission) or off, following the
  /// selected city's topic while they're on.
  Future<PushAvailability> setEnabled(bool enabled) async {
    final push = ref.read(pushServiceProvider);
    if (enabled) {
      final availability = await push.enable();
      if (availability != PushAvailability.enabled) return availability;
    }
    state = enabled;
    await ref.read(sharedPreferencesProvider).setBool(_key, enabled);
    await push.follow(enabled ? ref.read(selectedCityProvider) : null);
    return PushAvailability.enabled;
  }
}

/// Switches to the city of a place opened from a notification, so the map
/// behind its details shows where it is.
void selectCityOfPlace(WidgetRef ref, String placeId) {
  final place = ref.read(placeByIdProvider(placeId)).value;
  if (place != null) ref.read(selectedCityProvider.notifier).select(place.city);
}
