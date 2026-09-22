import 'package:latlong2/latlong.dart';

/// The cities Spotly has places in. Both are on West Africa Time.
enum City {
  lagos(
    label: 'Lagos',
    // Roughly Victoria Island / Ikoyi, the middle of the sample data.
    center: LatLng(6.4800, 3.4200),
    radiusMeters: 60000,
  ),
  abuja(
    label: 'Abuja',
    // Between Wuse II and Garki.
    center: LatLng(9.0550, 7.4700),
    radiusMeters: 45000,
  );

  const City({
    required this.label,
    required this.center,
    required this.radiusMeters,
  });

  final String label;
  final LatLng center;

  /// How far from [center] still counts as being in the city.
  final double radiusMeters;

  static const _distance = Distance();

  static City fromLabel(String label) {
    for (final city in values) {
      if (city.label == label) return city;
    }
    throw FormatException('Unknown city "$label"');
  }

  /// The city [position] is in, if any.
  static City? containing(LatLng position) {
    for (final city in values) {
      if (_distance.as(LengthUnit.Meter, position, city.center) <=
          city.radiusMeters) {
        return city;
      }
    }
    return null;
  }
}
