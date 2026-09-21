import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../location/location_providers.dart';
import '../../../application/place_providers.dart';
import '../../../domain/place.dart';
import '../../common/place_meta.dart';
import '../../common/place_photo.dart';

/// Opens the current results as a list. Resolves to the place the user
/// tapped, if any, so the map can fly to it.
Future<Place?> showResultsListSheet(BuildContext context) {
  return showModalBottomSheet<Place>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      builder: (context, scrollController) =>
          _ResultsList(scrollController: scrollController),
    ),
  );
}

class _ResultsList extends ConsumerWidget {
  const _ResultsList({required this.scrollController});

  final ScrollController scrollController;

  static const _distance = Distance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final places = ref.watch(searchResultsProvider).value ?? const [];
    final origin = ref.watch(nearbyOriginProvider);
    final now = ref.watch(lagosNowProvider).value ?? lagosNow();

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Results', style: theme.textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  origin == null
                      ? '${places.length} places · best match first'
                      : '${places.length} places · nearest first',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 16,
          ),
          sliver: SliverList.separated(
            itemCount: places.length,
            separatorBuilder: (_, _) =>
                const Divider(indent: 100, endIndent: 20),
            itemBuilder: (context, index) {
              final place = places[index];
              return _ResultTile(
                place: place,
                now: now,
                distanceMeters: origin == null
                    ? null
                    : _distance.as(LengthUnit.Meter, origin, place.location),
                onTap: () => Navigator.of(context).pop(place),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.place,
    required this.now,
    required this.onTap,
    this.distanceMeters,
  });

  final Place place;
  final DateTime now;
  final VoidCallback onTap;
  final double? distanceMeters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distance = distanceMeters;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: PlacePhoto(
                url: place.coverPhoto,
                category: place.category,
                width: 66,
                height: 66,
                iconSize: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${place.category.label} · ${place.area}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.palette.category(place.category),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RatingRow(place: place, showPrice: false),
                      const SizedBox(width: 10),
                      Flexible(
                        child: OpenStatusLabel(
                          place: place,
                          now: now,
                          showDetail: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (distance != null) ...[
              const SizedBox(width: 8),
              Text(
                Formatters.distance(distance),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
