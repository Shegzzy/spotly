import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/place.dart';

/// "★ 4.8 (312) · ₦₦"
class RatingRow extends StatelessWidget {
  const RatingRow({
    super.key,
    required this.place,
    this.style,
    this.showPrice = true,
    this.spellOutReviews = false,
  });

  final Place place;
  final TextStyle? style;
  final bool showPrice;

  /// "(312 reviews)" rather than "(312)", for roomier layouts.
  final bool spellOutReviews;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = style ?? theme.textTheme.bodySmall!;
    final muted = base.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final price = place.priceLevel;

    return Semantics(
      label: 'Rated ${place.rating} from ${place.reviewCount} reviews',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: (base.fontSize ?? 12) + 4,
            color: context.palette.star,
          ),
          const SizedBox(width: 3),
          Text(
            place.rating.toStringAsFixed(1),
            style: base.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          Text(
            spellOutReviews
                ? '(${Formatters.compactCount(place.reviewCount)} reviews)'
                : '(${Formatters.compactCount(place.reviewCount)})',
            style: muted,
          ),
          if (showPrice && price != null) ...[
            Text('  ·  ', style: muted),
            Text(Formatters.priceLevel(price), style: muted),
          ],
        ],
      ),
    );
  }
}

/// A coloured dot with "Open · Closes 9 PM" style text.
class OpenStatusLabel extends StatelessWidget {
  const OpenStatusLabel({
    super.key,
    required this.place,
    required this.now,
    this.style,
    this.showDetail = true,
  });

  final Place place;
  final DateTime now;
  final TextStyle? style;
  final bool showDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final text = OpenStatusText.describe(place.hours.statusAt(now), now);
    final color = switch (text.tone) {
      OpenTone.open => palette.open,
      OpenTone.closingSoon => palette.closingSoon,
      OpenTone.closed => palette.closed,
    };
    final base = style ?? theme.textTheme.bodySmall!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: text.headline,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                if (showDetail && text.detail.isNotEmpty)
                  TextSpan(
                    text: '  ·  ${text.detail}',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
            style: base,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
