import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Smoothly animates a [MapController], which on its own can only jump.
class AnimatedMapMover {
  AnimatedMapMover({required this.controller, required TickerProvider vsync})
    : _animation = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 700),
      );

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

    final tick = _tick = () =>
        controller.move(LatLng(latitude.value, longitude.value), zoom.value);
    _animation.addListener(tick);
    _animation.forward(from: 0);
  }

  void _detach() {
    final tick = _tick;
    if (tick != null) _animation.removeListener(tick);
    _tick = null;
  }
}
