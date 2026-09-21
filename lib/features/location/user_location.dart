import 'package:latlong2/latlong.dart';

import '../../core/constants.dart';

enum LocationAccess { granted, denied, deniedForever, serviceDisabled }

/// Where the user is, or why we don't know.
class UserLocation {
  const UserLocation({required this.access, this.position});

  const UserLocation.unavailable(this.access) : position = null;

  final LocationAccess access;
  final LatLng? position;

  static const _distance = Distance();

  bool get isInLagos {
    final here = position;
    return here != null &&
        _distance.as(LengthUnit.Meter, here, AppConstants.lagosCenter) <=
            AppConstants.lagosRadiusMeters;
  }
}
