import 'package:assessment_app/features/places/domain/city.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('finds the city a position is in', () {
    expect(City.containing(const LatLng(6.4478, 3.4741)), City.lagos); // Lekki
    expect(City.containing(const LatLng(6.6018, 3.3515)), City.lagos); // Ikeja
    expect(
      City.containing(const LatLng(9.0757, 7.4720)),
      City.abuja,
    ); // Wuse II
    expect(
      City.containing(const LatLng(9.0963, 7.4166)),
      City.abuja,
    ); // Gwarinpa
  });

  test('is null outside every city', () {
    expect(City.containing(const LatLng(7.3775, 3.9470)), isNull); // Ibadan
    expect(City.containing(const LatLng(51.5072, -0.1276)), isNull); // London
  });

  test('parses labels and rejects unknown cities', () {
    expect(City.fromLabel('Abuja'), City.abuja);
    expect(() => City.fromLabel('Kano'), throwsFormatException);
  });
}
