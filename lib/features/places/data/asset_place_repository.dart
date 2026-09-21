import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/place.dart';
import '../domain/place_repository.dart';

/// Loads the bundled sample places from `assets/data/places.json`.
///
/// This is the default data source, so the app runs with no backend setup.
class AssetPlaceRepository implements PlaceRepository {
  AssetPlaceRepository({
    AssetBundle? bundle,
    this.assetPath = 'assets/data/places.json',
    this.latency = const Duration(milliseconds: 450),
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;

  /// Simulated network delay so loading states are visible in the demo.
  final Duration latency;

  List<Place>? _cache;

  @override
  Future<List<Place>> fetchPlaces() async {
    final cached = _cache;
    if (cached != null) return cached;
    final delay = Future<void>.delayed(latency);
    final String raw;
    try {
      raw = await _bundle.loadString(assetPath);
    } on FlutterError catch (e) {
      throw PlaceRepositoryException('Sample data is missing', e);
    }
    await delay;
    try {
      return _cache = parse(raw);
    } on FormatException catch (e) {
      throw PlaceRepositoryException('Sample data is malformed', e);
    } on TypeError catch (e) {
      // A field had the wrong type, e.g. a number where a name should be.
      throw PlaceRepositoryException('Sample data is malformed', e);
    }
  }

  static List<Place> parse(String raw) {
    final json = jsonDecode(raw) as Map<String, Object?>;
    final places = json['places']! as List<Object?>;
    return List.unmodifiable([
      for (final item in places) Place.fromJson(item! as Map<String, Object?>),
    ]);
  }
}
