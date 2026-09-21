import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'location_service.dart';
import 'user_location.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

final userLocationProvider =
    AsyncNotifierProvider<UserLocationController, UserLocation>(
      UserLocationController.new,
    );

class UserLocationController extends AsyncNotifier<UserLocation> {
  @override
  Future<UserLocation> build() => ref.watch(locationServiceProvider).locate();

  /// Asks for the position again, e.g. from the "locate me" button.
  Future<UserLocation> refresh() async {
    final previous = state.value;
    final next = await ref.read(locationServiceProvider).locate();
    // Keep the last good fix if the new attempt came back empty.
    state = AsyncData(
      next.position == null && previous?.position != null ? previous! : next,
    );
    return next;
  }
}

/// The user's position when it's useful for distances, i.e. they're in
/// Lagos where the sample data lives. Otherwise every place would be
/// thousands of kilometres away.
final nearbyOriginProvider = Provider<LatLng?>((ref) {
  final location = ref.watch(userLocationProvider).value;
  return location != null && location.isInLagos ? location.position : null;
});
