import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/photo_url.dart';
import '../../domain/place_category.dart';
import 'category_visuals.dart';

/// A place photo that degrades to a branded category tile while loading,
/// offline, or when a place has no photo.
class PlacePhoto extends StatelessWidget {
  const PlacePhoto({
    super.key,
    required this.url,
    required this.category,
    this.width,
    this.height,
    this.iconSize = 32,
    this.lowResWidth,
  });

  final String? url;
  final PlaceCategory category;
  final double? width;
  final double? height;
  final double iconSize;

  /// Width of an already-cached smaller copy (e.g. the card thumbnail) to
  /// show while the full-size image loads, so hero transitions never flash.
  final double? lowResWidth;

  @override
  Widget build(BuildContext context) {
    final placeholder = _CategoryTile(category: category, iconSize: iconSize);
    final source = url;
    if (source == null) {
      return SizedBox(width: width, height: height, child: placeholder);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final logicalWidth =
            width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : 600);
        final pixelRatio = MediaQuery.devicePixelRatioOf(context);
        final lowRes = lowResWidth;
        final loading = lowRes == null
            ? placeholder
            : CachedNetworkImage(
                imageUrl: sizedPhotoUrl(source, width: lowRes * pixelRatio),
                width: width,
                height: height,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                placeholder: (_, _) => placeholder,
                errorWidget: (_, _, _) => placeholder,
              );
        return CachedNetworkImage(
          imageUrl: sizedPhotoUrl(source, width: logicalWidth * pixelRatio),
          width: width,
          height: height,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 220),
          placeholder: (_, _) => loading,
          errorWidget: (_, _, _) => loading,
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.iconSize});

  final PlaceCategory category;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final color = context.palette.category(category);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.9),
            Color.lerp(color, Colors.black, 0.35)!,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          category.icon,
          size: iconSize,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
