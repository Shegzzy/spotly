import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants.dart';
import '../../../location/location_providers.dart';
import '../../../location/user_location.dart';
import '../../application/place_providers.dart';
import '../../domain/place.dart';
import '../common/place_card.dart';
import 'animated_map_mover.dart';
import 'map_tiles.dart';
import 'widgets/category_chips.dart';
import 'widgets/map_controls.dart';
import 'widgets/map_search_bar.dart';
import 'widgets/map_status_panels.dart';
import 'widgets/place_carousel.dart';
import 'widgets/place_marker.dart';
import 'widgets/places_marker_layer.dart';
import 'widgets/results_list_sheet.dart';
import 'widgets/user_location_marker.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final _map = MapController();
  late final AnimatedMapMover _mover;

  bool _mapReady = false;
  bool _didInitialFit = false;
  bool _didCenterOnUser = false;
  bool _didWarnOutsideLagos = false;
  bool _locating = false;
  Timer? _refitDebounce;

  // Space taken by the floating search UI and bottom panels, so camera
  // moves keep places in the clear part of the map.
  double get _topInset => MediaQuery.paddingOf(context).top + 124;
  double get _bottomInset =>
      MediaQuery.paddingOf(context).bottom + PlaceCard.height + 86;

  /// Pins extend upwards from their coordinate, so the top needs room for
  /// a whole pin as well as the search UI.
  EdgeInsets get _fitPadding => EdgeInsets.fromLTRB(
    40,
    _topInset + PlaceMarker.size.height + 8,
    40,
    _bottomInset + 20,
  );

  /// Shifts a focused place to the middle of the unobstructed area.
  Offset get _focusOffset => Offset(0, (_topInset - _bottomInset) / 2);

  @override
  void initState() {
    super.initState();
    // Created up front: making it lazily in dispose() would need a ticker
    // from an element that's already deactivated.
    _mover = AnimatedMapMover(controller: _map, vsync: this);
  }

  @override
  void dispose() {
    _refitDebounce?.cancel();
    _mover.dispose();
    _map.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Camera

  void _onMapReady() {
    _mapReady = true;
    _maybeInitialFit();
    final location = ref.read(userLocationProvider).value;
    if (location != null) _onLocationResolved(location);
  }

  void _maybeInitialFit() {
    final places = ref.read(placesProvider).value;
    if (!_mapReady || _didInitialFit || _didCenterOnUser || places == null) {
      return;
    }
    _didInitialFit = true;
    _mover.fit([
      for (final place in places) place.location,
    ], padding: _fitPadding);
  }

  void _fitToResults() {
    _refitDebounce?.cancel();
    if (!_mapReady) return;
    final places = ref.read(searchResultsProvider).value;
    if (places == null || places.isEmpty) return;
    if (places.length == 1) {
      _mover.moveTo(places.single.location, 15, offset: _focusOffset);
    } else {
      _mover.fit(
        [for (final place in places) place.location],
        padding: _fitPadding,
        maxZoom: 15.5,
      );
    }
  }

  void _zoomToCluster(List<Place> places) {
    FocusManager.instance.primaryFocus?.unfocus();
    _mover.fit(
      [for (final place in places) place.location],
      padding: _fitPadding,
      maxZoom: PlacesMarkerLayer.clusterUntilZoom + 1,
    );
  }

  void _focusPlace(Place place) {
    if (!_mapReady) return;
    final zoom = _map.camera.zoom < 14 ? 14.5 : _map.camera.zoom;
    _mover.moveTo(place.location, zoom, offset: _focusOffset);
  }

  void _onLocationResolved(UserLocation location) {
    final position = location.position;
    if (!_mapReady || position == null) return;
    if (location.isInLagos) {
      if (_didCenterOnUser) return;
      _didCenterOnUser = true;
      _mover.moveTo(position, 13.5, offset: _focusOffset);
    } else if (!_didWarnOutsideLagos) {
      _didWarnOutsideLagos = true;
      _showMessage(
        'You’re outside Lagos, so we’re showing sample places there.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Actions

  void _select(Place? place) {
    ref.read(selectedPlaceIdProvider.notifier).select(place?.id);
  }

  void _openDetails(Place place) => context.push('/place/${place.id}');

  Future<void> _showList() async {
    final place = await showResultsListSheet(context);
    if (place != null && mounted) _select(place);
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    final location = await ref.read(userLocationProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _locating = false);

    final position = location.position;
    switch (location.access) {
      case LocationAccess.granted when position != null:
        if (location.isInLagos) {
          _mover.moveTo(position, 15, offset: _focusOffset);
        } else {
          _showMessage(
            'You’re outside Lagos, so we’re showing sample places there.',
          );
          _fitToResults();
        }
      case LocationAccess.denied:
        _showMessage('Allow location access to see what’s near you.');
      case LocationAccess.granted:
      case LocationAccess.deniedForever:
      case LocationAccess.serviceDisabled:
        _showMessage(
          location.access == LocationAccess.deniedForever
              ? 'Location access is turned off for Spotly.'
              : 'Location services are turned off.',
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () =>
                ref.read(locationServiceProvider).openSettings(location.access),
          ),
        );
    }
  }

  void _showMessage(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: action,
          // Float above the bottom panels rather than covering them.
          margin: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            _bottomInset - MediaQuery.paddingOf(context).bottom,
          ),
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // Build

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(placesProvider, (_, next) {
        if (next.hasValue) _maybeInitialFit();
      })
      ..listen(userLocationProvider, (_, next) {
        final location = next.value;
        if (location != null) _onLocationResolved(location);
      })
      ..listen(placeFilterProvider, (previous, next) {
        _select(null);
        // Category taps reframe straight away; typing waits for a pause.
        if (previous?.category != next.category) {
          _fitToResults();
        } else {
          _refitDebounce?.cancel();
          _refitDebounce = Timer(
            const Duration(milliseconds: 700),
            _fitToResults,
          );
        }
      })
      ..listen(selectedPlaceIdProvider, (_, id) {
        if (id == null) return;
        final place = ref
            .read(searchResultsProvider)
            .value
            ?.where((p) => p.id == id)
            .firstOrNull;
        if (place != null) _focusPlace(place);
      });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final results = ref.watch(searchResultsProvider);
    final places = results.value ?? const <Place>[];
    final selectedId = ref.watch(selectedPlaceIdProvider);
    final location = ref.watch(userLocationProvider).value;
    final userPosition = location?.position;

    return PopScope(
      canPop: selectedId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(null);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: AppConstants.lagosCenter,
                    initialZoom: 11.3,
                    minZoom: 9,
                    maxZoom: 19,
                    backgroundColor: isDark
                        ? const Color(0xFF0E1015)
                        : const Color(0xFFF2EFE9),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onMapReady: _onMapReady,
                    onTap: (_, _) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      _select(null);
                    },
                    onMapEvent: (event) {
                      // Let the user take over mid-animation.
                      final userGesture =
                          (event is MapEventMoveStart &&
                              event.source != MapEventSource.mapController) ||
                          event is MapEventDoubleTapZoomStart ||
                          event is MapEventScrollWheelZoom;
                      if (userGesture) _mover.stop();
                    },
                  ),
                  children: [
                    if (ref.watch(mapTilesEnabledProvider))
                      const ThemedTileLayer(),
                    if (userPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: userPosition,
                            width: UserLocationMarker.size,
                            height: UserLocationMarker.size,
                            child: const UserLocationMarker(),
                          ),
                        ],
                      ),
                    PlacesMarkerLayer(
                      places: places,
                      selectedId: selectedId,
                      onPlaceTap: _select,
                      onClusterTap: _zoomToCluster,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: MapSearchBar(onSubmitted: _fitToResults),
                      ),
                      const SizedBox(height: 12),
                      CategoryChips(
                        onChanged: () =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Expanded(
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: MapAttribution(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            LocateMeButton(
                              access: location?.access,
                              busy: _locating,
                              onPressed: _locateMe,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.25),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: _bottomPanel(results, places, selectedId),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomPanel(
    AsyncValue<List<Place>> results,
    List<Place> places,
    String? selectedId,
  ) {
    const inset = EdgeInsets.symmetric(horizontal: 16);

    if (!results.hasValue) {
      if (results.hasError) {
        return Padding(
          key: const ValueKey('error'),
          padding: inset,
          child: LoadErrorPanel(onRetry: () => ref.invalidate(placesProvider)),
        );
      }
      return const LoadingPanel(key: ValueKey('loading'));
    }

    final filter = ref.watch(placeFilterProvider);
    if (places.isEmpty) {
      return Padding(
        key: const ValueKey('empty'),
        padding: inset,
        child: EmptyResultsPanel(
          filter: filter,
          onClear: () => ref.read(placeFilterProvider.notifier).clear(),
        ),
      );
    }

    if (selectedId != null && places.any((p) => p.id == selectedId)) {
      return PlaceCarousel(
        key: const ValueKey('carousel'),
        places: places,
        selectedId: selectedId,
        now: ref.watch(lagosNowProvider).value ?? lagosNow(),
        origin: ref.watch(nearbyOriginProvider),
        onSwiped: _select,
        onOpen: _openDetails,
      );
    }

    return Padding(
      key: const ValueKey('summary'),
      padding: inset,
      child: ResultsSummary(
        count: places.length,
        filter: filter,
        onShowList: _showList,
      ),
    );
  }
}
