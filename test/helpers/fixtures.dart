import 'package:assessment_app/features/places/domain/city.dart';
import 'package:assessment_app/features/places/domain/opening_hours.dart';
import 'package:assessment_app/features/places/domain/place.dart';
import 'package:assessment_app/features/places/domain/place_category.dart';
import 'package:latlong2/latlong.dart';

OpeningHours everyDay(String range) =>
    OpeningHours(List.filled(7, TimeRange.parse(range)));

Place buildPlace({
  required String id,
  String? name,
  PlaceCategory category = PlaceCategory.eatery,
  LatLng location = const LatLng(6.45, 3.47),
  String area = 'Lekki Phase 1',
  City city = City.lagos,
  double rating = 4.5,
  List<String> tags = const [],
  OpeningHours? hours,
}) => Place(
  id: id,
  name: name ?? id,
  category: category,
  location: location,
  address: '1 Test Street',
  area: area,
  city: city,
  rating: rating,
  reviewCount: 10,
  description: 'A test place.',
  hours: hours ?? everyDay('08:00-20:00'),
  phone: '+234 1 000 0001',
  tags: tags,
);
