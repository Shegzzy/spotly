import 'package:assessment_app/features/places/domain/opening_hours.dart';
import 'package:flutter_test/flutter_test.dart';

/// 2026-09-21 is a Monday.
DateTime monday(int hour, [int minute = 0]) =>
    DateTime.utc(2026, 9, 21, hour, minute);

void main() {
  group('TimeRange', () {
    test('parses regular, overnight and all-day ranges', () {
      expect(TimeRange.parse('08:00-20:30'), const TimeRange(480, 1230));
      expect(TimeRange.parse('17:00-02:00').isOvernight, isTrue);
      expect(TimeRange.parse('00:00-24:00').isAllDay, isTrue);
      expect(TimeRange.parse('00:00-24:00').isOvernight, isFalse);
    });

    test('rejects malformed input', () {
      expect(() => TimeRange.parse('8am-5pm'), throwsFormatException);
      expect(() => TimeRange.parse('08:00'), throwsFormatException);
    });

    test('round-trips through format', () {
      expect(TimeRange.parse('07:30-19:05').format(), '07:30-19:05');
    });
  });

  group('OpeningHours.statusAt', () {
    final weekdays = OpeningHours.fromJson([
      '08:00-20:00',
      '08:00-20:00',
      '08:00-20:00',
      '08:00-20:00',
      '08:00-20:00',
      '10:00-16:00',
      null,
    ]);

    test('is open during the day and closes at the end of the window', () {
      final status = weekdays.statusAt(monday(12));
      expect(status.isOpen, isTrue);
      expect(status.nextChange, monday(20));
    });

    test('is closed before opening and opens later today', () {
      final status = weekdays.statusAt(monday(6, 30));
      expect(status.isOpen, isFalse);
      expect(status.nextChange, monday(8));
    });

    test('is closed after hours and opens tomorrow', () {
      final status = weekdays.statusAt(monday(21));
      expect(status.isOpen, isFalse);
      expect(status.nextChange, DateTime.utc(2026, 9, 22, 8));
    });

    test('skips closed days when finding the next opening', () {
      final saturdayEvening = DateTime.utc(2026, 9, 26, 18);
      final status = weekdays.statusAt(saturdayEvening);
      expect(status.isOpen, isFalse);
      // Sunday is closed, so the next opening is Monday morning.
      expect(status.nextChange, DateTime.utc(2026, 9, 28, 8));
    });

    test('flags closing within the hour', () {
      final now = monday(19, 15);
      expect(
        weekdays.statusAt(now).closesWithin(const Duration(hours: 1), now),
        isTrue,
      );
      final earlier = monday(15);
      expect(
        weekdays
            .statusAt(earlier)
            .closesWithin(const Duration(hours: 1), earlier),
        isFalse,
      );
    });

    group('overnight windows', () {
      final lateNight = OpeningHours(
        List.filled(7, TimeRange.parse('17:00-02:00')),
      );

      test('is open after midnight from the previous evening', () {
        final status = lateNight.statusAt(monday(1, 30));
        expect(status.isOpen, isTrue);
        expect(status.nextChange, monday(2));
      });

      test('is open in the evening and closes after midnight', () {
        final status = lateNight.statusAt(monday(22));
        expect(status.isOpen, isTrue);
        expect(status.nextChange, DateTime.utc(2026, 9, 22, 2));
      });

      test('is closed in the gap between windows', () {
        final status = lateNight.statusAt(monday(10));
        expect(status.isOpen, isFalse);
        expect(status.nextChange, monday(17));
      });
    });

    test('24/7 places never change', () {
      final always = OpeningHours(
        List.filled(7, TimeRange.parse('00:00-24:00')),
      );
      final status = always.statusAt(monday(3));
      expect(status.isOpen, isTrue);
      expect(status.nextChange, isNull);
      expect(always.isAlwaysOpen, isTrue);
    });

    test('an all-day window followed by normal hours closes at midnight', () {
      final hours = OpeningHours(
        [
          '00:00-24:00',
          '09:00-17:00',
          null,
          null,
          null,
          null,
          null,
        ].map((d) => d == null ? null : TimeRange.parse(d)).toList(),
      );
      final status = hours.statusAt(monday(15));
      expect(status.isOpen, isTrue);
      expect(status.nextChange, DateTime.utc(2026, 9, 22));
    });

    test('a place closed all week has no next change', () {
      final closed = OpeningHours(List.filled(7, null));
      final status = closed.statusAt(monday(12));
      expect(status.isOpen, isFalse);
      expect(status.nextChange, isNull);
    });
  });

  test('requires exactly seven days', () {
    expect(() => OpeningHours([null]), throwsArgumentError);
  });
}
