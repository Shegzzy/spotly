import 'package:assessment_app/core/utils/formatters.dart';
import 'package:assessment_app/features/places/domain/opening_hours.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('distance', () {
    expect(Formatters.distance(4), '10 m');
    expect(Formatters.distance(846), '850 m');
    expect(Formatters.distance(1234), '1.2 km');
    expect(Formatters.distance(14600), '15 km');
  });

  test('time', () {
    expect(Formatters.time(DateTime.utc(2026, 1, 1, 9)), '9 AM');
    expect(Formatters.time(DateTime.utc(2026, 1, 1, 21, 30)), '9:30 PM');
    expect(Formatters.time(DateTime.utc(2026, 1, 1)), 'Midnight');
    expect(Formatters.time(DateTime.utc(2026, 1, 1, 12)), 'Noon');
  });

  test('time ranges', () {
    expect(
      Formatters.timeRange(TimeRange.parse('08:00-21:30')),
      '8 AM – 9:30 PM',
    );
    expect(
      Formatters.timeRange(TimeRange.parse('00:00-24:00')),
      'Open 24 hours',
    );
  });

  test('price level and counts', () {
    expect(Formatters.priceLevel(3), '₦₦₦');
    expect(Formatters.compactCount(312), '312');
    expect(Formatters.compactCount(1104), '1.1k');
  });

  group('OpenStatusText', () {
    final now = DateTime.utc(2026, 9, 21, 12); // Monday noon

    test('open with a closing time', () {
      final text = OpenStatusText.describe(
        OpenStatus(isOpen: true, nextChange: DateTime.utc(2026, 9, 21, 21)),
        now,
      );
      expect(
        (text.headline, text.detail, text.tone),
        ('Open', 'Closes 9 PM', OpenTone.open),
      );
    });

    test('closing soon', () {
      final text = OpenStatusText.describe(
        OpenStatus(isOpen: true, nextChange: DateTime.utc(2026, 9, 21, 12, 40)),
        now,
      );
      expect(text.tone, OpenTone.closingSoon);
      expect(text.headline, 'Closes soon');
    });

    test('late-night closing reads as a time, not a day', () {
      final text = OpenStatusText.describe(
        OpenStatus(isOpen: true, nextChange: DateTime.utc(2026, 9, 22, 2)),
        DateTime.utc(2026, 9, 21, 22),
      );
      expect(text.detail, 'Closes 2 AM');
    });

    test('closed until tomorrow or a later day', () {
      expect(
        OpenStatusText.describe(
          OpenStatus(isOpen: false, nextChange: DateTime.utc(2026, 9, 22, 8)),
          now,
        ).detail,
        'Opens tomorrow 8 AM',
      );
      expect(
        OpenStatusText.describe(
          OpenStatus(isOpen: false, nextChange: DateTime.utc(2026, 9, 24, 8)),
          now,
        ).detail,
        'Opens Thu 8 AM',
      );
    });

    test('24 hours', () {
      final text = OpenStatusText.describe(const OpenStatus(isOpen: true), now);
      expect(text.headline, 'Open 24 hours');
      expect(text.detail, isEmpty);
    });
  });
}
