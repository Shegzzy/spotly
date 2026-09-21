import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/place.dart';
import 'floating_surface.dart';
import 'place_meta.dart';
import 'place_photo.dart';

/// Hero tag shared by a place's thumbnail and its details header, so the
/// photo flies between screens.
String placePhotoHeroTag(Place place) => 'place-photo-${place.id}';

/// Compact summary of a place used in the map carousel.
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    required this.now,
    required this.onTap,
    this.distanceMeters,
  });

  static const height = 124.0;
  static const photoWidth = 104.0;

  final Place place;
  final DateTime now;
  final VoidCallback onTap;
  final double? distanceMeters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = context.palette.category(place.category);
    final distance = distanceMeters;

    return FloatingSurface(
      radius: 22,
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Hero(
                tag: placePhotoHeroTag(place),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: PlacePhoto(
                    url: place.coverPhoto,
                    category: place.category,
                    width: photoWidth,
                    height: double.infinity,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${place.category.label} · ${place.area}'
                                .toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: categoryColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        if (distance != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.near_me_rounded,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            Formatters.distance(distance),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    RatingRow(place: place),
                    const SizedBox(height: 6),
                    OpenStatusLabel(place: place, now: now),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
