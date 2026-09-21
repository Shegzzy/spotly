import 'package:latlong2/latlong.dart';

abstract final class AppConstants {
  static const appName = 'Spotly';

  /// Centre of the sample data, roughly Victoria Island / Ikoyi.
  static const lagosCenter = LatLng(6.4800, 3.4200);

  /// Users further than this from Lagos see the Lagos sample data rather
  /// than being centred on their own (empty) surroundings.
  static const lagosRadiusMeters = 60000.0;

  /// Sample opening hours are in West Africa Time (UTC+1, no daylight
  /// saving), so open/closed status is correct wherever the viewer is.
  static const lagosUtcOffset = Duration(hours: 1);
}
