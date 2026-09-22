import 'package:flutter_riverpod/flutter_riverpod.dart';

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
