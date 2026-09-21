import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/place.dart';
import '../../map/map_tiles.dart';
import '../../map/widgets/place_marker.dart';

/// A small static map of the place with its address underneath.
class LocationPreview extends ConsumerWidget {
  const LocationPreview({
    super.key,
    required this.place,
    required this.onOpenDirections,
    required this.onCopyAddress,
  });

  final Place place;
  final VoidCallback onOpenDirections;
  final VoidCallback onCopyAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final showTiles = ref.watch(mapTilesEnabledProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: Stack(
              children: [
                IgnorePointer(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: place.location,
                      initialZoom: 15.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      if (showTiles) const ThemedTileLayer(),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: place.location,
                            width: PlaceMarker.size.width,
                            height: PlaceMarker.size.height,
                            alignment: Alignment.topCenter,
                            child: PlaceMarker(
                              category: place.category,
                              label: place.name,
                              selected: false,
                              onTap: onOpenDirections,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: onOpenDirections,
                      child: Semantics(
                        button: true,
                        label: 'Open directions to ${place.name}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
            child: Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    place.fullAddress,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy address',
                  onPressed: onCopyAddress,
                  icon: const Icon(Icons.copy_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
