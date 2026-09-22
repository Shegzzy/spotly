import 'package:latlong2/latlong.dart';

import 'city.dart';
import 'opening_hours.dart';
import 'place_category.dart';

/// A business shown on the map.
class Place {
  Place({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.address,
    required this.area,
    required this.city,
    required this.rating,
    required this.reviewCount,
    required this.description,
    required this.hours,
    this.phone,
    this.priceLevel,
    List<String> tags = const [],
    List<String> photos = const [],
  }) : tags = List.unmodifiable(tags),
       photos = List.unmodifiable(photos);

  factory Place.fromJson(Map<String, Object?> json) {
    final location = json['location']! as Map<String, Object?>;
    return Place(
      id: json['id']! as String,
      name: json['name']! as String,
      category: PlaceCategory.fromId(json['category']! as String),
      location: LatLng(
        (location['lat']! as num).toDouble(),
        (location['lng']! as num).toDouble(),
      ),
      address: json['address']! as String,
      area: json['area']! as String,
      city: City.fromLabel(json['city'] as String? ?? City.lagos.label),
      rating: (json['rating']! as num).toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      hours: OpeningHours.fromJson(json['hours']! as List<Object?>),
      phone: json['phone'] as String?,
      priceLevel: (json['priceLevel'] as num?)?.toInt(),
      tags: _stringList(json['tags']),
      photos: _stringList(json['photos']),
    );
  }

  final String id;
  final String name;
  final PlaceCategory category;
  final LatLng location;
  final String address;

  /// Neighbourhood, e.g. "Lekki Phase 1".
  final String area;
  final City city;
  final double rating;
  final int reviewCount;
  final String description;
  final OpeningHours hours;
  final String? phone;

  /// 1 (budget) to 4 (premium), or null where it doesn't apply.
  final int? priceLevel;
  final List<String> tags;
  final List<String> photos;

  String? get coverPhoto => photos.isEmpty ? null : photos.first;

  String get fullAddress => '$address, $area, ${city.label}';

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'location': {'lat': location.latitude, 'lng': location.longitude},
    'address': address,
    'area': area,
    'city': city.label,
    'rating': rating,
    'reviewCount': reviewCount,
    'description': description,
    'hours': hours.toJson(),
    'phone': ?phone,
    'priceLevel': ?priceLevel,
    'tags': tags,
    'photos': photos,
  };

  static List<String> _stringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];

  @override
  bool operator ==(Object other) => other is Place && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Place($id)';
}
