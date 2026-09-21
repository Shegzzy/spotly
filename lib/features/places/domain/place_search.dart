import 'package:latlong2/latlong.dart';

import 'place.dart';
import 'place_category.dart';

/// Client-side search over a list of places.
///
/// Every word in the query has to match something about a place: its name,
/// category (including synonyms like "saloon" or "chemist"), highlights or
/// neighbourhood. Matches are forgiving: plurals, accents and one-letter
/// typos are ignored. Results are ranked by match quality, then by distance
/// from [origin] when it's known, then by rating.
class PlaceSearch {
  const PlaceSearch._();

  static const _distance = Distance();

  static List<Place> run(
    Iterable<Place> places, {
    String query = '',
    PlaceCategory? category,
    LatLng? origin,
  }) {
    final queryTokens = tokenize(query);
    final scored = <({Place place, int score, double distance})>[];

    for (final place in places) {
      if (category != null && place.category != category) continue;
      final score = queryTokens.isEmpty ? 0 : _score(place, queryTokens);
      if (score < 0) continue;
      final distance = origin == null
          ? 0.0
          : _distance.as(LengthUnit.Meter, origin, place.location);
      scored.add((place: place, score: score, distance: distance));
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final byDistance = a.distance.compareTo(b.distance);
      if (byDistance != 0) return byDistance;
      return b.place.rating.compareTo(a.place.rating);
    });
    return [for (final entry in scored) entry.place];
  }

  /// Returns -1 when any query word fails to match.
  static int _score(Place place, List<String> queryTokens) {
    final name = tokenize(place.name);
    final categoryWords = _categoryTokens[place.category]!;
    final tags = tokenize(place.tags.join(' '));
    final area = tokenize('${place.area} ${place.address}');

    var total = 0;
    for (final token in queryTokens) {
      final best = [
        _match(token, name, exact: 10, prefix: 8, fuzzy: 5),
        _match(token, categoryWords, exact: 7, prefix: 6, fuzzy: 4),
        _match(token, tags, exact: 5, prefix: 4, fuzzy: 3),
        _match(token, area, exact: 4, prefix: 3, fuzzy: 0),
      ].reduce((a, b) => a > b ? a : b);
      if (best == 0) return -1;
      total += best;
    }

    // Favour names containing the query as typed, e.g. "jollof co".
    final phrase = queryTokens.join(' ');
    if (queryTokens.length > 1 && name.join(' ').contains(phrase)) total += 5;
    return total;
  }

  static int _match(
    String token,
    List<String> words, {
    required int exact,
    required int prefix,
    required int fuzzy,
  }) {
    var best = 0;
    for (final word in words) {
      if (word == token) return exact;
      if (word.startsWith(token)) {
        best = best > prefix ? best : prefix;
      } else if (fuzzy > 0 && best < fuzzy && _isTypo(token, word)) {
        best = fuzzy;
      }
    }
    return best;
  }

  static final Map<PlaceCategory, List<String>> _categoryTokens = {
    for (final category in PlaceCategory.values)
      category: tokenize(
        [category.label, category.pluralLabel, ...category.keywords].join(' '),
      ),
  };

  /// Lowercases, strips accents and punctuation, and reduces simple plurals
  /// so "Cafés", "cafe" and "cafes" all become `cafe`.
  static List<String> tokenize(String input) {
    final normalized = _stripAccents(input.toLowerCase())
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
    if (normalized.isEmpty) return const [];
    return [for (final word in normalized.split(' ')) _stem(word)];
  }

  static String _stem(String word) {
    if (word.length > 4 && word.endsWith('ies')) {
      return '${word.substring(0, word.length - 3)}y';
    }
    if (word.length > 3 && word.endsWith('s') && !word.endsWith('ss')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  // dart format off
  static const _accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'è': 'e', 'é': 'e', 'ê': 'e',
    'ë': 'e', 'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ò': 'o', 'ó': 'o',
    'ô': 'o', 'ö': 'o', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ọ': 'o',
    'ẹ': 'e', 'ṣ': 's', 'ç': 'c', 'ñ': 'n',
  };
  // dart format on

  static String _stripAccents(String input) {
    final buffer = StringBuffer();
    for (final char in input.split('')) {
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString();
  }

  /// True when [a] and [b] are within a small edit distance, scaled by
  /// length so short words must match more closely.
  static bool _isTypo(String a, String b) {
    if (a.length < 4) return false;
    final allowed = a.length >= 8 ? 2 : 1;
    if ((a.length - b.length).abs() > allowed) return false;
    return _editDistance(a, b, allowed) <= allowed;
  }

  /// Levenshtein distance with transpositions, abandoning early once every
  /// path exceeds [limit].
  static int _editDistance(String a, String b, int limit) {
    var previousPrevious = List<int>.filled(b.length + 1, 0);
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = i;
      var rowMin = current[0];
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        var value = [
          previous[j] + 1,
          current[j - 1] + 1,
          previous[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
        if (i > 1 &&
            j > 1 &&
            a[i - 1] == b[j - 2] &&
            a[i - 2] == b[j - 1] &&
            previousPrevious[j - 2] + 1 < value) {
          value = previousPrevious[j - 2] + 1;
        }
        current[j] = value;
        if (value < rowMin) rowMin = value;
      }
      if (rowMin > limit) return limit + 1;
      previousPrevious = previous;
      previous = current;
    }
    return previous[b.length];
  }
}
