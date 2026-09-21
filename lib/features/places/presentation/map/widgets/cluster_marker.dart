import 'package:flutter/material.dart';

import '../../../../../core/theme/app_palette.dart';
import '../../../domain/place.dart';
import '../../../domain/place_category.dart';

/// A bubble standing in for several nearby places. Its ring is a small
/// donut chart of the categories inside, so a cluster of mostly salons
/// reads as mostly pink before you zoom in.
class ClusterMarker extends StatelessWidget {
  const ClusterMarker({super.key, required this.places, required this.onTap});

  static const size = 48.0;

  final List<Place> places;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    final counts = <PlaceCategory, int>{};
    for (final place in places) {
      counts.update(place.category, (n) => n + 1, ifAbsent: () => 1);
    }
    final categories = PlaceCategory.values.where(counts.containsKey).toList();

    // Hard-edged sweep stops turn the gradient into pie segments.
    final colors = <Color>[];
    final stops = <double>[];
    var start = 0.0;
    for (final category in categories) {
      final end = start + counts[category]! / places.length;
      colors
        ..add(palette.category(category))
        ..add(palette.category(category));
      stops
        ..add(start)
        ..add(end);
      start = end;
    }

    final summary = categories
        .map((c) {
          final n = counts[c]!;
          return '$n ${(n == 1 ? c.label : c.pluralLabel).toLowerCase()}';
        })
        .join(', ');

    return Semantics(
      button: true,
      label: '${places.length} places: $summary. Tap to zoom in.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.4, end: 1),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: colors.length == 2
                  ? null
                  : SweepGradient(
                      colors: colors,
                      stops: stops,
                      transform: const GradientRotation(-1.5708),
                    ),
              color: colors.length == 2 ? colors.first : null,
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
              ),
              alignment: Alignment.center,
              child: Text(
                '${places.length}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
