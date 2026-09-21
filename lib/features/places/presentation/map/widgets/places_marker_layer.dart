import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../domain/place.dart';
import '../place_clustering.dart';
import 'cluster_marker.dart';
import 'place_marker.dart';

/// Draws places as pins, merging ones that would overlap into clusters
/// until the map is zoomed in far enough to show them all.
class PlacesMarkerLayer extends StatefulWidget {
  const PlacesMarkerLayer({
    super.key,
    required this.places,
    required this.selectedId,
    required this.onPlaceTap,
    required this.onClusterTap,
  });

  /// From this zoom on, every place gets its own pin.
  static const clusterUntilZoom = 15.0;

  final List<Place> places;
  final String? selectedId;
  final ValueChanged<Place> onPlaceTap;
  final ValueChanged<List<Place>> onClusterTap;

  @override
  State<PlacesMarkerLayer> createState() => _PlacesMarkerLayerState();
}

class _PlacesMarkerLayerState extends State<PlacesMarkerLayer> {
  List<PlaceCluster>? _clusters;
  (List<Place>, String?, double)? _cacheKey;

  /// Re-clusters only when the inputs or the zoom (to the nearest quarter
  /// step) change, not on every pan frame.
  List<PlaceCluster> _clustersFor(MapCamera camera) {
    final zoomStep = (camera.zoom * 4).floorToDouble() / 4;
    final key = (widget.places, widget.selectedId, zoomStep);
    final cached = _clusters;
    final cachedKey = _cacheKey;
    if (cached != null &&
        cachedKey != null &&
        identical(cachedKey.$1, key.$1) &&
        cachedKey.$2 == key.$2 &&
        cachedKey.$3 == key.$3) {
      return cached;
    }
    _cacheKey = key;
    return _clusters = zoomStep >= PlacesMarkerLayer.clusterUntilZoom
        ? [
            for (final place in widget.places) PlaceCluster([place]),
          ]
        : clusterPlaces(
            widget.places,
            project: (point) => camera.projectAtZoom(point, zoomStep),
            radius: 40,
            keepSeparate: widget.selectedId,
          );
  }

  @override
  Widget build(BuildContext context) {
    final clusters = _clustersFor(MapCamera.of(context));
    final singles = [
      for (final cluster in clusters)
        if (cluster.isSingle) cluster.places.single,
    ];
    // Draw the selected pin last so it sits on top of its neighbours.
    singles.sort(
      (a, b) =>
          (a.id == widget.selectedId ? 1 : 0) -
          (b.id == widget.selectedId ? 1 : 0),
    );

    return MarkerLayer(
      markers: [
        for (final cluster in clusters)
          if (!cluster.isSingle)
            Marker(
              key: ValueKey(
                'cluster-${cluster.places.map((p) => p.id).join(',')}',
              ),
              point: cluster.center,
              width: ClusterMarker.size,
              height: ClusterMarker.size,
              child: ClusterMarker(
                places: cluster.places,
                onTap: () => widget.onClusterTap(cluster.places),
              ),
            ),
        for (final place in singles)
          Marker(
            key: ValueKey(place.id),
            point: place.location,
            width: PlaceMarker.size.width,
            height: PlaceMarker.size.height,
            alignment: Alignment.topCenter,
            child: PlaceMarker(
              category: place.category,
              label: place.name,
              selected: place.id == widget.selectedId,
              onTap: () => widget.onPlaceTap(place),
            ),
          ),
      ],
    );
  }
}
