import 'package:flutter/material.dart';

import '../../domain/place_category.dart';

extension CategoryVisuals on PlaceCategory {
  IconData get icon => switch (this) {
    PlaceCategory.salon => Icons.content_cut_rounded,
    PlaceCategory.eatery => Icons.restaurant_rounded,
    PlaceCategory.pharmacy => Icons.local_pharmacy_rounded,
    PlaceCategory.cafe => Icons.local_cafe_rounded,
    PlaceCategory.supermarket => Icons.shopping_basket_rounded,
    PlaceCategory.gym => Icons.fitness_center_rounded,
  };
}
