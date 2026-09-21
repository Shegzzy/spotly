import 'dart:ui';

import 'package:latlong2/latlong.dart';

import '../../domain/place.dart';

/// One or more places drawn as a single marker.
class PlaceCluster {
  PlaceCluster(this.places)
    : assert(places.isNotEmpty),
      center = _centroid(places);

  final List<Place> places;
  final LatLng center;

  bool get isSingle => places.length == 1;

  static LatLng _centroid(List<Place> places) {
    var lat = 0.0;
    var lng = 0.0;
    for (final place in places) {
      lat += place.location.latitude;
      lng += place.location.longitude;
    }
    return LatLng(lat / places.length, lng / places.length);
  }
}

/// Greedily groups places whose pins would overlap at the current zoom.
///
/// [project] maps a coordinate to world pixels at the current zoom (so the
/// result doesn't change while panning), and places within [radius] pixels
/// of a cluster's first member join it. [keepSeparate] is never clustered,
/// so the selected place always stays visible.
List<PlaceCluster> clusterPlaces(
  List<Place> places, {
  required Offset Function(LatLng) project,
  required double radius,
  String? keepSeparate,
}) {
  final anchors = <Offset>[];
  final groups = <List<Place>>[];
  final result = <PlaceCluster>[];

  for (final place in places) {
    if (place.id == keepSeparate) {
      result.add(PlaceCluster([place]));
      continue;
    }
    final point = project(place.location);
    var joined = false;
    for (var i = 0; i < anchors.length; i++) {
      if ((anchors[i] - point).distance <= radius) {
        groups[i].add(place);
        joined = true;
        break;
      }
    }
    if (!joined) {
      anchors.add(point);
      groups.add([place]);
    }
  }

  return [for (final group in groups) PlaceCluster(group), ...result];
}
