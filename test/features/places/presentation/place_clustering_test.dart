import 'package:assessment_app/features/places/presentation/map/place_clustering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../../helpers/fixtures.dart';

void main() {
  // Treat degrees as pixels (x1000) so distances are easy to reason about.
  Offset project(LatLng p) => Offset(p.longitude * 1000, p.latitude * 1000);

  final a = buildPlace(id: 'a', location: const LatLng(0, 0));
  final b = buildPlace(id: 'b', location: const LatLng(0, 0.02)); // 20px
  final c = buildPlace(id: 'c', location: const LatLng(0, 0.2)); // 200px

  test('groups places within the radius and leaves distant ones alone', () {
    final clusters = clusterPlaces([a, b, c], project: project, radius: 40);
    expect(clusters, hasLength(2));
    expect(clusters.first.places.map((p) => p.id), ['a', 'b']);
    expect(clusters.last.isSingle, isTrue);
  });

  test('puts a cluster at the centre of its members', () {
    final cluster = clusterPlaces([a, b], project: project, radius: 40).single;
    expect(cluster.center.latitude, closeTo(0, 1e-9));
    expect(cluster.center.longitude, closeTo(0.01, 1e-9));
  });

  test('never clusters the selected place', () {
    final clusters = clusterPlaces(
      [a, b],
      project: project,
      radius: 40,
      keepSeparate: 'b',
    );
    expect(clusters, hasLength(2));
    expect(clusters.every((c) => c.isSingle), isTrue);
  });

  test('a zero radius keeps every place separate', () {
    expect(clusterPlaces([a, b, c], project: project, radius: 0), hasLength(3));
  });
}
