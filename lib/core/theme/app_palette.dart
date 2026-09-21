import 'package:flutter/material.dart';

import '../../features/places/domain/place_category.dart';

/// App-specific colours that Material's [ColorScheme] has no slot for:
/// one hue per place category plus open/closed status colours.
///
/// Read it with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.categories,
    required this.open,
    required this.closingSoon,
    required this.closed,
    required this.star,
    required this.userLocation,
    required this.markerRing,
    required this.shadow,
  });

  static const light = AppPalette(
    categories: {
      PlaceCategory.salon: Color(0xFFDB2777),
      PlaceCategory.eatery: Color(0xFFEA580C),
      PlaceCategory.pharmacy: Color(0xFF059669),
      PlaceCategory.cafe: Color(0xFFB45309),
      PlaceCategory.supermarket: Color(0xFF2563EB),
      PlaceCategory.gym: Color(0xFF7C3AED),
    },
    open: Color(0xFF16A34A),
    closingSoon: Color(0xFFD97706),
    closed: Color(0xFFDC2626),
    star: Color(0xFFF59E0B),
    userLocation: Color(0xFF2F80ED),
    markerRing: Colors.white,
    shadow: Color(0x290F172A),
  );

  static const dark = AppPalette(
    categories: {
      PlaceCategory.salon: Color(0xFFEC4899),
      PlaceCategory.eatery: Color(0xFFF26B1D),
      PlaceCategory.pharmacy: Color(0xFF10B981),
      PlaceCategory.cafe: Color(0xFFD97706),
      PlaceCategory.supermarket: Color(0xFF3B82F6),
      PlaceCategory.gym: Color(0xFF8B5CF6),
    },
    open: Color(0xFF4ADE80),
    closingSoon: Color(0xFFFBBF24),
    closed: Color(0xFFF87171),
    star: Color(0xFFFBBF24),
    userLocation: Color(0xFF4C9AFF),
    markerRing: Color(0xFFF8FAFC),
    shadow: Color(0x66000000),
  );

  final Map<PlaceCategory, Color> categories;
  final Color open;
  final Color closingSoon;
  final Color closed;
  final Color star;
  final Color userLocation;
  final Color markerRing;
  final Color shadow;

  Color category(PlaceCategory category) => categories[category]!;

  /// A soft tint of the category colour for chips and badges.
  Color categoryContainer(PlaceCategory category, Brightness brightness) =>
      categories[category]!.withValues(
        alpha: brightness == Brightness.dark ? 0.22 : 0.12,
      );

  @override
  AppPalette copyWith({
    Map<PlaceCategory, Color>? categories,
    Color? open,
    Color? closingSoon,
    Color? closed,
    Color? star,
    Color? userLocation,
    Color? markerRing,
    Color? shadow,
  }) => AppPalette(
    categories: categories ?? this.categories,
    open: open ?? this.open,
    closingSoon: closingSoon ?? this.closingSoon,
    closed: closed ?? this.closed,
    star: star ?? this.star,
    userLocation: userLocation ?? this.userLocation,
    markerRing: markerRing ?? this.markerRing,
    shadow: shadow ?? this.shadow,
  );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      categories: {
        for (final category in PlaceCategory.values)
          category: mix(categories[category]!, other.categories[category]!),
      },
      open: mix(open, other.open),
      closingSoon: mix(closingSoon, other.closingSoon),
      closed: mix(closed, other.closed),
      star: mix(star, other.star),
      userLocation: mix(userLocation, other.userLocation),
      markerRing: mix(markerRing, other.markerRing),
      shadow: mix(shadow, other.shadow),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
