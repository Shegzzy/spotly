import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tests turn this off so no network requests are made.
final mapTilesEnabledProvider = Provider<bool>((ref) => true);

/// OpenStreetMap tiles, restyled on-device to suit each theme: a soft,
/// desaturated light map and an inverted dark one. Muting the basemap lets
/// the coloured category pins do the talking, and it needs no API key.
///
/// OpenStreetMap's tile servers are fine for low-volume apps like this demo
/// as long as they're credited and requests identify the app. A production
/// app should use a commercial tile provider.
class ThemedTileLayer extends StatelessWidget {
  const ThemedTileLayer({super.key});

  static const userAgentPackageName = 'com.spotly.app';

  // 4x5 colour matrices (RGBA rows, last column is an offset).
  static const _light = ColorFilter.matrix([
    0.395, 0.4406, 0.0445, 0, 28, //
    0.131, 0.7046, 0.0445, 0, 28, //
    0.131, 0.4406, 0.3085, 0, 28, //
    0, 0, 0, 1, 0,
  ]);

  static const _dark = ColorFilter.matrix([
    0.016, -0.6506, -0.0654, 0, 182.5, //
    -0.194, -0.4406, -0.0654, 0, 184.5, //
    -0.194, -0.6506, 0.1446, 0, 190.5, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final filter = Theme.of(context).brightness == Brightness.dark
        ? _dark
        : _light;
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: userAgentPackageName,
      maxNativeZoom: 19,
      tileDisplay: const TileDisplay.fadeIn(
        duration: Duration(milliseconds: 180),
      ),
      tileBuilder: (context, tile, _) =>
          ColorFiltered(colorFilter: filter, child: tile),
    );
  }
}
