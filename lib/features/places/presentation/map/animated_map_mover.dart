import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Smoothly animates a [MapController], which on its own can only jump.
///
/// Long hops (e.g. Lagos to Abuja) zoom out and back in on the way, like a
/// plane taking off and landing, rather than smearing across the map.
class AnimatedMapMover {
  AnimatedMapMover({required this.controller, required TickerProvider vsync})
    : _animation = AnimationController(vsync: vsync, duration: _short);

  static const _short = Duration(milliseconds: 700);
  static const _long = Duration(milliseconds: 1500);

  final MapController controller;
  final AnimationController _animation;
  VoidCallback? _tick;

  /// Moves so that [target] is shown at [zoom], shifted by [offset] pixels
  /// from the centre of the map (e.g. to keep it clear of a bottom card).
  void moveTo(LatLng target, double zoom, {Offset offset = Offset.zero}) {
    final camera = controller.camera;
    final endZoom = camera.clampZoom(zoom);
    final endCenter = offset == Offset.zero
        ? target
        : camera.unprojectAtZoom(
            camera.projectAtZoom(target, endZoom) - offset,
            endZoom,
          );
    _animate(camera.center, camera.zoom, endCenter, endZoom);
  }

  /// Fits all [points] on screen, leaving [padding] clear for overlays.
  void fit(
    List<LatLng> points, {
    required EdgeInsets padding,
    double maxZoom = 16,
  }) {
    if (points.isEmpty) return;
    final fitted = CameraFit.coordinates(
      coordinates: points,
      padding: padding,
      maxZoom: maxZoom,
    ).fit(controller.camera);
    _animate(
      controller.camera.center,
      controller.camera.zoom,
      fitted.center,
      fitted.zoom,
    );
  }

  /// Stops any animation in progress, e.g. when the user starts dragging.
  void stop() {
    if (_animation.isAnimating) _animation.stop();
  }

  void dispose() {
    _detach();
    _animation.dispose();
  }

  void _animate(
    LatLng fromCenter,
    double fromZoom,
    LatLng toCenter,
    double toZoom,
  ) {
    _detach();

    final dip = _zoomOut(fromCenter, toCenter, math.min(fromZoom, toZoom));
    _animation.duration = dip > 1 ? _long : _short;

    final curve = CurvedAnimation(
      parent: _animation,
      curve: Curves.easeInOutCubic,
    );
    final latitude = Tween(
      begin: fromCenter.latitude,
      end: toCenter.latitude,
    ).animate(curve);
    final longitude = Tween(
      begin: fromCenter.longitude,
      end: toCenter.longitude,
    ).animate(curve);
    final zoom = Tween(begin: fromZoom, end: toZoom).animate(curve);

    final tick = _tick = () => controller.move(
      LatLng(latitude.value, longitude.value),
      zoom.value - dip * math.sin(math.pi * curve.value),
    );
    _animation.addListener(tick);
    _animation.forward(from: 0);
  }

  /// How far below [lowestZoom] the camera has to go to see both [from]
  /// and [to] at once, halfway through the move. Zero for nearby moves.
  double _zoomOut(LatLng from, LatLng to, double lowestZoom) {
    if (from == to) return 0;
    final overview = CameraFit.coordinates(
      coordinates: [from, to],
      padding: const EdgeInsets.all(48),
    ).fit(controller.camera).zoom;
    return overview.isFinite ? math.max(0, lowestZoom - overview) : 0;
  }

  void _detach() {
    final tick = _tick;
    if (tick != null) _animation.removeListener(tick);
    _tick = null;
  }
}
