import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'user_location.dart';

abstract interface class LocationService {
  /// Resolves the user's position, prompting for permission if needed.
  /// Never throws: failures come back as a [UserLocation] without a position.
  Future<UserLocation> locate();

  Future<void> openSettings(LocationAccess access);
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<UserLocation> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const UserLocation.unavailable(LocationAccess.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return const UserLocation.unavailable(LocationAccess.denied);
        case LocationPermission.deniedForever:
          return const UserLocation.unavailable(LocationAccess.deniedForever);
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          break;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        return _granted(position);
      } on TimeoutException {
        if (lastKnown != null) return _granted(lastKnown);
        rethrow;
      }
    } on Exception {
      return const UserLocation.unavailable(LocationAccess.serviceDisabled);
    }
  }

  @override
  Future<void> openSettings(LocationAccess access) async {
    if (access == LocationAccess.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  static UserLocation _granted(Position position) => UserLocation(
    access: LocationAccess.granted,
    position: LatLng(position.latitude, position.longitude),
  );
}
