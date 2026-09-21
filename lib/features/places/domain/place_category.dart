// dart format off
/// The kinds of places Spotly can find.
///
/// [keywords] power free-text search: typing any of them (or a close typo)
/// matches every place in the category, so "saloon", "barber" and "braids"
/// all surface salons.
enum PlaceCategory {
  salon(
    label: 'Salon',
    pluralLabel: 'Salons',
    keywords: [
      'salon', 'saloon', 'hair', 'hairdresser', 'hairstylist', 'stylist',
      'barber', 'barbing', 'barbershop', 'haircut', 'fade', 'braid',
      'braiding', 'loc', 'wig', 'nail', 'manicure', 'pedicure', 'spa',
      'beauty', 'makeup', 'lash',
    ],
  ),
  eatery(
    label: 'Eatery',
    pluralLabel: 'Eateries',
    keywords: [
      'eatery', 'restaurant', 'food', 'eat', 'chop', 'buka', 'bukka',
      'canteen', 'kitchen', 'amala', 'jollof', 'rice', 'suya', 'grill',
      'breakfast', 'lunch', 'dinner', 'meal', 'swallow', 'diner', 'bistro',
    ],
  ),
  pharmacy(
    label: 'Pharmacy',
    pluralLabel: 'Pharmacies',
    keywords: [
      'pharmacy', 'pharmacist', 'chemist', 'drug', 'drugstore', 'medicine',
      'meds', 'medication', 'prescription', 'pill', 'health', 'pharma',
    ],
  ),
  cafe(
    label: 'Café',
    pluralLabel: 'Cafés',
    keywords: [
      'cafe', 'coffee', 'espresso', 'latte', 'cappuccino', 'bakery',
      'pastry', 'tea', 'brunch', 'dessert', 'cake', 'bread',
    ],
  ),
  supermarket(
    label: 'Supermarket',
    pluralLabel: 'Supermarkets',
    keywords: [
      'supermarket', 'grocery', 'grocer', 'mart', 'market', 'store', 'shop',
      'shopping', 'provision', 'foodstuff',
    ],
  ),
  gym(
    label: 'Gym',
    pluralLabel: 'Gyms',
    keywords: [
      'gym', 'fitness', 'workout', 'exercise', 'training', 'yoga', 'pilates',
      'crossfit', 'boxing', 'weight', 'cardio',
    ],
  );
  // dart format on

  const PlaceCategory({
    required this.label,
    required this.pluralLabel,
    required this.keywords,
  });

  final String label;
  final String pluralLabel;
  final List<String> keywords;

  static PlaceCategory fromId(String id) {
    for (final category in values) {
      if (category.name == id) return category;
    }
    throw FormatException('Unknown place category "$id"');
  }
}
